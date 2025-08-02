#!/bin/bash
# Debian Trixie Desktop Environment Setup with Qtile
# Run as regular user with sudo
# Prerequisites: base_tty script must be run first

set -e

# Check user
[[ $EUID -eq 0 ]] && { echo "Run as user, not root"; exit 1; }

# Move desktop configuration files
echo "Setting up desktop configuration files..."
read -p "Press Enter to continue..."

cp -r "$HOME/base_qtile/.config/"* "$HOME/.config/"
cp -r "$HOME/base_qtile/.local/"* "$HOME/.local/"
mv "$HOME/base_qtile/.xinitrc" "$HOME/"
mv "$HOME/base_qtile/.Xresources" "$HOME/"
mv "$HOME/base_qtile/.icons" "$HOME/"
mv "$HOME/base_qtile/.themes" "$HOME/"

# Extract and setup themes
echo "Extracting and setting up themes..."
read -p "Press Enter to continue..."

cd "$HOME/.icons/"
tar -xf BreezeX-RosePine-Linux.tar.xz

cd "$HOME/.themes/"
tar -xf Tokyonight-Dark.tar.xz

# Add Chrome repository
echo "Adding Chrome repository..."
read -p "Press Enter to continue..."

wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

sudo apt update
sudo apt modernize-sources -y

# Install desktop packages
echo "Installing desktop packages..."
read -p "Press Enter to continue..."

sudo apt install -y \
    bluez \
    blueman \
    brightnessctl \
    dunst \
    firefox-esr-l10n-en-ca \
    flatpak \
    fonts-font-awesome \
    fonts-hack \
    gimp \
    google-chrome-stable \
    lxpolkit \
    network-manager-applet \
    pavucontrol \
    picom \
    pulseaudio \
    pulseaudio-utils \
    pulseaudio-module-bluetooth \
    python3-venv \
    python3-pip \
    python3-dev \
    libpangocairo-1.0-0 \
    libxcb-cursor0 \
    x11-xserver-utils \
    xclip \
    xorg \
    xserver-xorg \
    xinit

# Install Qtile with venv
echo "Installing Qtile with Python virtual environment..."
read -p "Press Enter to continue..."

# Create venv for qtile
python3 -m venv ~/.qtile-venv

# Activate venv
source ~/.qtile-venv/bin/activate

# Install qtile and dependencies
pip install qtile pulsectl-asyncio

# Deactivate venv for now
deactivate

# Build suckless tools
echo "Building suckless tools..."
read -p "Press Enter to continue..."

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

# Build ST terminal
echo "Building ST terminal..."
read -p "Press Enter to continue..."

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

# Build sxiv
echo "Building sxiv..."
read -p "Press Enter to continue..."

git clone https://github.com/xyb3rt/sxiv
cd sxiv
make clean
sudo make install
cd ..
tar -czf sxiv-backup.tar.gz sxiv/

# Build slock
# echo "Building slock..."
# read -p "Press Enter to continue..."

# git clone https://git.suckless.org/slock
# cd slock
# wget https://tools.suckless.org/slock/patches/blur-pixelated-screen/slock-blur_pixelated_screen-1.4.diff

# patch -p1 < slock-blur_pixelated_screen-1.4.diff
# sed -i 's/CFLAGS = /CFLAGS = -Wno-error /' Makefile
# make clean
# sudo make install
# cd ..
# tar -czf slock-patched-backup.tar.gz slock/

# Build dmenu
# echo "Building dmenu..."
# read -p "Press Enter to continue..."

# git clone https://git.suckless.org/dmenu
# cd dmenu
# wget https://tools.suckless.org/dmenu/patches/alpha/dmenu-alpha-20230110-5.2.diff

# patch -p1 < dmenu-alpha-20230110-5.2.diff
# make clean
# sudo make install
# cd ..
# tar -czf dmenu-patched-backup.tar.gz dmenu/

# Cleanup downloaded archives
rm -f st-0.9.2.tar.gz

# Install themes system-wide
echo "Installing themes system-wide..."
read -p "Press Enter to continue..."

sudo cp -r "$HOME/.icons/BreezeX-RosePine-Linux" /usr/share/icons/
sudo cp -r "$HOME/.themes/Tokyonight-Dark" /usr/share/themes/

# Configure cursor theme
sudo sed -i 's/Adwaita/BreezeX-RosePine-Linux/g' /usr/share/icons/default/index.theme

# Install Flatpak applications
echo "Installing Flatpak applications..."
read -p "Press Enter to continue..."

# Add Flathub repository
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo

# Install applications
flatpak install -y --user flathub org.flameshot.Flameshot
flatpak install -y --user flathub com.protonvpn.www

# Apply theme overrides for all Flatpak applications
flatpak override --user --env=GTK_THEME=Tokyonight-Dark
flatpak override --user --env=XCURSOR_THEME=BreezeX-RosePine-Linux

# Configure services
echo "Configuring desktop services..."
read -p "Press Enter to continue..."

# Enable PulseAudio services (user session will start automatically)
systemctl --user --global enable pulseaudio.service
systemctl --user --global enable pulseaudio.socket

# Update .xinitrc to use qtile from venv
echo "Updating .xinitrc for Qtile venv..."
read -p "Press Enter to continue..."

sed -i 's|exec qtile start|source ~/.qtile-venv/bin/activate \&\& exec qtile start|' ~/.xinitrc

echo "Desktop environment setup complete with Qtile and PulseAudio."
echo "To start: startx"
echo "Qtile will be available in virtual environment at ~/.qtile-venv"
