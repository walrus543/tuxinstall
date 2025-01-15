# tuxinstall
Basic repo for Arch post install for personal use.

# How to get it
````
sudo pacman -S --needed --noconfirm git base-devel \
  && git clone https://github.com/walrus543/tuxinstall.git ~/tuxinstall \
  && cd ~/tuxinstall \
  && chmod +x ./run_as_root_first.sh \
  && chmod +x ./install.sh
````
## How to run
1. Run `sudo ./run_as_root_first.sh` 
2. Run `./install.sh` 

# Credits
Inspired from Adrien D.'s script of Linuxtricks.fr  
https://github.com/aaaaadrien/fedora-config
