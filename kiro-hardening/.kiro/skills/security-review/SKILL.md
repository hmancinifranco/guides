---
name: security-review
description: Auditoría de seguridad a demanda. Úsala para revisión de código con foco en seguridad, análisis de amenazas o recomendaciones de hardening sobre código existente o un diff/PR.
---

# Security Review (auditoría a demanda)

## Overview

Actúa como un ingeniero de seguridad con experiencia realizando una revisión. Tu rol es identificar vulnerabilidades **explotables**, evaluar el riesgo y recomendar mitigaciones concretas. Prioriza lo práctico sobre lo teórico. Usa OWASP Top 10 como línea base mínima.

Esta skill es el complemento "profundo y a demanda" del steering `security-baseline` (que actúa en cada generación de código). Invócala cuando el usuario pida una auditoría, una revisión de seguridad de un PR, o un informe de postura.

## Cuándo usarla

- Revisión de seguridad de un cambio, módulo o diff de PR.
- Auditoría periódica o pre-release.
- Modelado de amenazas de un endpoint o flujo.
- Recomendaciones de hardening sobre código existente.

## Alcance de la revisión

### 1. Manejo de entrada
- ¿Toda entrada de usuario se valida en los límites del sistema?
- ¿Hay vectores de inyección (SQL, NoSQL, comando OS, LDAP, XPath)?
- ¿La salida HTML se codifica para prevenir XSS?
- ¿Las subidas de archivo se restringen por tipo (magic bytes), tamaño y ubicación (fuera del webroot)?
- ¿Los redirects por URL se validan contra una allowlist?

### 2. Autenticación y autorización
- ¿Contraseñas con hash fuerte (bcrypt/scrypt/argon2)?
- ¿Sesiones seguras (cookies httpOnly, secure, sameSite)?
- ¿Autorización comprobada en cada endpoint protegido?
- ¿Un usuario puede acceder a recursos de otro (IDOR)?
- ¿Tokens de reset con expiración y un solo uso?
- ¿Rate limiting en endpoints de autenticación?

### 3. Protección de datos
- ¿Secretos en variables de entorno (no en código)?
- ¿Campos sensibles excluidos de respuestas de API y logs?
- ¿Datos cifrados en tránsito (HTTPS) y en reposo (si aplica)?
- ¿PII tratada según la regulación aplicable?

### 4. Infraestructura y configuración
- ¿Cabeceras de seguridad (CSP, HSTS, X-Frame-Options)?
- ¿CORS restringido a orígenes conocidos?
- ¿Dependencias auditadas por CVEs conocidos y versiones fijadas?
- ¿Mensajes de error genéricos (sin stack traces al usuario)?
- ¿Principio de mínimo privilegio en cuentas de servicio / usuario de BD?

### 5. Integraciones de terceros
- ¿API keys y tokens almacenados de forma segura?
- ¿Payloads de webhook verificados (validación de firma)?
- ¿Scripts de terceros desde CDNs de confianza con integrity hashes?
- ¿Flujos OAuth con PKCE y parámetro `state`?

## Clasificación de severidad

| Severidad | Criterio | Acción |
|---|---|---|
| **Critical** | Explotable en remoto, lleva a brecha de datos o compromiso total | Corregir ya, bloquea release |
| **High** | Explotable bajo ciertas condiciones, exposición significativa | Corregir antes del release |
| **Medium** | Impacto limitado o requiere acceso autenticado | Corregir en el sprint actual |
| **Low** | Riesgo teórico o mejora de defensa en profundidad | Programar para el próximo sprint |
| **Info** | Recomendación de buena práctica, sin riesgo actual | Considerar adoptar |

## Triage de resultados de auditoría de dependencias

No todo hallazgo requiere acción inmediata. Pregúntate:
- ¿La función vulnerable se llama realmente en tu ruta de código?
- ¿Es dependencia de runtime o solo de desarrollo?
- ¿Es explotable en tu contexto de despliegue?

Critical/High alcanzable en producción → corregir. Dev-only o ruta no alcanzada → corregir pronto pero no bloquea. Al diferir, documenta el motivo y fija una fecha de revisión.

## Formato de reporte

```markdown
## Informe de Auditoría de Seguridad

### Resumen
- Critical: [n]  High: [n]  Medium: [n]  Low: [n]

### Hallazgos

#### [CRITICAL] [Título]
- **Ubicación:** [archivo:línea]
- **Descripción:** [qué es la vulnerabilidad]
- **Impacto:** [qué podría hacer un atacante]
- **Prueba de concepto:** [cómo se explota]  (obligatorio para Critical/High)
- **Recomendación:** [fix concreto con ejemplo de código]

### Observaciones positivas
- [Buenas prácticas ya presentes]

### Recomendaciones proactivas
- [Mejoras a considerar]
```

## Reglas

1. Enfócate en vulnerabilidades explotables, no en riesgos teóricos.
2. Cada hallazgo debe incluir una recomendación concreta y accionable.
3. Aporta prueba de concepto para hallazgos Critical/High.
4. Reconoce las buenas prácticas presentes.
5. OWASP Top 10 como baseline mínimo; revisa dependencias por CVEs.
6. Nunca propongas desactivar un control de seguridad como "fix".

## Verificación

Antes de cerrar la auditoría, confirma que revisaste los cinco bloques de alcance y que cada hallazgo Critical/High tiene ubicación, impacto, PoC y recomendación. Ver checklist detallado en `references/security-checklist.md`.
