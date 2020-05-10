#!/bin/bash
# TODO: standard settings

TMP_DIR=/tmp

#
SWAP_SIZE_MB=$(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024)))
# if [ ! -f /swapfile ]; then
    sudo dd if=/dev/zero of=/swapfile bs=1M count=$SWAP_SIZE_MB  # oflag=append conv=notrunc
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapoff -a
    sudo swapon /swapfile
# fi

exit

# 1. Install packages
sudo apt update
sudo apt install \
software-properties-common \
    apt-listbugs \
    apt-listchanges \
        docker.io \
        firefox-esr \
        git \
        grub-customizer \
        htop \
        keepassxc \
        vim \
        zulucrypt-gui \
        virt-manager \
        curl


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
