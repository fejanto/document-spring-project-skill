# Auto-Update System

El plugin `document-spring-project` incluye un sistema de auto-actualización que verifica y notifica sobre nuevas versiones disponibles.

## 🔄 Cómo Funciona

### 1. Hook de Carga (onLoad)

Cuando Claude Code carga el plugin (al iniciar o al ejecutar comandos del plugin), se ejecuta automáticamente `.claude-plugin/hooks/on-load.sh` que:

- ✅ Verifica si han pasado más de 24 horas desde la última verificación
- ✅ Hace `git fetch` para ver si hay nuevas versiones en el repositorio
- ✅ Compara commit local vs. commit remoto
- ✅ **Limpia automáticamente el cache viejo** para preparar la actualización
- ✅ Muestra notificación si hay actualización disponible

**Ejemplo de notificación:**
```
📦 Update available for document-spring-project plugin
   Current: a3f4b891
   Latest:  f7e2d943

   Run: /docs-update
   Or:  cd /path/to/plugin && git pull origin master

   (Old cache cleared automatically)
```

### 2. Configuración en plugin.json

```json
{
  "hooks": {
    "onLoad": "./.claude-plugin/hooks/on-load.sh"
  },
  "autoUpdate": {
    "enabled": true,
    "checkInterval": 86400,  // 24 horas
    "source": "git"
  }
}
```

## 📦 Formas de Actualizar

### Opción 1: Comando del Plugin (Recomendado)

```bash
/docs-update
```

Este comando:
1. Muestra la versión actual y los cambios disponibles
2. Pide confirmación antes de actualizar
3. Hace `git stash` de cambios locales (si existen)
4. Hace `git pull origin master`
5. Restaura cambios locales (si fueron stashed)
6. **Limpia automáticamente el cache del plugin**
7. La nueva versión se carga automáticamente en el próximo uso

### Opción 2: Comando de Claude Code

```bash
# Actualizar este plugin
/plugin update document-spring-project

# Actualizar todos los plugins
/plugin update --all
```

### Opción 3: Manual (Git)

```bash
cd ~/.claude/plugins/marketplaces/fejanto-skills/
git pull origin master

# O si está en cache:
cd ~/.claude/plugins/cache/fejanto-skills/document-spring-project/*/
git pull origin master

# Luego recargar
/plugin reload document-spring-project
```

## ⚙️ Configuración

### Cambiar Intervalo de Verificación

Editar `.claude-plugin/hooks/on-load.sh`:

```bash
UPDATE_INTERVAL=86400  # 24 horas (default)
# Cambiar a:
UPDATE_INTERVAL=3600   # 1 hora
UPDATE_INTERVAL=43200  # 12 horas
UPDATE_INTERVAL=604800 # 1 semana
```

### Deshabilitar Auto-Update Check

```bash
# Opción 1: Eliminar el hook
rm .claude-plugin/hooks/on-load.sh

# Opción 2: Hacer el archivo no ejecutable
chmod -x .claude-plugin/hooks/on-load.sh

# Opción 3: Editar plugin.json y remover la sección hooks
```

### Ver Cuándo Fue la Última Verificación

```bash
# El hook guarda timestamp en:
cat /path/to/plugin/.last-update-check

# Convertir a fecha legible:
date -r $(cat /path/to/plugin/.last-update-check)
```

## 🔍 Verificación Manual

### Ver si hay actualizaciones disponibles

```bash
cd /path/to/plugin

# Fetch sin pull
git fetch origin master

# Comparar versiones
git log HEAD..origin/master --oneline

# Ver cambios específicos
git diff HEAD..origin/master
```

### Ver versión instalada

```bash
# Opción 1: Ver tag
cd /path/to/plugin
git describe --tags

# Opción 2: Ver commit
git rev-parse --short HEAD

# Opción 3: Ver en Claude Code
/plugin show document-spring-project
```

## 🚀 Flujo Completo de Actualización

### Escenario: Nueva versión disponible

1. **Claude Code inicia** → Hook `onLoad` se ejecuta
2. **Hook detecta actualización** → Muestra notificación
3. **Usuario ejecuta** `/docs-update`
4. **Script muestra cambios** y pide confirmación
5. **Usuario confirma** (y)
6. **Git pull descarga** nueva versión
7. **Usuario recarga** plugin: `/plugin reload document-spring-project`
8. **Nueva versión activa** ✅

### Escenario: Auto-update desde marketplace

Si el plugin está instalado desde el marketplace de Claude Code y tienes `autoUpdate: true` en settings:

1. Claude Code verifica actualizaciones periódicamente
2. Descarga nueva versión automáticamente
3. Actualiza en próximo reinicio (sin intervención manual)

Para habilitarlo:

```json
// ~/.claude/settings.json
{
  "plugins": {
    "autoUpdate": true,
    "updateCheckInterval": 3600
  }
}
```

## 🐛 Troubleshooting

### El hook no se ejecuta

```bash
# Verificar que es ejecutable
ls -la .claude-plugin/hooks/on-load.sh

# Si no es ejecutable:
chmod +x .claude-plugin/hooks/on-load.sh
```

### La notificación no aparece

```bash
# Forzar verificación eliminando el timestamp
rm /path/to/plugin/.last-update-check

# Luego ejecutar cualquier comando del plugin
/docs
```

### El comando /docs-update no funciona

```bash
# Verificar que el script existe
ls -la scripts/update-plugin.sh

# Verificar que es ejecutable
chmod +x scripts/update-plugin.sh

# Ejecutar manualmente para ver errores
bash scripts/update-plugin.sh
```

### Git fetch falla

```bash
# Verificar conectividad
git fetch origin master

# Si hay problemas de autenticación:
git config credential.helper store

# O usar HTTPS en lugar de SSH:
git remote set-url origin https://github.com/fejanto/document-spring-project-skill.git
```

## 📊 Logs de Actualización

El hook registra información en:

```bash
# Archivo de timestamp (última verificación)
.last-update-check

# Para debugging, puedes agregar logs:
# En .claude-plugin/hooks/on-load.sh, agregar:
LOG_FILE="$PLUGIN_DIR/.update-check.log"
echo "$(date): Checking for updates..." >> "$LOG_FILE"
```

## 🧹 Limpieza Automática del Cache

El sistema de actualización incluye limpieza automática del cache para garantizar que siempre uses la versión más reciente:

### ¿Por qué es necesario?

Claude Code cachea los plugins en `~/.claude/plugins/cache/` para mejorar el rendimiento. Sin embargo, este cache no se actualiza automáticamente cuando hay nuevas versiones.

### Cuándo se limpia el cache

1. **Cuando el hook detecta una actualización**: Al encontrar una nueva versión, el hook onLoad elimina automáticamente el cache viejo
2. **Después de ejecutar `/docs-update`**: El script limpia el cache después de hacer git pull
3. **Resultado**: La próxima vez que uses el skill, Claude cargará la versión nueva

### Ubicación del cache

```bash
~/.claude/plugins/cache/fejanto-skills/document-spring-project/
```

### Limpieza manual (si es necesario)

```bash
# Si experimentas problemas, puedes limpiar el cache manualmente
rm -rf ~/.claude/plugins/cache/fejanto-skills/document-spring-project

# Luego simplemente usa el skill normalmente
/docs
```

## 🎯 Mejores Prácticas

1. **Usa el comando `/docs-update`** - Es la forma más segura y te muestra qué va a cambiar
2. **Revisa los cambios** antes de confirmar la actualización
3. **No necesitas reiniciar Claude Code** - El cache se limpia automáticamente
4. **Haz backup** de tu configuración si tienes personalizaciones locales

## 🔐 Seguridad

- El hook solo hace `git fetch` (solo lectura, no modifica archivos)
- El pull requiere confirmación explícita del usuario (via `/docs-update`)
- Cambios locales se guardan automáticamente en stash
- No se ejecuta código remoto sin confirmación

## 📝 Notas

- El auto-update check es **no intrusivo** (solo notifica, no actualiza automáticamente)
- Funciona solo si el plugin está instalado como repositorio git
- Si está instalado desde marketplace, Claude Code maneja las actualizaciones
- El intervalo de 24 horas evita verificaciones excesivas
