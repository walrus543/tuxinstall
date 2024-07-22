# tuxinstall
Basic repo for Arch post install

# How to use
````
sudo pacman -S --needed --noconfirm git base-devel \
  && git clone https://github.com/walrus543/tuxinstall.git ~/tuxinstall \
  && cd ~/tuxinstall \
  && chmod +x ./install.sh \
  && ./install.sh
````
