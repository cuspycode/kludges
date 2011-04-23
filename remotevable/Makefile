all:	setuid-wrapper

setuid-wrapper:	setuid-wrapper.c
	gcc -g -O2 $< -o $@
	chown root:root $@
	chmod 4711 $@

clean:
	rm -f *.o *~ setuid-wrapper

