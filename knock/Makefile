PREFIX		=	/opt/knock

all:	setuid-wrapper knock.pl

setuid-wrapper:	setuid-wrapper.c
	gcc -g -O2 $< -o $@

install:	all
	mkdir -p $(PREFIX)
	install -m 4711 -o root -g root setuid-wrapper $(PREFIX)/knock
	install -m 0755 -o root -g root knock.pl $(PREFIX)/

clean:
	rm -f *.o *~ setuid-wrapper

