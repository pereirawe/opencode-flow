# Guías de Revisión de Código

## Principios

- Revisar por corrección, no por estilo (el estilo debe automatizarse)
- Sea constructivo y específico
- Separe sugerencias menores de problemas bloqueantes
- Apruebe cuando esté satisfecho, solicite cambios cuando no

## Checklist

- [ ] El código es correcto y maneja casos frontera
- [ ] Las pruebas cubren adecuadamente el cambio
- [ ] Sin regresiones de seguridad o rendimiento
- [ ] Los cambios de API están documentados
- [ ] Las rutas de error están manejadas
- [ ] Sin código muerto o comentado
- [ ] Sigue las convenciones del proyecto

## Flujo de Revisión

1. Committer hace la revisión inicial
2. Publish Requester asigna Senior Reviewers por dominio
3. Senior Reviewers revisan en paralelo
4. Todos los revisores deben aprobar antes del merge
