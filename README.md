# Guides

Guías y materiales de habilitación sobre Kiro, MCP y desarrollo asistido por agentes en AWS.

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge)
![MCP](https://img.shields.io/badge/MCP-1F1F1F?style=for-the-badge&logo=modelcontextprotocol&logoColor=white)
![Governance](https://img.shields.io/badge/Governance-0B7285?style=for-the-badge)
![Agents](https://img.shields.io/badge/Agents-6741D9?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-3DA639?style=for-the-badge)

---

## Contenido

| Recurso | Descripción | Formato |
|---|---|---|
| [Gobierno de MCP en Kiro](./kiro-govern/mcp-governance/) | Manual de implementación del MCP Registry, lista de referencia con 15 servers validados y plantilla de configuración del cliente | Markdown + JSON |
| [Inducción a Kiro](./kiro-induccion/) | Glosario, setup, AI-DLC Discovery, Specs, CLI y recursos — [ver online](https://hmancinifranco.github.io/guides/kiro-induccion/) | HTML |

---

## Gobierno de MCP en Kiro

Cuando un equipo adopta MCP, cada desarrollador conecta los servers que quiere. A
escala aparecen dos necesidades: saber qué herramientas se están usando y definir un
set común para que todos trabajen con lo mismo. Kiro resuelve esto con el **MCP
Registry**: un archivo JSON con la lista de servers autorizados, publicado por HTTPS y
cargado en el Kiro Profile.

Este material sale de una implementación completa, así que además del procedimiento
documenta los puntos donde la configuración se traba y cómo resolverlos.

### Archivos

| Archivo | Para qué sirve |
|---|---|
| [`manual-gobierno-mcp-kiro.md`](./kiro-govern/mcp-governance/manual-gobierno-mcp-kiro.md) | Manual completo: modelo cliente/server, alcance del registry, publicación, configuración del cliente, manejo de credenciales y diagnóstico |
| [`mcp-registry.json`](./kiro-govern/mcp-governance/mcp-registry.json) | Lista de referencia con 15 servers validados. Se adapta agregando o quitando entradas |
| [`mcp-client-config.json`](./kiro-govern/mcp-governance/mcp-client-config.json) | Plantilla para el `.kiro/settings/mcp.json` de cada desarrollador |

### Qué incluye la lista de referencia

El punto de entrada principal es el **Agent Toolkit for AWS** (`aws-mcp`), que en un
solo endpoint da documentación actualizada, procedimientos curados y ejecución de APIs
con las credenciales IAM de cada desarrollador. La búsqueda de documentación funciona
sin credenciales.

Lo acompañan servers especializados que el toolkit no reemplaza:

- **Documentación y conocimiento** — AWS Documentation, AWS Knowledge, Context7, Strands Agents
- **Observabilidad y costos** — CloudWatch, Application Signals, CloudTrail, Managed Prometheus, Pricing
- **Desarrollo y despliegue** — AWS Serverless (SAM), AWS Transform
- **Propósito general** — draw.io, Filesystem, Chrome DevTools

Todos usan `"version": "latest"`, lo que elimina el mantenimiento del JSON: Kiro
relanza siempre con la última release publicada.

### Cómo usarlo

**1. Adaptar la lista.** Partí de `mcp-registry.json` y ajustá qué servers autoriza tu
organización.

**2. Publicar por HTTPS.** Dos opciones según el momento:

```bash
# Rápido, para probar: URL raw de un repositorio público
https://raw.githubusercontent.com/<org>/<repo>/refs/heads/main/<ruta>/mcp-registry.json

# Producción: S3 privado + CloudFront con Origin Access Control + certificado ACM
https://mcp-registry.tuempresa.com/registry.json
```

Verificá que devuelva 200 sin autenticación interactiva:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" "<URL_DEL_REGISTRY>"
```

**3. Cargar la URL en el Kiro Profile.** Kiro console → Settings → Shared settings →
MCP Registry URL.

**4. Configurar el cliente.** Cada desarrollador copia `mcp-client-config.json` en su
`.kiro/settings/mcp.json` y define sus variables de entorno:

```bash
export AWS_PROFILE=mi-perfil
```

El detalle completo de cada paso está en el manual.

### Requisitos

- Kiro IDE 0.11.28 o Kiro CLI 1.23 en adelante
- Autenticación con identidad corporativa: AWS IAM Identity Center, Okta o Microsoft Entra ID
- `uvx` y `npx` instalados en la máquina de cada desarrollador

---

## Referencias oficiales

| Tema | Enlace |
|---|---|
| Gobierno de MCP en Kiro | https://kiro.dev/docs/enterprise/governance/mcp/ |
| MCP Registry (Kiro IDE) | https://kiro.dev/docs/mcp/registry/ |
| Anuncio de la funcionalidad | https://kiro.dev/blog/enterprise-governance-mcp-and-models/ |
| Esquema completo del registry | https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-governance.html |
| Agent Toolkit for AWS | https://docs.aws.amazon.com/agent-toolkit/latest/userguide/ |
| MCP servers de AWS | https://github.com/awslabs/mcp |
| Catálogo de Powers de Kiro | https://github.com/kirodotdev/powers/tree/main |
| Estándar MCP Registry | https://modelcontextprotocol.io/registry/versioning |

---

## Estructura del repositorio

```
guides/
├── kiro-govern/
│   └── mcp-governance/           Gobierno de MCP: manual, registry y config
├── kiro-induccion/
│   └── index.html                Guía de inducción (publicada via GitHub Pages)
├── LICENSE
└── README.md
```

Las guías en HTML se publican automáticamente en GitHub Pages bajo
`https://hmancinifranco.github.io/guides/<carpeta>/`. Las guías en Markdown se leen
directamente desde GitHub.

---

## Licencia

Publicado bajo licencia MIT. Ver [LICENSE](./LICENSE).

Las marcas y los productos mencionados pertenecen a sus respectivos titulares. Este
material es de elaboración propia y no constituye documentación oficial de AWS ni de
Kiro; para eso están los enlaces de la sección de referencias.
