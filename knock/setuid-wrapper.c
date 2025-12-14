#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

#define PROGRAM_PATH "/opt/knock/knock.pl"
#define EXEC_DIR     "/opt/knock"

int main(int argc, char *argv[]) {
  int i = 0;
  while (i < argc) {
    if (argv[i] == NULL) {
      fprintf(stderr, "setuid-wrapper: null arg %d\n", i);
      exit(1);
    }
    i++;
  }
  if (argv[i] != NULL) {
      fprintf(stderr, "setuid-wrapper: illegal extra arg at %d\n", i);
      exit(1);
  }
  #pragma GCC diagnostic ignored "-Wunused-result"
  setreuid(geteuid(),geteuid());
  chdir(EXEC_DIR);
  execv(PROGRAM_PATH, argv);
}

