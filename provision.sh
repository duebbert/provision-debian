#!/bin/bash
# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# TODO:
#   - replace dotbot
#   - test in virt-man
#   - rootless Docker: https://docs.docker.com/engine/security/rootless/
#   - https://help.ubuntu.com/community/ManualFullSystemEncryption

#   - Add private settings:
#      - dotfiles:
#         - switch languages meta-space
#         - kpanel
#         - gcloud: ./config/gcloud
#         - kube: .kube
#         - .ssh config: .ssh/config
#         - docker hub: .docker directory
#         - add standard veracrypt volume to favourites
#         - insomnia: .config/Insomnia
#         - JetBrains: .config/JetBrains
#      - [PRIVATE] add symlinks
#      - [PRIVATE] start zulucrypt and mount volume
#      - [PRIVATE] start seafile after zulucrypt
#      - [PRIVATE] implement getting confidential settings
#      - [PRIVATEpycharm settings
#      - keepassxc settings
#      - Firefox sync

TMP_DIR=/tmp

########################################################################################################################
# Install Vagrant and Qemu/KVM

sudo apt update
sudo apt install -y vagrant vagrant-libvirt qemu-kvm libvirt-clients libvirt-daemon-system
sudo usermod -aG libvirt "$USER"
newgrp libvirt
sudo service libvirtd start

exit

########################################################################################################################
# Install Insomnia

# Add to sources
echo "deb https://dl.bintray.com/getinsomnia/Insomnia /" |
  sudo tee /etc/apt/sources.list.d/insomnia.list >/dev/null

# Add public key used to verify code signature
wget --quiet -O - https://insomnia.rest/keys/debian-public.key.asc |
  sudo apt-key add -

# Refresh repository sources and install Insomnia
sudo apt-get update
sudo apt-get install insomnia

########################################################################################################################
# Install Franz

FRANZ_DEB=franz_5.5.0_amd64.deb
FRANZ_URL=https://github.com/meetfranz/franz/releases/download/v5.5.0/$FRANZ_DEB
wget "$FRANZ_URL" -O $TMP_DIR/$FRANZ_DEB
sudo apt install $TMP_DIR/$FRANZ_DEB
rm $TMP_DIR/$FRANZ_DEB

########################################################################################################################
# Install Veracrypt

VERACRYPT_DEB=veracrypt-1.24-Update4-Debian-10-amd64.deb
VERACRYPT_URL="https://launchpad.net/veracrypt/trunk/1.24-update4/+download/$VERACRYPT_DEB"
wget "$VERACRYPT_URL" -O $TMP_DIR/$VERACRYPT_DEB
sudo apt install $TMP_DIR/$VERACRYPT_DEB
rm $TMP_DIR/$VERACRYPT_DEB

########################################################################################################################
# Install Yarn

sudo apt update
sudo apt install yarnpkg
sudo update-alternatives --install /usr/bin/yarn yarn /usr/bin/yarnpkg 1

exit

########################################################################################################################
# 7. Grub: replace graphics mode with 1024x768

GFX_MODES=1600x1200,1280x1024,1024x768,auto
sudo sed -i -E "s/^\#? *GRUB_GFXMODE=.+$/GRUB_GFXMODE=\"$GFX_MODES\"/g" /etc/default/grub
sudo sed -i -E "s/^\#? *GRUB_DISABLE_RECOVERY=.+$/GRUB_DISABLE_RECOVERY=\"true\"/g" /etc/default/grub
if grep --quiet GRUB_GFXPAYLOAD_LINUX /etc/default/grub; then
  sudo sed -i -E "s/^\#? *GRUB_GFXPAYLOAD_LINUX=.+$/GRUB_GFXPAYLOAD_LINUX=\"keep\"/g" /etc/default/grub
else
  printf "\nGRUB_GFXPAYLOAD_LINUX=\"keep\"\n" | sudo tee -a /etc/default/grub >/dev/null
fi
sudo update-grub

########################################################################################################################
# 1. Install packages

sudo apt update
sudo apt install \
  software-properties-common \
  apt-listbugs \
  apt-listchanges \
  git \
  grub-customizer \
  htop \
  keepassxc \
  vim \
  virt-manager \
  curl \
  nodejs \
  firmware-linux \
  yarnpkg \
  jq \
  pulseaudio \
  pulseaudio-module-bluetooth \
  bluez-firmware

#  zulucrypt-gui \

########################################################################################################################
# Install Docker

sudo apt update
sudo apt install docker.io uidmap docker-compose

# Allow running as non-root
# https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
sudo groupadd docker
sudo usermod -aG docker "$USER"
newgrp docker

# TODO
## https://docs.docker.com/engine/security/rootless/
#echo "kernel.unprivileged_userns_clone=1" | sudo tee /etc/sysctl.d/60-docker.conf >/dev/null
#sudo sysctl -p --system
#sudo modprobe overlay permit_mounts_in_userns=1
#echo "options overlay permit_mounts_in_userns=1" | sudo tee /etc/modprobe.d/docker-overlay.conf >/dev/null

########################################################################################################################
# Install Podman
# TODO: make it work....

#echo 'deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_Testing/ /' | sudo tee /etc/apt/sources.list.d/podman-kubic.list > /dev/null
#curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_Testing/Release.key | sudo apt-key add -
#sudo apt update
#sudo apt-get -qq -y install podman

########################################################################################################################
# Install Firefox Quantum

FIREFOX_URL='https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-GB'
sudo wget "$FIREFOX_URL" -O /opt/firefox.tar.bz2
sudo tar xfj /opt/firefox.tar.bz2 -C /opt
sudo rm /opt/firefox.tar.bz2

cat <<END |
[Desktop Entry]
Name=Firefox Quantum
Comment=Browse the World Wide Web
GenericName=Web Browser
X-GNOME-FullName=Firefox Quantum Web Browser
Exec=/opt/firefox/firefox %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=firefox
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Firefox-esr
StartupNotify=true
END
  sudo tee /usr/share/applications/firefox-quantum.desktop >/dev/null

########################################################################################################################
# 2. Install Dropbox

DROPBOX_DEB=dropbox_2020.03.04_amd64.deb
DROPBOX_URL="https://www.dropbox.com/download?dl=packages/ubuntu/$DROPBOX_DEB"
DROPBOX_DEB_FIXED="${DROPBOX_DEB%.*}_fixed.deb"
sudo wget "$DROPBOX_URL" -O $TMP_DIR/$DROPBOX_DEB

# https://www.reddit.com/r/debian/comments/g13vxj/dropbox_users_in_testingsid_libpango100_to/
sudo dpkg-deb -R $TMP_DIR/$DROPBOX_DEB $TMP_DIR/dropbox-fix
sudo sed -i "s/libpango1.0-0/libpango-1.0-0/g" $TMP_DIR/dropbox-fix/DEBIAN/control
sudo dpkg-deb -b $TMP_DIR/dropbox-fix $TMP_DIR/$DROPBOX_DEB_FIXED
sudo apt install python3-gpg
sudo dpkg -i $TMP_DIR/$DROPBOX_DEB_FIXED
sudo rm -rf $TMP_DIR/dropbox-fix $TMP_DIR/$DROPBOX_DEB_FIXED
dropbox start -i

########################################################################################################################
# 3. Install PyCharm

PYCHARM_ROOT=/opt
PYCHARM_FILE=pycharm-professional-2020.1.tar.gz
PYCHARM_URL=https://download.jetbrains.com/python/$PYCHARM_FILE
cd $PYCHARM_ROOT || exit
sudo wget $PYCHARM_URL -O $PYCHARM_FILE
sudo tar xfz $PYCHARM_FILE
cd "$PYCHARM_ROOT/pycharm-*/bin" || exit
./pycharm.sh
cd "$PYCHARM_ROOT" || exit
sudo rm $PYCHARM_FILE

# Increaase inotify limit
echo "fs.inotify.max_user_watches = 524288" | sudo tee /etc/sysctl.d/99-pycharm-inotify.conf >/dev/null
sudo sysctl -p --system
# systemctl restart systemd-sysctl.service

########################################################################################################################
# 4. Install Chrome

sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt -y install ./google-chrome-stable_current_amd64.deb
sudo rm google-chrome-stable_current_amd64.deb

########################################################################################################################
# 5. Install Seafile

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8756C4F765C9AC3CB6B85D62379CE192D401AB61
sudo add-apt-repository -u "echo deb http://deb.seadrive.org buster main"
sudo apt -y install seafile-gui

########################################################################################################################
# 6. Google Cloud & kubectl

echo "deb http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt update && sudo apt -y install google-cloud-sdk kubectl

########################################################################################################################
# 8. Install Zoom

wget https://zoom.us/client/latest/zoom_amd64.deb -O /tmp/zoom_amd64.deb
sudo dpkg -i /tmp/zoom_amd64.deb
rm /tmp/zoom_amd64.deb

########################################################################################################################
# 9. Install Spotify

curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb http://repository.spotify.com testing non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get -y install spotify-client libavcodec-extra58 libavformat58

########################################################################################################################
# 10. Enable hibernation with existing swap partition

SWAP_UUID=$(sudo blkid | grep "TYPE=\"swap\"" | sed -r "s/.* UUID=\"([^\"]+)\" .*/\1/g")
if ! grep --quiet "resume=UUID=$SWAP_UUID" /etc/default/grub; then
  sudo sed -i -r "s/\#? *GRUB_CMDLINE_LINUX_DEFAULT=\"(.*)\" *$/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 resume=UUID=$SWAP_UUID\"/g" /etc/default/grub
  sudo update-grub
fi

echo "RESUME=UUID=$SWAP_UUID" | sudo tee /etc/initramfs-tools/conf.d/resume >/dev/null
sudo update-initramfs -u -k all

# Enable hibernation in Gnome and KDE
if [ ! -d /etc/polkit-1/rules.d ]; then
  sudo mkdir /etc/polkit-1/rules.d
fi
cat <<END |
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.suspend" ||
        action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
        action.id == "org.freedesktop.login1.hibernate" ||
        action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
    {
        return polkit.Result.YES;
    }
});
END
  sudo tee /etc/polkit-1/rules.d/85-suspend.rules /dev/null
