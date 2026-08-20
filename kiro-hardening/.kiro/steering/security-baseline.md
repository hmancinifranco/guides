---
inclusion: always
---

# Security Baseline (siempre activo)

> Reglas de seguridad no negociables que Kiro debe aplicar al **generar, modificar o revisar** cualquier código de este proyecto. Si una petición choca con una de estas reglas, señálalo explícitamente en la respuesta en lugar de cumplirla en silencio.

Trata toda entrada externa como hostil, todo secreto como sagrado y toda comprobación de autorización como obligatoria. La seguridad no es una fase: es una restricción sobre cada línea que toca datos de usuario, autenticación o sistemas externos.

## Siempre (sin excepción)

- **Validar toda entrada externa** en el límite del sistema (rutas de API, handlers de formularios, mensajes de cola). Usa validación por esquema (Zod, Pydantic, Bean Validation, etc.).
- **Parametrizar todo acceso a base de datos**. Nunca concatenar entrada de usuario en SQL/NoSQL/consultas de cualquier tipo. Usa consultas parametrizadas, ORM o stored procedures.
- **Codificar/escapar la salida** para prevenir XSS. Usa el auto-escaping del framework; no lo desactives.
- **Hashear contraseñas** con bcrypt/scrypt/argon2 (coste/rondas ≥ 12). Nunca en texto plano.
- **Cookies de sesión** con `httpOnly`, `secure`, `sameSite`. No guardar tokens de auth en `localStorage`.
- **HTTPS/TLS** para toda comunicación externa y conexiones a base de datos.
- **Cabeceras de seguridad** cuando aplique: CSP, HSTS, X-Frame-Options, X-Content-Type-Options.
- **Autorización por recurso**: comprueba propiedad del recurso (p. ej. `resource.ownerId == user.id`), no solo el rol. Verifica auth en cada endpoint protegido.
- **Fijar versiones de dependencias** (sin rangos flotantes `latest`/`^`/`RELEASE` en lo que llega a producción).

## Preguntar primero (requiere aprobación humana)

- Añadir o cambiar flujos de autenticación/autorización.
- Almacenar nuevas categorías de datos sensibles (PII, pagos, salud).
- Añadir nuevas integraciones con servicios externos o webhooks.
- Cambiar configuración de CORS o relajar cabeceras de seguridad.
- Añadir handlers de subida de archivos.
- Otorgar permisos o roles elevados; cambiar rate limiting.

## Nunca

- **Nunca commitear secretos** (API keys, contraseñas, tokens, claves privadas). Van en variables de entorno o un secrets manager.
- **Nunca loggear datos sensibles** (contraseñas, tokens, PII, números de tarjeta completos).
- **Nunca confiar en la validación de cliente** como frontera de seguridad.
- **Nunca usar `eval()`, `innerHTML`, `Runtime.exec()`/`ProcessBuilder`** con datos controlados por el usuario.
- **Nunca exponer stack traces** ni errores internos al cliente. Devuelve mensajes genéricos.
- **Nunca desactivar controles de seguridad** "por comodidad".

## Red flags que debes marcar al instante

- Entrada de usuario que llega directa a consultas, comandos de shell o render HTML.
- Secretos en el código fuente o en el historial de git.
- Endpoints sin comprobación de autenticación/autorización.
- CORS con origen comodín (`*`) o sin configurar.
- Endpoints de autenticación sin rate limiting.
- Dependencias con CVEs críticos/altos conocidos.

## Ajustes por stack (personalizar)

> Reemplaza estos valores por los de tu proyecto. Por defecto son genéricos y funcionan sin cambios; concretarlos mejora la señal. Ver la guía de adopción en el `README.md`.

- **Lenguaje / framework principal:** genérico _(ej.: Java + Spring Boot, Node + Express, Python + FastAPI, .NET)_
- **Validación de entrada:** el validador del stack _(ej.: Zod, Pydantic, Jakarta Bean Validation)_
- **Hashing de contraseñas:** bcrypt/scrypt/argon2 _(la librería estándar del stack)_
- **Gestor de secretos:** variables de entorno _(ej.: AWS Secrets Manager, Azure Key Vault, HashiCorp Vault)_
- **Comando de auditoría de dependencias:** `npm audit --audit-level=high` _(ej.: `pip-audit`, `mvn org.owasp:dependency-check`, `cargo audit`)_

## Verificación mínima tras un cambio sensible

- [ ] `npm audit` / `pip-audit` / equivalente sin vulnerabilidades críticas o altas.
- [ ] Sin secretos en el código ni en el diff staged (`git diff --cached | grep -iE "password|secret|api_key|token"`).
- [ ] Toda entrada de usuario validada en el límite.
- [ ] Auth y autorización comprobadas en cada endpoint protegido.
- [ ] Respuestas de error sin detalles internos.

Para una auditoría profunda a demanda, usa la skill `security-review` (`.kiro/skills/security-review/SKILL.md`) o el checklist `docs/security-validation.md`.
