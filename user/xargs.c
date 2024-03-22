#include "kernel/types.h"
#include "user/user.h"
#include "kernel/param.h"
int
main(int argc,char *argv[])
{
    sleep(10);//睡眠保证管道符前输出完全进行
    //echo hello1 hello2 | xargs echo hi
    /*
    mkdir a
    echo hello > a/b
    mkdir c
    echo hello > c/b
    echo hello > b
    find . b | xargs grep hello //grep会看这个文件里面有没有hello
    */
    //step1. get standard input
    char buf[MAXARG];
    read(0,buf,MAXARG);
    // printf("获得到的标准输入是: %s\n",buf);


    //step2. get command-line parameter
    char *xargvs[MAXARG];
    int xarg = 0;
    for (int i = 1; i < argc; i++)
    {
        xargvs[xarg] = argv[i];
        // printf("xargvs[%d] = %s\n",xarg,xargvs[xarg]);
        xarg++;
    }
    char *p = buf;
    for(int i = 0; i < MAXARG; i++)
    {

        //默认buf后面有一个隐式的 '\n
        if(buf[i] == '\n')//fork
        {
            // printf("buf[%d] = enter\n",i);
            int pid = fork();
            if(pid > 0)
            {
                p = &buf[i+1];
                wait(0);
            }
            else
            {
                buf[i] = 0; //进行隔断
                xargvs[xarg] = p;
                xarg++;
                // printf("xargvs[%d] = %s\n",xarg-1,xargvs[xarg-1]);
                xargvs[xarg] = 0;
                xarg++;
                exec(xargvs[0],xargvs);
                exit(0);
            }
        }
    }
    wait(0);
    exit(0);
}
