#!/bin/bash
# TODO: standard settings

TMP_DIR=/tmp

# 1. Install packages
sudo apt update
sudo apt install \
software-properties-common \
    apt-listbugs \
    apt-listchanges \
        docker.io \
        docker-compose \
        git \
        grub-customizer \
        htop \
        keepassxc \
        vim \
        zulucrypt-gui \
        virt-manager \
        curl \
        nodejs \
        firmware-linux


# Install Firefox Quantum
FIREFOX_URL='https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-GB'
# sudo wget $FIREFOX_URL -O /opt/firefox.tar.bz2
# sudo tar xfj /opt/firefox.tar.bz2 -C /opt
sudo rm /opt/firefox.tar.bz2

cat << END |
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
sudo tee /usr/share/applications/firefox-quantum.desktop > /dev/null

# 2. Install Dropbox
DROPBOX_DEB=dropbox_2020.03.04_amd64.deb
DROPBOX_URL=https://www.dropbox.com/download?dl=packages/ubuntu/$DROPBOX_DEB
DROPBOX_DEB_FIXED="${DROPBOX_DEB%.*}_fixed.deb"
sudo wget $DROPBOX_URL -O $TMP_DIR/$DROPBOX_DEB
sudo dpkg-deb -R $TMP_DIR/$DROPBOX_DEB $TMP_DIR/dropbox-fix
sudo sed -i "s/libpango1.0-0/libpango-1.0-0/g" $TMP_DIR/dropbox-fix/DEBIAN/control 
sudo dpkg-deb -b $TMP_DIR/dropbox-fix $TMP_DIR/$DROPBOX_DEB_FIXED
sudo apt install python3-gpg 
sudo dpkg -i $TMP_DIR/$DROPBOX_DEB_FIXED
sudo rm -rf $TMP_DIR/dropbox-fix $TMP_DIR/$DROPBOX_DEB_FIXED
dropbox start -i


# 3. Install PyCharm
PYCHARM_ROOT=/opt
PYCHARM_FILE=pycharm-professional-2020.1.tar.gz
PYCHARM_URL=https://download.jetbrains.com/python/$PYCHARM_FILE
cd $PYCHARM_ROOT
sudo wget $PYCHARM_URL -O $PYCHARM_FILE
sudo tar xfz $PYCHARM_FILE
cd $PYCHARM_ROOT/pycharm-*/bin
./pycharm.sh
cd $PYCHARM_ROOT
sudo rm $PYCHARM_FILE

# 4. Install Chrome
sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt -y install ./google-chrome-stable_current_amd64.deb
sudo rm google-chrome-stable_current_amd64.deb


# 5. Install Seafile
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8756C4F765C9AC3CB6B85D62379CE192D401AB61
sudo add-apt-repository -u "echo deb http://deb.seadrive.org buster main"
sudo apt -y install seafile-gui

# 6. Google Cloud & kubectl
echo "deb http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt update && sudo apt -y install google-cloud-sdk kubectl

# 7. Grub: replace graphics mode with 1024x768
sudo sed -i -E "s/^\#? *GRUB_GFXMODE=.+$/GRUB_GFXMODE=\"1024x768\"/g" /etc/default/grub
sudo update-grub


# 8. Install Zoom
wget https://zoom.us/client/latest/zoom_amd64.deb -O /tmp/zoom_amd64.deb
sudo dpkg -i /tmp/zoom_amd64.deb
rm /tmp/zoom_amd64.deb


# 9. Install Spotify
curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com testing non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get -y install spotify-client libavcodec-extra58 libavformat58

# 10. Enable hibernation with existing swap partition
SWAP_UUID=$(sudo blkid | grep "TYPE=\"swap\"" | sed -r "s/.* UUID=\"([^\"]+)\" .*/\1/g")
if ! grep --quiet resume=UUID=$SWAP_UUID /etc/default/grub; then
    sudo sed -i -r "s/\#? *GRUB_CMDLINE_LINUX_DEFAULT=\"(.*)\" *$/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 resume=UUID=$SWAP_UUID\"/g" /etc/default/grub
    sudo update-grub
fi

echo "RESUME=UUID=$SWAP_UUID" | sudo tee /etc/initramfs-tools/conf.d/resume > /dev/null
sudo update-initramfs -u -k all

# 11. Enable hibernation in Gnome and KDE
if [ ! -d /etc/polkit-1/rules.d ]; then
    sudo mkdir /etc/polkit-1/rules.d
fi
cat << END |
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
sudo tee /etc/polkit-1/rules.d/85-suspend.rules  /dev/null