# Set base de seguridad / postura de código para Kiro

Plantilla mínima y **reutilizable** para hacer revisiones básicas de seguridad y postura de código con Kiro. Se adopta tal cual y luego se **reemplazan las partes genéricas por el stack propio de cada cliente**. Destilada del patrón `.kiro` del repo de referencia (`RahulRaja-14/sample`) y de la guía "Security Enforcement with Kiro".

## Índice

- [Modelo de capas](#modelo-de-capas)
- [Estructura](#estructura)
- [Instalación rápida](#instalación-rápida)
- [Guía de adopción y personalización por stack](#guía-de-adopción-y-personalización-por-stack)
  - [Opción A — Manual](#opción-a--manual-paso-a-paso)
  - [Opción B — Vía prompt a Kiro](#opción-b--vía-prompt-a-kiro-instalar-y-adaptar)
- [Capa 4 (opcional): hook anti-secretos + gate de CI](#capa-4-opcional-hook-anti-secretos--gate-de-ci)
- [Cómo se usa en el día a día](#cómo-se-usa-en-el-día-a-día)
- [Brief de implementación por cliente](#brief-de-implementación-por-cliente)
- [Extensión y notas de diseño](#extensión-y-notas-de-diseño)

## Modelo de capas

Defensa en profundidad. Las 3 primeras capas son el set base; la 4ª es opcional.

| Capa | Archivo | Cuándo actúa | Propósito |
|---|---|---|---|
| **1. Prevención** | `.kiro/steering/security-baseline.md` | Siempre (`inclusion: always`) | Reglas no negociables aplicadas en cada generación/edición de código. Evita que el problema se escriba. |
| **2. Revisión** | `.kiro/steering/code-review-and-quality.md` | Manual (`#code-review-and-quality`) | Mirada de calidad en 5 ejes al revisar un diff/PR. |
| **3. Auditoría** | `.kiro/skills/security-review/SKILL.md` + `docs/security-validation.md` | A demanda | Auditoría profunda, modelado de amenazas e informe con severidades. |
| **4. Barreras (opcional)** | `.kiro/hooks/secrets-detection.json.example` + `.github/workflows/security-review.yml` | Al escribir / en cada PR | Hook que bloquea secretos al escribir y gate de CI que corta PRs con hallazgos bloqueantes. |

## Estructura

```
.kiro/
  steering/
    security-baseline.md          # capa 1 — always-on: reglas no negociables
    code-review-and-quality.md    # capa 2 — manual: revisión en 5 ejes + severidades
  skills/
    security-review/
      SKILL.md                    # capa 3 — auditoría a demanda: alcance, severidad, reporte
      references/
        security-checklist.md     # checklist detallado de apoyo
  hooks/
    secrets-detection.json.example  # capa 4 — hook PreToolUse anti-secretos (deshabilitado; renombrar a .json para activar)
    scripts/
      detect-secrets.sh           # lógica del hook (patrones de secretos)
docs/
  security-validation.md          # capa 3 — checklist ejecutable para PR/release
  IMPLEMENTATION_BRIEF.md         # plantilla de brief por cliente (mapea el PDF a lo aplicado)
  ci/
    gitlab-ci.yml                 # capa 4 — gate de CI (ejemplo GitLab)
    azure-pipelines-security-review.yml  # capa 4 — gate de CI (ejemplo Azure DevOps)
.github/
  workflows/
    security-review.yml           # capa 4 — gate de CI (ejemplo GitHub Actions)
.gitignore                        # ignora secretos/.env y artefactos de revisión
```

## Instalación rápida

1. Copia `.kiro/` y `docs/` a la raíz del proyecto del cliente. Si usas la capa 4, copia también `.github/workflows/security-review.yml`.
2. Abre el proyecto en Kiro. El steering `security-baseline.md` se carga solo en cada interacción; no hace falta configurar nada.
3. (Recomendado) Personaliza por stack siguiendo la guía de abajo.
4. Versiona los archivos en el repo y revísalos por PR como cualquier otro artefacto.

## Guía de adopción y personalización por stack

El set funciona genérico desde el minuto cero. Para sacarle el máximo, cada cliente reemplaza los puntos personalizables con las herramientas de su stack. **Puntos de reemplazo:**

| Archivo | Qué personalizar |
|---|---|
| `.kiro/steering/security-baseline.md` | Sección **"Ajustes por stack (personalizar)"**: lenguaje/framework, validador de entrada, librería de hashing, gestor de secretos y comando de auditoría de dependencias. |
| `.kiro/skills/security-review/references/security-checklist.md` | Bloque **"Verificación pre-commit"**: comandos de auditoría (`npm audit` → `pip-audit`, `mvn dependency-check`, `cargo audit`, etc.). |
| `docs/security-validation.md` | Ítems del checklist que no apliquen (p. ej. borrar la sección Frontend en un servicio backend puro). |
| `.kiro/hooks/scripts/detect-secrets.sh` | Patrones de secretos según el contexto (proveedores cloud, formatos de token propios). |
| `.github/workflows/security-review.yml` | Paso de instalación/autenticación de Kiro CLI y ramas objetivo; o traducir a GitLab CI / Azure DevOps. |
| `.kiro/steering/code-review-and-quality.md` | Umbrales de tamaño de cambio y ejes, si el equipo usa otros. |

> Regla práctica: **no borres reglas de seguridad, ajústalas.** Cambia *cómo* se cumple una regla (la herramienta concreta), no *si* se cumple.

### Opción A — Manual (paso a paso)

1. **Copia** `.kiro/` (y `docs/`, y la capa 4 si la usas) al repo del cliente.
2. Edita en `.kiro/steering/security-baseline.md` la sección **"Ajustes por stack"**. Ejemplo para Java + Spring Boot + SQL Server:
   - Lenguaje/framework: `Java 21 + Spring Boot 3`
   - Validación de entrada: `Jakarta Bean Validation (@Valid, @NotNull, @Pattern)`
   - Hashing: `Spring Security BCryptPasswordEncoder (strength 12)`
   - Gestor de secretos: `Azure Key Vault`
   - Auditoría de dependencias: `mvn org.owasp:dependency-check-check`
3. Reemplaza los comandos del bloque **"Verificación pre-commit"** en `.kiro/skills/security-review/references/security-checklist.md`.
4. En `docs/security-validation.md`, elimina o marca `N/A` las secciones que no apliquen.
5. (Capa 4) Ajusta patrones en `detect-secrets.sh` y el paso de Kiro CLI en el workflow de CI.
6. Commitea y ábrelo en Kiro. Verifica que el baseline está activo: *"¿qué reglas de seguridad tienes activas para este proyecto?"*.

### Opción B — Vía prompt a Kiro (instalar y adaptar)

Kiro puede crear e instalar todo el set adaptado al stack. Pega uno de estos prompts en una sesión de Kiro abierta en la raíz del proyecto.

**B.1 — Instalar el set base desde cero, adaptado al stack:**

```
Instala un set base de seguridad/postura de código para Kiro en este proyecto,
siguiendo el modelo de capas (prevención always-on, revisión manual, auditoría
on-demand). Crea:
- .kiro/steering/security-baseline.md  (inclusion: always)
- .kiro/steering/code-review-and-quality.md  (inclusion: manual)
- .kiro/skills/security-review/SKILL.md  + references/security-checklist.md
- docs/security-validation.md

Antes de escribir, detecta mi stack revisando los manifiestos del repo
(package.json, pom.xml, requirements.txt/pyproject.toml, go.mod, Cargo.toml, etc.)
y adapta a ese stack: el validador de entrada, la librería de hashing, el gestor
de secretos y el comando de auditoría de dependencias. No inventes herramientas que
no estén en el proyecto: si no puedes determinar algo, déjalo genérico y avísame.
Al terminar, muéstrame un resumen de qué detectaste y qué personalizaste.
```

**B.2 — Adaptar un set ya instalado a mi stack:**

```
Este proyecto ya tiene el set base de seguridad en .kiro/. Detecta mi stack a
partir de los manifiestos del repo y personaliza, sin quitar ninguna regla de
seguridad (solo ajusta cómo se cumple):
- La sección "Ajustes por stack" de .kiro/steering/security-baseline.md
- Los comandos de "Verificación pre-commit" en
  .kiro/skills/security-review/references/security-checklist.md
- Las secciones no aplicables de docs/security-validation.md (márcalas N/A)
Muéstrame un diff de lo que cambiarías antes de aplicarlo.
```

**B.3 — Especializar por stack con carga condicional (opcional):**

```
Crea un steering adicional .kiro/steering/security-<stack>.md con reglas de
seguridad específicas de <mi stack> (ej.: Spring Boot o React). Usa
inclusion: fileMatch con un fileMatchPattern que solo lo cargue al abrir
archivos de ese stack, para no inflar el contexto en cada interacción.
```

**B.4 — Instalar la capa 4 (hook anti-secretos + gate de CI):**

```
Añade la capa de barreras al set de seguridad de este proyecto:
1) Un hook PreToolUse que bloquee escrituras con secretos. Crea
   .kiro/hooks/scripts/detect-secrets.sh (grep de patrones: claves privadas,
   AWS keys, tokens tipo gh_/xox, y pares clave=valor password/secret/api_key)
   que lea el payload por stdin y haga exit 2 si detecta un secreto; y regístralo
   como hook v2 en .kiro/hooks/secrets-detection.json con matcher
   "fs_write|str_replace|fs_append".
2) Un workflow de CI (.github/workflows/security-review.yml) que corra la revisión
   de seguridad sobre el diff del PR usando docs/security-validation.md y falle si
   aparece SECURITY_REVIEW_FAILED. Adáptalo a mi plataforma de CI.
Ajusta los patrones de secretos a mi proveedor cloud y muéstrame un resumen.
```

> Consejo: pídele a Kiro que muestre un **diff o resumen antes de aplicar** (como en B.2). Así revisas la personalización antes de commitear.

## Capa 4 (opcional): hook anti-secretos + gate de CI

Dos barreras automáticas que complementan a las capas 1–3:

**Hook de secretos (`PreToolUse`).** `secrets-detection.json` intercepta `fs_write`, `str_replace` y `fs_append` y ejecuta `detect-secrets.sh`. El script recibe por stdin el contenido a escribir y hace `exit 2` (bloquea) si encuentra patrones de secretos (claves privadas, AWS keys, tokens `gh_`/`xox`, pares `password/secret/api_key = valor`).

> **Deshabilitado por defecto en esta guía.** El hook se entrega como `secrets-detection.json.example` para que no se active al copiar el set. Para activarlo, renómbralo a `secrets-detection.json` en la raíz de tu proyecto; se aplicará al iniciar la próxima sesión de Kiro. (El formato v2 de hooks no tiene un flag `disabled`, por eso se distribuye con extensión `.example`.)

- Personaliza los patrones en `.kiro/hooks/scripts/detect-secrets.sh`.
- Es una red de seguridad: puede dar falsos positivos; ajústalos a tu contexto. Si algo se bloquea por error, el mensaje indica dónde editar los patrones.
- Valida en tu entorno que el hook dispara (el `cwd` del hook debe permitir encontrar el script; si no, usa una ruta absoluta).

**Gate de CI.** Corre Kiro sobre el diff del PR contra `docs/security-validation.md` y falla el pipeline si hay `SECURITY_REVIEW_FAILED`, publicando el informe. Usa el **[modo headless de Kiro CLI](https://kiro.dev/blog/introducing-headless-mode/)**: se instala con `curl -fsSL https://cli.kiro.dev/install | bash` y se autentica con la variable de entorno `KIRO_API_KEY` (guardada como secret del repo), sin login por navegador. Hay ejemplos para las tres plataformas más comunes; usa el que corresponda:

| Plataforma | Archivo | Ubicación canónica |
|---|---|---|
| GitHub Actions | `.github/workflows/security-review.yml` | ya en su sitio (activo) |
| GitLab CI | `docs/ci/gitlab-ci.yml` | copiar el job a tu `.gitlab-ci.yml` |
| Azure DevOps | `docs/ci/azure-pipelines-security-review.yml` | crear pipeline y marcarlo requerido en la branch policy |

Todos siguen la misma idea: extraer diff → pasar a Kiro con el checklist → cortar si hay hallazgos bloqueantes. Los ejemplos de GitLab/Azure se dejan en `docs/ci/` para no pisar la configuración de CI existente del cliente.

**`.gitignore`.** Incluye patrones para no commitear secretos ni entorno (`.env`, `*.pem`, `*.key`, credenciales cloud, etc.) y los artefactos temporales de la revisión (`pr-diff.txt`, `security-review.txt`). Respeta `.env.example` (sí se commitea, como plantilla). Fusiona estas reglas con el `.gitignore` existente del cliente.

## Cómo se usa en el día a día

- **Prevención (automática):** `security-baseline.md` se carga en cada interacción. Kiro aplica las reglas al escribir código y marca conflictos en su respuesta.
- **Revisión de un PR:** en el chat, referencia `#code-review-and-quality` y apunta al diff.
- **Auditoría a demanda:** pide *"revisa este código/diff contra `docs/security-validation.md`"* o invoca la skill `security-review`. Obtienes un informe con severidades (Critical→Info) y veredicto `SECURITY_REVIEW_PASSED` / `SECURITY_REVIEW_FAILED`.
- **Barreras (capa 4):** el hook actúa solo al escribir; el gate de CI, en cada PR.

## Brief de implementación por cliente

`docs/IMPLEMENTATION_BRIEF.md` es una plantilla para documentar, por cada cliente, **qué aplicamos y cómo**, mapeando cada capa del documento del cliente ("Security Enforcement with Kiro") a lo entregado y su estado. Rellena la cabecera, revisa la tabla de mapeo, anota la personalización por stack y lo que quedó fuera de alcance.

## Extensión y notas de diseño

- **Steering vs. skill:** el steering es corto y de alta señal (siempre activo o manual); la skill contiene el detalle y solo se activa cuando hace falta. Mantiene bajo el consumo de contexto.
- **Precedencia:** las reglas de workspace (`.kiro/steering/`) tienen prioridad sobre las globales (`~/.kiro/steering/`). Mantén las reglas versionadas en el repo.
- **Actualización viva:** tras un incidente, pide a Kiro que proponga adiciones a `security-baseline.md` y al checklist.
- **Próximas capas (del PDF, aún no incluidas):** threat modeling en diseño, reporte de postura periódico y base de conocimiento de seguridad. Ver `docs/IMPLEMENTATION_BRIEF.md`.
