PREFIX	=	/srv/www/cgi-bin/removable

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

