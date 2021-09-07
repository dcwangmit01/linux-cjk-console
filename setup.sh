#!/usr/bin/env bash
set -euo pipefail

# Install X and Xterm
if ! which startx 2>&1 > /dev/null; then
    sudo apt-get -y update
    sudo apt-get install -y --no-install-recommends \
	 xinit xterm \
	 xserver-xorg-video-vesa \
	 xserver-xorg-input-mouse \
	 xserver-xorg-input-kbd \
	 xserver-xorg-input-evdev \
	 x11-xserver-utils
fi

# Install CJK Fonts
if ! dpkg -l |grep noto 2>&1 > /dev/null; then
    # Install CJK Fonts (Chinese, Japanese, Korean)
    #   https://www.google.com/get/noto/
    sudo apt-get -y update
    sudo apt-get install -y --no-install-recommends \
	 fonts-noto-cjk \
	 fonts-noto-cjk-extra
fi

# Install Dialog
if ! which dialog 2>&1 > /dev/null; then
    sudo apt-get -y update
    sudo apt-get install -y --no-install-recommends \
	 dialog
fi

# Add a linux user named 'user' with password 'user'
if ! grep user /etc/passwd 2>&1 >/dev/null; then
    username=user
    password=user
    sudo adduser --gecos "" --disabled-password $username
    sudo chpasswd <<<"$username:$password"
fi

# Create a Dialog script that uses CJK UTF8 characters
cat << EOF | sudo -i -u user tee dialog.sh > /dev/null
#!/usr/bin/env bash
set -euo pipefail

# Only necessary to set i18n of "OK" or "Cancel" buttons
# LANG="ja_JP.utf8"
# LANGUAGE="ja_JP.utf8"

CHINESE="Chinese (中国)"
JAPANESE="Japanese (日本)"
KOREAN="Korean (대한민국)"
dialog --title 'Asian CJK Language Demo' \
       --menu 'Select:' 0 0 0 \
       1 "\$CHINESE" \
       2 "\$JAPANESE" \
       3 "\$KOREAN"
EOF
sudo -i -u user chmod a+x dialog.sh

# Configure Xterm via .Xresources, to use Noto Fonts
cat << EOF | sudo -i -u user tee .Xresources > /dev/null
! fonts and encoding
xterm*utf8: true
xterm*locale: true
xterm*utf8Title: true
xterm*renderFont: true
xterm*preeditType: Root
xterm*xftAntialias: true
xterm*faceName: DejaVu Sans Mono:size=12
xterm*faceNameDoublesize: Noto Sans Mono CJK SC:size=12
EOF

# Create a .xinitrc
cat << EOF | sudo -i -u user tee /home/user/.xinitrc > /dev/null
# Load Xterm settings from Xresources
xrdb -merge ~/.Xresources

# Starts Xterm, which in term starts the dialog script
/usr/bin/xterm -maximized -e "bash -c './dialog.sh'"
EOF

# Bash Profile
# if ! cat .bash_profile | grep tty1 2>&1 > /dev/null; then
#     cat << EOF | sudo -i -u user tee .bash_profile > /dev/null
# if [ -z "\$DISPLAY" ] && [ \$(tty) == /dev/tty1 ]; then
#     startx
# fi
# EOF
# fi

# Override/Take Over Getty configuration to startx instead
sudo mkdir -p "/etc/systemd/system/getty@tty1.service.d"
cat <<EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null
[Service]
ExecStart=
ExecStart=-/usr/bin/su -l user startx
WorkingDirectory=~
StandardInput=tty
StandardOutput=tty
EOF

# Restart Getty systemd service to take effect
sudo systemctl daemon-reload
sudo systemctl restart getty@tty1.service

# Start the minimal X server with default xterm
# startx
