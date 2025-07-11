driver: *.odin
	odin build . -out:$@ -debug -error-pos-style:unix
.PHONY: release 
release: *.odin
	odin build . -out:./driver -o:size
DESTDIR ?= /
.PHONY: install
install: ./driver 
	mkdir -p "$(DESTDIR)usr/bin"
	mkdir -p "$(DESTDIR)usr/lib/udev/rules.d"
	mkdir -p "${DESTDIR}etc"
	install -Dm755  driver "${DESTDIR}usr/bin/atk-a9-ultra-driver"
	install -Dm644 99-atk-a9-ultra.rules "${DESTDIR}usr/lib/udev/rules.d"
.PHONY: uninstall
uninstall:
	rm "${DESTDIR}usr/bin/atk-a9-ultra-driver" "${DESTDIR}etc/atk-a9-ultra.ini" "${DESTDIR}usr/lib/udev/rules.d/99-atk-a9-ultra.rules"

.PHONY: clean
clean:
	rm -r driver

