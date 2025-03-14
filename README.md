# tuxinstall
Basic repo for Arch post install for personal use.

# How to get it
````
sudo pacman -S --needed --noconfirm git base-devel \
  && git clone https://github.com/walrus543/tuxinstall.git ~/tuxinstall \
  && cd ~/tuxinstall \
  && chmod +x ./root_only.sh \
  && chmod +x ./install.sh
````
## How to run
1. Run `./install.sh` 

# Credits
Inspired from Adrien D.'s script of Linuxtricks.fr  
https://github.com/aaaaadrien/fedora-config
