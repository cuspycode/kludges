#define DEBUG 0

#include <stdlib.h>
#include <stdio.h>
#include <strings.h>

#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <errno.h>

char *remote_hostname = "localhost";
int remote_port = 25;
int local_port = 4711;
FILE *logfp = NULL;
u_long client_ipnumber = 0;
long bytestotal = 0;
long print_bytestotal = 0;
long print_bytestotal_inc = 100000;

int server_socket = -1;
int client_socket = -1;
int remote_socket = -1;

size_t remote_bufsize;
char remote_buf[64000];

size_t client_bufsize;
char client_buf[64000];

int client_need_auth = 0;
int server_need_auth = 0;
char auth_string[80] = { 0 };
char *authp = &auth_string[0];

#define FATAL1(f) { fprintf(stderr, (f)); exit(1); }
#define FATAL2(f,x) { fprintf(stderr, (f), (x)); exit(1); }

#if DEBUG
#define IFDEBUG(s) { s; }
#else
#define IFDEBUG(s) { ; }
#endif


void
fprint_ipnumber(FILE *f, u_long n)
{
  fprintf(f, "%ld.%ld.%ld.%ld", (n>>24)&255, (n>>16)&255, (n>>8)&255, n&255);
}


void
parse_arguments(int argc, char *argv[])
{
  if (4 <= argc && argc <= 7) {
    if (argv[1][0] == '-') {
      if (argv[1][1] == 'r') {
	client_need_auth = 1;
	argv += 1;
	argc -= 1;
      } else if (argv[1][1] == 'l') {
	server_need_auth = 1;
	argv += 1;
	argc -= 1;
      } else {
	goto usage;
      }
    }
    remote_hostname = argv[1];
    remote_port = atoi(argv[2]);
    local_port = atoi(argv[3]);

    IFDEBUG(fprintf(stdout, "remote_hostname = %s, remote_port = %d, local_port = %d\n", remote_hostname, remote_port, local_port))

    if (argc == 4) return;
    if (argv[4][0] == '-' && argv[4][1] == 'o') {
      if (argc == 5) {
	logfp = stdout;
      } else {
	logfp = fopen(argv[5], "w");
	if (logfp == NULL) FATAL2("proxy: can't open file \"%s\"\n", argv[5]);
      }
      return;
    }
  }
usage:
  FATAL2("usage: %s [-r|-l] hostname port proxyport [-o [logfile]]\n", argv[0]);
}


void
log_buffer(char *tag, char *buffer, size_t size)
{
  if (logfp != NULL) {
    fprintf(logfp, tag);
    fwrite(buffer, sizeof(char), size, logfp);
    fflush(logfp);
  }
}


int
grab_port(int port)
{
  int s;
  struct sockaddr_in sin;
  unsigned long listen_addr = INADDR_ANY;

  if (server_need_auth) {
    listen_addr = INADDR_LOOPBACK;
  }
  bzero(&sin, sizeof(sin));
  sin.sin_family = AF_INET;
  sin.sin_port = htons(port);
  sin.sin_addr.s_addr = htonl(listen_addr);

  s = socket(AF_INET, SOCK_STREAM, 0);
  if (s<0) {
    FATAL1("grab_port: socket() failed\n");
  }

  {
    unsigned int opt = 1;
    setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
  }

  if (bind(s, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
    FATAL1("grab_port: bind() failed\n");
  }

  return s;
}

static void (*sighandler)();

void handle_sigchld(int sig) {
  wait(NULL);				/* [BD] Unix brain damage */
  signal(SIGCHLD, sighandler);		/* [BD] Necessary on Linux */
}

int
await_connect(int s)
{
  struct sockaddr sa;
  int length;
  int cs;
  pid_t pid;
  static int init_done = 0;

  if (!init_done) {
#if 1
    sighandler = handle_sigchld;
#else
    sighandler = SIG_IGN;		/* [BD] This also works, it seems */
#endif
    signal(SIGCHLD, sighandler);
    if (listen(s, SOMAXCONN) < 0) {
      FATAL1("await_connect: listen() failed\n");
    }
    init_done = 1;
  }

  for (;;) {
    bzero(&sa, sizeof(sa));
    length = sizeof(sa);
    cs = accept(s, &sa, &length);

    if (cs<0) {
      if (errno == EINTR) {		/* [BD] Needed for SunOS & Solaris */
	continue;
      } else {
	FATAL2("await_connect: accept() failed. errno=%d\n", errno);
      }
    }

    fcntl(cs, F_SETFL, 0);
    fflush(stdout);
    fflush(stderr);

    pid = fork();

    if (pid != 0) {
      /* parent */
      if (pid<0) {
	FATAL1("await_connect: fork() failed\n");
      }
      close(cs);
    } else {
      /* child */
      close(s);

      client_ipnumber = 0;

      if (sa.sa_family == AF_INET) {
	struct sockaddr_in *sin = (struct sockaddr_in *)&sa;
	client_ipnumber = ntohl(sin->sin_addr.s_addr);
      }

      return cs;
    }
  }
}

int
connect_remote_socket(char *remote, int port)
{

  /*
   * [BD] Most of the following is snarfed from the NNTP client library
   * (the NNTP "reference implementation"). Some code has been deleted
   * and some details have been changed.
   */

  int s;
  struct sockaddr_in sin;
  struct hostent *hp;
  /*  struct hostent *gethostbyname(); */
#ifdef h_addr
  int x = 0;
  char **cp;
  static char *alist[1];
#endif
  unsigned long inet_addr();
  static struct hostent def;
  static struct in_addr defaddr;
  static char namebuf[256];

  /* If not a raw ip address, try nameserver */
  if (!isdigit(*remote) ||
      (long)(defaddr.s_addr = inet_addr(remote)) == -1)
    hp = gethostbyname(remote);
  else {
    /* Raw ip address, fake  */
    (void) strcpy(namebuf, remote);
    def.h_name = namebuf;
#ifdef h_addr
    def.h_addr_list = alist;
#endif
    def.h_addr = (char *)&defaddr;
    def.h_length = sizeof(struct in_addr);
    def.h_addrtype = AF_INET;
    def.h_aliases = 0;
    hp = &def;
  }
  if (hp == NULL) {
    FATAL2("%s: Unknown host.\n", remote);
  }
  bzero((char *) &sin, sizeof(sin));
  sin.sin_family = hp->h_addrtype;
  sin.sin_port = htons(port);

  /*
   * [BD] The comment below is from the original author.
   */

  /*
   * The following is kinda gross.  The name server under 4.3
   * returns a list of addresses, each of which should be tried
   * in turn if the previous one fails.  However, 4.2 hostent
   * structure doesn't have this list of addresses.
   * Under 4.3, h_addr is a #define to h_addr_list[0].
   * We use this to figure out whether to include the NS specific
   * code...
   */

#ifdef h_addr

  /* get a socket and initiate connection -- use multiple addresses */

  for (cp = hp->h_addr_list; cp && *cp; cp++) {
    s = socket(hp->h_addrtype, SOCK_STREAM, 0);
    if (s<0) {
      FATAL1("connect_remote_socket: socket() failed\n");
    }
    bcopy(*cp, (char *)&sin.sin_addr, hp->h_length);
    
    if (x<0) {
      fprintf(stderr, "trying %s\n", inet_ntoa(sin.sin_addr));
    }
    x = connect(s, (struct sockaddr *)&sin, sizeof (sin));
    if (x==0) {
      break;
    }
    FATAL2("connect() to %s failed\n", inet_ntoa(sin.sin_addr));
  }
  if (x<0) {
    FATAL1("giving up...\n");
  }
#else
  if ((s = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    FATAL1("connect_remote_socket: socket() failed\n");
  }

  /* And then connect */

  bcopy(hp->h_addr, (char *) &sin.sin_addr, hp->h_length);
  if (connect(s, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
    FATAL1("connect() failed\n");
  }
#endif
  return s;
}


void
read_write_loop()
{
  int n, nmax;
  long timeout = 100000000L;
  fd_set fds;
  struct timeval tv;
  int client_auth = client_need_auth;

#define MAX(x,y) ((x)>(y)?(x):(y))

  nmax = 1+MAX(remote_socket, client_socket);

  if (server_need_auth) {
    send(remote_socket, auth_string, strlen(auth_string), 0);
  }

  authp = &auth_string[0];

  for (;;) {
    FD_ZERO(&fds);
    FD_SET(remote_socket, &fds);
    FD_SET(client_socket, &fds);

    tv.tv_sec = timeout;
    tv.tv_usec = 0;

    n = select(nmax, &fds, NULL, NULL, &tv);

    if (n<0) {
      FATAL2("read_write_loop: select returned %d\n", n);
    } else if (n==0) {
      fprintf(stderr, "read_write_loop: timeout after %ld s.\n", timeout);
    } else {

      if (FD_ISSET(remote_socket, &fds)) {
	remote_bufsize = sizeof(remote_buf);
	remote_bufsize = recv(remote_socket, remote_buf, remote_bufsize, 0);
	if (remote_bufsize > 0) {
	  bytestotal += remote_bufsize;
	  send(client_socket, remote_buf, remote_bufsize, 0);
	  log_buffer("\n**SERVER**\n", remote_buf, remote_bufsize);
	} else {
	  printf("Server terminated.\n");
	  break;
	}

      }

      if (FD_ISSET(client_socket, &fds)) {
	client_bufsize = sizeof(client_buf);
	client_bufsize = recv(client_socket, client_buf, client_bufsize, 0);
	if (client_bufsize > 0) {
	  int i = 0;
	  if (client_auth) {
	    while (*authp != 0 && i < client_bufsize) {
	      if (*authp != client_buf[i]) {
		char *msg = "Authorization failed\r\n";
		send(client_socket, msg, strlen(msg), 0);
		FATAL1("Authorization failed\n");
	      }
	      authp += 1;
	      i += 1;
	    }
	    if (*authp == 0) {
	      client_auth = 0;
	      client_bufsize -= i;
	      if (client_bufsize > 0) {
		bytestotal += client_bufsize;
		send(remote_socket, client_buf + i, client_bufsize, 0);
		log_buffer("\n**CLIENT**\n", client_buf + i, client_bufsize);
	      }
	    }
	    continue;
	  }
	  bytestotal += client_bufsize;
	  send(remote_socket, client_buf, client_bufsize, 0);
	  log_buffer("\n**CLIENT**\n", client_buf, client_bufsize);
	} else {
	  printf("Client terminated.\n");
	  break;
	}
      }

    }

    if (bytestotal > print_bytestotal) {
      if (logfp != stdout)
	printf("%ld kilobytes\n", print_bytestotal/1000);
      print_bytestotal += print_bytestotal_inc;
    }
  }
}


int
main(int argc, char *argv[])
{
  parse_arguments(argc, argv);

  if (client_need_auth || server_need_auth) {
    printf("Choose authorization phrase: "); fflush(stdout);
    fgets(auth_string, sizeof(auth_string), stdin);
  }

  server_socket = grab_port(local_port);

  {
    struct sockaddr_in sin;
    int namelen = sizeof(struct sockaddr_in);
    if (getsockname(server_socket, (struct sockaddr *)&sin, &namelen) == 0) {
      printf("Grabbed port %d\n", ntohs(sin.sin_port));
    } else {
      FATAL1("getsockname() failed\n");
    }
  }

  /* printf("Grabbed port %d\n", local_port); */

  fflush(stdout);

  client_socket = await_connect(server_socket);

  printf("Connection from "); fprint_ipnumber(stdout, client_ipnumber);
  printf(" accepted\n");

  authp = &auth_string[0];

  remote_socket = connect_remote_socket(remote_hostname, remote_port);

  printf("Connection to %s established\n", remote_hostname);

  IFDEBUG(printf("remote_socket = %d\n", remote_socket));

  bytestotal = 0;
  print_bytestotal = print_bytestotal_inc;

  read_write_loop();

  printf("End of session.\n");

  close(remote_socket);
  close(client_socket);
}
