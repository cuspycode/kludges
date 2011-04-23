PREFIX		=	/srv/www/cgi-bin/removable

TARFILES	=	Makefile mount.html request.pl response.pl setuid-wrapper.c sample.htaccess

all:	setuid-wrapper .htaccess

setuid-wrapper:	setuid-wrapper.c
	gcc -g -O2 $< -o $@

.htaccess:
	test -f .htaccess || cp sample.htaccess .htaccess

install:	all
	mkdir -p $(PREFIX)
	install -m 4711 -o root -g root setuid-wrapper $(PREFIX)/
	install -m 0755 -o root -g root request.pl $(PREFIX)/
	install -m 0755 -o root -g root response.pl $(PREFIX)/
	install -m 0644 -o root -g root .htaccess $(PREFIX)/

install-web:
	install -m 0644 -o root -g root mount.html /removable/

clean:
	rm -f *.o *~ setuid-wrapper

tarball:	
	sh -c "$(MAKE) TMPID=$$$$ remotevable.tar.gz"

remotevable.tar.gz:	$(TARFILES)
	mkdir -p tmp$(TMPID).d/remotevable
	cp -a $(TARFILES) tmp$(TMPID).d/remotevable/
	(cd tmp$(TMPID).d && tar zcf ../remotevable.tar.gz remotevable)
	rm -rf tmp$(TMPID).d

