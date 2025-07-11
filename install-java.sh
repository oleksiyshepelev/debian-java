#!/usr/bin/env bash
# 01-install-java.sh - Instalación de Java 21 Temurin y paquetes básicos

set -euo pipefail

# ─── Funciones de logging (heredadas) ──────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[1;34m'; CYAN='\033[1;36m'; NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

step()  { echo -e "\n${BLUE}▶️  $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
info()  { echo -e "${CYAN}ℹ️  $1${NC}"; }
ok()    { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# ─── Verificar que se ejecuta como root ───────────────────────
if [[ $EUID -ne 0 ]]; then
    error "Este script debe ejecutarse como root"
fi

# ─── Actualizar repositorios ───────────────────────────────────
step "Actualizando repositorios del sistema..."
apt-get update -qq
ok "Repositorios actualizados"

# ─── Instalar paquetes básicos ────────────────────────────────
step "Instalando paquetes básicos del sistema..."
BASIC_PACKAGES=(
    curl wget git htop vim nano unzip net-tools
    gnupg2 software-properties-common ca-certificates
    openssh-server ufw fail2ban ipcalc dirmngr
    apt-transport-https lsb-release
)

apt-get install -y "${BASIC_PACKAGES[@]}"
ok "Paquetes básicos instalados"

# ─── Configurar repositorio Adoptium ──────────────────────────
step "Configurando repositorio Adoptium para Java 21..."

# Crear directorio para keyrings si no existe
mkdir -p /usr/share/keyrings

# Descargar e instalar clave GPG
auto_import_key() {
    curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public |
      gpg --dearmor -o /usr/share/keyrings/adoptium-archive-keyring.gpg
}
if ! auto_import_key; then
    error "Error al descargar la clave GPG de Adoptium"
fi

[[ -f /usr/share/keyrings/adoptium-archive-keyring.gpg ]] || \
    error "La clave GPG no se guardó correctamente"
ok "Clave GPG de Adoptium instalada"

# ─── Añadir repositorio ────────────────────────────────────────
info "Añadiendo repositorio Adoptium..."

# Obtener codename de la distribución
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    CODENAME="${VERSION_CODENAME:-}"
fi
CODENAME="${CODENAME:-$(lsb_release -cs 2>/dev/null)}"
CODENAME="${CODENAME:-bookworm}"
info "Codename detectado: $CODENAME"

# Crear archivo de repositorio
tee /etc/apt/sources.list.d/adoptium.list > /dev/null << EOF
# Repositorio Adoptium para Java Temurin
deb [signed-by=/usr/share/keyrings/adoptium-archive-keyring.gpg] \
    https://packages.adoptium.net/artifactory/deb $CODENAME main
EOF
ok "Repositorio Adoptium configurado"

# ─── Actualizar e instalar Java ───────────────────────────────
step "Actualizando repositorios e instalando Java 21..."
apt-get update -qq

# Verificar que el paquete está disponible
if ! apt-cache show temurin-21-jdk &>/dev/null; then
    error "El paquete temurin-21-jdk no está disponible en los repositorios"
fi

# Instalar Java 21
apt-get install -y temurin-21-jdk
ok "Java 21 Temurin instalado"

# ─── Configurar Java por defecto ──────────────────────────────
step "Configurando Java como versión por defecto..."

# Verificar instalación
command -v java &>/dev/null || error "Java no se instaló correctamente"

# Mostrar versión instalada
info "Verificando instalación de Java..."
java -version
javac -version

# Determinar JAVA_HOME
default_home=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
if [[ -d "$default_home" ]]; then
    # Crear script en profile.d para usuarios interactivos
    cat > /etc/profile.d/java.sh << EOF
export JAVA_HOME="$default_home"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
    chmod 644 /etc/profile.d/java.sh
    ok "JAVA_HOME configurado en /etc/profile.d/java.sh: $default_home"
else
    warn "No se pudo determinar JAVA_HOME automáticamente"
fi

# ─── Limpiar cache ─────────────────────────────────────────────
step "Limpiando cache de paquetes..."
apt-get autoremove -y
apt-get autoclean
ok "Cache limpiado"

# ─── Verificación final ────────────────────────────────────────
step "Verificación final de la instalación..."
echo
info "=== INFORMACIÓN DE JAVA INSTALADO ==="
echo "Versión Java: $(java -version 2>&1 | head -1)"
echo "Versión Javac: $(javac -version 2>&1)"
echo "Ubicación Java: $(which java)"
echo "JAVA_HOME: ${default_home:-No configurado}"
echo

# Verificar versión
JAVA_VERSION=$(java -version 2>&1 | grep -oP '"\K[0-9]+' | head -1)
if [[ "$JAVA_VERSION" == "21" ]]; then
    ok "Java 21 instalado y configurado correctamente"
else
    warn "La versión de Java instalada no es la 21 ($JAVA_VERSION)"
fi

info "Script de instalación de Java completado"
info "Si JAVA_HOME no aparece en tu entorno, ejecuta: source /etc/profile.d/java.sh o reinicia la sesión."
