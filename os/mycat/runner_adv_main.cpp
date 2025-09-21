// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com

#include <iostream>
#include <cassert>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

using std::cout;
using std::cerr;
using std::endl;

extern char **environ;

int main(int argc, char* argv[]) {
    pid_t parent = getpid();
    pid_t pid = fork();

    if (pid == -1)
    {
        std::cerr << "Failed to fork()" << std::endl;
        exit(EXIT_FAILURE);
    }
    else if (pid > 0)
    {
        int status;
        // We are parent process
        // cout << "Parent: Starting signals" << endl;
        while(!waitpid(pid, &status, WNOHANG )){
            kill(pid, SIGCONT);
            kill(pid, SIGURG);
            kill(pid, SIGCHLD);
            kill(pid, SIGWINCH);
            //usleep(1);
        };
        // cout << "Parent: child stopped, exit code: " << status << endl;
        return WEXITSTATUS(status);
    }
    else
    {
        execvp(argv[1], &(argv[1]));

        cerr << "Child: Failed to execute " << argv[1] << " \n\tCode: " << errno << endl;
        exit(EXIT_FAILURE);   // exec never returns
    }
    assert(false && "Ureachable.");
}