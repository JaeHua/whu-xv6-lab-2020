## Lab 1

环境：
Ubuntu22.04
实验前准备
● 拉取仓库
git clone git://g.csail.mit.edu/xv6-labs-2020
● 切换分支
for example
git checkout util
● 编译运行xv6
make qemu

### sleep
/home/xv6/xv6/user/sleep.c
_Makefile文件line 135加上:
    $U/_sleep\_

![image](https://github.com/JaeHua/whu-xv6-lab-2020/assets/126366914/5d07ccd5-252a-4eff-a770-f70172c4d198)

### pingpong
/home/xv6/xv6/user/pingpong.c
![image](https://github.com/JaeHua/whu-xv6-lab-2020/assets/126366914/7fe71dab-b1f3-45f9-987f-de20b95a62d8)

### prime
**实验思路：
在进入每个管道之前，依次剔除2的倍数，3的倍数，4的倍数以此类推**
![image](https://github.com/JaeHua/whu-xv6-lab-2020/assets/126366914/c2e3c746-dfee-41b1-8502-fe63f1c92af5)

### find
实验思路:参照ls.c进行修改
● 记得补全'/'
● . 和 .. 不能递归
![image](https://github.com/JaeHua/whu-xv6-lab-2020/assets/126366914/ab5ddd56-d911-4faa-9066-ddc281c5571c)

加了printf("read de = %s\n",de.name);用来理解

### xargs

**step1 get standard input**
![image](https://github.com/JaeHua/whu-xv6-lab-2020/assets/126366914/82aa08ec-c7ea-4b47-809c-91412c76a2ef)

**step2. get command-line parameter**
```
    for (int i = 1; i < argc; i++)
    {
        xargvs[xarg] = argv[i];
        printf("xargvs[%d] = %s\n",xarg,xargvs[xarg]);
        xarg++;
    }
```

**step3 exec && fork**
● 记得sleep确保管道|前全部输出完成

![image](https://github.com/JaeHua/whu-xv6-lab-2020/assets/126366914/3820e729-f6b9-413b-8aab-031f2cc44685)


