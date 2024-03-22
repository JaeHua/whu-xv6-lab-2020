#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

char*
fmtname(char *path)
{
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
    ;
  p++;

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), 0, DIRSIZ-strlen(p));//改为0结束标志
  return buf;
}
int
norecurse(char *path)
{
    char *buf = fmtname(path);
    if(buf[0] =='.' && buf[1] == 0)
    {
        return 1;
    }
    if(buf[0] == '.' && buf[1] =='.' && buf[2] == 0)
    {
        return 1;
    }
    return 0;
}
void
find(char *path,char *target)
{
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  if((fd = open(path, 0)) < 0){
    fprintf(2, "find: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
    fprintf(2, "find: cannot stat %s\n", path);
    close(fd);
    return;
  }
      if(strcmp(fmtname(path),target) == 0)//判断格式化后是否相等
      {
        printf("%s\n",path);
      }
  switch(st.type){
  case T_DEVICE:
  case T_FILE:

    break;

  case T_DIR:
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
      printf("find: path too long\n");
      break;
    }
    strcpy(buf, path);
    p = buf+strlen(buf);
    *p++ = '/';
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
      if(de.inum == 0)
        continue;
      memmove(p, de.name, DIRSIZ);
      p[DIRSIZ] = 0;
      if(stat(buf, &st) < 0){
        printf("find: cannot stat %s\n", buf);
        continue;
      }
        // printf("%s",target);
      if(!norecurse(buf))
      {
        find(buf,target);
      }
    }
    break;
  }
  close(fd);
}

int
main(int argc, char *argv[])
{
  if(argc == 2){
    find(".",argv[1]);
    exit(0);
  }else
    if(argc == 3)
  {
    find(argv[1],argv[2]);
    exit(0);
  }
  else
  {
        printf("usage: find [path] [target]\n");
        exit(0);
  }
}




// #include "kernel/types.h"
// #include "kernel/stat.h"
// #include "user/user.h"
// #include "kernel/fs.h"

// void
// find(char *path, char *target)
// {
//     char buf[512],*p;
//     int fd;//存储文件描述符
//     struct dirent de; //fs.h
//     struct stat st; //存储打开的i-node信息

//     if((fd = open(path,0))<0)
//     {
//         fprintf(2,"find: cannot open %s\n",path);
//         return;
//     }
//     if(fstat(fd, &st) < 0)
//     {
//         fprintf(2, "find: cannot stat %s\n", path);
//         close(fd);
//         return;
//     }

//     if(st.type != T_DIR)
//     {
//         //类型不是目录错误
//         fprintf(2,"find: %s is not a directory\n",path);
//         close(fd);
//         return;
//     }
//     //路径过长放不进缓冲区
//     if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
//        fprintf(2,"find: directory is too long\n");
//        close(fd);
//        return;
//     }

//     //将path路径复制到buf
//     strcpy(buf,path);
//     p = buf+strlen(buf);
//     *p++ = '/';

//      while(read(fd, &de, sizeof(de)) == sizeof(de)){
//       if(de.inum == 0)
//         continue;
//     printf("read de = %s\n",de.name);

//     // 不要递归 "." 和 "..."
//     if(!strcmp(de.name,".") || !strcmp(de.name,".."))
//         continue;
//     // memmove，把 de.name 信息复制 p，其中 de.name 代表文件名
//       memmove(p, de.name, DIRSIZ);
//       p[DIRSIZ] = 0;
//       if(stat(buf, &st) < 0){
//         fprintf(2,"find: cannot stat %s\n",buf);
//         continue;
//       }
//     // 如果是目录类型，递归查找
//     if(st.type == T_DIR)
//     {
//         find(buf,target);
//     }
//     else if(st.type == T_FILE  && !strcmp(de.name,target))
//     {
//         printf("%s\n",buf);
//     }
//      }
// }
// int
// main(int argc,char *argv[])
// {
//     if(argc < 3)
//     {
//         printf("error please input : find <path> <target>\n");
//         exit(1);
//     }
//     find(argv[1],argv[2]);
//     exit(0);
// }
