pkgname="atk-a9-ultra-driver"
pkgver="1.0.0"
pkgrel="1"
pkgdesc="Userspace driver for ATK A9 Ultra mouse"
arch=("x86_64")
depends=("libusb")
makedepends=("odin" "git")
url="https://github.com/xb-bx/atk-a9-ultra-driver"
source=("git+$url")
md5sums=("SKIP")

build() {
    cd $pkgname
    git submodule update --force --init --recursive
    make release
}
package() {
    cd $pkgname
    DESTDIR="${pkgdir}/" make install
}

