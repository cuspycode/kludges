/* buffer.c by Bjorn Danielsson. Buffers input from stdin to stdout */
/* $Id$ */
#include <sys/types.h>
#include <sys/time.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <stdio.h>

#define DEFAULT_NBUFS 64
#define BUFSIZE 65536

struct iobuf {
  struct iobuf *next;
  size_t fill;
  char data[BUFSIZE];
};

struct iobuf *rbuf, *wbuf;

void initbuf(unsigned long count) {
  struct iobuf *buf, *firstbuf, *prevbuf;
  firstbuf = NULL;
  prevbuf = NULL;
  while (count > 0) {
    buf = (struct iobuf *) malloc(sizeof(struct iobuf));
    if (buf == NULL) {
      fprintf(stderr, "buffer: malloc failed\n");
      exit(1);
    }
    if (firstbuf == NULL) firstbuf = buf;
    buf->next = prevbuf;
    buf->fill = 0;
    count--;
    prevbuf = buf;
  }
  firstbuf->next = buf;
  rbuf = firstbuf;
  wbuf = firstbuf;
}

 int main(int argc, char *argv[]) {
   char *rbufptr, *wbufptr;
   size_t rbuffree, wbufremain, totread, totwrite, diff, maxdiff;
   fd_set rfds, wfds;
   int read_eof = 0;
   if (argc > 1) {
     initbuf(16L*atoi(argv[1]));	/* argv[1] is number of Mbytes */
   } else {
     initbuf(DEFAULT_NBUFS);
   }
   rbufptr = &rbuf->data[0];
   rbuffree = BUFSIZE;
   wbufptr = &wbuf->data[0];
   wbufremain = 0;
   totread = 0;
   totwrite = 0;
   diff = 0;
   maxdiff = 0;
   fcntl(0, F_SETFL, O_NONBLOCK);
   fcntl(1, F_SETFL, O_NONBLOCK);
   FD_ZERO(&rfds);
   FD_ZERO(&wfds);
   for (;;) {
     FD_SET(0, &rfds);
     if (select(2, &rfds, &wfds, NULL, NULL) > 0) {
       if (FD_ISSET(0, &rfds)) {
	 ssize_t n = read(0, rbufptr, rbuffree);
	 if (n >= 0) {
	   totread += n;
	   diff = totread - totwrite;
	   if (diff > maxdiff) {
	     maxdiff = diff;
	   }
	   FD_SET(1, &wfds);
	   rbufptr += n;
	   rbuffree -= n;
	   rbuf->fill += n;
	   if (wbuf == rbuf) {
	     wbufremain += n;
	   }
	   if (rbuffree == 0) {
	     rbuf = rbuf->next;
	     if (rbuf == wbuf) {
	       fprintf(stderr, "buffer: overflow\n");
	       exit(1);			/* read overflow */
	     }
	     rbufptr = &rbuf->data[0];
	     rbuffree = BUFSIZE;
	     rbuf->fill = 0;
	   }
	   if (n == 0) {
	     read_eof = 1;
	     FD_CLR(0, &rfds);
	   }
	 } else if (errno != EAGAIN) {
	   fprintf(stderr, "buffer: read error\n");
	   exit(1);
	 }
       }
       if (FD_ISSET(1, &wfds)) {
	 ssize_t n = 0;
	 if (wbufremain > 0) {
	   n = write(1, wbufptr, wbufremain);
	 }
	 if (n >= 0) {
	   totwrite += n;
	   wbufptr += n;
	   wbufremain -= n;
	   if (wbufremain == 0) {
	     if (wbufptr - &wbuf->data[0] == BUFSIZE) {
	       wbuf = wbuf->next;
	       wbufptr = &wbuf->data[0];
	       wbufremain = wbuf->fill;
	     } else if (read_eof) {
	       break;
	     } else {
	       FD_CLR(1, &wfds);
	     }
	   }
	 } else if (errno != EAGAIN) {
	   fprintf(stderr, "buffer: write error (%d)\n", errno);
	   exit(1);
	 }
       }
     }
   }
   fprintf(stderr, "[buffer] max diff %ld bytes.\n", maxdiff);
   if (totwrite != totread) {
     fprintf(stderr, "buffer: %ld written != %ld read\n", totwrite, totread);
     exit(1);
  }
}

