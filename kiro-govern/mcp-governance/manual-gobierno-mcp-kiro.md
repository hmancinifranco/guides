# Manual de gobierno de MCP en Kiro

> Guía de implementación para administradores. Cubre el modelo cliente/server,
> qué controla realmente el MCP Registry, cómo cargarlo en un Kiro Profile de AWS,
> y las buenas prácticas de seguridad. Documento genérico, no atado a un rol.

Archivo de referencia que acompaña este manual: `mcp-registry.json` (allow-list
recomendada, en este mismo directorio).

---

## 1. Modelo cliente / server (leer primero)

MCP (Model Context Protocol) es el "idioma" con el que un programa de IA se conecta
a proveedores de herramientas. Hay dos roles:

- **Cliente (MCP client / host):** es **Kiro** corriendo en la máquina del
  desarrollador (IDE, CLI, etc.). Kiro *consume* las herramientas. El "cliente" no
  es una persona: es la app Kiro instalada en el laptop.
- **Server (MCP server):** proveedor de herramientas. Le ofrece a Kiro un menú de
  *tools* (buscar documentación, listar buckets, leer un repo…) y las ejecuta.

El modelo de IA nunca toca AWS ni el disco directamente: le pide al server, y el
server realiza la acción.

### Los dos tipos de server

| Tipo | ¿Quién lo ejecuta? | Cómo | En el registry |
|---|---|---|---|
| **Local (stdio)** | **Kiro lo lanza** como proceso hijo en el laptop del dev | Corre `uvx`/`npx`/`docker` según el paquete; se comunican por stdin/stdout | bloque `packages` |
| **Remoto (HTTP/SSE)** | Ya corre en infra externa; **Kiro solo se conecta** | HTTPS a una URL | bloque `remotes` |

El `registryType` de un server local le dice a Kiro qué lanzador usar:
`npm` → `npx`, `pypi` → `uvx`, `oci` → `docker`. **Esos lanzadores deben estar
preinstalados** en la máquina del desarrollador. El dev no arranca nada a mano:
Kiro lo hace automáticamente cuando el server está permitido.

**Implicancia de seguridad:** un server local corre como proceso **con los
privilegios del usuario** (acceso a archivos, variables de entorno, secretos y
credenciales de la sesión) y **fuera del sandbox** de Kiro. Kiro lo lanza pero no lo
aísla. Los remotos corren en infra ajena: el riesgo se corre a "¿confío en ese
endpoint?" y "¿qué datos le envío?".

---

## 2. Qué es el MCP Registry y el Kiro Profile

- **MCP Registry (en gobierno de Kiro):** un **archivo JSON** que publicás y que
  contiene la **lista blanca (allow-list)** de MCP servers autorizados. Su formato
  es un subconjunto del estándar *MCP registry standard v0.1*. No es un servicio que
  se instale: es un archivo que se redacta, valida y sirve por HTTPS.
- **Kiro Profile:** la abstracción de gestión que define y aplica los ajustes
  administrativos a los usuarios enterprise en **una cuenta AWS + una región**
  (una sola por cuenta/región). Se administra desde la **Kiro console**.
- Los profiles pueden ser de **nivel organización** o de **nivel cuenta**, y **el de
  cuenta prevalece** sobre el de organización. Patrón típico: denegar/limitar por
  defecto en la organización y habilitar con allow-list para cuentas concretas.

El Kiro Profile lleva dos atributos de gobierno de MCP: un **toggle MCP on/off** y
una **URL de MCP Registry**. Los clientes Kiro que autentican contra ese profile
descargan y **obligan** esa política.

**Alcance:** el gobierno de MCP aplica solo a usuarios que autentican con una
**identidad corporativa**: AWS IAM Identity Center, Okta o Microsoft Entra ID.
Usuarios con **Builder ID o login social NO quedan sujetos** a los controles de
organización. Habilitar la autenticación corporativa es prerrequisito del gobierno.

---

## 3. Cuánta granularidad de control da realmente el registry

Punto clave y frecuentemente malinterpretado: **el registry controla a nivel
*server*, no a nivel *acción/tool*.**

| Nivel de control | ¿En el registry? | Robustez |
|---|---|---|
| Prender/apagar un server entero | Sí, total (está = permitido; no está = bloqueado) | Fuerte (el usuario no puede sumar servers fuera de la lista) |
| Fijar la versión que corre | Sí | Fuerte |
| Limitar el server con un **argumento** nativo (`packageArguments`) | Solo si el server expone ese flag | Fuerte (los args del registry son read-only para el usuario) |
| Limitar el server con una **variable de entorno** | Solo si el server la honra | **Débil** (las env vars del usuario sobrescriben las del registry) |
| Habilitar/deshabilitar **tools individuales** | **No existe en el registry** | — |

El control fino de acciones vive en **tres capas fuera del "server on/off"**:

1. **Flags/env del propio server** (cuando existen): p. ej. omitir `--allow-write`
   deja `aws-serverless` en read-only; fijar el directorio permitido acota
   `filesystem`. Es capacidad del server, no universal.
2. **IAM (para AWS) o el scope del token (para SaaS):** el control de acciones
   **real y el único robusto**. Un rol *ReadOnly* bloquea toda escritura sin importar
   qué flag tenga el server o qué edite el usuario.
3. **`disabledTools` / `autoApprove` por tool:** existen, pero **solo en la config
   local del cliente**, que es del usuario y **no se gobierna centralmente**.

**Regla mental:** el registry es un *interruptor por server* (y, si el server lo
permite, un selector grueso de "modo"). No es un panel de permisos por acción. El
permiso por acción real lo pone IAM o el scope del token.

**Argumento vs. variable de entorno — la diferencia que importa:**
- Un freno puesto por **argumento** (ej. ausencia de `--allow-write`) el usuario
  **no lo puede revertir** desde su config → robusto.
- Un freno puesto por **env var** (ej. `READ_OPERATIONS_ONLY=true`) el usuario
  **sí lo puede pisar** → débil; ahí el candado duro es IAM.

---

## 4. Implementación paso a paso

### Opción A — Deshabilitar MCP por completo (más restrictivo)

1. Kiro console → **Settings**.
2. En **Shared settings**, toggle **Model Context Protocol (MCP)** en **Off**.

Efecto: el cliente suprime **todos** los servers (user-configured, legacy, registry,
session-injected). `/mcp` muestra `MCP has been disabled by your administrator`.

*Fail-closed:* si el cliente no puede alcanzar la API de gobierno, MCP queda
deshabilitado (`Failed to retrieve MCP settings — MCP disabled`). Suele ser
transitorio.

### Opción B — Publicar una allow-list (MCP Registry)

**Paso 1 — Redactar el JSON.** Allow-list pura: lo que está se permite; lo que se
omite se deniega. (Ver §5 para el formato y `mcp-registry.json` como base.)

**Paso 2 — Servir por HTTPS.** Cualquier server web: Amazon S3 (+ CloudFront),
Apache o nginx. La URL debe ser accesible desde las máquinas de los usuarios (puede
ser privada a la red corporativa). **Requisito:** certificado SSL válido de una CA
de confianza. **Autofirmados no se soportan.**

> ⚠️ **La URL tiene que devolver HTTP 200 sin autenticación interactiva.** Un error
> fácil de cometer es publicar el JSON en un repositorio Git **privado**: la URL raw
> devuelve 404 y el cliente no puede sincronizar. El síntoma es engañoso porque los
> servers siguen funcionando un rato con la copia cacheada, y recién al siguiente
> sync se apaga todo por *fail-closed*. Verificá siempre con:
>
> ```bash
> curl -s -o /dev/null -w "HTTP %{http_code}\n" "<URL_DEL_REGISTRY>"
> ```
>
> Repositorios Git públicos sirven para pruebas rápidas, pero para producción usá
> S3 + CloudFront (patrón de abajo): controlás el acceso por red y tenés versionado.

Patrón AWS recomendado (esquema):

```
Bucket S3      : privado, sin acceso publico directo, versioning ON
CloudFront     : Origin Access Control (OAC) hacia el bucket
Certificado    : ACM sobre dominio corporativo
Ruta publicada : https://mcp-registry.tuempresa.com/registry.json
```

**Paso 3 — Cargar la URL en el Kiro Profile.**
1. Kiro console → **Settings**.
2. Asegurar **MCP** en **On**.
3. Campo **MCP Registry URL** → **Edit** → pegar la URL → **Save**.

La URL se cifra en tránsito y en reposo.

**Jerarquía org/cuenta:** para "denegar por defecto, permitir por excepción",
configurá el profile de organización restrictivo y creá profiles de **cuenta** con
MCP On + su registry para los equipos que lo necesiten (el de cuenta prevalece).

### Ciclo de sincronización (operativa)

Kiro descarga el registry **al arrancar y cada 24 h**. En cada sync:
- Si un server local instalado **ya no está** en el registry → Kiro lo **termina** e
  impide volver a agregarlo.
- Si el server local tiene **otra versión** que la del registry → Kiro lo **relanza
  con la versión del registry**.

Implicancia: **revocar = quitar del JSON** (se propaga en ≤24 h sin tocar máquinas);
pero un error se propaga igual de rápido → versioná el archivo y controlá cambios.

---

## 5. Formato del registry

Estructura: raíz `{ "servers": [ { "server": {...} } ] }`. Campos obligatorios de
cada `server`: `name`, `description`, `version`. `name` con patrón
`^[a-zA-Z0-9._-]+$` (3–200). `description` ≤ 100 caracteres. `version` debe ser
concreta: **los rangos se rechazan** (`^1.2.3`, `~1.2.3`, `>=1.2.3`, `1.x`).
Cada server lleva **o** `packages` (local) **o** `remotes` (remoto), máximo 1 entrada.

**Server local (stdio):**

```json
{
  "server": {
    "name": "awslabs.aws-documentation-mcp-server",
    "title": "AWS Documentation",
    "description": "Busqueda y lectura de documentacion oficial de AWS.",
    "version": "1.0.0",
    "packages": [
      {
        "registryType": "pypi",
        "registryBaseUrl": "https://pypi.org",
        "identifier": "awslabs.aws-documentation-mcp-server",
        "transport": { "type": "stdio" },
        "environmentVariables": [
          { "name": "FASTMCP_LOG_LEVEL", "value": "ERROR" }
        ]
      }
    ]
  }
}
```

**Server remoto (HTTP):**

```json
{
  "server": {
    "name": "aws-knowledge-mcp-server",
    "title": "AWS Knowledge",
    "description": "Conocimiento AWS gestionado. Remoto, sin auth.",
    "version": "1.0.0",
    "remotes": [
      { "type": "streamable-http", "url": "https://knowledge-mcp.global.api.aws" }
    ]
  }
}
```

**Qué puede sobrescribir el usuario** (aunque los parámetros del registry son
read-only): variables de entorno adicionales (locales), headers HTTP adicionales
(remotos), timeout, scope (Global/Workspace/Agente) y los trust permissions de las
tools. Las env vars/headers del usuario **sobrescriben** las del registry — por eso
las env vars son un freno débil (§3).

**Lanzadores requeridos en la máquina:** `npm`→`npx`, `pypi`→`uvx`, `oci`→`docker`.

---

## 6. Buenas prácticas de seguridad

**Origen y cadena de suministro**
- Allow-listear solo servers de fuentes confiables y revisadas (código y proveedor).
- Fijar versiones exactas (el registry lo obliga) y, si se puede, servir paquetes
  desde registros internos (npm/PyPI corporativos vía `registryBaseUrl`).

**Credenciales y secretos**
- Nunca commitear config con tokens. Tokens con permisos mínimos (p. ej. PAT
  fine-grained de GitHub). Rotación periódica.
- Preferir variables de entorno / keychains a hardcodear. En Kiro IDE solo se
  expanden las env vars **explícitamente aprobadas** ("Mcp Approved Env Vars").
- Permisos restrictivos en la config local: `chmod 600 ~/.kiro/settings/mcp.json`.

**Menor privilegio y control de acciones**
- Rol IAM *ReadOnly* como default para servers de AWS; escritura solo donde haga
  falta y con rol dedicado.
- `disabledTools` (config local) para bloquear operaciones peligrosas (ej.
  `delete_repository`, `force_push`).
- Auto-aprobar (config local) **solo** tools de lectura, de fuente verificada, de
  uso frecuente y alcance limitado.

**Red**
- HTTPS para remotos, verificar TLS, restringir egress por firewall, monitorear
  tráfico. Cuidado con servers que piden acceso de red amplio (ej. `fetch`).

**Aislamiento**
- Config a nivel workspace para servers específicos de proyecto: contiene tokens y
  alcance por repo.

**Monitoreo y respuesta**
- Revisar MCP Logs (panel Kiro → Output → "Kiro - MCP Logs"). Auditar auto-approves.
- Incidente: deshabilitar el server, revocar tokens, revisar actividad en los
  servicios conectados, reportar al mantenedor.

**Límite de fondo (repetir siempre):** el toggle y el registry se aplican
**client-side** y un usuario con admin local puede eludirlos. Combinar con controles
de endpoint (MDM/EDR), perímetros de red e IAM. No es una barrera criptográfica.

---

## 7. Powers y su relación con el registry

Un **Power** es un plugin (estándar *Agent Plugins*) que empaqueta skills +
conocimiento + **opcionalmente un MCP server** (`mcp.json`). Instala con un clic y
**carga sus tools MCP dinámicamente** (solo cuando aparecen keywords relevantes),
lo que reduce el ruido de contexto y la superficie de ataque en reposo.

**Punto de compatibilidad:** el gobierno de MCP suprime todos los servers no
allow-listeados, **incluidos los que un Power inyecta**. Por lo tanto, para que un
Power funcione bajo gobierno, **el MCP server que trae adentro debe estar en el
registry**. Regla operativa: por cada Power aprobado, mirar su `mcp.json`, extraer
sus servers y agregarlos al registry.

Mapeo verificado (Powers → servers a allow-listear):

| Power | MCP servers | Paquete/endpoint real |
|---|---|---|
| aws-sam | aws-serverless, fetch | `awslabs.aws-serverless-mcp-server`, `mcp-server-fetch` |
| aws-observability | cloudwatch, appsignals, cloudtrail, prometheus, aws-docs | `awslabs.cloudwatch-mcp-server`, `awslabs.cloudwatch-applicationsignals-mcp-server`, `awslabs.cloudtrail-mcp-server`, `awslabs.prometheus-mcp-server`, `awslabs.aws-documentation-mcp-server` |
| cloud-architect | awspricing, awsknowledge, awsapi, context7, fetch | `awslabs.aws-pricing-mcp-server`, `https://knowledge-mcp.global.api.aws`, `awslabs.aws-api-mcp-server`, `@upstash/context7-mcp`, `mcp-server-fetch` |
| aws-transform-agent-toolkit | aws-transform-agent-toolkit | `awslabs.aws-transform-mcp-server` |
| Strands | strands | `strands-agents-mcp-server` |

> **Nota:** este mapeo lista lo que cada Power declara. Nuestra allow-list no incluye
> `mcp-server-fetch` ni `awslabs.aws-api-mcp-server`: el primero está roto respecto
> del SDK `mcp` actual, y el segundo quedó cubierto por `aws-mcp` (Agent Toolkit),
> cuyo `run_script` reemplaza a `call_aws`. Los Powers que dependan de ellos van a
> funcionar con capacidades reducidas hasta que se resuelva cada caso.

---

## 8. Agent Toolkit for AWS vs. MCP servers individuales

El **Agent Toolkit for AWS** es la oferta oficial de AWS para dar a los agentes
(Kiro, Claude Code, Cursor, Codex…) herramientas + conocimiento + guardrails.
Componentes: **AWS MCP Server** (server gestionado, endpoint único; docs sin auth,
acciones con IAM), **agent skills**, **plugins** (Kiro no los necesita: se conecta
directo) y **rules files**.

Por qué es relevante para gobierno: a diferencia de un server de terceros, el AWS
MCP Server está diseñado para control central:
- Autenticación con tus **roles IAM** existentes (SigV4 o OAuth 2.1).
- **CloudTrail** registra todas las llamadas; **CloudWatch** aporta métricas.
- Agrega automáticamente los *condition keys* `aws:ViaAWSMCPService` y
  `aws:CalledViaAWSMCP` → podés diferenciar en IAM lo iniciado vía MCP y, p. ej.,
  forzar read-only para todo lo que venga por ahí.

Cuándo usar cada uno:
- **AWS MCP Server (Agent Toolkit):** punto de acceso gobernado a AWS (leer docs +
  ejecutar acciones bajo IAM/CloudTrail). Preferible a armar `aws-api`/`aws-serverless`
  sueltos — la doc oficial marca a `aws-api` como **superado** por él.
- **Servers individuales:** para lo que no es AWS o no cubre el toolkit (GitHub,
  bases de datos, observabilidad de terceros, Playwright, filesystem, drawio…).
- **Combinar:** publicar en el registry el AWS MCP Server (o los awslabs) + el puñado
  de servers no-AWS aprobados, y reforzar con rules files en los proyectos.

Modelo de dos capas: **registry + Kiro Profile = "qué servers pueden existir";
IAM + CloudTrail = "qué pueden hacer contra AWS y cómo se audita".**

---

## 9. Configurar el cliente Kiro (guía rápida para el developer)

Una vez que el administrador publicó el registry y cargó la URL en el Kiro Profile,
el developer necesita configurar su cliente. Esta sección explica cómo.

### Prerequisitos en la máquina del developer

| Lanzador | Instalar si no lo tenés | Para qué servers |
|---|---|---|
| `uvx` (viene con `uv`) | `brew install uv` o [guía oficial](https://docs.astral.sh/uv/getting-started/installation/) | Todos los `registryType: "pypi"` |
| `npx` (viene con Node.js) | `brew install node` o [nodejs.org](https://nodejs.org/) | Todos los `registryType: "npm"` |
| `docker` (opcional) | [docker.com](https://www.docker.com/products/docker-desktop/) | Solo si hay `registryType: "oci"` |

### Archivo de configuración

El archivo del cliente es `.kiro/settings/mcp.json` (a nivel workspace) o
`~/.kiro/settings/mcp.json` (global). Usá el template `mcp-client-config.json`
de este repo como base.

### Tipos de entrada en el mcp.json del cliente

**Servers remotos y npm** — usar referencia al registry:

```json
{
  "server-name": {
    "type": "registry",
    "disabled": false
  }
}
```

Kiro descarga la definición completa del registry (URL, headers, paquete, args).
El developer no necesita saber los detalles — solo el `name`.

**Servers pypi (uvx)** — usar configuración explícita:

```json
{
  "awslabs.aws-documentation-mcp-server": {
    "command": "uvx",
    "args": ["awslabs.aws-documentation-mcp-server@latest"],
    "env": {
      "FASTMCP_LOG_LEVEL": "ERROR",
      "AWS_DOCUMENTATION_PARTITION": "aws"
    },
    "disabled": false
  }
}
```

> **Nota:** los servers pypi se configuran con `"command": "uvx"` explícito y el
> identifier con `@latest` para mantenimiento cero. El `name` (key del JSON) debe
> coincidir exactamente con el `name` del server en el registry para que el
> governance lo acepte.

### Credenciales: el patrón placeholder + variable de entorno

Este es el punto que más confusión genera, así que vale explicarlo completo.

**El problema:** el registry es **uno solo para toda la organización**, pero cada
developer tiene un **perfil IAM distinto** (`hmancini+genia-admin`, `juan-readonly`,
etc.). No podés hardcodear un perfil en el registry.

**La solución:** el registry declara un **placeholder** `${VAR}` y cada developer
define esa variable en **su** shell. Kiro la expande al lanzar el server.

```
Registry (admin, compartido)          Shell del developer (personal)
─────────────────────────────         ──────────────────────────────
"environmentVariables": [        →    export AWS_PROFILE=mi-perfil
  { "name": "AWS_PROFILE",
    "value": "${AWS_PROFILE}" }       Kiro lanza el server con
]                                     AWS_PROFILE=mi-perfil
```

Así el registry queda **agnóstico del usuario** y cada uno usa sus credenciales sin
tocar el JSON compartido.

**Configuración del developer:**

```bash
# Definir el perfil (usar uno de los que tengas en ~/.aws/config)
export AWS_PROFILE=mi-perfil-readonly

# Para que persista entre sesiones
echo 'export AWS_PROFILE=mi-perfil-readonly' >> ~/.zshrc
```

> ⚠️ **Reiniciá Kiro después de definir la variable.** Kiro hereda el entorno del
> proceso que lo lanzó; si exportás la variable en una terminal con Kiro ya abierto,
> el IDE no la ve.

**Cómo verificar que está definida:**

```bash
echo "AWS_PROFILE=[${AWS_PROFILE}]"    # debe mostrar el nombre, no [] vacío
aws configure list-profiles            # perfiles disponibles
```

#### Por qué algunos servers fallan y otros no cuando falta la credencial

No todos los servers reaccionan igual a un `AWS_PROFILE` ausente o vacío. Hay dos
comportamientos:

| Comportamiento | Servers | Sin `AWS_PROFILE` |
|---|---|---|
| **Validación al arranque** — crean la sesión boto3 durante el init | `aws-mcp`, `cloudwatch`, `cloudwatch-applicationsignals`, `prometheus`, `aws-serverless`, `aws-transform` | ❌ El proceso muere → `Connection closed` |
| **Carga diferida** — resuelven credenciales en la primera llamada | `aws-documentation`, `aws-pricing`, `cloudtrail` | ✅ Conecta; falla recién al usar un tool |

**Síntoma típico del problema:** el panel MCP muestra `Connection Failed` con
`MCP error -32000: Connection closed` en los servers de la primera fila, mientras
los de la segunda conectan sin problema. Si ves ese patrón, lo primero a revisar es
si `AWS_PROFILE` está definido y **no vacío**.

La causa técnica: cuando el placeholder no expande, el server recibe
`AWS_PROFILE=""` (string vacío) y boto3 falla al inicializar la sesión con un perfil
sin nombre. El proceso termina antes de completar el handshake MCP, y Kiro lo
reporta como conexión cerrada.

#### Otros placeholders del mismo patrón

| Placeholder | Para qué | Cómo lo define el developer |
|---|---|---|
| `${AWS_PROFILE}` | Perfil IAM de los servers AWS | `export AWS_PROFILE=mi-perfil` |
| `${ALLOWED_PATH}` | Directorio permitido de `filesystem` | `export ALLOWED_PATH=/Users/yo/proyectos` |

Regla general: **todo lo que sea específico del developer va como placeholder en el
registry y como variable de entorno en su máquina.** El registry solo lleva valores
compartidos (región de la org, nivel de log, flags de seguridad).

### Controles opcionales del developer

| Control | Dónde | Ejemplo |
|---|---|---|
| Deshabilitar un server | `"disabled": true` | Server de alto riesgo que solo se habilita bajo demanda |
| Bloquear tools peligrosos | `"disabledTools": [...]` | `["delete_repository", "force_push"]` en github |
| Auto-aprobar tools de lectura | `"autoApprove": [...]` | `["search_documentation", "read_documentation"]` |
| Timeout extendido | `"timeout": 100000` | Para servers lentos como `aws-mcp` (proxy remoto) |

### Verificar la conexión

1. Abrí el panel **MCP Servers** en Kiro (icono en la barra lateral).
2. Cada server debería mostrar **Connected** (✔) o **Connection Failed** (✖).
3. Para más detalle: Command Palette → `Kiro: Show MCP Logs`.
4. Test rápido: preguntale a Kiro *"¿Qué regiones de AWS hay disponibles?"* — si
   responde usando `aws-mcp` o `aws-knowledge-mcp-server`, la conexión funciona.

### Diagnóstico de `Connection closed`

Si un server local muestra `MCP error -32000: Connection closed`, significa que el
proceso arrancó y **murió antes de completar el handshake**. Revisá en este orden:

| # | Revisar | Cómo |
|---|---|---|
| 1 | ¿El lanzador está instalado? | `which uvx` / `which npx` |
| 2 | ¿La variable de entorno está definida y no vacía? | `echo "[${AWS_PROFILE}]"` |
| 3 | ¿El server arranca a mano? | Ver comando abajo |
| 4 | ¿El paquete es compatible con su SDK? | El traceback lo dice (`ImportError` / `AttributeError`) |

Para probar un server local fuera de Kiro y ver el error real:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}' \
  | AWS_PROFILE=mi-perfil uvx <identifier-del-registry>
```

Si devuelve un JSON con `"result"` y `serverInfo`, el server está sano y el problema
es de configuración. Si devuelve un traceback de Python, el problema está en el
paquete o en sus dependencias.

> **Nota sobre `registryBaseUrl`:** este campo es **opcional** y conviene omitirlo en
> entradas `pypi`. El valor `https://pypi.org` es el sitio web, **no** el índice de
> paquetes PEP 503 (que sería `https://pypi.org/simple/`), y si el cliente lo usa
> como índice, `uvx` no resuelve ningún paquete y el server muere al arrancar.
> Omitiéndolo, el lanzador usa su índice por defecto, que es lo correcto. Para `npm`
> sí es válido declarar `https://registry.npmjs.org`.

### Estructura de archivos de referencia

```
kiro-govern/mcp-governance/
├── mcp-registry.json          ← allow-list (publicar por HTTPS)
├── mcp-client-config.json     ← template para .kiro/settings/mcp.json
├── manual-gobierno-mcp-kiro.md        ← este manual
└── playbook-kiro-registry-implementacion.md  ← playbook operativo
```

---

## 10. Set recomendado (referencia)

La allow-list de arranque está en `mcp-registry.json` (15 servers), organizada por
riesgo:

- **Bajo / lectura:** aws-documentation, aws-knowledge, aws-pricing, cloudwatch (x2),
  cloudtrail, prometheus, strands, context7, drawio.
- **Medio:** filesystem (acotado por `${ALLOWED_PATH}`).
- **Alto (habilitar por cuenta/equipo, IAM mínimo, sin auto-approve):** aws-mcp
  (Agent Toolkit), aws-serverless, aws-transform, chrome-devtools.

Antes de agregar un server a la allow-list, **verificá que arranca** con el
procedimiento de §9 (Diagnóstico). Los paquetes de la comunidad pueden quedar
desactualizados respecto del SDK `mcp` y romperse; no tiene sentido publicar en el
registry algo que no puede conectar.

Estrategia de versión: **mantenimiento cero con `latest`**. Todos los servers
locales usan `"version": "latest"`, así Kiro relanza siempre con la última release
publicada sin editar el JSON. `latest` es un valor válido (no es un rango; los rangos
sí se rechazan). Trade-off asumido: se adoptan releases nuevas automáticamente sin
re-vetting — aceptable para este set; si algún server pasara a ser crítico, se puede
fijar su versión exacta puntualmente. Antes de producción: ajustar el directorio de
`filesystem` y el token de `github` (por override de usuario), y servir el archivo
por HTTPS con CA de confianza.

---

## Anexo — Comportamientos a recordar

- **Fail-closed** ante falla de la API de gobierno (MCP se apaga).
- **Refresco cada 24 h** + al arrancar; revocar = quitar del JSON.
- **Enforcement client-side** → combinar con IAM, endpoint y red.
- **Builder ID / social** no quedan gobernados a nivel organización.
