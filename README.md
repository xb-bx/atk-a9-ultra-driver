# Linux driver for ATK A9 Ultra
Capabilities:
- [X] Query battery charge
- [X] Set/Query polling rate
- [X] Set/Query hibernation time 
- [X] Set/Query angle snap
- [X] Set/Query ripple correction
- [X] Set/Query move synchronization
- [X] Set/Query key delay time
- [X] Set/Query DPI colors 
- [X] Set/Query Performance mode
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
git clone https://github.com/xb-bx/atk-a9-ultra-driver --recursive
cd atk-a9-ultra-driver 
makepkg -si
```
## Other
```sh
git clone https://github.com/xb-bx/atk-a9-ultra-driver --recursive
sudo make install
```
