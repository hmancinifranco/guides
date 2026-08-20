# Security Validation Checklist (auditoría a demanda)

Este documento **no** se carga automáticamente (no está en `.kiro/steering/`). Se referencia de forma explícita cuando quieres que Kiro haga una auditoría de seguridad de código existente o de un PR.

## Cómo dispararla

Pídele a Kiro, por ejemplo:

> Revisa el codebase (o este diff) contra `docs/security-validation.md`.
> Para cada ítem reporta PASS, FAIL o N/A con referencia de archivo y línea.
> Separa los hallazgos en BLOCKING (corregir antes del release) y ADVISORY (rastrear).

Úsalo en revisión de PR, auditoría periódica o antes de un hito de release.

## Autenticación y autorización
- [ ] Todos los endpoints requieren autenticación salvo allowlist explícita.
- [ ] La autorización verifica propiedad del recurso, no solo el rol.
- [ ] Tokens validados por expiración, audiencia y emisor.
- [ ] Timeout de sesión configurado y aplicado.
- [ ] Intentos fallidos de autenticación con rate limiting.

## Prevención de inyección
- [ ] Todo acceso SQL usa consultas parametrizadas (sin concatenación).
- [ ] Sin `eval()`, `exec()` ni ejecución dinámica sobre entrada de usuario.
- [ ] Vectores LDAP, XPath y comando OS considerados.
- [ ] Sin `dangerouslySetInnerHTML` sin sanitización.

## Protección de datos
- [ ] Campos sensibles (PII, credenciales) nunca se loggean.
- [ ] Contraseñas con bcrypt/scrypt/argon2 (coste ≥ 12).
- [ ] Respuestas sin stack traces, errores de SQL ni rutas internas.
- [ ] Conexiones a BD con TLS.
- [ ] Secretos desde entorno o secrets manager, no en el código.

## Seguridad de dependencias
- [ ] Sin dependencias con CVEs críticos o altos.
- [ ] Versiones fijadas (sin rangos flotantes).
- [ ] Sin transitivas innecesarias con permisos amplios.

## Frontend
- [ ] Tokens de auth en cookies httpOnly, no en localStorage.
- [ ] Cabeceras Content-Security-Policy configuradas.
- [ ] Sin secretos ni URLs internas en bundles de cliente.
- [ ] Entrada de usuario sanitizada antes de renderizar.

## Infraestructura y configuración
- [ ] Protección CSRF en operaciones que cambian estado.
- [ ] CORS restringe orígenes a dominios conocidos.
- [ ] Subidas validadas por tipo, tamaño y almacenadas fuera del webroot.
- [ ] Respuestas de error genéricas.
- [ ] Usuario de BD con mínimo privilegio.

## Salida esperada

Al final, Kiro debe emitir un veredicto claro:
- `SECURITY_REVIEW_PASSED` — si no hay ítems FAIL de tipo BLOCKING.
- `SECURITY_REVIEW_FAILED` — si existe algún FAIL BLOCKING.

Este marcador facilita integrar la revisión en un gate de CI/CD más adelante.
