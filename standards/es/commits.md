# Convenciones de Commit

## Formato

```
<tipo>: <descripción corta> (#<id-de-issue>)
```

## Tipos

| Tipo | Uso |
|------|-----|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de error |
| `refactor` | Reestructuración de código |
| `test` | Cambios en pruebas |
| `docs` | Documentación |
| `chore` | Mantenimiento, config, dependencias |

## Ejemplos

```
feat: añadir endpoint de analytics (#6)
fix: validar esquema de URL antes del fetch (#3)
refactor: extraer capa de servicio del handler (#7)
docs: actualizar documentación de la API (#12)
```

## Reglas

- Use el presente imperativo
- Mantenga la primera línea bajo 72 caracteres
- Referencie el número de issue entre paréntesis
- El cuerpo es opcional pero recomendado para cambios complejos
