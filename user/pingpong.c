#include "kernel/types.h"
#include "user/user.h"
#include "stddef.h"
int
main(int argc,char*argv[] )
{
    int proc_fd[2],ctop_fd[2];
    //一个是用于父进程向子进程传递信息，一个用于子进程向父进程传递信息
    pipe(proc_fd);
    pipe(ctop_fd);
    //一个字节的缓冲区
    char buf[8];
    if(fork()==0)
    {
        //子进程
        read(proc_fd[0],buf,4);
        printf("%d: received %s\n",getpid(),buf);
        write(ctop_fd[1],"pong",strlen("pong"));
    }
    else
    {
        //父进程
        write(proc_fd[1],"ping",strlen("ping"));
        wait(NULL);
        read(ctop_fd[0],buf,4);
        printf("%d: received %s\n",getpid(),buf);
    }

    exit(0);
}
