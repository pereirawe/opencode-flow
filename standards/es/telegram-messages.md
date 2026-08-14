# Mensajes de Telegram — Formato estándar para notificaciones de agentes

Formato estandarizado para las notificaciones de Telegram enviadas por los
agentes mediante la skill `telegram-notifier`. Cada mensaje identifica el
proyecto de origen y sigue una plantilla específica por categoría.

## Reglas generales

1. **Siempre incluir el contexto del proyecto** — la primera línea DEBE ser
   `🔹 [NOMBRE-DEL-PROYECTO]` para que el usuario sepa de qué workspace viene
   la notificación.
2. **Una notificación por evento** — cada finalización de tarea, fallo, pregunta
   o milestone genera exactamente un mensaje.
3. **Máximo 300 caracteres** — notificaciones móviles; poner la info clave al
   inicio.
4. **Siempre incluir línea de acción cuando se necesite interacción** —
   prefijada con `→`.
5. **Usar el flag `--parse-mode html`** para negritas, enlaces y código.
6. **Nunca pedir permiso para enviar** — simplemente envía la notificación.
7. **Detectar el nombre del proyecto** desde el nombre del repositorio git
   (`basename "$(git rev-parse --show-toplevel)"` o fallback al último
   componente del directorio actual).

## Categorías

| Clave | Emoji | Uso |
|-------|-------|-----|
| `done` | ✅ | Tarea/comando finalizado con éxito |
| `fail` | ❌ | Tarea/comando falló con error |
| `question` | 💬 | Agente necesita respuesta del usuario |
| `blocked` | 🚫 | Agente no puede continuar (falta info, permisos) |
| `milestone` | 🏁 | Fase del pipeline o release alcanzada |
| `alert` | ⚠️ | Aviso no bloqueante / alerta |
| `progress` | ⏳ | Actualización de tarea larga en curso |

## Plantillas por clave

### `done` — tarea completada con éxito

```
🔹 [PROYECTO]
✅ <qué se completó>

<resultado o enlace, 1 línea>
```

Ejemplo:
```
🔹 [opencode-flow]
✅ Pipeline completado — issue #42

MR: https://github.com/pereirawe/opencode-flow/pull/34
```

### `fail` — tarea falló con error

```
🔹 [PROYECTO]
❌ <qué falló>

<causa del error, 1 línea>

→ <acción correctiva>
```

Ejemplo:
```
🔹 [setup-tecnologia]
❌ Suite de tests falló — 3/47 tests

pytest core/tests/test_auth.py - 2 assertion errors

→ Revisar fallos y re-ejecutar desarrollo
```

### `question` — agente necesita input del usuario

```
🔹 [PROYECTO]
💬 <contexto>

<la pregunta>

→ Responder aquí o en la terminal
```

Ejemplo:
```
🔹 [opencode-flow]
💬 Seleccionar cantidad de revisores para issue #28

¿Cuántos Senior Reviewers deben revisar esta rama?

→ Responder con un número (1–5)
```

### `blocked` — agente bloqueado

```
🔹 [PROYECTO]
🚫 Bloqueado — <bloqueador>

<por qué no puede continuar, 1 línea>

→ <qué se necesita para desbloquear>
```

Ejemplo:
```
🔹 [my-app]
🚫 Bloqueado — reglas de negocio ausentes

Issue #15 (feat) no tiene campo `Business rules:`.

→ Agregar reglas de negocio en known_issues.md o refinar vía discovery
```

### `milestone` — milestone del pipeline alcanzado

```
🔹 [PROYECTO]
🏁 <descripción del milestone>

<enlace o detalle clave>
```

Ejemplo:
```
🔹 [opencode-flow]
🏁 Versión 1.8.0 publicada

https://github.com/pereirawe/opencode-flow/releases/tag/v1.8.0
```

### `alert` — aviso no bloqueante

```
🔹 [PROYECTO]
⚠️ <mensaje de aviso>
```

Ejemplo:
```
🔹 [my-app]
⚠️ PR #12 abierto hace 5 días — mergear o cerrar
```

### `progress` — actualización de tarea larga

```
🔹 [PROYECTO]
⏳ <qué está pasando> (paso X/Y)
```

Ejemplo:
```
🔹 [opencode-flow]
⏳ Escaneo profundo en curso (paso 2/3 — analizando archivos Go)
```

## Invocación del script

El script respeta el emoji de categoría como parte del `--title`, y el
encabezado del proyecto + cuerpo como mensaje:

```bash
SCRIPT="$HOME/.config/opencode/scripts/telegram-notify.sh"

# done
"$SCRIPT" --title "✅ Pipeline completado" "🔹 [mi-proyecto]\n\nMR: https://github.com/..."

# fail
"$SCRIPT" --title "❌ Tests fallaron" "🔹 [mi-proyecto]\n\n→ Revisar fallos y re-ejecutar"

# question
"$SCRIPT" --title "💬 Input necesario" "🔹 [mi-proyecto]\n\n¿Qué rama para issue #42?\n\n→ Responder aquí"
```

Para mensajes multi-línea, usar stdin:

```bash
printf "🔹 [mi-proyecto]\n\n✅ Feature implementada\nRama: issue-42-login\nMR: %s" "$MR_URL" | \
  "$SCRIPT" --title "✅ Completado"
```

## Chat ID por proyecto (configuración multi-repo)

Al trabajar con múltiples proyectos, usar el archivo `.opencode/telegram.env`
específico de cada proyecto. El script carga las credenciales del proyecto
antes que las globales:

```
<proyecto>/
├── .opencode/
│   └── telegram.env    ← cargado primero (específico del proyecto)
```

Si todos los proyectos deben notificar al mismo chat, mantener solo el archivo
global en `~/.config/opencode/.opencode/telegram.env`.
