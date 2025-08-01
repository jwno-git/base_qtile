#!/bin/bash
# Debian Trixie Qtile Desktop Environment Setup
# Run as regular user with sudo
# Prerequisites: base_tty script must be run first

set -e

# Check user
[[ $EUID -eq 0 ]] && { echo "Run as user, not root"; exit 1; }

echo "Starting Qtile desktop environment setup..."

# Move desktop configuration files
echo "Setting up desktop configuration files..."
read -p "Press Enter to continue..."

cp -r "$HOME/base_qtile/.config/"* "$HOME/.config/"
cp -r "$HOME/base_qtile/.local/"* "$HOME/.local/"
mv "$HOME/base_qtile/.xinitrc" "$HOME/"
mv "$HOME/base_qtile/.Xresources" "$HOME/"
mv "$HOME/base_qtile/.icons" "$HOME/"
mv "$HOME/base_qtile/.themes" "$HOME/"

# Move battery toggle script
sudo mv "$HOME/base_qtile/battery-toggle" /usr/local/bin/
sudo chmod +x /usr/local/bin/battery-toggle

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

# Install desktop packages (qtile removed - will install separately)
echo "Installing desktop packages..."
read -p "Press Enter to continue..."

sudo apt install -y \
    bluez \
    brightnessctl \
    dunst \
    feh \
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
    pipewire \
    pipewire-pulse \
    pipewire-audio \
    pipewire-alsa \
    x11-xserver-utils \
    xclip \
    xorg \
    xserver-xorg \
    xinit

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
echo "Building dmenu..."
read -p "Press Enter to continue..."

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

# Install Qtile with uv (reliable method)
echo "Installing Qtile with uv..."
read -p "Press Enter to continue..."

# Install Python development dependencies
sudo apt install -y \
    python3-dev \
    python3-venv \
    libpangocairo-1.0-0 \
    libxcb-render0-dev \
    libffi-dev \
    libcairo2 \
    libpango-1.0-0 \
    libgdk-pixbuf-2.0-0 \
    libxcb-xinerama0-dev \
    libxcb-randr0-dev

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add uv to PATH
export PATH="$HOME/.local/bin:$PATH"

# Create isolated qtile environment
uv venv ~/.qtile-env
source ~/.qtile-env/bin/activate

# Install qtile
uv pip install qtile

# Create qtile launcher script
sudo tee /usr/local/bin/qtile > /dev/null << 'EOF'
#!/bin/bash
source ~/.qtile-env/bin/activate
exec python -m qtile "$@"
EOF

sudo chmod +x /usr/local/bin/qtile

# Test installation
echo "Testing Qtile installation..."
source ~/.qtile-env/bin/activate
python -c "import qtile; print('Qtile version:', qtile.__version__)"
deactivate

# Configure Qtile
echo "Configuring Qtile..."
read -p "Press Enter to continue..."

# Install themes system-wide
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

# Enable user services
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
systemctl --user enable wireplumber

# Setup monitor hotplug udev rule
echo "Setting up monitor hotplug detection..."
read -p "Press Enter to continue..."

# Create udev rule for monitor hotplug
sudo tee /etc/udev/rules.d/95-monitor-hotplug.rules > /dev/null << 'EOF'
ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", RUN+="/usr/local/bin/monitor-hotplug.sh"
EOF

# Create hotplug script
sudo tee /usr/local/bin/monitor-hotplug.sh > /dev/null << 'EOF'
#!/bin/bash

# Log the event
echo "$(date): Monitor hotplug event detected" >> /tmp/monitor-hotplug.log

# Find the user running X session
DISPLAY_USER=$(who | grep -E "\(:0\)|tty7" | head -n1 | awk '{print $1}')

if [ -n "$DISPLAY_USER" ]; then
    # Run the monitor config as the user
    sudo -u "$DISPLAY_USER" DISPLAY=:0 /home/"$DISPLAY_USER"/.local/bin/monitor-config.sh
    echo "$(date): Executed monitor-config.sh for user $DISPLAY_USER" >> /tmp/monitor-hotplug.log
else
    echo "$(date): No active X session found" >> /tmp/monitor-hotplug.log
fi
EOF

sudo chmod +x /usr/local/bin/monitor-hotplug.sh

# Reload udev rules
sudo udevadm control --reload-rules

echo "Qtile desktop environment setup complete. Reboot recommended."
