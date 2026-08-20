# Guides

Compendio de guías prácticas sobre Kiro, MCP y desarrollo asistido por agentes en AWS.

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge)
![MCP](https://img.shields.io/badge/MCP-1F1F1F?style=for-the-badge&logo=modelcontextprotocol&logoColor=white)
![Governance](https://img.shields.io/badge/Governance-0B7285?style=for-the-badge)
![Agents](https://img.shields.io/badge/Agents-6741D9?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-3DA639?style=for-the-badge)

Cada guía incluye el procedimiento de configuración, los archivos de ejemplo y los
errores más comunes con su solución.

---

## Guías

| Guía | De qué trata |
|---|---|
| [Gobierno de MCP en Kiro](./kiro-govern/mcp-governance/) | Definir un set común de MCP servers para toda la organización con el MCP Registry. Incluye manual, lista de referencia con 15 servers validados y plantilla de configuración del cliente. |
| [Hardening de seguridad en Kiro](./kiro-hardening/) | Set base reutilizable de seguridad/postura de código para Kiro con modelo de capas (prevención always-on, revisión manual, auditoría on-demand y barreras opcionales). Incluye steering, skill de revisión, checklist ejecutable y ejemplos de gate de CI. |
| [Inducción a Kiro](./kiro-induccion/) | Primeros pasos con Kiro: glosario, setup, AI-DLC Discovery, Specs y CLI. [Ver online](https://hmancinifranco.github.io/guides/kiro-induccion/) |

---

## Cómo está organizado

Cada guía vive en su propia carpeta y es autocontenida. Las que están en Markdown se
leen directamente desde GitHub; las que están en HTML se publican en GitHub Pages bajo
`https://hmancinifranco.github.io/guides/<carpeta>/`.

```
guides/
├── kiro-govern/
│   └── mcp-governance/     Gobierno de MCP en Kiro
├── kiro-hardening/         Hardening de seguridad en Kiro
├── kiro-induccion/         Inducción a Kiro
├── LICENSE
└── README.md
```

---

## Licencia

Publicado bajo licencia MIT. Ver [LICENSE](./LICENSE).

Las marcas y los productos mencionados pertenecen a sus respectivos titulares. Este
material es de elaboración propia y no constituye documentación oficial de AWS ni de
Kiro.
