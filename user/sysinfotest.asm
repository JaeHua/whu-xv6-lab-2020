
user/_sysinfotest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <sinfo>:
#include "kernel/sysinfo.h"
#include "user/user.h"


void
sinfo(struct sysinfo *info) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  if (sysinfo(info) < 0) {
   8:	00000097          	auipc	ra,0x0
   c:	668080e7          	jalr	1640(ra) # 670 <sysinfo>
  10:	00054663          	bltz	a0,1c <sinfo+0x1c>
    printf("FAIL: sysinfo failed");
    exit(1);
  }
}
  14:	60a2                	ld	ra,8(sp)
  16:	6402                	ld	s0,0(sp)
  18:	0141                	addi	sp,sp,16
  1a:	8082                	ret
    printf("FAIL: sysinfo failed");
  1c:	00001517          	auipc	a0,0x1
  20:	af450513          	addi	a0,a0,-1292 # b10 <malloc+0x102>
  24:	00001097          	auipc	ra,0x1
  28:	92c080e7          	jalr	-1748(ra) # 950 <printf>
    exit(1);
  2c:	4505                	li	a0,1
  2e:	00000097          	auipc	ra,0x0
  32:	59a080e7          	jalr	1434(ra) # 5c8 <exit>

0000000000000036 <countfree>:
//
// use sbrk() to count how many free physical memory pages there are.
//
int
countfree()
{
  36:	7139                	addi	sp,sp,-64
  38:	fc06                	sd	ra,56(sp)
  3a:	f822                	sd	s0,48(sp)
  3c:	f426                	sd	s1,40(sp)
  3e:	f04a                	sd	s2,32(sp)
  40:	ec4e                	sd	s3,24(sp)
  42:	e852                	sd	s4,16(sp)
  44:	0080                	addi	s0,sp,64
  uint64 sz0 = (uint64)sbrk(0);
  46:	4501                	li	a0,0
  48:	00000097          	auipc	ra,0x0
  4c:	608080e7          	jalr	1544(ra) # 650 <sbrk>
  50:	8a2a                	mv	s4,a0
  struct sysinfo info;
  int n = 0;
  52:	4481                	li	s1,0

  while(1){
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  54:	597d                	li	s2,-1
      break;
    }
    n += PGSIZE;
  56:	6985                	lui	s3,0x1
  58:	a019                	j	5e <countfree+0x28>
  5a:	009984bb          	addw	s1,s3,s1
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  5e:	6505                	lui	a0,0x1
  60:	00000097          	auipc	ra,0x0
  64:	5f0080e7          	jalr	1520(ra) # 650 <sbrk>
  68:	ff2519e3          	bne	a0,s2,5a <countfree+0x24>
  }
  sinfo(&info);
  6c:	fc040513          	addi	a0,s0,-64
  70:	00000097          	auipc	ra,0x0
  74:	f90080e7          	jalr	-112(ra) # 0 <sinfo>
  if (info.freemem != 0) {
  78:	fc043583          	ld	a1,-64(s0)
  7c:	e58d                	bnez	a1,a6 <countfree+0x70>
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
      info.freemem);
    exit(1);
  }
  sbrk(-((uint64)sbrk(0) - sz0));
  7e:	4501                	li	a0,0
  80:	00000097          	auipc	ra,0x0
  84:	5d0080e7          	jalr	1488(ra) # 650 <sbrk>
  88:	40aa053b          	subw	a0,s4,a0
  8c:	00000097          	auipc	ra,0x0
  90:	5c4080e7          	jalr	1476(ra) # 650 <sbrk>
  return n;
}
  94:	8526                	mv	a0,s1
  96:	70e2                	ld	ra,56(sp)
  98:	7442                	ld	s0,48(sp)
  9a:	74a2                	ld	s1,40(sp)
  9c:	7902                	ld	s2,32(sp)
  9e:	69e2                	ld	s3,24(sp)
  a0:	6a42                	ld	s4,16(sp)
  a2:	6121                	addi	sp,sp,64
  a4:	8082                	ret
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
  a6:	00001517          	auipc	a0,0x1
  aa:	a8250513          	addi	a0,a0,-1406 # b28 <malloc+0x11a>
  ae:	00001097          	auipc	ra,0x1
  b2:	8a2080e7          	jalr	-1886(ra) # 950 <printf>
    exit(1);
  b6:	4505                	li	a0,1
  b8:	00000097          	auipc	ra,0x0
  bc:	510080e7          	jalr	1296(ra) # 5c8 <exit>

00000000000000c0 <testmem>:

void
testmem() {
  c0:	7179                	addi	sp,sp,-48
  c2:	f406                	sd	ra,40(sp)
  c4:	f022                	sd	s0,32(sp)
  c6:	ec26                	sd	s1,24(sp)
  c8:	e84a                	sd	s2,16(sp)
  ca:	1800                	addi	s0,sp,48
  struct sysinfo info;
  uint64 n = countfree();
  cc:	00000097          	auipc	ra,0x0
  d0:	f6a080e7          	jalr	-150(ra) # 36 <countfree>
  d4:	84aa                	mv	s1,a0
  
  sinfo(&info);
  d6:	fd040513          	addi	a0,s0,-48
  da:	00000097          	auipc	ra,0x0
  de:	f26080e7          	jalr	-218(ra) # 0 <sinfo>

  if (info.freemem!= n) {
  e2:	fd043583          	ld	a1,-48(s0)
  e6:	04959e63          	bne	a1,s1,142 <testmem+0x82>
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
    exit(1);
  }
  
  if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  ea:	6505                	lui	a0,0x1
  ec:	00000097          	auipc	ra,0x0
  f0:	564080e7          	jalr	1380(ra) # 650 <sbrk>
  f4:	57fd                	li	a5,-1
  f6:	06f50463          	beq	a0,a5,15e <testmem+0x9e>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
  fa:	fd040513          	addi	a0,s0,-48
  fe:	00000097          	auipc	ra,0x0
 102:	f02080e7          	jalr	-254(ra) # 0 <sinfo>
    
  if (info.freemem != n-PGSIZE) {
 106:	fd043603          	ld	a2,-48(s0)
 10a:	75fd                	lui	a1,0xfffff
 10c:	95a6                	add	a1,a1,s1
 10e:	06b61563          	bne	a2,a1,178 <testmem+0xb8>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
    exit(1);
  }
  
  if((uint64)sbrk(-PGSIZE) == 0xffffffffffffffff){
 112:	757d                	lui	a0,0xfffff
 114:	00000097          	auipc	ra,0x0
 118:	53c080e7          	jalr	1340(ra) # 650 <sbrk>
 11c:	57fd                	li	a5,-1
 11e:	06f50a63          	beq	a0,a5,192 <testmem+0xd2>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
 122:	fd040513          	addi	a0,s0,-48
 126:	00000097          	auipc	ra,0x0
 12a:	eda080e7          	jalr	-294(ra) # 0 <sinfo>
    
  if (info.freemem != n) {
 12e:	fd043603          	ld	a2,-48(s0)
 132:	06961d63          	bne	a2,s1,1ac <testmem+0xec>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
    exit(1);
  }
}
 136:	70a2                	ld	ra,40(sp)
 138:	7402                	ld	s0,32(sp)
 13a:	64e2                	ld	s1,24(sp)
 13c:	6942                	ld	s2,16(sp)
 13e:	6145                	addi	sp,sp,48
 140:	8082                	ret
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
 142:	8626                	mv	a2,s1
 144:	00001517          	auipc	a0,0x1
 148:	a1c50513          	addi	a0,a0,-1508 # b60 <malloc+0x152>
 14c:	00001097          	auipc	ra,0x1
 150:	804080e7          	jalr	-2044(ra) # 950 <printf>
    exit(1);
 154:	4505                	li	a0,1
 156:	00000097          	auipc	ra,0x0
 15a:	472080e7          	jalr	1138(ra) # 5c8 <exit>
    printf("sbrk failed");
 15e:	00001517          	auipc	a0,0x1
 162:	a3250513          	addi	a0,a0,-1486 # b90 <malloc+0x182>
 166:	00000097          	auipc	ra,0x0
 16a:	7ea080e7          	jalr	2026(ra) # 950 <printf>
    exit(1);
 16e:	4505                	li	a0,1
 170:	00000097          	auipc	ra,0x0
 174:	458080e7          	jalr	1112(ra) # 5c8 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
 178:	00001517          	auipc	a0,0x1
 17c:	9e850513          	addi	a0,a0,-1560 # b60 <malloc+0x152>
 180:	00000097          	auipc	ra,0x0
 184:	7d0080e7          	jalr	2000(ra) # 950 <printf>
    exit(1);
 188:	4505                	li	a0,1
 18a:	00000097          	auipc	ra,0x0
 18e:	43e080e7          	jalr	1086(ra) # 5c8 <exit>
    printf("sbrk failed");
 192:	00001517          	auipc	a0,0x1
 196:	9fe50513          	addi	a0,a0,-1538 # b90 <malloc+0x182>
 19a:	00000097          	auipc	ra,0x0
 19e:	7b6080e7          	jalr	1974(ra) # 950 <printf>
    exit(1);
 1a2:	4505                	li	a0,1
 1a4:	00000097          	auipc	ra,0x0
 1a8:	424080e7          	jalr	1060(ra) # 5c8 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
 1ac:	85a6                	mv	a1,s1
 1ae:	00001517          	auipc	a0,0x1
 1b2:	9b250513          	addi	a0,a0,-1614 # b60 <malloc+0x152>
 1b6:	00000097          	auipc	ra,0x0
 1ba:	79a080e7          	jalr	1946(ra) # 950 <printf>
    exit(1);
 1be:	4505                	li	a0,1
 1c0:	00000097          	auipc	ra,0x0
 1c4:	408080e7          	jalr	1032(ra) # 5c8 <exit>

00000000000001c8 <testcall>:

void
testcall() {
 1c8:	1101                	addi	sp,sp,-32
 1ca:	ec06                	sd	ra,24(sp)
 1cc:	e822                	sd	s0,16(sp)
 1ce:	1000                	addi	s0,sp,32
  struct sysinfo info;
  
  if (sysinfo(&info) < 0) {
 1d0:	fe040513          	addi	a0,s0,-32
 1d4:	00000097          	auipc	ra,0x0
 1d8:	49c080e7          	jalr	1180(ra) # 670 <sysinfo>
 1dc:	02054163          	bltz	a0,1fe <testcall+0x36>
    printf("FAIL: sysinfo failed\n");
    exit(1);
  }

  if (sysinfo((struct sysinfo *) 0xeaeb0b5b00002f5e) !=  0xffffffffffffffff) {
 1e0:	00001517          	auipc	a0,0x1
 1e4:	92053503          	ld	a0,-1760(a0) # b00 <malloc+0xf2>
 1e8:	00000097          	auipc	ra,0x0
 1ec:	488080e7          	jalr	1160(ra) # 670 <sysinfo>
 1f0:	57fd                	li	a5,-1
 1f2:	02f51363          	bne	a0,a5,218 <testcall+0x50>
    printf("FAIL: sysinfo succeeded with bad argument\n");
    exit(1);
  }
}
 1f6:	60e2                	ld	ra,24(sp)
 1f8:	6442                	ld	s0,16(sp)
 1fa:	6105                	addi	sp,sp,32
 1fc:	8082                	ret
    printf("FAIL: sysinfo failed\n");
 1fe:	00001517          	auipc	a0,0x1
 202:	9a250513          	addi	a0,a0,-1630 # ba0 <malloc+0x192>
 206:	00000097          	auipc	ra,0x0
 20a:	74a080e7          	jalr	1866(ra) # 950 <printf>
    exit(1);
 20e:	4505                	li	a0,1
 210:	00000097          	auipc	ra,0x0
 214:	3b8080e7          	jalr	952(ra) # 5c8 <exit>
    printf("FAIL: sysinfo succeeded with bad argument\n");
 218:	00001517          	auipc	a0,0x1
 21c:	9a050513          	addi	a0,a0,-1632 # bb8 <malloc+0x1aa>
 220:	00000097          	auipc	ra,0x0
 224:	730080e7          	jalr	1840(ra) # 950 <printf>
    exit(1);
 228:	4505                	li	a0,1
 22a:	00000097          	auipc	ra,0x0
 22e:	39e080e7          	jalr	926(ra) # 5c8 <exit>

0000000000000232 <testproc>:

void testproc() {
 232:	7139                	addi	sp,sp,-64
 234:	fc06                	sd	ra,56(sp)
 236:	f822                	sd	s0,48(sp)
 238:	f426                	sd	s1,40(sp)
 23a:	0080                	addi	s0,sp,64
  struct sysinfo info;
  uint64 nproc;
  int status;
  int pid;
  
  sinfo(&info);
 23c:	fd040513          	addi	a0,s0,-48
 240:	00000097          	auipc	ra,0x0
 244:	dc0080e7          	jalr	-576(ra) # 0 <sinfo>
  nproc = info.nproc;
 248:	fd843483          	ld	s1,-40(s0)

  pid = fork();
 24c:	00000097          	auipc	ra,0x0
 250:	374080e7          	jalr	884(ra) # 5c0 <fork>
  if(pid < 0){
 254:	02054c63          	bltz	a0,28c <testproc+0x5a>
    printf("sysinfotest: fork failed\n");
    exit(1);
  }
  if(pid == 0){
 258:	ed21                	bnez	a0,2b0 <testproc+0x7e>
    sinfo(&info);
 25a:	fd040513          	addi	a0,s0,-48
 25e:	00000097          	auipc	ra,0x0
 262:	da2080e7          	jalr	-606(ra) # 0 <sinfo>
    if(info.nproc != nproc+1) {
 266:	fd843583          	ld	a1,-40(s0)
 26a:	00148613          	addi	a2,s1,1
 26e:	02c58c63          	beq	a1,a2,2a6 <testproc+0x74>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc+1);
 272:	00001517          	auipc	a0,0x1
 276:	99650513          	addi	a0,a0,-1642 # c08 <malloc+0x1fa>
 27a:	00000097          	auipc	ra,0x0
 27e:	6d6080e7          	jalr	1750(ra) # 950 <printf>
      exit(1);
 282:	4505                	li	a0,1
 284:	00000097          	auipc	ra,0x0
 288:	344080e7          	jalr	836(ra) # 5c8 <exit>
    printf("sysinfotest: fork failed\n");
 28c:	00001517          	auipc	a0,0x1
 290:	95c50513          	addi	a0,a0,-1700 # be8 <malloc+0x1da>
 294:	00000097          	auipc	ra,0x0
 298:	6bc080e7          	jalr	1724(ra) # 950 <printf>
    exit(1);
 29c:	4505                	li	a0,1
 29e:	00000097          	auipc	ra,0x0
 2a2:	32a080e7          	jalr	810(ra) # 5c8 <exit>
    }
    exit(0);
 2a6:	4501                	li	a0,0
 2a8:	00000097          	auipc	ra,0x0
 2ac:	320080e7          	jalr	800(ra) # 5c8 <exit>
  }
  wait(&status);
 2b0:	fcc40513          	addi	a0,s0,-52
 2b4:	00000097          	auipc	ra,0x0
 2b8:	31c080e7          	jalr	796(ra) # 5d0 <wait>
  sinfo(&info);
 2bc:	fd040513          	addi	a0,s0,-48
 2c0:	00000097          	auipc	ra,0x0
 2c4:	d40080e7          	jalr	-704(ra) # 0 <sinfo>
  if(info.nproc != nproc) {
 2c8:	fd843583          	ld	a1,-40(s0)
 2cc:	00959763          	bne	a1,s1,2da <testproc+0xa8>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
      exit(1);
  }
}
 2d0:	70e2                	ld	ra,56(sp)
 2d2:	7442                	ld	s0,48(sp)
 2d4:	74a2                	ld	s1,40(sp)
 2d6:	6121                	addi	sp,sp,64
 2d8:	8082                	ret
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
 2da:	8626                	mv	a2,s1
 2dc:	00001517          	auipc	a0,0x1
 2e0:	92c50513          	addi	a0,a0,-1748 # c08 <malloc+0x1fa>
 2e4:	00000097          	auipc	ra,0x0
 2e8:	66c080e7          	jalr	1644(ra) # 950 <printf>
      exit(1);
 2ec:	4505                	li	a0,1
 2ee:	00000097          	auipc	ra,0x0
 2f2:	2da080e7          	jalr	730(ra) # 5c8 <exit>

00000000000002f6 <main>:

int
main(int argc, char *argv[])
{
 2f6:	1141                	addi	sp,sp,-16
 2f8:	e406                	sd	ra,8(sp)
 2fa:	e022                	sd	s0,0(sp)
 2fc:	0800                	addi	s0,sp,16
  printf("sysinfotest: start\n");
 2fe:	00001517          	auipc	a0,0x1
 302:	93a50513          	addi	a0,a0,-1734 # c38 <malloc+0x22a>
 306:	00000097          	auipc	ra,0x0
 30a:	64a080e7          	jalr	1610(ra) # 950 <printf>
  testcall();
 30e:	00000097          	auipc	ra,0x0
 312:	eba080e7          	jalr	-326(ra) # 1c8 <testcall>
  testmem();
 316:	00000097          	auipc	ra,0x0
 31a:	daa080e7          	jalr	-598(ra) # c0 <testmem>
  testproc();
 31e:	00000097          	auipc	ra,0x0
 322:	f14080e7          	jalr	-236(ra) # 232 <testproc>
  printf("sysinfotest: OK\n");
 326:	00001517          	auipc	a0,0x1
 32a:	92a50513          	addi	a0,a0,-1750 # c50 <malloc+0x242>
 32e:	00000097          	auipc	ra,0x0
 332:	622080e7          	jalr	1570(ra) # 950 <printf>
  exit(0);
 336:	4501                	li	a0,0
 338:	00000097          	auipc	ra,0x0
 33c:	290080e7          	jalr	656(ra) # 5c8 <exit>

0000000000000340 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 340:	1141                	addi	sp,sp,-16
 342:	e406                	sd	ra,8(sp)
 344:	e022                	sd	s0,0(sp)
 346:	0800                	addi	s0,sp,16
  extern int main();
  main();
 348:	00000097          	auipc	ra,0x0
 34c:	fae080e7          	jalr	-82(ra) # 2f6 <main>
  exit(0);
 350:	4501                	li	a0,0
 352:	00000097          	auipc	ra,0x0
 356:	276080e7          	jalr	630(ra) # 5c8 <exit>

000000000000035a <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 35a:	1141                	addi	sp,sp,-16
 35c:	e422                	sd	s0,8(sp)
 35e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 360:	87aa                	mv	a5,a0
 362:	0585                	addi	a1,a1,1
 364:	0785                	addi	a5,a5,1
 366:	fff5c703          	lbu	a4,-1(a1) # ffffffffffffefff <base+0xffffffffffffdfef>
 36a:	fee78fa3          	sb	a4,-1(a5)
 36e:	fb75                	bnez	a4,362 <strcpy+0x8>
    ;
  return os;
}
 370:	6422                	ld	s0,8(sp)
 372:	0141                	addi	sp,sp,16
 374:	8082                	ret

0000000000000376 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 376:	1141                	addi	sp,sp,-16
 378:	e422                	sd	s0,8(sp)
 37a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 37c:	00054783          	lbu	a5,0(a0)
 380:	cb91                	beqz	a5,394 <strcmp+0x1e>
 382:	0005c703          	lbu	a4,0(a1)
 386:	00f71763          	bne	a4,a5,394 <strcmp+0x1e>
    p++, q++;
 38a:	0505                	addi	a0,a0,1
 38c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 38e:	00054783          	lbu	a5,0(a0)
 392:	fbe5                	bnez	a5,382 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 394:	0005c503          	lbu	a0,0(a1)
}
 398:	40a7853b          	subw	a0,a5,a0
 39c:	6422                	ld	s0,8(sp)
 39e:	0141                	addi	sp,sp,16
 3a0:	8082                	ret

00000000000003a2 <strlen>:

uint
strlen(const char *s)
{
 3a2:	1141                	addi	sp,sp,-16
 3a4:	e422                	sd	s0,8(sp)
 3a6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 3a8:	00054783          	lbu	a5,0(a0)
 3ac:	cf91                	beqz	a5,3c8 <strlen+0x26>
 3ae:	0505                	addi	a0,a0,1
 3b0:	87aa                	mv	a5,a0
 3b2:	4685                	li	a3,1
 3b4:	9e89                	subw	a3,a3,a0
 3b6:	00f6853b          	addw	a0,a3,a5
 3ba:	0785                	addi	a5,a5,1
 3bc:	fff7c703          	lbu	a4,-1(a5)
 3c0:	fb7d                	bnez	a4,3b6 <strlen+0x14>
    ;
  return n;
}
 3c2:	6422                	ld	s0,8(sp)
 3c4:	0141                	addi	sp,sp,16
 3c6:	8082                	ret
  for(n = 0; s[n]; n++)
 3c8:	4501                	li	a0,0
 3ca:	bfe5                	j	3c2 <strlen+0x20>

00000000000003cc <memset>:

void*
memset(void *dst, int c, uint n)
{
 3cc:	1141                	addi	sp,sp,-16
 3ce:	e422                	sd	s0,8(sp)
 3d0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3d2:	ca19                	beqz	a2,3e8 <memset+0x1c>
 3d4:	87aa                	mv	a5,a0
 3d6:	1602                	slli	a2,a2,0x20
 3d8:	9201                	srli	a2,a2,0x20
 3da:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 3de:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3e2:	0785                	addi	a5,a5,1
 3e4:	fee79de3          	bne	a5,a4,3de <memset+0x12>
  }
  return dst;
}
 3e8:	6422                	ld	s0,8(sp)
 3ea:	0141                	addi	sp,sp,16
 3ec:	8082                	ret

00000000000003ee <strchr>:

char*
strchr(const char *s, char c)
{
 3ee:	1141                	addi	sp,sp,-16
 3f0:	e422                	sd	s0,8(sp)
 3f2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3f4:	00054783          	lbu	a5,0(a0)
 3f8:	cb99                	beqz	a5,40e <strchr+0x20>
    if(*s == c)
 3fa:	00f58763          	beq	a1,a5,408 <strchr+0x1a>
  for(; *s; s++)
 3fe:	0505                	addi	a0,a0,1
 400:	00054783          	lbu	a5,0(a0)
 404:	fbfd                	bnez	a5,3fa <strchr+0xc>
      return (char*)s;
  return 0;
 406:	4501                	li	a0,0
}
 408:	6422                	ld	s0,8(sp)
 40a:	0141                	addi	sp,sp,16
 40c:	8082                	ret
  return 0;
 40e:	4501                	li	a0,0
 410:	bfe5                	j	408 <strchr+0x1a>

0000000000000412 <gets>:

char*
gets(char *buf, int max)
{
 412:	711d                	addi	sp,sp,-96
 414:	ec86                	sd	ra,88(sp)
 416:	e8a2                	sd	s0,80(sp)
 418:	e4a6                	sd	s1,72(sp)
 41a:	e0ca                	sd	s2,64(sp)
 41c:	fc4e                	sd	s3,56(sp)
 41e:	f852                	sd	s4,48(sp)
 420:	f456                	sd	s5,40(sp)
 422:	f05a                	sd	s6,32(sp)
 424:	ec5e                	sd	s7,24(sp)
 426:	1080                	addi	s0,sp,96
 428:	8baa                	mv	s7,a0
 42a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 42c:	892a                	mv	s2,a0
 42e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 430:	4aa9                	li	s5,10
 432:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 434:	89a6                	mv	s3,s1
 436:	2485                	addiw	s1,s1,1
 438:	0344d863          	bge	s1,s4,468 <gets+0x56>
    cc = read(0, &c, 1);
 43c:	4605                	li	a2,1
 43e:	faf40593          	addi	a1,s0,-81
 442:	4501                	li	a0,0
 444:	00000097          	auipc	ra,0x0
 448:	19c080e7          	jalr	412(ra) # 5e0 <read>
    if(cc < 1)
 44c:	00a05e63          	blez	a0,468 <gets+0x56>
    buf[i++] = c;
 450:	faf44783          	lbu	a5,-81(s0)
 454:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 458:	01578763          	beq	a5,s5,466 <gets+0x54>
 45c:	0905                	addi	s2,s2,1
 45e:	fd679be3          	bne	a5,s6,434 <gets+0x22>
  for(i=0; i+1 < max; ){
 462:	89a6                	mv	s3,s1
 464:	a011                	j	468 <gets+0x56>
 466:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 468:	99de                	add	s3,s3,s7
 46a:	00098023          	sb	zero,0(s3) # 1000 <freep>
  return buf;
}
 46e:	855e                	mv	a0,s7
 470:	60e6                	ld	ra,88(sp)
 472:	6446                	ld	s0,80(sp)
 474:	64a6                	ld	s1,72(sp)
 476:	6906                	ld	s2,64(sp)
 478:	79e2                	ld	s3,56(sp)
 47a:	7a42                	ld	s4,48(sp)
 47c:	7aa2                	ld	s5,40(sp)
 47e:	7b02                	ld	s6,32(sp)
 480:	6be2                	ld	s7,24(sp)
 482:	6125                	addi	sp,sp,96
 484:	8082                	ret

0000000000000486 <stat>:

int
stat(const char *n, struct stat *st)
{
 486:	1101                	addi	sp,sp,-32
 488:	ec06                	sd	ra,24(sp)
 48a:	e822                	sd	s0,16(sp)
 48c:	e426                	sd	s1,8(sp)
 48e:	e04a                	sd	s2,0(sp)
 490:	1000                	addi	s0,sp,32
 492:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 494:	4581                	li	a1,0
 496:	00000097          	auipc	ra,0x0
 49a:	172080e7          	jalr	370(ra) # 608 <open>
  if(fd < 0)
 49e:	02054563          	bltz	a0,4c8 <stat+0x42>
 4a2:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 4a4:	85ca                	mv	a1,s2
 4a6:	00000097          	auipc	ra,0x0
 4aa:	17a080e7          	jalr	378(ra) # 620 <fstat>
 4ae:	892a                	mv	s2,a0
  close(fd);
 4b0:	8526                	mv	a0,s1
 4b2:	00000097          	auipc	ra,0x0
 4b6:	13e080e7          	jalr	318(ra) # 5f0 <close>
  return r;
}
 4ba:	854a                	mv	a0,s2
 4bc:	60e2                	ld	ra,24(sp)
 4be:	6442                	ld	s0,16(sp)
 4c0:	64a2                	ld	s1,8(sp)
 4c2:	6902                	ld	s2,0(sp)
 4c4:	6105                	addi	sp,sp,32
 4c6:	8082                	ret
    return -1;
 4c8:	597d                	li	s2,-1
 4ca:	bfc5                	j	4ba <stat+0x34>

00000000000004cc <atoi>:

int
atoi(const char *s)
{
 4cc:	1141                	addi	sp,sp,-16
 4ce:	e422                	sd	s0,8(sp)
 4d0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4d2:	00054603          	lbu	a2,0(a0)
 4d6:	fd06079b          	addiw	a5,a2,-48
 4da:	0ff7f793          	andi	a5,a5,255
 4de:	4725                	li	a4,9
 4e0:	02f76963          	bltu	a4,a5,512 <atoi+0x46>
 4e4:	86aa                	mv	a3,a0
  n = 0;
 4e6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 4e8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 4ea:	0685                	addi	a3,a3,1
 4ec:	0025179b          	slliw	a5,a0,0x2
 4f0:	9fa9                	addw	a5,a5,a0
 4f2:	0017979b          	slliw	a5,a5,0x1
 4f6:	9fb1                	addw	a5,a5,a2
 4f8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4fc:	0006c603          	lbu	a2,0(a3)
 500:	fd06071b          	addiw	a4,a2,-48
 504:	0ff77713          	andi	a4,a4,255
 508:	fee5f1e3          	bgeu	a1,a4,4ea <atoi+0x1e>
  return n;
}
 50c:	6422                	ld	s0,8(sp)
 50e:	0141                	addi	sp,sp,16
 510:	8082                	ret
  n = 0;
 512:	4501                	li	a0,0
 514:	bfe5                	j	50c <atoi+0x40>

0000000000000516 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 516:	1141                	addi	sp,sp,-16
 518:	e422                	sd	s0,8(sp)
 51a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 51c:	02b57463          	bgeu	a0,a1,544 <memmove+0x2e>
    while(n-- > 0)
 520:	00c05f63          	blez	a2,53e <memmove+0x28>
 524:	1602                	slli	a2,a2,0x20
 526:	9201                	srli	a2,a2,0x20
 528:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 52c:	872a                	mv	a4,a0
      *dst++ = *src++;
 52e:	0585                	addi	a1,a1,1
 530:	0705                	addi	a4,a4,1
 532:	fff5c683          	lbu	a3,-1(a1)
 536:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 53a:	fee79ae3          	bne	a5,a4,52e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 53e:	6422                	ld	s0,8(sp)
 540:	0141                	addi	sp,sp,16
 542:	8082                	ret
    dst += n;
 544:	00c50733          	add	a4,a0,a2
    src += n;
 548:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 54a:	fec05ae3          	blez	a2,53e <memmove+0x28>
 54e:	fff6079b          	addiw	a5,a2,-1
 552:	1782                	slli	a5,a5,0x20
 554:	9381                	srli	a5,a5,0x20
 556:	fff7c793          	not	a5,a5
 55a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 55c:	15fd                	addi	a1,a1,-1
 55e:	177d                	addi	a4,a4,-1
 560:	0005c683          	lbu	a3,0(a1)
 564:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 568:	fee79ae3          	bne	a5,a4,55c <memmove+0x46>
 56c:	bfc9                	j	53e <memmove+0x28>

000000000000056e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 56e:	1141                	addi	sp,sp,-16
 570:	e422                	sd	s0,8(sp)
 572:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 574:	ca05                	beqz	a2,5a4 <memcmp+0x36>
 576:	fff6069b          	addiw	a3,a2,-1
 57a:	1682                	slli	a3,a3,0x20
 57c:	9281                	srli	a3,a3,0x20
 57e:	0685                	addi	a3,a3,1
 580:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 582:	00054783          	lbu	a5,0(a0)
 586:	0005c703          	lbu	a4,0(a1)
 58a:	00e79863          	bne	a5,a4,59a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 58e:	0505                	addi	a0,a0,1
    p2++;
 590:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 592:	fed518e3          	bne	a0,a3,582 <memcmp+0x14>
  }
  return 0;
 596:	4501                	li	a0,0
 598:	a019                	j	59e <memcmp+0x30>
      return *p1 - *p2;
 59a:	40e7853b          	subw	a0,a5,a4
}
 59e:	6422                	ld	s0,8(sp)
 5a0:	0141                	addi	sp,sp,16
 5a2:	8082                	ret
  return 0;
 5a4:	4501                	li	a0,0
 5a6:	bfe5                	j	59e <memcmp+0x30>

00000000000005a8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 5a8:	1141                	addi	sp,sp,-16
 5aa:	e406                	sd	ra,8(sp)
 5ac:	e022                	sd	s0,0(sp)
 5ae:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 5b0:	00000097          	auipc	ra,0x0
 5b4:	f66080e7          	jalr	-154(ra) # 516 <memmove>
}
 5b8:	60a2                	ld	ra,8(sp)
 5ba:	6402                	ld	s0,0(sp)
 5bc:	0141                	addi	sp,sp,16
 5be:	8082                	ret

00000000000005c0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5c0:	4885                	li	a7,1
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 5c8:	4889                	li	a7,2
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 5d0:	488d                	li	a7,3
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 5d8:	4891                	li	a7,4
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <read>:
.global read
read:
 li a7, SYS_read
 5e0:	4895                	li	a7,5
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <write>:
.global write
write:
 li a7, SYS_write
 5e8:	48c1                	li	a7,16
 ecall
 5ea:	00000073          	ecall
 ret
 5ee:	8082                	ret

00000000000005f0 <close>:
.global close
close:
 li a7, SYS_close
 5f0:	48d5                	li	a7,21
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5f8:	4899                	li	a7,6
 ecall
 5fa:	00000073          	ecall
 ret
 5fe:	8082                	ret

0000000000000600 <exec>:
.global exec
exec:
 li a7, SYS_exec
 600:	489d                	li	a7,7
 ecall
 602:	00000073          	ecall
 ret
 606:	8082                	ret

0000000000000608 <open>:
.global open
open:
 li a7, SYS_open
 608:	48bd                	li	a7,15
 ecall
 60a:	00000073          	ecall
 ret
 60e:	8082                	ret

0000000000000610 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 610:	48c5                	li	a7,17
 ecall
 612:	00000073          	ecall
 ret
 616:	8082                	ret

0000000000000618 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 618:	48c9                	li	a7,18
 ecall
 61a:	00000073          	ecall
 ret
 61e:	8082                	ret

0000000000000620 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 620:	48a1                	li	a7,8
 ecall
 622:	00000073          	ecall
 ret
 626:	8082                	ret

0000000000000628 <link>:
.global link
link:
 li a7, SYS_link
 628:	48cd                	li	a7,19
 ecall
 62a:	00000073          	ecall
 ret
 62e:	8082                	ret

0000000000000630 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 630:	48d1                	li	a7,20
 ecall
 632:	00000073          	ecall
 ret
 636:	8082                	ret

0000000000000638 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 638:	48a5                	li	a7,9
 ecall
 63a:	00000073          	ecall
 ret
 63e:	8082                	ret

0000000000000640 <dup>:
.global dup
dup:
 li a7, SYS_dup
 640:	48a9                	li	a7,10
 ecall
 642:	00000073          	ecall
 ret
 646:	8082                	ret

0000000000000648 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 648:	48ad                	li	a7,11
 ecall
 64a:	00000073          	ecall
 ret
 64e:	8082                	ret

0000000000000650 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 650:	48b1                	li	a7,12
 ecall
 652:	00000073          	ecall
 ret
 656:	8082                	ret

0000000000000658 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 658:	48b5                	li	a7,13
 ecall
 65a:	00000073          	ecall
 ret
 65e:	8082                	ret

0000000000000660 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 660:	48b9                	li	a7,14
 ecall
 662:	00000073          	ecall
 ret
 666:	8082                	ret

0000000000000668 <trace>:
.global trace
trace:
 li a7, SYS_trace
 668:	48d9                	li	a7,22
 ecall
 66a:	00000073          	ecall
 ret
 66e:	8082                	ret

0000000000000670 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 670:	48dd                	li	a7,23
 ecall
 672:	00000073          	ecall
 ret
 676:	8082                	ret

0000000000000678 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 678:	1101                	addi	sp,sp,-32
 67a:	ec06                	sd	ra,24(sp)
 67c:	e822                	sd	s0,16(sp)
 67e:	1000                	addi	s0,sp,32
 680:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 684:	4605                	li	a2,1
 686:	fef40593          	addi	a1,s0,-17
 68a:	00000097          	auipc	ra,0x0
 68e:	f5e080e7          	jalr	-162(ra) # 5e8 <write>
}
 692:	60e2                	ld	ra,24(sp)
 694:	6442                	ld	s0,16(sp)
 696:	6105                	addi	sp,sp,32
 698:	8082                	ret

000000000000069a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 69a:	7139                	addi	sp,sp,-64
 69c:	fc06                	sd	ra,56(sp)
 69e:	f822                	sd	s0,48(sp)
 6a0:	f426                	sd	s1,40(sp)
 6a2:	f04a                	sd	s2,32(sp)
 6a4:	ec4e                	sd	s3,24(sp)
 6a6:	0080                	addi	s0,sp,64
 6a8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 6aa:	c299                	beqz	a3,6b0 <printint+0x16>
 6ac:	0805c863          	bltz	a1,73c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 6b0:	2581                	sext.w	a1,a1
  neg = 0;
 6b2:	4881                	li	a7,0
 6b4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 6b8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 6ba:	2601                	sext.w	a2,a2
 6bc:	00000517          	auipc	a0,0x0
 6c0:	5b450513          	addi	a0,a0,1460 # c70 <digits>
 6c4:	883a                	mv	a6,a4
 6c6:	2705                	addiw	a4,a4,1
 6c8:	02c5f7bb          	remuw	a5,a1,a2
 6cc:	1782                	slli	a5,a5,0x20
 6ce:	9381                	srli	a5,a5,0x20
 6d0:	97aa                	add	a5,a5,a0
 6d2:	0007c783          	lbu	a5,0(a5)
 6d6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6da:	0005879b          	sext.w	a5,a1
 6de:	02c5d5bb          	divuw	a1,a1,a2
 6e2:	0685                	addi	a3,a3,1
 6e4:	fec7f0e3          	bgeu	a5,a2,6c4 <printint+0x2a>
  if(neg)
 6e8:	00088b63          	beqz	a7,6fe <printint+0x64>
    buf[i++] = '-';
 6ec:	fd040793          	addi	a5,s0,-48
 6f0:	973e                	add	a4,a4,a5
 6f2:	02d00793          	li	a5,45
 6f6:	fef70823          	sb	a5,-16(a4)
 6fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6fe:	02e05863          	blez	a4,72e <printint+0x94>
 702:	fc040793          	addi	a5,s0,-64
 706:	00e78933          	add	s2,a5,a4
 70a:	fff78993          	addi	s3,a5,-1
 70e:	99ba                	add	s3,s3,a4
 710:	377d                	addiw	a4,a4,-1
 712:	1702                	slli	a4,a4,0x20
 714:	9301                	srli	a4,a4,0x20
 716:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 71a:	fff94583          	lbu	a1,-1(s2)
 71e:	8526                	mv	a0,s1
 720:	00000097          	auipc	ra,0x0
 724:	f58080e7          	jalr	-168(ra) # 678 <putc>
  while(--i >= 0)
 728:	197d                	addi	s2,s2,-1
 72a:	ff3918e3          	bne	s2,s3,71a <printint+0x80>
}
 72e:	70e2                	ld	ra,56(sp)
 730:	7442                	ld	s0,48(sp)
 732:	74a2                	ld	s1,40(sp)
 734:	7902                	ld	s2,32(sp)
 736:	69e2                	ld	s3,24(sp)
 738:	6121                	addi	sp,sp,64
 73a:	8082                	ret
    x = -xx;
 73c:	40b005bb          	negw	a1,a1
    neg = 1;
 740:	4885                	li	a7,1
    x = -xx;
 742:	bf8d                	j	6b4 <printint+0x1a>

0000000000000744 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 744:	7119                	addi	sp,sp,-128
 746:	fc86                	sd	ra,120(sp)
 748:	f8a2                	sd	s0,112(sp)
 74a:	f4a6                	sd	s1,104(sp)
 74c:	f0ca                	sd	s2,96(sp)
 74e:	ecce                	sd	s3,88(sp)
 750:	e8d2                	sd	s4,80(sp)
 752:	e4d6                	sd	s5,72(sp)
 754:	e0da                	sd	s6,64(sp)
 756:	fc5e                	sd	s7,56(sp)
 758:	f862                	sd	s8,48(sp)
 75a:	f466                	sd	s9,40(sp)
 75c:	f06a                	sd	s10,32(sp)
 75e:	ec6e                	sd	s11,24(sp)
 760:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 762:	0005c903          	lbu	s2,0(a1)
 766:	18090f63          	beqz	s2,904 <vprintf+0x1c0>
 76a:	8aaa                	mv	s5,a0
 76c:	8b32                	mv	s6,a2
 76e:	00158493          	addi	s1,a1,1
  state = 0;
 772:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 774:	02500a13          	li	s4,37
      if(c == 'd'){
 778:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 77c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 780:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 784:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 788:	00000b97          	auipc	s7,0x0
 78c:	4e8b8b93          	addi	s7,s7,1256 # c70 <digits>
 790:	a839                	j	7ae <vprintf+0x6a>
        putc(fd, c);
 792:	85ca                	mv	a1,s2
 794:	8556                	mv	a0,s5
 796:	00000097          	auipc	ra,0x0
 79a:	ee2080e7          	jalr	-286(ra) # 678 <putc>
 79e:	a019                	j	7a4 <vprintf+0x60>
    } else if(state == '%'){
 7a0:	01498f63          	beq	s3,s4,7be <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 7a4:	0485                	addi	s1,s1,1
 7a6:	fff4c903          	lbu	s2,-1(s1)
 7aa:	14090d63          	beqz	s2,904 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 7ae:	0009079b          	sext.w	a5,s2
    if(state == 0){
 7b2:	fe0997e3          	bnez	s3,7a0 <vprintf+0x5c>
      if(c == '%'){
 7b6:	fd479ee3          	bne	a5,s4,792 <vprintf+0x4e>
        state = '%';
 7ba:	89be                	mv	s3,a5
 7bc:	b7e5                	j	7a4 <vprintf+0x60>
      if(c == 'd'){
 7be:	05878063          	beq	a5,s8,7fe <vprintf+0xba>
      } else if(c == 'l') {
 7c2:	05978c63          	beq	a5,s9,81a <vprintf+0xd6>
      } else if(c == 'x') {
 7c6:	07a78863          	beq	a5,s10,836 <vprintf+0xf2>
      } else if(c == 'p') {
 7ca:	09b78463          	beq	a5,s11,852 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 7ce:	07300713          	li	a4,115
 7d2:	0ce78663          	beq	a5,a4,89e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 7d6:	06300713          	li	a4,99
 7da:	0ee78e63          	beq	a5,a4,8d6 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 7de:	11478863          	beq	a5,s4,8ee <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 7e2:	85d2                	mv	a1,s4
 7e4:	8556                	mv	a0,s5
 7e6:	00000097          	auipc	ra,0x0
 7ea:	e92080e7          	jalr	-366(ra) # 678 <putc>
        putc(fd, c);
 7ee:	85ca                	mv	a1,s2
 7f0:	8556                	mv	a0,s5
 7f2:	00000097          	auipc	ra,0x0
 7f6:	e86080e7          	jalr	-378(ra) # 678 <putc>
      }
      state = 0;
 7fa:	4981                	li	s3,0
 7fc:	b765                	j	7a4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 7fe:	008b0913          	addi	s2,s6,8
 802:	4685                	li	a3,1
 804:	4629                	li	a2,10
 806:	000b2583          	lw	a1,0(s6)
 80a:	8556                	mv	a0,s5
 80c:	00000097          	auipc	ra,0x0
 810:	e8e080e7          	jalr	-370(ra) # 69a <printint>
 814:	8b4a                	mv	s6,s2
      state = 0;
 816:	4981                	li	s3,0
 818:	b771                	j	7a4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 81a:	008b0913          	addi	s2,s6,8
 81e:	4681                	li	a3,0
 820:	4629                	li	a2,10
 822:	000b2583          	lw	a1,0(s6)
 826:	8556                	mv	a0,s5
 828:	00000097          	auipc	ra,0x0
 82c:	e72080e7          	jalr	-398(ra) # 69a <printint>
 830:	8b4a                	mv	s6,s2
      state = 0;
 832:	4981                	li	s3,0
 834:	bf85                	j	7a4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 836:	008b0913          	addi	s2,s6,8
 83a:	4681                	li	a3,0
 83c:	4641                	li	a2,16
 83e:	000b2583          	lw	a1,0(s6)
 842:	8556                	mv	a0,s5
 844:	00000097          	auipc	ra,0x0
 848:	e56080e7          	jalr	-426(ra) # 69a <printint>
 84c:	8b4a                	mv	s6,s2
      state = 0;
 84e:	4981                	li	s3,0
 850:	bf91                	j	7a4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 852:	008b0793          	addi	a5,s6,8
 856:	f8f43423          	sd	a5,-120(s0)
 85a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 85e:	03000593          	li	a1,48
 862:	8556                	mv	a0,s5
 864:	00000097          	auipc	ra,0x0
 868:	e14080e7          	jalr	-492(ra) # 678 <putc>
  putc(fd, 'x');
 86c:	85ea                	mv	a1,s10
 86e:	8556                	mv	a0,s5
 870:	00000097          	auipc	ra,0x0
 874:	e08080e7          	jalr	-504(ra) # 678 <putc>
 878:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 87a:	03c9d793          	srli	a5,s3,0x3c
 87e:	97de                	add	a5,a5,s7
 880:	0007c583          	lbu	a1,0(a5)
 884:	8556                	mv	a0,s5
 886:	00000097          	auipc	ra,0x0
 88a:	df2080e7          	jalr	-526(ra) # 678 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 88e:	0992                	slli	s3,s3,0x4
 890:	397d                	addiw	s2,s2,-1
 892:	fe0914e3          	bnez	s2,87a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 896:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 89a:	4981                	li	s3,0
 89c:	b721                	j	7a4 <vprintf+0x60>
        s = va_arg(ap, char*);
 89e:	008b0993          	addi	s3,s6,8
 8a2:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 8a6:	02090163          	beqz	s2,8c8 <vprintf+0x184>
        while(*s != 0){
 8aa:	00094583          	lbu	a1,0(s2)
 8ae:	c9a1                	beqz	a1,8fe <vprintf+0x1ba>
          putc(fd, *s);
 8b0:	8556                	mv	a0,s5
 8b2:	00000097          	auipc	ra,0x0
 8b6:	dc6080e7          	jalr	-570(ra) # 678 <putc>
          s++;
 8ba:	0905                	addi	s2,s2,1
        while(*s != 0){
 8bc:	00094583          	lbu	a1,0(s2)
 8c0:	f9e5                	bnez	a1,8b0 <vprintf+0x16c>
        s = va_arg(ap, char*);
 8c2:	8b4e                	mv	s6,s3
      state = 0;
 8c4:	4981                	li	s3,0
 8c6:	bdf9                	j	7a4 <vprintf+0x60>
          s = "(null)";
 8c8:	00000917          	auipc	s2,0x0
 8cc:	3a090913          	addi	s2,s2,928 # c68 <malloc+0x25a>
        while(*s != 0){
 8d0:	02800593          	li	a1,40
 8d4:	bff1                	j	8b0 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 8d6:	008b0913          	addi	s2,s6,8
 8da:	000b4583          	lbu	a1,0(s6)
 8de:	8556                	mv	a0,s5
 8e0:	00000097          	auipc	ra,0x0
 8e4:	d98080e7          	jalr	-616(ra) # 678 <putc>
 8e8:	8b4a                	mv	s6,s2
      state = 0;
 8ea:	4981                	li	s3,0
 8ec:	bd65                	j	7a4 <vprintf+0x60>
        putc(fd, c);
 8ee:	85d2                	mv	a1,s4
 8f0:	8556                	mv	a0,s5
 8f2:	00000097          	auipc	ra,0x0
 8f6:	d86080e7          	jalr	-634(ra) # 678 <putc>
      state = 0;
 8fa:	4981                	li	s3,0
 8fc:	b565                	j	7a4 <vprintf+0x60>
        s = va_arg(ap, char*);
 8fe:	8b4e                	mv	s6,s3
      state = 0;
 900:	4981                	li	s3,0
 902:	b54d                	j	7a4 <vprintf+0x60>
    }
  }
}
 904:	70e6                	ld	ra,120(sp)
 906:	7446                	ld	s0,112(sp)
 908:	74a6                	ld	s1,104(sp)
 90a:	7906                	ld	s2,96(sp)
 90c:	69e6                	ld	s3,88(sp)
 90e:	6a46                	ld	s4,80(sp)
 910:	6aa6                	ld	s5,72(sp)
 912:	6b06                	ld	s6,64(sp)
 914:	7be2                	ld	s7,56(sp)
 916:	7c42                	ld	s8,48(sp)
 918:	7ca2                	ld	s9,40(sp)
 91a:	7d02                	ld	s10,32(sp)
 91c:	6de2                	ld	s11,24(sp)
 91e:	6109                	addi	sp,sp,128
 920:	8082                	ret

0000000000000922 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 922:	715d                	addi	sp,sp,-80
 924:	ec06                	sd	ra,24(sp)
 926:	e822                	sd	s0,16(sp)
 928:	1000                	addi	s0,sp,32
 92a:	e010                	sd	a2,0(s0)
 92c:	e414                	sd	a3,8(s0)
 92e:	e818                	sd	a4,16(s0)
 930:	ec1c                	sd	a5,24(s0)
 932:	03043023          	sd	a6,32(s0)
 936:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 93a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 93e:	8622                	mv	a2,s0
 940:	00000097          	auipc	ra,0x0
 944:	e04080e7          	jalr	-508(ra) # 744 <vprintf>
}
 948:	60e2                	ld	ra,24(sp)
 94a:	6442                	ld	s0,16(sp)
 94c:	6161                	addi	sp,sp,80
 94e:	8082                	ret

0000000000000950 <printf>:

void
printf(const char *fmt, ...)
{
 950:	711d                	addi	sp,sp,-96
 952:	ec06                	sd	ra,24(sp)
 954:	e822                	sd	s0,16(sp)
 956:	1000                	addi	s0,sp,32
 958:	e40c                	sd	a1,8(s0)
 95a:	e810                	sd	a2,16(s0)
 95c:	ec14                	sd	a3,24(s0)
 95e:	f018                	sd	a4,32(s0)
 960:	f41c                	sd	a5,40(s0)
 962:	03043823          	sd	a6,48(s0)
 966:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 96a:	00840613          	addi	a2,s0,8
 96e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 972:	85aa                	mv	a1,a0
 974:	4505                	li	a0,1
 976:	00000097          	auipc	ra,0x0
 97a:	dce080e7          	jalr	-562(ra) # 744 <vprintf>
}
 97e:	60e2                	ld	ra,24(sp)
 980:	6442                	ld	s0,16(sp)
 982:	6125                	addi	sp,sp,96
 984:	8082                	ret

0000000000000986 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 986:	1141                	addi	sp,sp,-16
 988:	e422                	sd	s0,8(sp)
 98a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 98c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 990:	00000797          	auipc	a5,0x0
 994:	6707b783          	ld	a5,1648(a5) # 1000 <freep>
 998:	a805                	j	9c8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 99a:	4618                	lw	a4,8(a2)
 99c:	9db9                	addw	a1,a1,a4
 99e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 9a2:	6398                	ld	a4,0(a5)
 9a4:	6318                	ld	a4,0(a4)
 9a6:	fee53823          	sd	a4,-16(a0)
 9aa:	a091                	j	9ee <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 9ac:	ff852703          	lw	a4,-8(a0)
 9b0:	9e39                	addw	a2,a2,a4
 9b2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 9b4:	ff053703          	ld	a4,-16(a0)
 9b8:	e398                	sd	a4,0(a5)
 9ba:	a099                	j	a00 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9bc:	6398                	ld	a4,0(a5)
 9be:	00e7e463          	bltu	a5,a4,9c6 <free+0x40>
 9c2:	00e6ea63          	bltu	a3,a4,9d6 <free+0x50>
{
 9c6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9c8:	fed7fae3          	bgeu	a5,a3,9bc <free+0x36>
 9cc:	6398                	ld	a4,0(a5)
 9ce:	00e6e463          	bltu	a3,a4,9d6 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9d2:	fee7eae3          	bltu	a5,a4,9c6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 9d6:	ff852583          	lw	a1,-8(a0)
 9da:	6390                	ld	a2,0(a5)
 9dc:	02059713          	slli	a4,a1,0x20
 9e0:	9301                	srli	a4,a4,0x20
 9e2:	0712                	slli	a4,a4,0x4
 9e4:	9736                	add	a4,a4,a3
 9e6:	fae60ae3          	beq	a2,a4,99a <free+0x14>
    bp->s.ptr = p->s.ptr;
 9ea:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9ee:	4790                	lw	a2,8(a5)
 9f0:	02061713          	slli	a4,a2,0x20
 9f4:	9301                	srli	a4,a4,0x20
 9f6:	0712                	slli	a4,a4,0x4
 9f8:	973e                	add	a4,a4,a5
 9fa:	fae689e3          	beq	a3,a4,9ac <free+0x26>
  } else
    p->s.ptr = bp;
 9fe:	e394                	sd	a3,0(a5)
  freep = p;
 a00:	00000717          	auipc	a4,0x0
 a04:	60f73023          	sd	a5,1536(a4) # 1000 <freep>
}
 a08:	6422                	ld	s0,8(sp)
 a0a:	0141                	addi	sp,sp,16
 a0c:	8082                	ret

0000000000000a0e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 a0e:	7139                	addi	sp,sp,-64
 a10:	fc06                	sd	ra,56(sp)
 a12:	f822                	sd	s0,48(sp)
 a14:	f426                	sd	s1,40(sp)
 a16:	f04a                	sd	s2,32(sp)
 a18:	ec4e                	sd	s3,24(sp)
 a1a:	e852                	sd	s4,16(sp)
 a1c:	e456                	sd	s5,8(sp)
 a1e:	e05a                	sd	s6,0(sp)
 a20:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a22:	02051493          	slli	s1,a0,0x20
 a26:	9081                	srli	s1,s1,0x20
 a28:	04bd                	addi	s1,s1,15
 a2a:	8091                	srli	s1,s1,0x4
 a2c:	0014899b          	addiw	s3,s1,1
 a30:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a32:	00000517          	auipc	a0,0x0
 a36:	5ce53503          	ld	a0,1486(a0) # 1000 <freep>
 a3a:	c515                	beqz	a0,a66 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a3c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a3e:	4798                	lw	a4,8(a5)
 a40:	02977f63          	bgeu	a4,s1,a7e <malloc+0x70>
 a44:	8a4e                	mv	s4,s3
 a46:	0009871b          	sext.w	a4,s3
 a4a:	6685                	lui	a3,0x1
 a4c:	00d77363          	bgeu	a4,a3,a52 <malloc+0x44>
 a50:	6a05                	lui	s4,0x1
 a52:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a56:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a5a:	00000917          	auipc	s2,0x0
 a5e:	5a690913          	addi	s2,s2,1446 # 1000 <freep>
  if(p == (char*)-1)
 a62:	5afd                	li	s5,-1
 a64:	a88d                	j	ad6 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 a66:	00000797          	auipc	a5,0x0
 a6a:	5aa78793          	addi	a5,a5,1450 # 1010 <base>
 a6e:	00000717          	auipc	a4,0x0
 a72:	58f73923          	sd	a5,1426(a4) # 1000 <freep>
 a76:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a78:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a7c:	b7e1                	j	a44 <malloc+0x36>
      if(p->s.size == nunits)
 a7e:	02e48b63          	beq	s1,a4,ab4 <malloc+0xa6>
        p->s.size -= nunits;
 a82:	4137073b          	subw	a4,a4,s3
 a86:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a88:	1702                	slli	a4,a4,0x20
 a8a:	9301                	srli	a4,a4,0x20
 a8c:	0712                	slli	a4,a4,0x4
 a8e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a90:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a94:	00000717          	auipc	a4,0x0
 a98:	56a73623          	sd	a0,1388(a4) # 1000 <freep>
      return (void*)(p + 1);
 a9c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 aa0:	70e2                	ld	ra,56(sp)
 aa2:	7442                	ld	s0,48(sp)
 aa4:	74a2                	ld	s1,40(sp)
 aa6:	7902                	ld	s2,32(sp)
 aa8:	69e2                	ld	s3,24(sp)
 aaa:	6a42                	ld	s4,16(sp)
 aac:	6aa2                	ld	s5,8(sp)
 aae:	6b02                	ld	s6,0(sp)
 ab0:	6121                	addi	sp,sp,64
 ab2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 ab4:	6398                	ld	a4,0(a5)
 ab6:	e118                	sd	a4,0(a0)
 ab8:	bff1                	j	a94 <malloc+0x86>
  hp->s.size = nu;
 aba:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 abe:	0541                	addi	a0,a0,16
 ac0:	00000097          	auipc	ra,0x0
 ac4:	ec6080e7          	jalr	-314(ra) # 986 <free>
  return freep;
 ac8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 acc:	d971                	beqz	a0,aa0 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 ace:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 ad0:	4798                	lw	a4,8(a5)
 ad2:	fa9776e3          	bgeu	a4,s1,a7e <malloc+0x70>
    if(p == freep)
 ad6:	00093703          	ld	a4,0(s2)
 ada:	853e                	mv	a0,a5
 adc:	fef719e3          	bne	a4,a5,ace <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 ae0:	8552                	mv	a0,s4
 ae2:	00000097          	auipc	ra,0x0
 ae6:	b6e080e7          	jalr	-1170(ra) # 650 <sbrk>
  if(p == (char*)-1)
 aea:	fd5518e3          	bne	a0,s5,aba <malloc+0xac>
        return 0;
 aee:	4501                	li	a0,0
 af0:	bf45                	j	aa0 <malloc+0x92>
