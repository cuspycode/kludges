#include <unistd.h>
#include <stdio.h>
/* #define PROGRAM_PATH "/usr/local/bin/macaddress.pl"
*/
#define PROGRAM_PATH "/home/bd/macaddress.pl"

main(int argc, char *argv[]) {
    argv[1] = 0;
    execvp(PROGRAM_PATH, argv);
    fprintf(stderr, "%s: exec failed.\n", argv[0]);
    exit(1);
}
