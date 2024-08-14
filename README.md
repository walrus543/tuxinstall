# tuxinstall
Basic repo for Arch post install for personal use.

# How to get it
````
sudo pacman -S --needed --noconfirm git base-devel \
  && git clone https://github.com/walrus543/tuxinstall.git ~/tuxinstall \
  && cd ~/tuxinstall \
  && chmod +x ./install.sh
````
## How to run
* Run `sudo ./install.sh` to set main settings and install packages
* Run `./install.sh user` for user specific commands without root access

# Credits
Inspired from Adrien D.'s script of Linuxtricks.fr  
https://github.com/aaaaadrien/fedora-config
