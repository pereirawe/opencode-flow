## /ocf:backup

---
description: Create intelligent timestamped backups excluding junk dirs
---

Create a clean backup of a project directory, excluding common development
junk (node_modules, .venv, __pycache__, etc.) and preserving `.env` files.

Automatically prevents infinite recursion (won't copy existing backups into
the new backup).

### Usage

```
/ocf:backup <source_dir> [backup_name] [--zip]
```

| Argument | Description |
|----------|-------------|
| `source_dir` | Directory to back up (required) |
| `backup_name` | Base name (default: `dev_backup`) |
| `--zip` | Also create a `.zip` archive |

### Examples

```
/ocf:backup /home/user/dev
/ocf:backup /home/user/dev my_backup
/ocf:backup /home/user/dev my_backup --zip
```

### What is excluded

| Pattern | Reason |
|---------|--------|
| `bk/` | User-defined backup copys |
| `node_modules/` | npm packages |
| `.venv/` | Python virtual env |
| `__pycache__/` | Python bytecode cache |
| `.pytest_cache/` | Pytest cache |
| `my_pycache/` | Custom Python cache |
| `vendor/` | Composer packages |
| `bootstrap/cache/` | Laravel cache |
| `<backup_name>_*` | Previous backups (prevents recursion) |

### Behavior

- Creates `<source_dir>/<backup_name>_<timestamp>/`
- Updates `<source_dir>/<backup_name>_latest` symlink
- Optionally creates `<source_dir>/<backup_name>_<timestamp>.zip`
- `.env` files are always preserved (only directories above are excluded)

### Programmatic use

```bash
$SCRIPTS_DIR/backup.sh /home/user/dev --zip
```
