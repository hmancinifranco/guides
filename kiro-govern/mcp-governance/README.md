# Gobierno de MCP en Kiro

Cómo definir un set común de MCP servers para toda una organización usando el MCP
Registry de Kiro.

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge)
![MCP](https://img.shields.io/badge/MCP-1F1F1F?style=for-the-badge&logo=modelcontextprotocol&logoColor=white)
![Governance](https://img.shields.io/badge/Governance-0B7285?style=for-the-badge)

---

## El problema

Por defecto cada desarrollador conecta los MCP servers que quiere. A escala eso
dificulta dos cosas: saber qué herramientas se están usando en la organización y
mantener un set común entre todos.

Kiro lo resuelve con el **MCP Registry**: un archivo JSON con la lista de servers
autorizados, publicado por HTTPS y cargado en el Kiro Profile. Lo que está en la lista
se permite, lo que no está el cliente lo suprime. El desarrollador sigue eligiendo
cuáles activa y configura sus propias credenciales, pero no puede sumar servers fuera
de la lista.

---

## Archivos

| Archivo | Para qué sirve |
|---|---|
| [`manual-gobierno-mcp-kiro.md`](./manual-gobierno-mcp-kiro.md) | Manual completo: modelo cliente/server, alcance del registry, publicación, configuración del cliente, credenciales y diagnóstico |
| [`mcp-registry.json`](./mcp-registry.json) | Lista de referencia con 15 servers validados. Se adapta agregando o quitando entradas |
| [`mcp-client-config.json`](./mcp-client-config.json) | Plantilla para el `.kiro/settings/mcp.json` de cada desarrollador |

---

## Qué incluye la lista de referencia

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

---

## Cómo usarlo

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

**4. Configurar el cliente.** Cada desarrollador activa los servers desde el panel de
Kiro o copiando `mcp-client-config.json` en su `.kiro/settings/mcp.json`, y define sus
variables de entorno:

```bash
export AWS_PROFILE=mi-perfil
```

El detalle de cada paso, con capturas del flujo de activación, está en el
[manual](./manual-gobierno-mcp-kiro.md).

---

## Requisitos

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
