/*
*   Created by NumquamScire for iwsh project.
*   This binary spawns a TTY shell.
*   For compile: gcc -o pty pty.c -O3 -s -static
*   For spawning tty: ./pty /bin/bash 
*/
#include <stdio.h>
#include <stdlib.h>
#include <pty.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/select.h>

#define BUFFER_SIZE 100

void setNonBlocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <shell>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    int master, slave;
    char buffer[BUFFER_SIZE];

    // Open a new pseudo-terminal pair
    if (openpty(&master, &slave, NULL, NULL, NULL) == -1) {
        perror("openpty");
        exit(EXIT_FAILURE);
    }

    // Set master and slave to non-blocking mode
    setNonBlocking(master);
    setNonBlocking(slave);

    pid_t pid = fork();

    if (pid == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (pid == 0) {
        // Child process
        close(master);

        // Attach the slave side of the pseudo-terminal as the controlling terminal
        setsid();
        ioctl(slave, TIOCSCTTY, 0);

        // Duplicate the slave side file descriptor to standard input, output, and error
        dup2(slave, STDIN_FILENO);
        dup2(slave, STDOUT_FILENO);
        dup2(slave, STDERR_FILENO);

        // Close the original slave file descriptor
        close(slave);

        // Execute the specified shell
        execlp(argv[1], argv[1], (char *)NULL);

        // If execlp fails
        perror("execlp");
        exit(EXIT_FAILURE);
    } else {
        // Parent process
        // Close the slave side of the pseudo-terminal as we're not using it
        close(slave);

        // Now you can use 'master' to interact with the pseudo-terminal
        printf("Hello from master!\n");

        fd_set readSet;
        struct timeval timeout;

        while (1) {
            FD_ZERO(&readSet);
            FD_SET(STDIN_FILENO, &readSet);
            FD_SET(master, &readSet);

            timeout.tv_sec = 1;
            timeout.tv_usec = 0;

            int ready = select(master + 1, &readSet, NULL, NULL, &timeout);

            if (ready == -1) {
                perror("select");
                break;
            }

            if (FD_ISSET(STDIN_FILENO, &readSet)) {
                ssize_t inputBytes = read(STDIN_FILENO, buffer, BUFFER_SIZE);
                if (inputBytes <= 0) {
                    break; // Break the loop if there's no more input
                }
                write(master, buffer, inputBytes);
            }

            if (FD_ISSET(master, &readSet)) {
                ssize_t bytesRead = read(master, buffer, BUFFER_SIZE);
                if (bytesRead <= 0) {
                    break; // Break the loop if there's nothing more to read
                }
                write(STDOUT_FILENO, buffer, bytesRead);
            }
        }

        // Close the master side when done
        close(master);

        // Wait for the child process to finish (optional)
        waitpid(pid, NULL, 0);
    }

    return 0;
}


