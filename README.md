# Linux driver for ATK A9 Ultra
Capabilities:
- [X] Get battery charge
- [X] Set current polling rate
# Build requirements
    - odin
    - make
    - libusb
# Build instructions
```sh
make
```

# Installation
## Arch-based distros
```sh
git clone https://github.com/xb-bx/attack-shark-r1-driver --recursive
cd attack-shark-r1-driver
makepkg -si
```
## Other
```sh
git clone https://github.com/xb-bx/attack-shark-r1-driver --recursive
sudo make install
```
