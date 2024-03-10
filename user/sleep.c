#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
/*睡眠程序
*接受两个参数例如 sleep T
*shell经过T时间才会有反应
*/
int
main(int argc,char *argv[] )
{
    // 系统调用 write(int fd, char *buf, int n) 函数输出错误信息
    // 参数 fd 是文件描述符，0 表示标准输入，1 表示标准输出，2 表示标准错误
    if(argc != 2)
    {
        //错误输出
        write(2,"Usage: sleep time\n",strlen("Usage: sleep time\n"));
        //退出程序
        exit(1);
    }
    int time = atoi(argv[1]);
    sleep(time);
    //正常退出程序
    exit(0);
}
