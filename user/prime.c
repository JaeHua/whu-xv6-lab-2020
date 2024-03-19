#include "kernel/types.h" // 包含定义系统类型的头文件
#include "user/user.h"    // 包含系统调用和库函数的头文件
#include "stddef.h"
void
prime(int fd)
{
    int base_num;
    if(read(fd,&base_num,sizeof(int)) == 0)
    {
        exit(0);
    }
    printf("Prime : %d\n",base_num);
    int p[2];
    pipe(p);//创建新管道
    if(fork())
    {
        //父进程
        close(p[0]);//关闭读端
        int num;//读到的整数
        int _fd;//读取到的字节大小
        do
        {
            _fd = read(fd,&num,sizeof(int));
            if(num % base_num != 0)
            {
                write(p[1],&num,sizeof(int));
            }
        }while(_fd);
        close(p[1]);//关闭写端
    }
    else
    {
        //子进程
        close(p[1]);//关闭写端
        prime(p[0]);
    }
    wait(NULL);
    exit(0);
}
int
main(){
    int par_fd[2];              //存储父进程管道的文件描述符
    pipe(par_fd);               //创建一个管道
    if(fork())
    {
        //父进程
        close(par_fd[0]);//关闭管道的读端
        for(int i = 2; i < 36;i++)
        {
            write(par_fd[1],&i,sizeof(int));//写入管道
        }
        close(par_fd[1]);//关闭管道写端
    }
    else
    {
        //子进程
        close(par_fd[1]);//关闭写端
        prime(par_fd[0]);//读文件描述符
    }
    wait(NULL);//等待子进程结束
    exit(0);
}
