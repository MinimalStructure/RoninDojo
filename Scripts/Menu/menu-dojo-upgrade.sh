#!/bin/bash

RED='\033[0;31m'
# used for color with ${RED}
YELLOW='\033[1;33m'
# used for color with ${YELLOW}
NC='\033[0m'
# No Color

USER=$(sudo cat /etc/passwd | grep 1000 | awk -F: '{ print $1}' | cut -c 1-)

echo -e "${RED}"
echo "***"
echo "Upgrading Dojo in 30s..."
echo "Use Ctrl+C to exit if needed!"
echo "***"
echo -e "${NC}"
sleep 30s
cd ~/dojo/docker/my-dojo
sudo ./dojo.sh stop
sudo chown -R $USER:$USER ~/dojo/*
mkdir ~/.dojo > /dev/null 2>&1
cd ~/.dojo
sudo rm -rf samourai-dojo > /dev/null 2>&1
git clone -b feat_mydojo_local_indexer https://github.com/BTCxZelko/samourai-dojo.git
cp -rv samourai-dojo/* ~/dojo

echo -e "${RED}"
echo "Installing your Dojo-backed Bitcoin Explorer"
sleep 1s
echo -e "${YELLOW}"
echo "This password should be something you can remember and is alphanumerical"
sleep 1s
echo -e "${NC}"
if [ ! -f /home/$USER/dojo/docker/my-dojo/conf/docker-explorer.conf ]; then
    read -p 'Your Dojo Explorer password: ' EXPLORER_PASS
    sleep 1s
    echo -e "${YELLOW}"
    echo "----------------"
    echo "$EXPLORER_PASS"
    echo "----------------"
    echo -e "${RED}"
    echo "Is this correct?"
    echo -e "${NC}"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) read -p 'New Dojo Explorer password: ' EXPLORER_PASS
            echo "$EXPLORER_PASS"
        esac
    done
    echo -e "${RED}"
    echo "$EXPLORER_PASS"
else
    echo "Explorer is already installed"
fi

sed -i '16i EXPLORER_KEY='$EXPLORER_PASS'' ~/dojo/docker/my-dojo/conf/docker-explorer.conf.tpl
sed -i '17d' ~/dojo/docker/my-dojo/conf/docker-explorer.conf.tpl

# Install Indexer

if [ ! -f /home/$USER/dojo/docker/my-dojo/conf/docker-indexer.conf ]; then
    read -p "Do you want to install an indexer? [y/n]" yn
    case $yn in
        [Y/y]* ) sudo sed -i '9d' ~/dojo/docker/my-dojo/conf/docker-indexer.conf.tpl; sudo sed -i '9i INDEXER_INSTALL=on' ~/dojo/docker/my-dojo/conf/docker-indexer.conf.tpl; sudo sed -i '25d' ~/dojo/docker/my-dojo/conf/docker-node.conf.tpl; sudo sed -i '25i NODE_ACTIVE_INDEXER=local_indexer' ~/dojo/docker/my-dojo/conf/docker-node.conf.tpl;;
        [N/n]* ) echo "Indexer will not installed";;
        * ) echo "Please answer yes or no.";;
    esac 
else 
    echo "Indexer already installed"
fi 

read -p "Do you want to install Electrs? [y/n]" yn
case $yn in
    [Y/y]* ) bash ~/RoninDojo/Scripts/Install/electrs-indexer.sh;;
    [N/n]* ) echo "Electrs not installed.";;
    * ) echo "Please answer yes or no.";;
esac

# Run upgrade
cd ~/dojo/docker/my-dojo
sudo ./dojo.sh upgrade

# Return to menu
bash ~/RoninDojo/Scripts/Menu/menu-dojo.sh
