# Brief de implementación — Seguridad con Kiro

Documento para preparar, con cada cliente, un **brief de qué aplicamos y cómo**, tomando como referencia el documento del cliente "Security Enforcement with Kiro". Rellena la cabecera, revisa el mapeo de capas y ajusta el estado según lo entregado.

---

## 1. Cabecera del engagement

| Campo | Valor |
|---|---|
| Cliente | _(rellenar)_ |
| Repositorio / proyecto | _(rellenar)_ |
| Stack detectado | _(ej.: Java + Spring Boot + SQL Server / Node + React)_ |
| Fecha | _(rellenar)_ |
| Responsable (nosotros) | _(rellenar)_ |
| Contacto (cliente) | _(rellenar)_ |
| Alcance acordado | _(capas 1–3 base / + capa 4 / a medida)_ |

---

## 2. Mapeo: documento del cliente → lo que aplicamos

El PDF del cliente propone un "full stack" de capas de seguridad. Esta tabla mapea cada capa a lo que este set base entrega, con qué artefacto y en qué estado.

| Capa del PDF | Cuándo actúa | Cómo lo cubrimos | Artefacto | Estado |
|---|---|---|---|---|
| **Steering file (Option B)** | En cada generación de código | Steering always-on con reglas no negociables (Always / Ask-first / Never) | `.kiro/steering/security-baseline.md` | ✅ Implementado |
| **On-demand audit (Option A)** | Periódico / pre-release | Skill de auditoría + checklist ejecutable con severidades y veredicto | `.kiro/skills/security-review/` + `docs/security-validation.md` | ✅ Implementado |
| **Code review** | Al revisar un PR | Steering de revisión en 5 ejes + etiquetas de severidad | `.kiro/steering/code-review-and-quality.md` | ✅ Implementado |
| **Secrets detection hook** | Al escribir archivos | Hook `PreToolUse` que bloquea escrituras con patrones de secretos | `.kiro/hooks/secrets-detection.json` + `scripts/detect-secrets.sh` | ⭘ Opcional (incluido) |
| **CI security gate (Option C)** | En cada PR | Workflow que corre Kiro sobre el diff y falla si hay BLOCKING | `.github/workflows/security-review.yml` | ⭘ Opcional (ejemplo) |
| **Dependency review** | Al cambiar dependencias | Regla en baseline + triage en la skill; comando de auditoría por stack | baseline + skill | ◐ Parcial (guía, sin automatización) |
| **Developer self-review (pre-push)** | Antes de push | Prompt/skill invocable manualmente por el dev | skill `security-review` | ◐ Parcial (manual) |
| **Threat modeling** | Fase de diseño | No incluido en el set base | — | ✗ No incluido |
| **Posture report** | Mensual / trimestral | No incluido en el set base | — | ✗ No incluido |
| **Incident-driven updates** | Post-incidente | Práctica documentada en README (actualización viva) | README | ◐ Parcial (proceso) |
| **Security knowledge base** | Siempre disponible | No incluido en el set base | — | ✗ No incluido |

Leyenda: ✅ implementado · ⭘ opcional incluido · ◐ parcial · ✗ no incluido.

---

## 3. Qué aplicamos y cómo (resumen para el cliente)

Redacta 3–6 bullets en lenguaje de negocio. Plantilla:

- **Prevención en tiempo de desarrollo.** Cargamos reglas de seguridad always-on en Kiro (`security-baseline.md`), de modo que cada código generado ya nace aplicando validación de entrada, consultas parametrizadas, manejo de secretos y auth. _Adaptado a: <stack>._
- **Auditoría a demanda.** Dejamos una skill y un checklist (`docs/security-validation.md`) para auditar código o PRs con severidades (Critical→Info) y un veredicto claro.
- **Revisión de código.** Steering de revisión en 5 ejes para usar en PRs.
- **Hook anti-secretos (opcional).** Bloquea que se escriban secretos en el código. _Estado: <activado/no>._
- **Gate de CI (opcional).** Revisión automática en cada PR con corte por hallazgos bloqueantes. _Estado: <activado/no>._

---

## 4. Personalización aplicada por stack

| Punto de reemplazo | Valor genérico | Valor del cliente |
|---|---|---|
| Lenguaje / framework | genérico | _(rellenar)_ |
| Validador de entrada | Zod/Pydantic/Bean Validation | _(rellenar)_ |
| Hashing de contraseñas | bcrypt/scrypt/argon2 | _(rellenar)_ |
| Gestor de secretos | variables de entorno | _(rellenar)_ |
| Auditoría de dependencias | `npm audit` | _(rellenar)_ |

---

## 5. Fuera de alcance / próximos pasos

Marca lo que quedó fuera y propón siguiente iteración:

- [ ] Threat modeling en fase de diseño (`docs/threat-model.md`).
- [ ] Reporte de postura periódico (mensual/trimestral).
- [ ] Base de conocimiento de seguridad indexada.
- [ ] Automatizar dependency review en PRs que tocan manifiestos.
- [ ] Endurecer el hook de secretos / reducir falsos positivos.

---

## 6. Verificación de entrega

- [ ] `security-baseline.md` se carga (Kiro lista las reglas al preguntarle).
- [ ] La skill `security-review` produce informe con severidades.
- [ ] `docs/security-validation.md` da veredicto PASSED/FAILED.
- [ ] (Si aplica) el hook bloquea una escritura de prueba con un secreto.
- [ ] (Si aplica) el workflow de CI corre en un PR de prueba.
- [ ] Personalización por stack revisada y commiteada.
