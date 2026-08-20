# Security Checklist (referencia detallada)

Checklist de apoyo para la skill `security-review`. Para cada ítem evalúa: **PASS**, **FAIL** o **N/A**. Para FAIL, indica archivo, línea y remediación. Separa hallazgos en **BLOCKING** (corregir antes del release) y **ADVISORY** (rastrear para el próximo sprint).

## Autenticación y autorización
- [ ] Todos los endpoints requieren autenticación salvo los explícitamente en allowlist.
- [ ] La autorización verifica propiedad del recurso, no solo el rol.
- [ ] Los tokens se validan por expiración, audiencia y emisor.
- [ ] Timeout de sesión configurado y aplicado.
- [ ] Intentos fallidos de login con rate limiting.
- [ ] Tokens de reset con expiración y un solo uso.

## Prevención de inyección
- [ ] Todo acceso a datos usa consultas parametrizadas (sin concatenación).
- [ ] Sin `eval()`, `exec()` ni ejecución dinámica sobre entrada de usuario.
- [ ] Vectores de inyección LDAP, XPath y comando OS considerados.
- [ ] Sin `dangerouslySetInnerHTML` / `innerHTML` sin sanitizar (DOMPurify si es imprescindible).

## Protección de datos
- [ ] Campos sensibles (PII, credenciales) nunca se loggean.
- [ ] Contraseñas con bcrypt/scrypt/argon2 (coste ≥ 12).
- [ ] Las respuestas no filtran stack traces, errores de SQL ni rutas internas.
- [ ] Conexiones a BD con TLS.
- [ ] Secretos desde entorno o secrets manager, no en el código.

## Seguridad de dependencias
- [ ] Sin dependencias con CVEs críticos o altos conocidos.
- [ ] Versiones fijadas (sin rangos flotantes).
- [ ] Sin dependencias transitivas innecesarias con permisos amplios.
- [ ] Sin paquetes abandonados (sin releases en 18+ meses) o con riesgo de typosquatting.

## Frontend
- [ ] Tokens de auth en cookies httpOnly, no en localStorage.
- [ ] Cabeceras Content-Security-Policy configuradas.
- [ ] Sin secretos ni URLs internas en bundles de cliente.
- [ ] Entrada de usuario sanitizada antes de renderizar.

## Infraestructura y configuración
- [ ] Protección CSRF en operaciones que cambian estado.
- [ ] CORS restringe orígenes a dominios conocidos (sin `*`).
- [ ] Subidas de archivo validadas por tipo, tamaño y almacenadas fuera del webroot.
- [ ] Respuestas de error genéricas.
- [ ] Usuario de BD con mínimo privilegio.

## Integraciones de terceros
- [ ] API keys y tokens almacenados de forma segura.
- [ ] Webhooks con validación de firma.
- [ ] Scripts de terceros con integrity hashes desde CDNs de confianza.
- [ ] OAuth con PKCE y parámetro `state`.

## Verificación pre-commit
```bash
# Secretos accidentalmente en staging
git diff --cached | grep -iE "password|secret|api_key|token|BEGIN (RSA|PRIVATE) KEY"

# Auditoría de dependencias (según ecosistema)
npm audit --audit-level=high      # Node
pip-audit                         # Python
```
