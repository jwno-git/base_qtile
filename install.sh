#!/bin/bash
# Debian Trixie Desktop Environment Setup Script
# Run as regular user with sudo privileges
# Prerequisites: base_tty script must be run first

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "Do not run this script as root. Run as regular user with sudo privileges."
    exit 1
fi

# Set base directory variable
BASE_DIR="$HOME/base_qtile"

# Verify we're on Debian Trixie
if ! grep -q "trixie" /etc/debian_version 2>/dev/null; then
    log_warn "This script is designed for Debian Trixie. Continue anyway? [y/N]"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]] || exit 1
fi

log_info "Starting Debian Trixie desktop environment setup..."

read -p "Press Enter to continue..."

# ============================================================================
# STEP 1: Move Desktop Configuration Files
# ============================================================================
log_info "Setting up desktop configuration files..."

# Move user configuration directories and files
mv "$BASE_DIR/.config" "$HOME/"
mv "$BASE_DIR/.local" "$HOME/"
mv "$BASE_DIR/Pictures" "$HOME/"
mv "$BASE_DIR/.xinitrc" "$HOME/"
mv "$BASE_DIR/.Xresources" "$HOME/"
mv "$BASE_DIR/.icons" "$HOME/"
mv "$BASE_DIR/.themes" "$HOME/"

# Move battery toggle script
sudo mv "$BASE_DIR/battery-toggle" /usr/local/bin/
sudo chmod +x /usr/local/bin/battery-toggle

log_info "Desktop configuration files moved successfully"

# ============================================================================
# STEP 2: Extract and Setup Themes
# ============================================================================
log_info "Extracting and setting up themes..."

# Extract icon theme
cd "$HOME/.icons/"
tar -xf BreezeX-RosePine-Linux.tar.xz

# Extract GTK theme
cd "$HOME/.themes/"
tar -xf Tokyonight-Dark.tar.xz

log_info "Themes extracted successfully"

# ============================================================================
# STEP 3: Add Chrome Repository
# ============================================================================
log_info "Adding Chrome repository..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

sudo apt update
sudo apt modernize-sources -y

# ============================================================================
# STEP 4: Install Desktop Packages
# ============================================================================
log_info "Installing desktop packages..."
sudo apt install -y \
    bluez \
    brightnessctl \
    dunst \
    feh \
    firefox-esr-l10n-en-ca \
    flatpak \
    fonts-font-awesome \
    fonts-hack \
    gawk \
    gimp \
    google-chrome-stable \
    lxpolkit \
    network-manager-applet \
    pavucontrol \
    picom \
    pipewire \
    pipewire-pulse \
    pipewire-audio \
    pipewire-alsa \
    qtile \
    x11-xserver-utils \
    xclip \
    xorg \
    xserver-xorg \
    xinit

# ============================================================================
# STEP 5: Build Suckless Tools
# ============================================================================
log_info "Building suckless tools..."

# Install build dependencies
sudo apt install -y \
    build-essential \
    libx11-dev \
    libxft-dev \
    libxinerama-dev \
    libxext-dev \
    libxrandr-dev \
    libimlib2-dev \
    libexif-dev \
    libgif-dev \
    libpam0g-dev \
    libxmu-dev \
    pkg-config \
    make

cd "$HOME/src"

# ============================================================================
# Build ST terminal
# ============================================================================
log_info "Building ST terminal..."
wget https://dl.suckless.org/st/st-0.9.2.tar.gz
tar -xzf st-0.9.2.tar.gz
cd st-0.9.2

# Download and apply patches
wget https://st.suckless.org/patches/blinking_cursor/st-blinking_cursor-20230819-3a6d6d7.diff
wget https://st.suckless.org/patches/bold-is-not-bright/st-bold-is-not-bright-20190127-3be4cf1.diff
wget https://st.suckless.org/patches/scrollback/st-scrollback-0.9.2.diff
wget https://st.suckless.org/patches/scrollback/st-scrollback-mouse-0.9.2.diff

patch -p1 < st-blinking_cursor-20230819-3a6d6d7.diff
patch -p1 < st-bold-is-not-bright-20190127-3be4cf1.diff
patch -p1 < st-scrollback-0.9.2.diff
patch -p1 < st-scrollback-mouse-0.9.2.diff

make clean
sudo make install
cd ..
tar -czf st-patched-backup.tar.gz st-0.9.2/

# ============================================================================
# Build sxiv
# ============================================================================
log_info "Building sxiv..."
git clone https://github.com/xyb3rt/sxiv
cd sxiv
make clean
sudo make install
cd ..
tar -czf sxiv-backup.tar.gz sxiv/

# ============================================================================
# Build slock
# ============================================================================
log_info "Building slock..."
git clone https://git.suckless.org/slock
cd slock
wget https://tools.suckless.org/slock/patches/blur-pixelated-screen/slock-blur_pixelated_screen-1.4.diff

patch -p1 < slock-blur_pixelated_screen-1.4.diff
sed -i 's/CFLAGS = /CFLAGS = -Wno-error /' Makefile
make clean
sudo make install
cd ..
tar -czf slock-patched-backup.tar.gz slock/

# ============================================================================
# Build dmenu
# ============================================================================
log_info "Building dmenu..."
git clone https://git.suckless.org/dmenu
cd dmenu
wget https://tools.suckless.org/dmenu/patches/alpha/dmenu-alpha-20230110-5.2.diff

patch -p1 < dmenu-alpha-20230110-5.2.diff
make clean
sudo make install
cd ..
tar -czf dmenu-patched-backup.tar.gz dmenu/

# Cleanup downloaded archives
rm -f st-0.9.2.tar.gz

log_info "Suckless tools built and installed successfully"

# ============================================================================
# STEP 6: Configure Qtile
# ============================================================================
log_info "Configuring qtile..."

# Create qtile desktop entry
sudo mkdir -p /usr/share/xsessions
sudo tee /usr/share/xsessions/qtile.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Qtile
Comment=Qtile Session
Exec=qtile start
Type=Application
Keywords=wm;tiling
EOF

# Install themes system-wide
sudo cp -r "$HOME/.icons/BreezeX-RosePine-Linux" /usr/share/icons/
sudo cp -r "$HOME/.themes/Tokyonight-Dark" /usr/share/themes/

# Configure cursor theme
sudo sed -i 's/Adwaita/BreezeX-RosePine-Linux/g' /usr/share/icons/default/index.theme

log_info "Qtile configured successfully"

# ============================================================================
# STEP 7: Install Flatpak Applications
# ============================================================================
log_info "Installing Flatpak applications..."

# Add Flathub repository
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo

# Install applications
flatpak install -y --user flathub org.flameshot.Flameshot
flatpak install -y --user flathub com.protonvpn.www
flatpak install -y --user flathub com.obsproject.Studio
flatpak install -y --user flathub org.standardnotes.standardnotes
flatpak install -y --user flathub com.discordapp.Discord
flatpak install -y --user flathub com.bitwarden.desktop
flatpak install -y --user flathub org.kde.kdenlive
flatpak install -y --user flathub com.slack.Slack

# Apply theme overrides to Flatpak applications
log_info "Applying theme overrides to Flatpak applications..."
flatpak override --user --env=GTK_THEME=Tokyonight-Dark org.flameshot.Flameshot
flatpak override --user --env=XCURSOR_THEME=BreezeX-RosePine-Linux org.flameshot.Flameshot
flatpak override --user --env=GTK_THEME=Tokyonight-Dark com.protonvpn.www
flatpak override --user --env=XCURSOR_THEME=BreezeX-RosePine-Linux com.protonvpn.www
flatpak override --user --env=GTK_THEME=Tokyonight-Dark com.obsproject.Studio
flatpak override --user --env=XCURSOR_THEME=BreezeX-RosePine-Linux com.obsproject.Studio
flatpak override --user --env=GTK_THEME=Tokyonight-Dark org.standardnotes.standardnotes
flatpak override --user --env=XCURSOR_THEME=BreezeX-RosePine-Linux org.standardnotes.standardnotes
flatpak override --user --env=GTK_THEME=Tokyonight-Dark com.discordapp.Discord
flatpak override --user --env=XCURSOR_THEME=BreezeX-RosePine-Linux com.discordapp.Discord
flatpak override --user --env=GTK_THEME=Tokyonight-Dark com.bitwarden.desktop
flatpak override --user --env=XCURSOR_THEME=BreezeX-RosePine-Linux com.bitwarden.desktop
flatpak override --user --env=GTK_THEME=Tokyonight-Dark org.kde.kdenlive
flatpak override --user --env=XCURSOR_THEME=BreezeX-RosePine-Linux org.kde.kdenlive
flatpak override --user --env=GTK_THEME=Tokyonight-Dark com.slack.Slack
flatpak override --user --env=XCURSOR_THEME=BreezeX-RosePine-Linux com.slack.Slack

log_info "Flatpak applications installed and themed"

# ============================================================================
# STEP 8: Configure Services
# ============================================================================
log_info "Configuring desktop services..."

# Enable user services
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
systemctl --user enable wireplumber

log_info "Desktop services configured"

# ============================================================================
# STEP 9: Final Status
# ============================================================================
log_info "Desktop environment setup completed successfully!"
log_info "Installed components:"
echo "  ✓ Desktop configuration files"
echo "  ✓ Themes and icons (BreezeX-RosePine, Tokyonight-Dark)"
echo "  ✓ Suckless tools (st, sxiv, slock, dmenu)"
echo "  ✓ Qtile window manager"
echo "  ✓ Google Chrome and Firefox"
echo "  ✓ Flatpak applications with theming"
echo "  ✓ Audio system (PipeWire)"

log_warn "Next steps:"
echo "  1. Reboot to ensure all services start correctly"
echo "  2. Log into qtile desktop session"
echo "  3. Test suckless tools and applications"
echo "  4. Configure Python development environment if needed"

log_info "Reboot recommended. Reboot now? [y/N]"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    sudo reboot
fi
