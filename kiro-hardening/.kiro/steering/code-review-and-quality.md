---
inclusion: manual
---

# Code Review y Postura de Código

> Revisión multidimensional antes de fusionar cualquier cambio. Invócala manualmente (con `#code-review-and-quality`) cuando revises un diff o prepares un PR. Complementa al `security-baseline` (siempre activo) con una mirada de calidad más amplia.

## Los cinco ejes

1. **Correctitud** — ¿Cumple la spec? ¿Casos borde y rutas de error cubiertos?
2. **Legibilidad** — ¿Nombres claros? ¿Flujo de control directo? ¿Se puede en menos líneas?
3. **Arquitectura** — ¿Sigue patrones existentes? ¿Límites de módulo limpios? ¿Sin dependencias circulares?
4. **Seguridad** — ¿Entrada validada? ¿Sin secretos? ¿Auth/autorización en su sitio? ¿Datos externos tratados como no confiables? (ver `security-baseline`)
5. **Rendimiento** — ¿Sin consultas N+1? ¿Sin bucles no acotados? ¿Paginación en endpoints de listado?

## Etiquetas de severidad en comentarios

| Prefijo | Significado |
|---|---|
| *(ninguno)* | Requerido — corregir antes de fusionar |
| **Critical:** | Bloquea el merge — seguridad, pérdida de datos, funcionalidad rota |
| **Nit:** | Opcional — preferencia de estilo |
| **Consider:** | Sugerencia — vale la pena pensarlo, no obligatorio |
| **FYI** | Informativo — sin acción requerida |

## Tamaño de cambio recomendado

- ~100 líneas: ideal.
- ~300 líneas: aceptable para un cambio lógico único.
- ~1000 líneas: demasiado, divídelo.
- Separa refactor de feature: envíalos como cambios distintos.

## Checklist de revisión

- [ ] Los tests cubren el cambio adecuadamente.
- [ ] Nombres claros y consistentes.
- [ ] Sin secretos en el código.
- [ ] Entrada validada en los límites.
- [ ] Sin patrones N+1 ni bucles no acotados.
- [ ] Tests pasan y el build compila.

## Formato de salida sugerido

Al revisar, agrupa los hallazgos por eje y usa las etiquetas de severidad. Termina con un veredicto claro: **APROBADO**, **APROBADO CON CAMBIOS MENORES** o **CAMBIOS REQUERIDOS**.
