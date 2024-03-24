
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b9010113          	addi	sp,sp,-1136 # 80008b90 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	9fe70713          	addi	a4,a4,-1538 # 80008a50 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	cac78793          	addi	a5,a5,-852 # 80005d10 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc73f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e1478793          	addi	a5,a5,-492 # 80000ec2 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3dc080e7          	jalr	988(ra) # 80002508 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	a0650513          	addi	a0,a0,-1530 # 80010b90 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a8e080e7          	jalr	-1394(ra) # 80000c20 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	9f648493          	addi	s1,s1,-1546 # 80010b90 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a8690913          	addi	s2,s2,-1402 # 80010c28 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	836080e7          	jalr	-1994(ra) # 800019f6 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	18a080e7          	jalr	394(ra) # 80002352 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ed4080e7          	jalr	-300(ra) # 800020aa <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2a0080e7          	jalr	672(ra) # 800024b2 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	96a50513          	addi	a0,a0,-1686 # 80010b90 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	aa6080e7          	jalr	-1370(ra) # 80000cd4 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	95450513          	addi	a0,a0,-1708 # 80010b90 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a90080e7          	jalr	-1392(ra) # 80000cd4 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	9af72b23          	sw	a5,-1610(a4) # 80010c28 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	8c450513          	addi	a0,a0,-1852 # 80010b90 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	94c080e7          	jalr	-1716(ra) # 80000c20 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	26c080e7          	jalr	620(ra) # 8000255e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	89650513          	addi	a0,a0,-1898 # 80010b90 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9d2080e7          	jalr	-1582(ra) # 80000cd4 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	87270713          	addi	a4,a4,-1934 # 80010b90 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	84878793          	addi	a5,a5,-1976 # 80010b90 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8b27a783          	lw	a5,-1870(a5) # 80010c28 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	80670713          	addi	a4,a4,-2042 # 80010b90 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	7f648493          	addi	s1,s1,2038 # 80010b90 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	7ba70713          	addi	a4,a4,1978 # 80010b90 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	84f72223          	sw	a5,-1980(a4) # 80010c30 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	77e78793          	addi	a5,a5,1918 # 80010b90 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	7ec7ab23          	sw	a2,2038(a5) # 80010c2c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	7ea50513          	addi	a0,a0,2026 # 80010c28 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cc8080e7          	jalr	-824(ra) # 8000210e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	73050513          	addi	a0,a0,1840 # 80010b90 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	728080e7          	jalr	1832(ra) # 80000b90 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ab078793          	addi	a5,a5,-1360 # 80020f28 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	7007a323          	sw	zero,1798(a5) # 80010c50 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	48f72923          	sw	a5,1170(a4) # 80008a10 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	696dad83          	lw	s11,1686(s11) # 80010c50 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	64050513          	addi	a0,a0,1600 # 80010c38 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	620080e7          	jalr	1568(ra) # 80000c20 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	4e250513          	addi	a0,a0,1250 # 80010c38 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	576080e7          	jalr	1398(ra) # 80000cd4 <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	4c648493          	addi	s1,s1,1222 # 80010c38 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	40c080e7          	jalr	1036(ra) # 80000b90 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	48650513          	addi	a0,a0,1158 # 80010c58 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	3b6080e7          	jalr	950(ra) # 80000b90 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	3de080e7          	jalr	990(ra) # 80000bd4 <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	2127a783          	lw	a5,530(a5) # 80008a10 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	450080e7          	jalr	1104(ra) # 80000c74 <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	1e27b783          	ld	a5,482(a5) # 80008a18 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	1e273703          	ld	a4,482(a4) # 80008a20 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	3f8a0a13          	addi	s4,s4,1016 # 80010c58 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	1b048493          	addi	s1,s1,432 # 80008a18 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	1b098993          	addi	s3,s3,432 # 80008a20 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	87c080e7          	jalr	-1924(ra) # 8000210e <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	38a50513          	addi	a0,a0,906 # 80010c58 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	34a080e7          	jalr	842(ra) # 80000c20 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	1327a783          	lw	a5,306(a5) # 80008a10 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	13873703          	ld	a4,312(a4) # 80008a20 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	1287b783          	ld	a5,296(a5) # 80008a18 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	35c98993          	addi	s3,s3,860 # 80010c58 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	11448493          	addi	s1,s1,276 # 80008a18 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	11490913          	addi	s2,s2,276 # 80008a20 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	78e080e7          	jalr	1934(ra) # 800020aa <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	32648493          	addi	s1,s1,806 # 80010c58 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	0ce7bd23          	sd	a4,218(a5) # 80008a20 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	37c080e7          	jalr	892(ra) # 80000cd4 <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	29c48493          	addi	s1,s1,668 # 80010c58 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	25a080e7          	jalr	602(ra) # 80000c20 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2fc080e7          	jalr	764(ra) # 80000cd4 <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00021797          	auipc	a5,0x21
    80000a02:	6c278793          	addi	a5,a5,1730 # 800220c0 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	306080e7          	jalr	774(ra) # 80000d1c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	27290913          	addi	s2,s2,626 # 80010c90 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1f8080e7          	jalr	504(ra) # 80000c20 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	298080e7          	jalr	664(ra) # 80000cd4 <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	1d650513          	addi	a0,a0,470 # 80010c90 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	0ce080e7          	jalr	206(ra) # 80000b90 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	5f250513          	addi	a0,a0,1522 # 800220c0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	1a048493          	addi	s1,s1,416 # 80010c90 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	126080e7          	jalr	294(ra) # 80000c20 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	18850513          	addi	a0,a0,392 # 80010c90 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	1c2080e7          	jalr	450(ra) # 80000cd4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1fc080e7          	jalr	508(ra) # 80000d1c <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	15c50513          	addi	a0,a0,348 # 80010c90 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	198080e7          	jalr	408(ra) # 80000cd4 <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <acquire_freemem>:

uint64
acquire_freemem()
{
    80000b46:	1101                	addi	sp,sp,-32
    80000b48:	ec06                	sd	ra,24(sp)
    80000b4a:	e822                	sd	s0,16(sp)
    80000b4c:	e426                	sd	s1,8(sp)
    80000b4e:	1000                	addi	s0,sp,32
  struct run *r;
  uint64 cnt = 0;
  acquire(&kmem.lock);
    80000b50:	00010497          	auipc	s1,0x10
    80000b54:	14048493          	addi	s1,s1,320 # 80010c90 <kmem>
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	0c6080e7          	jalr	198(ra) # 80000c20 <acquire>
  r = kmem.freelist;
    80000b62:	6c9c                	ld	a5,24(s1)
  while(r)
    80000b64:	c785                	beqz	a5,80000b8c <acquire_freemem+0x46>
  uint64 cnt = 0;
    80000b66:	4481                	li	s1,0
  {
    r = r->next;
    80000b68:	639c                	ld	a5,0(a5)
    cnt++;
    80000b6a:	0485                	addi	s1,s1,1
  while(r)
    80000b6c:	fff5                	bnez	a5,80000b68 <acquire_freemem+0x22>
  }
  release(&kmem.lock);
    80000b6e:	00010517          	auipc	a0,0x10
    80000b72:	12250513          	addi	a0,a0,290 # 80010c90 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	15e080e7          	jalr	350(ra) # 80000cd4 <release>


  return cnt*PGSIZE;
}
    80000b7e:	00c49513          	slli	a0,s1,0xc
    80000b82:	60e2                	ld	ra,24(sp)
    80000b84:	6442                	ld	s0,16(sp)
    80000b86:	64a2                	ld	s1,8(sp)
    80000b88:	6105                	addi	sp,sp,32
    80000b8a:	8082                	ret
  uint64 cnt = 0;
    80000b8c:	4481                	li	s1,0
    80000b8e:	b7c5                	j	80000b6e <acquire_freemem+0x28>

0000000080000b90 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b90:	1141                	addi	sp,sp,-16
    80000b92:	e422                	sd	s0,8(sp)
    80000b94:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b96:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b98:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b9c:	00053823          	sd	zero,16(a0)
}
    80000ba0:	6422                	ld	s0,8(sp)
    80000ba2:	0141                	addi	sp,sp,16
    80000ba4:	8082                	ret

0000000080000ba6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba6:	411c                	lw	a5,0(a0)
    80000ba8:	e399                	bnez	a5,80000bae <holding+0x8>
    80000baa:	4501                	li	a0,0
  return r;
}
    80000bac:	8082                	ret
{
    80000bae:	1101                	addi	sp,sp,-32
    80000bb0:	ec06                	sd	ra,24(sp)
    80000bb2:	e822                	sd	s0,16(sp)
    80000bb4:	e426                	sd	s1,8(sp)
    80000bb6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bb8:	6904                	ld	s1,16(a0)
    80000bba:	00001097          	auipc	ra,0x1
    80000bbe:	e20080e7          	jalr	-480(ra) # 800019da <mycpu>
    80000bc2:	40a48533          	sub	a0,s1,a0
    80000bc6:	00153513          	seqz	a0,a0
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret

0000000080000bd4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd4:	1101                	addi	sp,sp,-32
    80000bd6:	ec06                	sd	ra,24(sp)
    80000bd8:	e822                	sd	s0,16(sp)
    80000bda:	e426                	sd	s1,8(sp)
    80000bdc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bde:	100024f3          	csrr	s1,sstatus
    80000be2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000be8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bec:	00001097          	auipc	ra,0x1
    80000bf0:	dee080e7          	jalr	-530(ra) # 800019da <mycpu>
    80000bf4:	5d3c                	lw	a5,120(a0)
    80000bf6:	cf89                	beqz	a5,80000c10 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf8:	00001097          	auipc	ra,0x1
    80000bfc:	de2080e7          	jalr	-542(ra) # 800019da <mycpu>
    80000c00:	5d3c                	lw	a5,120(a0)
    80000c02:	2785                	addiw	a5,a5,1
    80000c04:	dd3c                	sw	a5,120(a0)
}
    80000c06:	60e2                	ld	ra,24(sp)
    80000c08:	6442                	ld	s0,16(sp)
    80000c0a:	64a2                	ld	s1,8(sp)
    80000c0c:	6105                	addi	sp,sp,32
    80000c0e:	8082                	ret
    mycpu()->intena = old;
    80000c10:	00001097          	auipc	ra,0x1
    80000c14:	dca080e7          	jalr	-566(ra) # 800019da <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c18:	8085                	srli	s1,s1,0x1
    80000c1a:	8885                	andi	s1,s1,1
    80000c1c:	dd64                	sw	s1,124(a0)
    80000c1e:	bfe9                	j	80000bf8 <push_off+0x24>

0000000080000c20 <acquire>:
{
    80000c20:	1101                	addi	sp,sp,-32
    80000c22:	ec06                	sd	ra,24(sp)
    80000c24:	e822                	sd	s0,16(sp)
    80000c26:	e426                	sd	s1,8(sp)
    80000c28:	1000                	addi	s0,sp,32
    80000c2a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c2c:	00000097          	auipc	ra,0x0
    80000c30:	fa8080e7          	jalr	-88(ra) # 80000bd4 <push_off>
  if(holding(lk))
    80000c34:	8526                	mv	a0,s1
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	f70080e7          	jalr	-144(ra) # 80000ba6 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c3e:	4705                	li	a4,1
  if(holding(lk))
    80000c40:	e115                	bnez	a0,80000c64 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c42:	87ba                	mv	a5,a4
    80000c44:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c48:	2781                	sext.w	a5,a5
    80000c4a:	ffe5                	bnez	a5,80000c42 <acquire+0x22>
  __sync_synchronize();
    80000c4c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c50:	00001097          	auipc	ra,0x1
    80000c54:	d8a080e7          	jalr	-630(ra) # 800019da <mycpu>
    80000c58:	e888                	sd	a0,16(s1)
}
    80000c5a:	60e2                	ld	ra,24(sp)
    80000c5c:	6442                	ld	s0,16(sp)
    80000c5e:	64a2                	ld	s1,8(sp)
    80000c60:	6105                	addi	sp,sp,32
    80000c62:	8082                	ret
    panic("acquire");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	40c50513          	addi	a0,a0,1036 # 80008070 <digits+0x30>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8d2080e7          	jalr	-1838(ra) # 8000053e <panic>

0000000080000c74 <pop_off>:

void
pop_off(void)
{
    80000c74:	1141                	addi	sp,sp,-16
    80000c76:	e406                	sd	ra,8(sp)
    80000c78:	e022                	sd	s0,0(sp)
    80000c7a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c7c:	00001097          	auipc	ra,0x1
    80000c80:	d5e080e7          	jalr	-674(ra) # 800019da <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c84:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c88:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c8a:	e78d                	bnez	a5,80000cb4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c8c:	5d3c                	lw	a5,120(a0)
    80000c8e:	02f05b63          	blez	a5,80000cc4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c92:	37fd                	addiw	a5,a5,-1
    80000c94:	0007871b          	sext.w	a4,a5
    80000c98:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c9a:	eb09                	bnez	a4,80000cac <pop_off+0x38>
    80000c9c:	5d7c                	lw	a5,124(a0)
    80000c9e:	c799                	beqz	a5,80000cac <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ca4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca8:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cac:	60a2                	ld	ra,8(sp)
    80000cae:	6402                	ld	s0,0(sp)
    80000cb0:	0141                	addi	sp,sp,16
    80000cb2:	8082                	ret
    panic("pop_off - interruptible");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3c450513          	addi	a0,a0,964 # 80008078 <digits+0x38>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	882080e7          	jalr	-1918(ra) # 8000053e <panic>
    panic("pop_off");
    80000cc4:	00007517          	auipc	a0,0x7
    80000cc8:	3cc50513          	addi	a0,a0,972 # 80008090 <digits+0x50>
    80000ccc:	00000097          	auipc	ra,0x0
    80000cd0:	872080e7          	jalr	-1934(ra) # 8000053e <panic>

0000000080000cd4 <release>:
{
    80000cd4:	1101                	addi	sp,sp,-32
    80000cd6:	ec06                	sd	ra,24(sp)
    80000cd8:	e822                	sd	s0,16(sp)
    80000cda:	e426                	sd	s1,8(sp)
    80000cdc:	1000                	addi	s0,sp,32
    80000cde:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	ec6080e7          	jalr	-314(ra) # 80000ba6 <holding>
    80000ce8:	c115                	beqz	a0,80000d0c <release+0x38>
  lk->cpu = 0;
    80000cea:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cee:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cf2:	0f50000f          	fence	iorw,ow
    80000cf6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cfa:	00000097          	auipc	ra,0x0
    80000cfe:	f7a080e7          	jalr	-134(ra) # 80000c74 <pop_off>
}
    80000d02:	60e2                	ld	ra,24(sp)
    80000d04:	6442                	ld	s0,16(sp)
    80000d06:	64a2                	ld	s1,8(sp)
    80000d08:	6105                	addi	sp,sp,32
    80000d0a:	8082                	ret
    panic("release");
    80000d0c:	00007517          	auipc	a0,0x7
    80000d10:	38c50513          	addi	a0,a0,908 # 80008098 <digits+0x58>
    80000d14:	00000097          	auipc	ra,0x0
    80000d18:	82a080e7          	jalr	-2006(ra) # 8000053e <panic>

0000000080000d1c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d1c:	1141                	addi	sp,sp,-16
    80000d1e:	e422                	sd	s0,8(sp)
    80000d20:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d22:	ca19                	beqz	a2,80000d38 <memset+0x1c>
    80000d24:	87aa                	mv	a5,a0
    80000d26:	1602                	slli	a2,a2,0x20
    80000d28:	9201                	srli	a2,a2,0x20
    80000d2a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d2e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d32:	0785                	addi	a5,a5,1
    80000d34:	fee79de3          	bne	a5,a4,80000d2e <memset+0x12>
  }
  return dst;
}
    80000d38:	6422                	ld	s0,8(sp)
    80000d3a:	0141                	addi	sp,sp,16
    80000d3c:	8082                	ret

0000000080000d3e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d3e:	1141                	addi	sp,sp,-16
    80000d40:	e422                	sd	s0,8(sp)
    80000d42:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d44:	ca05                	beqz	a2,80000d74 <memcmp+0x36>
    80000d46:	fff6069b          	addiw	a3,a2,-1
    80000d4a:	1682                	slli	a3,a3,0x20
    80000d4c:	9281                	srli	a3,a3,0x20
    80000d4e:	0685                	addi	a3,a3,1
    80000d50:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d52:	00054783          	lbu	a5,0(a0)
    80000d56:	0005c703          	lbu	a4,0(a1)
    80000d5a:	00e79863          	bne	a5,a4,80000d6a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d5e:	0505                	addi	a0,a0,1
    80000d60:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d62:	fed518e3          	bne	a0,a3,80000d52 <memcmp+0x14>
  }

  return 0;
    80000d66:	4501                	li	a0,0
    80000d68:	a019                	j	80000d6e <memcmp+0x30>
      return *s1 - *s2;
    80000d6a:	40e7853b          	subw	a0,a5,a4
}
    80000d6e:	6422                	ld	s0,8(sp)
    80000d70:	0141                	addi	sp,sp,16
    80000d72:	8082                	ret
  return 0;
    80000d74:	4501                	li	a0,0
    80000d76:	bfe5                	j	80000d6e <memcmp+0x30>

0000000080000d78 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d78:	1141                	addi	sp,sp,-16
    80000d7a:	e422                	sd	s0,8(sp)
    80000d7c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d7e:	c205                	beqz	a2,80000d9e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d80:	02a5e263          	bltu	a1,a0,80000da4 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	1602                	slli	a2,a2,0x20
    80000d86:	9201                	srli	a2,a2,0x20
    80000d88:	00c587b3          	add	a5,a1,a2
{
    80000d8c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d8e:	0585                	addi	a1,a1,1
    80000d90:	0705                	addi	a4,a4,1
    80000d92:	fff5c683          	lbu	a3,-1(a1)
    80000d96:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d9a:	fef59ae3          	bne	a1,a5,80000d8e <memmove+0x16>

  return dst;
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret
  if(s < d && s + n > d){
    80000da4:	02061693          	slli	a3,a2,0x20
    80000da8:	9281                	srli	a3,a3,0x20
    80000daa:	00d58733          	add	a4,a1,a3
    80000dae:	fce57be3          	bgeu	a0,a4,80000d84 <memmove+0xc>
    d += n;
    80000db2:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000db4:	fff6079b          	addiw	a5,a2,-1
    80000db8:	1782                	slli	a5,a5,0x20
    80000dba:	9381                	srli	a5,a5,0x20
    80000dbc:	fff7c793          	not	a5,a5
    80000dc0:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dc2:	177d                	addi	a4,a4,-1
    80000dc4:	16fd                	addi	a3,a3,-1
    80000dc6:	00074603          	lbu	a2,0(a4)
    80000dca:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dce:	fee79ae3          	bne	a5,a4,80000dc2 <memmove+0x4a>
    80000dd2:	b7f1                	j	80000d9e <memmove+0x26>

0000000080000dd4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd4:	1141                	addi	sp,sp,-16
    80000dd6:	e406                	sd	ra,8(sp)
    80000dd8:	e022                	sd	s0,0(sp)
    80000dda:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ddc:	00000097          	auipc	ra,0x0
    80000de0:	f9c080e7          	jalr	-100(ra) # 80000d78 <memmove>
}
    80000de4:	60a2                	ld	ra,8(sp)
    80000de6:	6402                	ld	s0,0(sp)
    80000de8:	0141                	addi	sp,sp,16
    80000dea:	8082                	ret

0000000080000dec <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dec:	1141                	addi	sp,sp,-16
    80000dee:	e422                	sd	s0,8(sp)
    80000df0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000df2:	ce11                	beqz	a2,80000e0e <strncmp+0x22>
    80000df4:	00054783          	lbu	a5,0(a0)
    80000df8:	cf89                	beqz	a5,80000e12 <strncmp+0x26>
    80000dfa:	0005c703          	lbu	a4,0(a1)
    80000dfe:	00f71a63          	bne	a4,a5,80000e12 <strncmp+0x26>
    n--, p++, q++;
    80000e02:	367d                	addiw	a2,a2,-1
    80000e04:	0505                	addi	a0,a0,1
    80000e06:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e08:	f675                	bnez	a2,80000df4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e0a:	4501                	li	a0,0
    80000e0c:	a809                	j	80000e1e <strncmp+0x32>
    80000e0e:	4501                	li	a0,0
    80000e10:	a039                	j	80000e1e <strncmp+0x32>
  if(n == 0)
    80000e12:	ca09                	beqz	a2,80000e24 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e14:	00054503          	lbu	a0,0(a0)
    80000e18:	0005c783          	lbu	a5,0(a1)
    80000e1c:	9d1d                	subw	a0,a0,a5
}
    80000e1e:	6422                	ld	s0,8(sp)
    80000e20:	0141                	addi	sp,sp,16
    80000e22:	8082                	ret
    return 0;
    80000e24:	4501                	li	a0,0
    80000e26:	bfe5                	j	80000e1e <strncmp+0x32>

0000000080000e28 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2e:	872a                	mv	a4,a0
    80000e30:	8832                	mv	a6,a2
    80000e32:	367d                	addiw	a2,a2,-1
    80000e34:	01005963          	blez	a6,80000e46 <strncpy+0x1e>
    80000e38:	0705                	addi	a4,a4,1
    80000e3a:	0005c783          	lbu	a5,0(a1)
    80000e3e:	fef70fa3          	sb	a5,-1(a4)
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	f7f5                	bnez	a5,80000e30 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e46:	86ba                	mv	a3,a4
    80000e48:	00c05c63          	blez	a2,80000e60 <strncpy+0x38>
    *s++ = 0;
    80000e4c:	0685                	addi	a3,a3,1
    80000e4e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e52:	fff6c793          	not	a5,a3
    80000e56:	9fb9                	addw	a5,a5,a4
    80000e58:	010787bb          	addw	a5,a5,a6
    80000e5c:	fef048e3          	bgtz	a5,80000e4c <strncpy+0x24>
  return os;
}
    80000e60:	6422                	ld	s0,8(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret

0000000080000e66 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e66:	1141                	addi	sp,sp,-16
    80000e68:	e422                	sd	s0,8(sp)
    80000e6a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e6c:	02c05363          	blez	a2,80000e92 <safestrcpy+0x2c>
    80000e70:	fff6069b          	addiw	a3,a2,-1
    80000e74:	1682                	slli	a3,a3,0x20
    80000e76:	9281                	srli	a3,a3,0x20
    80000e78:	96ae                	add	a3,a3,a1
    80000e7a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e7c:	00d58963          	beq	a1,a3,80000e8e <safestrcpy+0x28>
    80000e80:	0585                	addi	a1,a1,1
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff5c703          	lbu	a4,-1(a1)
    80000e88:	fee78fa3          	sb	a4,-1(a5)
    80000e8c:	fb65                	bnez	a4,80000e7c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e92:	6422                	ld	s0,8(sp)
    80000e94:	0141                	addi	sp,sp,16
    80000e96:	8082                	ret

0000000080000e98 <strlen>:

int
strlen(const char *s)
{
    80000e98:	1141                	addi	sp,sp,-16
    80000e9a:	e422                	sd	s0,8(sp)
    80000e9c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9e:	00054783          	lbu	a5,0(a0)
    80000ea2:	cf91                	beqz	a5,80000ebe <strlen+0x26>
    80000ea4:	0505                	addi	a0,a0,1
    80000ea6:	87aa                	mv	a5,a0
    80000ea8:	4685                	li	a3,1
    80000eaa:	9e89                	subw	a3,a3,a0
    80000eac:	00f6853b          	addw	a0,a3,a5
    80000eb0:	0785                	addi	a5,a5,1
    80000eb2:	fff7c703          	lbu	a4,-1(a5)
    80000eb6:	fb7d                	bnez	a4,80000eac <strlen+0x14>
    ;
  return n;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ebe:	4501                	li	a0,0
    80000ec0:	bfe5                	j	80000eb8 <strlen+0x20>

0000000080000ec2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ec2:	1141                	addi	sp,sp,-16
    80000ec4:	e406                	sd	ra,8(sp)
    80000ec6:	e022                	sd	s0,0(sp)
    80000ec8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	b00080e7          	jalr	-1280(ra) # 800019ca <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ed2:	00008717          	auipc	a4,0x8
    80000ed6:	b5670713          	addi	a4,a4,-1194 # 80008a28 <started>
  if(cpuid() == 0){
    80000eda:	c139                	beqz	a0,80000f20 <main+0x5e>
    while(started == 0)
    80000edc:	431c                	lw	a5,0(a4)
    80000ede:	2781                	sext.w	a5,a5
    80000ee0:	dff5                	beqz	a5,80000edc <main+0x1a>
      ;
    __sync_synchronize();
    80000ee2:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	ae4080e7          	jalr	-1308(ra) # 800019ca <cpuid>
    80000eee:	85aa                	mv	a1,a0
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1c850513          	addi	a0,a0,456 # 800080b8 <digits+0x78>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	690080e7          	jalr	1680(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000f00:	00000097          	auipc	ra,0x0
    80000f04:	0d8080e7          	jalr	216(ra) # 80000fd8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	7ec080e7          	jalr	2028(ra) # 800026f4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f10:	00005097          	auipc	ra,0x5
    80000f14:	e40080e7          	jalr	-448(ra) # 80005d50 <plicinithart>
  }

  scheduler();        
    80000f18:	00001097          	auipc	ra,0x1
    80000f1c:	fe0080e7          	jalr	-32(ra) # 80001ef8 <scheduler>
    consoleinit();
    80000f20:	fffff097          	auipc	ra,0xfffff
    80000f24:	530080e7          	jalr	1328(ra) # 80000450 <consoleinit>
    printfinit();
    80000f28:	00000097          	auipc	ra,0x0
    80000f2c:	840080e7          	jalr	-1984(ra) # 80000768 <printfinit>
    printf("\n");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	19850513          	addi	a0,a0,408 # 800080c8 <digits+0x88>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	16050513          	addi	a0,a0,352 # 800080a0 <digits+0x60>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	640080e7          	jalr	1600(ra) # 80000588 <printf>
    printf("\n");
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	17850513          	addi	a0,a0,376 # 800080c8 <digits+0x88>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	630080e7          	jalr	1584(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	b4a080e7          	jalr	-1206(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f68:	00000097          	auipc	ra,0x0
    80000f6c:	326080e7          	jalr	806(ra) # 8000128e <kvminit>
    kvminithart();   // turn on paging
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	068080e7          	jalr	104(ra) # 80000fd8 <kvminithart>
    procinit();      // process table
    80000f78:	00001097          	auipc	ra,0x1
    80000f7c:	99e080e7          	jalr	-1634(ra) # 80001916 <procinit>
    trapinit();      // trap vectors
    80000f80:	00001097          	auipc	ra,0x1
    80000f84:	74c080e7          	jalr	1868(ra) # 800026cc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	76c080e7          	jalr	1900(ra) # 800026f4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f90:	00005097          	auipc	ra,0x5
    80000f94:	daa080e7          	jalr	-598(ra) # 80005d3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f98:	00005097          	auipc	ra,0x5
    80000f9c:	db8080e7          	jalr	-584(ra) # 80005d50 <plicinithart>
    binit();         // buffer cache
    80000fa0:	00002097          	auipc	ra,0x2
    80000fa4:	f60080e7          	jalr	-160(ra) # 80002f00 <binit>
    iinit();         // inode table
    80000fa8:	00002097          	auipc	ra,0x2
    80000fac:	604080e7          	jalr	1540(ra) # 800035ac <iinit>
    fileinit();      // file table
    80000fb0:	00003097          	auipc	ra,0x3
    80000fb4:	5a2080e7          	jalr	1442(ra) # 80004552 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb8:	00005097          	auipc	ra,0x5
    80000fbc:	ea0080e7          	jalr	-352(ra) # 80005e58 <virtio_disk_init>
    userinit();      // first user process
    80000fc0:	00001097          	auipc	ra,0x1
    80000fc4:	d12080e7          	jalr	-750(ra) # 80001cd2 <userinit>
    __sync_synchronize();
    80000fc8:	0ff0000f          	fence
    started = 1;
    80000fcc:	4785                	li	a5,1
    80000fce:	00008717          	auipc	a4,0x8
    80000fd2:	a4f72d23          	sw	a5,-1446(a4) # 80008a28 <started>
    80000fd6:	b789                	j	80000f18 <main+0x56>

0000000080000fd8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd8:	1141                	addi	sp,sp,-16
    80000fda:	e422                	sd	s0,8(sp)
    80000fdc:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fde:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	a4e7b783          	ld	a5,-1458(a5) # 80008a30 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0aa50513          	addi	a0,a0,170 # 800080d0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	510080e7          	jalr	1296(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	aac080e7          	jalr	-1364(ra) # 80000ae6 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cd2080e7          	jalr	-814(ra) # 80000d1c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	00a7d513          	srli	a0,a5,0xa
    800010e0:	0532                	slli	a0,a0,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010e8:	715d                	addi	sp,sp,-80
    800010ea:	e486                	sd	ra,72(sp)
    800010ec:	e0a2                	sd	s0,64(sp)
    800010ee:	fc26                	sd	s1,56(sp)
    800010f0:	f84a                	sd	s2,48(sp)
    800010f2:	f44e                	sd	s3,40(sp)
    800010f4:	f052                	sd	s4,32(sp)
    800010f6:	ec56                	sd	s5,24(sp)
    800010f8:	e85a                	sd	s6,16(sp)
    800010fa:	e45e                	sd	s7,8(sp)
    800010fc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010fe:	c639                	beqz	a2,8000114c <mappages+0x64>
    80001100:	8aaa                	mv	s5,a0
    80001102:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001104:	77fd                	lui	a5,0xfffff
    80001106:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000110a:	15fd                	addi	a1,a1,-1
    8000110c:	00c589b3          	add	s3,a1,a2
    80001110:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001114:	8952                	mv	s2,s4
    80001116:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000111a:	6b85                	lui	s7,0x1
    8000111c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001120:	4605                	li	a2,1
    80001122:	85ca                	mv	a1,s2
    80001124:	8556                	mv	a0,s5
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	eda080e7          	jalr	-294(ra) # 80001000 <walk>
    8000112e:	cd1d                	beqz	a0,8000116c <mappages+0x84>
    if(*pte & PTE_V)
    80001130:	611c                	ld	a5,0(a0)
    80001132:	8b85                	andi	a5,a5,1
    80001134:	e785                	bnez	a5,8000115c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001136:	80b1                	srli	s1,s1,0xc
    80001138:	04aa                	slli	s1,s1,0xa
    8000113a:	0164e4b3          	or	s1,s1,s6
    8000113e:	0014e493          	ori	s1,s1,1
    80001142:	e104                	sd	s1,0(a0)
    if(a == last)
    80001144:	05390063          	beq	s2,s3,80001184 <mappages+0x9c>
    a += PGSIZE;
    80001148:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114a:	bfc9                	j	8000111c <mappages+0x34>
    panic("mappages: size");
    8000114c:	00007517          	auipc	a0,0x7
    80001150:	f8c50513          	addi	a0,a0,-116 # 800080d8 <digits+0x98>
    80001154:	fffff097          	auipc	ra,0xfffff
    80001158:	3ea080e7          	jalr	1002(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000115c:	00007517          	auipc	a0,0x7
    80001160:	f8c50513          	addi	a0,a0,-116 # 800080e8 <digits+0xa8>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	3da080e7          	jalr	986(ra) # 8000053e <panic>
      return -1;
    8000116c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000116e:	60a6                	ld	ra,72(sp)
    80001170:	6406                	ld	s0,64(sp)
    80001172:	74e2                	ld	s1,56(sp)
    80001174:	7942                	ld	s2,48(sp)
    80001176:	79a2                	ld	s3,40(sp)
    80001178:	7a02                	ld	s4,32(sp)
    8000117a:	6ae2                	ld	s5,24(sp)
    8000117c:	6b42                	ld	s6,16(sp)
    8000117e:	6ba2                	ld	s7,8(sp)
    80001180:	6161                	addi	sp,sp,80
    80001182:	8082                	ret
  return 0;
    80001184:	4501                	li	a0,0
    80001186:	b7e5                	j	8000116e <mappages+0x86>

0000000080001188 <kvmmap>:
{
    80001188:	1141                	addi	sp,sp,-16
    8000118a:	e406                	sd	ra,8(sp)
    8000118c:	e022                	sd	s0,0(sp)
    8000118e:	0800                	addi	s0,sp,16
    80001190:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001192:	86b2                	mv	a3,a2
    80001194:	863e                	mv	a2,a5
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	f52080e7          	jalr	-174(ra) # 800010e8 <mappages>
    8000119e:	e509                	bnez	a0,800011a8 <kvmmap+0x20>
}
    800011a0:	60a2                	ld	ra,8(sp)
    800011a2:	6402                	ld	s0,0(sp)
    800011a4:	0141                	addi	sp,sp,16
    800011a6:	8082                	ret
    panic("kvmmap");
    800011a8:	00007517          	auipc	a0,0x7
    800011ac:	f5050513          	addi	a0,a0,-176 # 800080f8 <digits+0xb8>
    800011b0:	fffff097          	auipc	ra,0xfffff
    800011b4:	38e080e7          	jalr	910(ra) # 8000053e <panic>

00000000800011b8 <kvmmake>:
{
    800011b8:	1101                	addi	sp,sp,-32
    800011ba:	ec06                	sd	ra,24(sp)
    800011bc:	e822                	sd	s0,16(sp)
    800011be:	e426                	sd	s1,8(sp)
    800011c0:	e04a                	sd	s2,0(sp)
    800011c2:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	922080e7          	jalr	-1758(ra) # 80000ae6 <kalloc>
    800011cc:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011ce:	6605                	lui	a2,0x1
    800011d0:	4581                	li	a1,0
    800011d2:	00000097          	auipc	ra,0x0
    800011d6:	b4a080e7          	jalr	-1206(ra) # 80000d1c <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011da:	4719                	li	a4,6
    800011dc:	6685                	lui	a3,0x1
    800011de:	10000637          	lui	a2,0x10000
    800011e2:	100005b7          	lui	a1,0x10000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	fa0080e7          	jalr	-96(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	6685                	lui	a3,0x1
    800011f4:	10001637          	lui	a2,0x10001
    800011f8:	100015b7          	lui	a1,0x10001
    800011fc:	8526                	mv	a0,s1
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f8a080e7          	jalr	-118(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001206:	4719                	li	a4,6
    80001208:	004006b7          	lui	a3,0x400
    8000120c:	0c000637          	lui	a2,0xc000
    80001210:	0c0005b7          	lui	a1,0xc000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	f72080e7          	jalr	-142(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000121e:	00007917          	auipc	s2,0x7
    80001222:	de290913          	addi	s2,s2,-542 # 80008000 <etext>
    80001226:	4729                	li	a4,10
    80001228:	80007697          	auipc	a3,0x80007
    8000122c:	dd868693          	addi	a3,a3,-552 # 8000 <_entry-0x7fff8000>
    80001230:	4605                	li	a2,1
    80001232:	067e                	slli	a2,a2,0x1f
    80001234:	85b2                	mv	a1,a2
    80001236:	8526                	mv	a0,s1
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	f50080e7          	jalr	-176(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001240:	4719                	li	a4,6
    80001242:	46c5                	li	a3,17
    80001244:	06ee                	slli	a3,a3,0x1b
    80001246:	412686b3          	sub	a3,a3,s2
    8000124a:	864a                	mv	a2,s2
    8000124c:	85ca                	mv	a1,s2
    8000124e:	8526                	mv	a0,s1
    80001250:	00000097          	auipc	ra,0x0
    80001254:	f38080e7          	jalr	-200(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001258:	4729                	li	a4,10
    8000125a:	6685                	lui	a3,0x1
    8000125c:	00006617          	auipc	a2,0x6
    80001260:	da460613          	addi	a2,a2,-604 # 80007000 <_trampoline>
    80001264:	040005b7          	lui	a1,0x4000
    80001268:	15fd                	addi	a1,a1,-1
    8000126a:	05b2                	slli	a1,a1,0xc
    8000126c:	8526                	mv	a0,s1
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f1a080e7          	jalr	-230(ra) # 80001188 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001276:	8526                	mv	a0,s1
    80001278:	00000097          	auipc	ra,0x0
    8000127c:	608080e7          	jalr	1544(ra) # 80001880 <proc_mapstacks>
}
    80001280:	8526                	mv	a0,s1
    80001282:	60e2                	ld	ra,24(sp)
    80001284:	6442                	ld	s0,16(sp)
    80001286:	64a2                	ld	s1,8(sp)
    80001288:	6902                	ld	s2,0(sp)
    8000128a:	6105                	addi	sp,sp,32
    8000128c:	8082                	ret

000000008000128e <kvminit>:
{
    8000128e:	1141                	addi	sp,sp,-16
    80001290:	e406                	sd	ra,8(sp)
    80001292:	e022                	sd	s0,0(sp)
    80001294:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001296:	00000097          	auipc	ra,0x0
    8000129a:	f22080e7          	jalr	-222(ra) # 800011b8 <kvmmake>
    8000129e:	00007797          	auipc	a5,0x7
    800012a2:	78a7b923          	sd	a0,1938(a5) # 80008a30 <kernel_pagetable>
}
    800012a6:	60a2                	ld	ra,8(sp)
    800012a8:	6402                	ld	s0,0(sp)
    800012aa:	0141                	addi	sp,sp,16
    800012ac:	8082                	ret

00000000800012ae <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ae:	715d                	addi	sp,sp,-80
    800012b0:	e486                	sd	ra,72(sp)
    800012b2:	e0a2                	sd	s0,64(sp)
    800012b4:	fc26                	sd	s1,56(sp)
    800012b6:	f84a                	sd	s2,48(sp)
    800012b8:	f44e                	sd	s3,40(sp)
    800012ba:	f052                	sd	s4,32(sp)
    800012bc:	ec56                	sd	s5,24(sp)
    800012be:	e85a                	sd	s6,16(sp)
    800012c0:	e45e                	sd	s7,8(sp)
    800012c2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c4:	03459793          	slli	a5,a1,0x34
    800012c8:	e795                	bnez	a5,800012f4 <uvmunmap+0x46>
    800012ca:	8a2a                	mv	s4,a0
    800012cc:	892e                	mv	s2,a1
    800012ce:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d0:	0632                	slli	a2,a2,0xc
    800012d2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d8:	6b05                	lui	s6,0x1
    800012da:	0735e263          	bltu	a1,s3,8000133e <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012de:	60a6                	ld	ra,72(sp)
    800012e0:	6406                	ld	s0,64(sp)
    800012e2:	74e2                	ld	s1,56(sp)
    800012e4:	7942                	ld	s2,48(sp)
    800012e6:	79a2                	ld	s3,40(sp)
    800012e8:	7a02                	ld	s4,32(sp)
    800012ea:	6ae2                	ld	s5,24(sp)
    800012ec:	6b42                	ld	s6,16(sp)
    800012ee:	6ba2                	ld	s7,8(sp)
    800012f0:	6161                	addi	sp,sp,80
    800012f2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e0c50513          	addi	a0,a0,-500 # 80008100 <digits+0xc0>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    80001304:	00007517          	auipc	a0,0x7
    80001308:	e1450513          	addi	a0,a0,-492 # 80008118 <digits+0xd8>
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	232080e7          	jalr	562(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001314:	00007517          	auipc	a0,0x7
    80001318:	e1450513          	addi	a0,a0,-492 # 80008128 <digits+0xe8>
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	222080e7          	jalr	546(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001324:	00007517          	auipc	a0,0x7
    80001328:	e1c50513          	addi	a0,a0,-484 # 80008140 <digits+0x100>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	212080e7          	jalr	530(ra) # 8000053e <panic>
    *pte = 0;
    80001334:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001338:	995a                	add	s2,s2,s6
    8000133a:	fb3972e3          	bgeu	s2,s3,800012de <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000133e:	4601                	li	a2,0
    80001340:	85ca                	mv	a1,s2
    80001342:	8552                	mv	a0,s4
    80001344:	00000097          	auipc	ra,0x0
    80001348:	cbc080e7          	jalr	-836(ra) # 80001000 <walk>
    8000134c:	84aa                	mv	s1,a0
    8000134e:	d95d                	beqz	a0,80001304 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001350:	6108                	ld	a0,0(a0)
    80001352:	00157793          	andi	a5,a0,1
    80001356:	dfdd                	beqz	a5,80001314 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001358:	3ff57793          	andi	a5,a0,1023
    8000135c:	fd7784e3          	beq	a5,s7,80001324 <uvmunmap+0x76>
    if(do_free){
    80001360:	fc0a8ae3          	beqz	s5,80001334 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001364:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001366:	0532                	slli	a0,a0,0xc
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	682080e7          	jalr	1666(ra) # 800009ea <kfree>
    80001370:	b7d1                	j	80001334 <uvmunmap+0x86>

0000000080001372 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001372:	1101                	addi	sp,sp,-32
    80001374:	ec06                	sd	ra,24(sp)
    80001376:	e822                	sd	s0,16(sp)
    80001378:	e426                	sd	s1,8(sp)
    8000137a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000137c:	fffff097          	auipc	ra,0xfffff
    80001380:	76a080e7          	jalr	1898(ra) # 80000ae6 <kalloc>
    80001384:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001386:	c519                	beqz	a0,80001394 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001388:	6605                	lui	a2,0x1
    8000138a:	4581                	li	a1,0
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	990080e7          	jalr	-1648(ra) # 80000d1c <memset>
  return pagetable;
}
    80001394:	8526                	mv	a0,s1
    80001396:	60e2                	ld	ra,24(sp)
    80001398:	6442                	ld	s0,16(sp)
    8000139a:	64a2                	ld	s1,8(sp)
    8000139c:	6105                	addi	sp,sp,32
    8000139e:	8082                	ret

00000000800013a0 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013a0:	7179                	addi	sp,sp,-48
    800013a2:	f406                	sd	ra,40(sp)
    800013a4:	f022                	sd	s0,32(sp)
    800013a6:	ec26                	sd	s1,24(sp)
    800013a8:	e84a                	sd	s2,16(sp)
    800013aa:	e44e                	sd	s3,8(sp)
    800013ac:	e052                	sd	s4,0(sp)
    800013ae:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013b0:	6785                	lui	a5,0x1
    800013b2:	04f67863          	bgeu	a2,a5,80001402 <uvmfirst+0x62>
    800013b6:	8a2a                	mv	s4,a0
    800013b8:	89ae                	mv	s3,a1
    800013ba:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	72a080e7          	jalr	1834(ra) # 80000ae6 <kalloc>
    800013c4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c6:	6605                	lui	a2,0x1
    800013c8:	4581                	li	a1,0
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	952080e7          	jalr	-1710(ra) # 80000d1c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013d2:	4779                	li	a4,30
    800013d4:	86ca                	mv	a3,s2
    800013d6:	6605                	lui	a2,0x1
    800013d8:	4581                	li	a1,0
    800013da:	8552                	mv	a0,s4
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	d0c080e7          	jalr	-756(ra) # 800010e8 <mappages>
  memmove(mem, src, sz);
    800013e4:	8626                	mv	a2,s1
    800013e6:	85ce                	mv	a1,s3
    800013e8:	854a                	mv	a0,s2
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	98e080e7          	jalr	-1650(ra) # 80000d78 <memmove>
}
    800013f2:	70a2                	ld	ra,40(sp)
    800013f4:	7402                	ld	s0,32(sp)
    800013f6:	64e2                	ld	s1,24(sp)
    800013f8:	6942                	ld	s2,16(sp)
    800013fa:	69a2                	ld	s3,8(sp)
    800013fc:	6a02                	ld	s4,0(sp)
    800013fe:	6145                	addi	sp,sp,48
    80001400:	8082                	ret
    panic("uvmfirst: more than a page");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d5650513          	addi	a0,a0,-682 # 80008158 <digits+0x118>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	134080e7          	jalr	308(ra) # 8000053e <panic>

0000000080001412 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001412:	1101                	addi	sp,sp,-32
    80001414:	ec06                	sd	ra,24(sp)
    80001416:	e822                	sd	s0,16(sp)
    80001418:	e426                	sd	s1,8(sp)
    8000141a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000141c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000141e:	00b67d63          	bgeu	a2,a1,80001438 <uvmdealloc+0x26>
    80001422:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001424:	6785                	lui	a5,0x1
    80001426:	17fd                	addi	a5,a5,-1
    80001428:	00f60733          	add	a4,a2,a5
    8000142c:	767d                	lui	a2,0xfffff
    8000142e:	8f71                	and	a4,a4,a2
    80001430:	97ae                	add	a5,a5,a1
    80001432:	8ff1                	and	a5,a5,a2
    80001434:	00f76863          	bltu	a4,a5,80001444 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001438:	8526                	mv	a0,s1
    8000143a:	60e2                	ld	ra,24(sp)
    8000143c:	6442                	ld	s0,16(sp)
    8000143e:	64a2                	ld	s1,8(sp)
    80001440:	6105                	addi	sp,sp,32
    80001442:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001444:	8f99                	sub	a5,a5,a4
    80001446:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001448:	4685                	li	a3,1
    8000144a:	0007861b          	sext.w	a2,a5
    8000144e:	85ba                	mv	a1,a4
    80001450:	00000097          	auipc	ra,0x0
    80001454:	e5e080e7          	jalr	-418(ra) # 800012ae <uvmunmap>
    80001458:	b7c5                	j	80001438 <uvmdealloc+0x26>

000000008000145a <uvmalloc>:
  if(newsz < oldsz)
    8000145a:	0ab66563          	bltu	a2,a1,80001504 <uvmalloc+0xaa>
{
    8000145e:	7139                	addi	sp,sp,-64
    80001460:	fc06                	sd	ra,56(sp)
    80001462:	f822                	sd	s0,48(sp)
    80001464:	f426                	sd	s1,40(sp)
    80001466:	f04a                	sd	s2,32(sp)
    80001468:	ec4e                	sd	s3,24(sp)
    8000146a:	e852                	sd	s4,16(sp)
    8000146c:	e456                	sd	s5,8(sp)
    8000146e:	e05a                	sd	s6,0(sp)
    80001470:	0080                	addi	s0,sp,64
    80001472:	8aaa                	mv	s5,a0
    80001474:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001476:	6985                	lui	s3,0x1
    80001478:	19fd                	addi	s3,s3,-1
    8000147a:	95ce                	add	a1,a1,s3
    8000147c:	79fd                	lui	s3,0xfffff
    8000147e:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	08c9f363          	bgeu	s3,a2,80001508 <uvmalloc+0xae>
    80001486:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001488:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000148c:	fffff097          	auipc	ra,0xfffff
    80001490:	65a080e7          	jalr	1626(ra) # 80000ae6 <kalloc>
    80001494:	84aa                	mv	s1,a0
    if(mem == 0){
    80001496:	c51d                	beqz	a0,800014c4 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001498:	6605                	lui	a2,0x1
    8000149a:	4581                	li	a1,0
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	880080e7          	jalr	-1920(ra) # 80000d1c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014a4:	875a                	mv	a4,s6
    800014a6:	86a6                	mv	a3,s1
    800014a8:	6605                	lui	a2,0x1
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	c3a080e7          	jalr	-966(ra) # 800010e8 <mappages>
    800014b6:	e90d                	bnez	a0,800014e8 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b8:	6785                	lui	a5,0x1
    800014ba:	993e                	add	s2,s2,a5
    800014bc:	fd4968e3          	bltu	s2,s4,8000148c <uvmalloc+0x32>
  return newsz;
    800014c0:	8552                	mv	a0,s4
    800014c2:	a809                	j	800014d4 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f48080e7          	jalr	-184(ra) # 80001412 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
}
    800014d4:	70e2                	ld	ra,56(sp)
    800014d6:	7442                	ld	s0,48(sp)
    800014d8:	74a2                	ld	s1,40(sp)
    800014da:	7902                	ld	s2,32(sp)
    800014dc:	69e2                	ld	s3,24(sp)
    800014de:	6a42                	ld	s4,16(sp)
    800014e0:	6aa2                	ld	s5,8(sp)
    800014e2:	6b02                	ld	s6,0(sp)
    800014e4:	6121                	addi	sp,sp,64
    800014e6:	8082                	ret
      kfree(mem);
    800014e8:	8526                	mv	a0,s1
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	500080e7          	jalr	1280(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f1a080e7          	jalr	-230(ra) # 80001412 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
    80001502:	bfc9                	j	800014d4 <uvmalloc+0x7a>
    return oldsz;
    80001504:	852e                	mv	a0,a1
}
    80001506:	8082                	ret
  return newsz;
    80001508:	8532                	mv	a0,a2
    8000150a:	b7e9                	j	800014d4 <uvmalloc+0x7a>

000000008000150c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000150c:	7179                	addi	sp,sp,-48
    8000150e:	f406                	sd	ra,40(sp)
    80001510:	f022                	sd	s0,32(sp)
    80001512:	ec26                	sd	s1,24(sp)
    80001514:	e84a                	sd	s2,16(sp)
    80001516:	e44e                	sd	s3,8(sp)
    80001518:	e052                	sd	s4,0(sp)
    8000151a:	1800                	addi	s0,sp,48
    8000151c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000151e:	84aa                	mv	s1,a0
    80001520:	6905                	lui	s2,0x1
    80001522:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001524:	4985                	li	s3,1
    80001526:	a821                	j	8000153e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001528:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000152a:	0532                	slli	a0,a0,0xc
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	fe0080e7          	jalr	-32(ra) # 8000150c <freewalk>
      pagetable[i] = 0;
    80001534:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001538:	04a1                	addi	s1,s1,8
    8000153a:	03248163          	beq	s1,s2,8000155c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000153e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001540:	00f57793          	andi	a5,a0,15
    80001544:	ff3782e3          	beq	a5,s3,80001528 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001548:	8905                	andi	a0,a0,1
    8000154a:	d57d                	beqz	a0,80001538 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000154c:	00007517          	auipc	a0,0x7
    80001550:	c2c50513          	addi	a0,a0,-980 # 80008178 <digits+0x138>
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	fea080e7          	jalr	-22(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000155c:	8552                	mv	a0,s4
    8000155e:	fffff097          	auipc	ra,0xfffff
    80001562:	48c080e7          	jalr	1164(ra) # 800009ea <kfree>
}
    80001566:	70a2                	ld	ra,40(sp)
    80001568:	7402                	ld	s0,32(sp)
    8000156a:	64e2                	ld	s1,24(sp)
    8000156c:	6942                	ld	s2,16(sp)
    8000156e:	69a2                	ld	s3,8(sp)
    80001570:	6a02                	ld	s4,0(sp)
    80001572:	6145                	addi	sp,sp,48
    80001574:	8082                	ret

0000000080001576 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001576:	1101                	addi	sp,sp,-32
    80001578:	ec06                	sd	ra,24(sp)
    8000157a:	e822                	sd	s0,16(sp)
    8000157c:	e426                	sd	s1,8(sp)
    8000157e:	1000                	addi	s0,sp,32
    80001580:	84aa                	mv	s1,a0
  if(sz > 0)
    80001582:	e999                	bnez	a1,80001598 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001584:	8526                	mv	a0,s1
    80001586:	00000097          	auipc	ra,0x0
    8000158a:	f86080e7          	jalr	-122(ra) # 8000150c <freewalk>
}
    8000158e:	60e2                	ld	ra,24(sp)
    80001590:	6442                	ld	s0,16(sp)
    80001592:	64a2                	ld	s1,8(sp)
    80001594:	6105                	addi	sp,sp,32
    80001596:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001598:	6605                	lui	a2,0x1
    8000159a:	167d                	addi	a2,a2,-1
    8000159c:	962e                	add	a2,a2,a1
    8000159e:	4685                	li	a3,1
    800015a0:	8231                	srli	a2,a2,0xc
    800015a2:	4581                	li	a1,0
    800015a4:	00000097          	auipc	ra,0x0
    800015a8:	d0a080e7          	jalr	-758(ra) # 800012ae <uvmunmap>
    800015ac:	bfe1                	j	80001584 <uvmfree+0xe>

00000000800015ae <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015ae:	c679                	beqz	a2,8000167c <uvmcopy+0xce>
{
    800015b0:	715d                	addi	sp,sp,-80
    800015b2:	e486                	sd	ra,72(sp)
    800015b4:	e0a2                	sd	s0,64(sp)
    800015b6:	fc26                	sd	s1,56(sp)
    800015b8:	f84a                	sd	s2,48(sp)
    800015ba:	f44e                	sd	s3,40(sp)
    800015bc:	f052                	sd	s4,32(sp)
    800015be:	ec56                	sd	s5,24(sp)
    800015c0:	e85a                	sd	s6,16(sp)
    800015c2:	e45e                	sd	s7,8(sp)
    800015c4:	0880                	addi	s0,sp,80
    800015c6:	8b2a                	mv	s6,a0
    800015c8:	8aae                	mv	s5,a1
    800015ca:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015cc:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015ce:	4601                	li	a2,0
    800015d0:	85ce                	mv	a1,s3
    800015d2:	855a                	mv	a0,s6
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	a2c080e7          	jalr	-1492(ra) # 80001000 <walk>
    800015dc:	c531                	beqz	a0,80001628 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015de:	6118                	ld	a4,0(a0)
    800015e0:	00177793          	andi	a5,a4,1
    800015e4:	cbb1                	beqz	a5,80001638 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015e6:	00a75593          	srli	a1,a4,0xa
    800015ea:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ee:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	4f4080e7          	jalr	1268(ra) # 80000ae6 <kalloc>
    800015fa:	892a                	mv	s2,a0
    800015fc:	c939                	beqz	a0,80001652 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015fe:	6605                	lui	a2,0x1
    80001600:	85de                	mv	a1,s7
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	776080e7          	jalr	1910(ra) # 80000d78 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000160a:	8726                	mv	a4,s1
    8000160c:	86ca                	mv	a3,s2
    8000160e:	6605                	lui	a2,0x1
    80001610:	85ce                	mv	a1,s3
    80001612:	8556                	mv	a0,s5
    80001614:	00000097          	auipc	ra,0x0
    80001618:	ad4080e7          	jalr	-1324(ra) # 800010e8 <mappages>
    8000161c:	e515                	bnez	a0,80001648 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000161e:	6785                	lui	a5,0x1
    80001620:	99be                	add	s3,s3,a5
    80001622:	fb49e6e3          	bltu	s3,s4,800015ce <uvmcopy+0x20>
    80001626:	a081                	j	80001666 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001628:	00007517          	auipc	a0,0x7
    8000162c:	b6050513          	addi	a0,a0,-1184 # 80008188 <digits+0x148>
    80001630:	fffff097          	auipc	ra,0xfffff
    80001634:	f0e080e7          	jalr	-242(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001638:	00007517          	auipc	a0,0x7
    8000163c:	b7050513          	addi	a0,a0,-1168 # 800081a8 <digits+0x168>
    80001640:	fffff097          	auipc	ra,0xfffff
    80001644:	efe080e7          	jalr	-258(ra) # 8000053e <panic>
      kfree(mem);
    80001648:	854a                	mv	a0,s2
    8000164a:	fffff097          	auipc	ra,0xfffff
    8000164e:	3a0080e7          	jalr	928(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001652:	4685                	li	a3,1
    80001654:	00c9d613          	srli	a2,s3,0xc
    80001658:	4581                	li	a1,0
    8000165a:	8556                	mv	a0,s5
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	c52080e7          	jalr	-942(ra) # 800012ae <uvmunmap>
  return -1;
    80001664:	557d                	li	a0,-1
}
    80001666:	60a6                	ld	ra,72(sp)
    80001668:	6406                	ld	s0,64(sp)
    8000166a:	74e2                	ld	s1,56(sp)
    8000166c:	7942                	ld	s2,48(sp)
    8000166e:	79a2                	ld	s3,40(sp)
    80001670:	7a02                	ld	s4,32(sp)
    80001672:	6ae2                	ld	s5,24(sp)
    80001674:	6b42                	ld	s6,16(sp)
    80001676:	6ba2                	ld	s7,8(sp)
    80001678:	6161                	addi	sp,sp,80
    8000167a:	8082                	ret
  return 0;
    8000167c:	4501                	li	a0,0
}
    8000167e:	8082                	ret

0000000080001680 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001680:	1141                	addi	sp,sp,-16
    80001682:	e406                	sd	ra,8(sp)
    80001684:	e022                	sd	s0,0(sp)
    80001686:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001688:	4601                	li	a2,0
    8000168a:	00000097          	auipc	ra,0x0
    8000168e:	976080e7          	jalr	-1674(ra) # 80001000 <walk>
  if(pte == 0)
    80001692:	c901                	beqz	a0,800016a2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001694:	611c                	ld	a5,0(a0)
    80001696:	9bbd                	andi	a5,a5,-17
    80001698:	e11c                	sd	a5,0(a0)
}
    8000169a:	60a2                	ld	ra,8(sp)
    8000169c:	6402                	ld	s0,0(sp)
    8000169e:	0141                	addi	sp,sp,16
    800016a0:	8082                	ret
    panic("uvmclear");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	b2650513          	addi	a0,a0,-1242 # 800081c8 <digits+0x188>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	e94080e7          	jalr	-364(ra) # 8000053e <panic>

00000000800016b2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016b2:	c6bd                	beqz	a3,80001720 <copyout+0x6e>
{
    800016b4:	715d                	addi	sp,sp,-80
    800016b6:	e486                	sd	ra,72(sp)
    800016b8:	e0a2                	sd	s0,64(sp)
    800016ba:	fc26                	sd	s1,56(sp)
    800016bc:	f84a                	sd	s2,48(sp)
    800016be:	f44e                	sd	s3,40(sp)
    800016c0:	f052                	sd	s4,32(sp)
    800016c2:	ec56                	sd	s5,24(sp)
    800016c4:	e85a                	sd	s6,16(sp)
    800016c6:	e45e                	sd	s7,8(sp)
    800016c8:	e062                	sd	s8,0(sp)
    800016ca:	0880                	addi	s0,sp,80
    800016cc:	8b2a                	mv	s6,a0
    800016ce:	8c2e                	mv	s8,a1
    800016d0:	8a32                	mv	s4,a2
    800016d2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016d4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016d6:	6a85                	lui	s5,0x1
    800016d8:	a015                	j	800016fc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016da:	9562                	add	a0,a0,s8
    800016dc:	0004861b          	sext.w	a2,s1
    800016e0:	85d2                	mv	a1,s4
    800016e2:	41250533          	sub	a0,a0,s2
    800016e6:	fffff097          	auipc	ra,0xfffff
    800016ea:	692080e7          	jalr	1682(ra) # 80000d78 <memmove>

    len -= n;
    800016ee:	409989b3          	sub	s3,s3,s1
    src += n;
    800016f2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016f4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016f8:	02098263          	beqz	s3,8000171c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016fc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001700:	85ca                	mv	a1,s2
    80001702:	855a                	mv	a0,s6
    80001704:	00000097          	auipc	ra,0x0
    80001708:	9a2080e7          	jalr	-1630(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000170c:	cd01                	beqz	a0,80001724 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000170e:	418904b3          	sub	s1,s2,s8
    80001712:	94d6                	add	s1,s1,s5
    if(n > len)
    80001714:	fc99f3e3          	bgeu	s3,s1,800016da <copyout+0x28>
    80001718:	84ce                	mv	s1,s3
    8000171a:	b7c1                	j	800016da <copyout+0x28>
  }
  return 0;
    8000171c:	4501                	li	a0,0
    8000171e:	a021                	j	80001726 <copyout+0x74>
    80001720:	4501                	li	a0,0
}
    80001722:	8082                	ret
      return -1;
    80001724:	557d                	li	a0,-1
}
    80001726:	60a6                	ld	ra,72(sp)
    80001728:	6406                	ld	s0,64(sp)
    8000172a:	74e2                	ld	s1,56(sp)
    8000172c:	7942                	ld	s2,48(sp)
    8000172e:	79a2                	ld	s3,40(sp)
    80001730:	7a02                	ld	s4,32(sp)
    80001732:	6ae2                	ld	s5,24(sp)
    80001734:	6b42                	ld	s6,16(sp)
    80001736:	6ba2                	ld	s7,8(sp)
    80001738:	6c02                	ld	s8,0(sp)
    8000173a:	6161                	addi	sp,sp,80
    8000173c:	8082                	ret

000000008000173e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000173e:	caa5                	beqz	a3,800017ae <copyin+0x70>
{
    80001740:	715d                	addi	sp,sp,-80
    80001742:	e486                	sd	ra,72(sp)
    80001744:	e0a2                	sd	s0,64(sp)
    80001746:	fc26                	sd	s1,56(sp)
    80001748:	f84a                	sd	s2,48(sp)
    8000174a:	f44e                	sd	s3,40(sp)
    8000174c:	f052                	sd	s4,32(sp)
    8000174e:	ec56                	sd	s5,24(sp)
    80001750:	e85a                	sd	s6,16(sp)
    80001752:	e45e                	sd	s7,8(sp)
    80001754:	e062                	sd	s8,0(sp)
    80001756:	0880                	addi	s0,sp,80
    80001758:	8b2a                	mv	s6,a0
    8000175a:	8a2e                	mv	s4,a1
    8000175c:	8c32                	mv	s8,a2
    8000175e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001760:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001762:	6a85                	lui	s5,0x1
    80001764:	a01d                	j	8000178a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001766:	018505b3          	add	a1,a0,s8
    8000176a:	0004861b          	sext.w	a2,s1
    8000176e:	412585b3          	sub	a1,a1,s2
    80001772:	8552                	mv	a0,s4
    80001774:	fffff097          	auipc	ra,0xfffff
    80001778:	604080e7          	jalr	1540(ra) # 80000d78 <memmove>

    len -= n;
    8000177c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001780:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001782:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001786:	02098263          	beqz	s3,800017aa <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000178a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000178e:	85ca                	mv	a1,s2
    80001790:	855a                	mv	a0,s6
    80001792:	00000097          	auipc	ra,0x0
    80001796:	914080e7          	jalr	-1772(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000179a:	cd01                	beqz	a0,800017b2 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000179c:	418904b3          	sub	s1,s2,s8
    800017a0:	94d6                	add	s1,s1,s5
    if(n > len)
    800017a2:	fc99f2e3          	bgeu	s3,s1,80001766 <copyin+0x28>
    800017a6:	84ce                	mv	s1,s3
    800017a8:	bf7d                	j	80001766 <copyin+0x28>
  }
  return 0;
    800017aa:	4501                	li	a0,0
    800017ac:	a021                	j	800017b4 <copyin+0x76>
    800017ae:	4501                	li	a0,0
}
    800017b0:	8082                	ret
      return -1;
    800017b2:	557d                	li	a0,-1
}
    800017b4:	60a6                	ld	ra,72(sp)
    800017b6:	6406                	ld	s0,64(sp)
    800017b8:	74e2                	ld	s1,56(sp)
    800017ba:	7942                	ld	s2,48(sp)
    800017bc:	79a2                	ld	s3,40(sp)
    800017be:	7a02                	ld	s4,32(sp)
    800017c0:	6ae2                	ld	s5,24(sp)
    800017c2:	6b42                	ld	s6,16(sp)
    800017c4:	6ba2                	ld	s7,8(sp)
    800017c6:	6c02                	ld	s8,0(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret

00000000800017cc <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017cc:	c6c5                	beqz	a3,80001874 <copyinstr+0xa8>
{
    800017ce:	715d                	addi	sp,sp,-80
    800017d0:	e486                	sd	ra,72(sp)
    800017d2:	e0a2                	sd	s0,64(sp)
    800017d4:	fc26                	sd	s1,56(sp)
    800017d6:	f84a                	sd	s2,48(sp)
    800017d8:	f44e                	sd	s3,40(sp)
    800017da:	f052                	sd	s4,32(sp)
    800017dc:	ec56                	sd	s5,24(sp)
    800017de:	e85a                	sd	s6,16(sp)
    800017e0:	e45e                	sd	s7,8(sp)
    800017e2:	0880                	addi	s0,sp,80
    800017e4:	8a2a                	mv	s4,a0
    800017e6:	8b2e                	mv	s6,a1
    800017e8:	8bb2                	mv	s7,a2
    800017ea:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ec:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ee:	6985                	lui	s3,0x1
    800017f0:	a035                	j	8000181c <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017f2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017f6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017f8:	0017b793          	seqz	a5,a5
    800017fc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001800:	60a6                	ld	ra,72(sp)
    80001802:	6406                	ld	s0,64(sp)
    80001804:	74e2                	ld	s1,56(sp)
    80001806:	7942                	ld	s2,48(sp)
    80001808:	79a2                	ld	s3,40(sp)
    8000180a:	7a02                	ld	s4,32(sp)
    8000180c:	6ae2                	ld	s5,24(sp)
    8000180e:	6b42                	ld	s6,16(sp)
    80001810:	6ba2                	ld	s7,8(sp)
    80001812:	6161                	addi	sp,sp,80
    80001814:	8082                	ret
    srcva = va0 + PGSIZE;
    80001816:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000181a:	c8a9                	beqz	s1,8000186c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000181c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001820:	85ca                	mv	a1,s2
    80001822:	8552                	mv	a0,s4
    80001824:	00000097          	auipc	ra,0x0
    80001828:	882080e7          	jalr	-1918(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000182c:	c131                	beqz	a0,80001870 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000182e:	41790833          	sub	a6,s2,s7
    80001832:	984e                	add	a6,a6,s3
    if(n > max)
    80001834:	0104f363          	bgeu	s1,a6,8000183a <copyinstr+0x6e>
    80001838:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000183a:	955e                	add	a0,a0,s7
    8000183c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001840:	fc080be3          	beqz	a6,80001816 <copyinstr+0x4a>
    80001844:	985a                	add	a6,a6,s6
    80001846:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001848:	41650633          	sub	a2,a0,s6
    8000184c:	14fd                	addi	s1,s1,-1
    8000184e:	9b26                	add	s6,s6,s1
    80001850:	00f60733          	add	a4,a2,a5
    80001854:	00074703          	lbu	a4,0(a4)
    80001858:	df49                	beqz	a4,800017f2 <copyinstr+0x26>
        *dst = *p;
    8000185a:	00e78023          	sb	a4,0(a5)
      --max;
    8000185e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001862:	0785                	addi	a5,a5,1
    while(n > 0){
    80001864:	ff0796e3          	bne	a5,a6,80001850 <copyinstr+0x84>
      dst++;
    80001868:	8b42                	mv	s6,a6
    8000186a:	b775                	j	80001816 <copyinstr+0x4a>
    8000186c:	4781                	li	a5,0
    8000186e:	b769                	j	800017f8 <copyinstr+0x2c>
      return -1;
    80001870:	557d                	li	a0,-1
    80001872:	b779                	j	80001800 <copyinstr+0x34>
  int got_null = 0;
    80001874:	4781                	li	a5,0
  if(got_null){
    80001876:	0017b793          	seqz	a5,a5
    8000187a:	40f00533          	neg	a0,a5
}
    8000187e:	8082                	ret

0000000080001880 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001880:	7139                	addi	sp,sp,-64
    80001882:	fc06                	sd	ra,56(sp)
    80001884:	f822                	sd	s0,48(sp)
    80001886:	f426                	sd	s1,40(sp)
    80001888:	f04a                	sd	s2,32(sp)
    8000188a:	ec4e                	sd	s3,24(sp)
    8000188c:	e852                	sd	s4,16(sp)
    8000188e:	e456                	sd	s5,8(sp)
    80001890:	e05a                	sd	s6,0(sp)
    80001892:	0080                	addi	s0,sp,64
    80001894:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001896:	00010497          	auipc	s1,0x10
    8000189a:	84a48493          	addi	s1,s1,-1974 # 800110e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000189e:	8b26                	mv	s6,s1
    800018a0:	00006a97          	auipc	s5,0x6
    800018a4:	760a8a93          	addi	s5,s5,1888 # 80008000 <etext>
    800018a8:	04000937          	lui	s2,0x4000
    800018ac:	197d                	addi	s2,s2,-1
    800018ae:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b0:	00015a17          	auipc	s4,0x15
    800018b4:	430a0a13          	addi	s4,s4,1072 # 80016ce0 <tickslock>
    char *pa = kalloc();
    800018b8:	fffff097          	auipc	ra,0xfffff
    800018bc:	22e080e7          	jalr	558(ra) # 80000ae6 <kalloc>
    800018c0:	862a                	mv	a2,a0
    if(pa == 0)
    800018c2:	c131                	beqz	a0,80001906 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018c4:	416485b3          	sub	a1,s1,s6
    800018c8:	8591                	srai	a1,a1,0x4
    800018ca:	000ab783          	ld	a5,0(s5)
    800018ce:	02f585b3          	mul	a1,a1,a5
    800018d2:	2585                	addiw	a1,a1,1
    800018d4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018d8:	4719                	li	a4,6
    800018da:	6685                	lui	a3,0x1
    800018dc:	40b905b3          	sub	a1,s2,a1
    800018e0:	854e                	mv	a0,s3
    800018e2:	00000097          	auipc	ra,0x0
    800018e6:	8a6080e7          	jalr	-1882(ra) # 80001188 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ea:	17048493          	addi	s1,s1,368
    800018ee:	fd4495e3          	bne	s1,s4,800018b8 <proc_mapstacks+0x38>
  }
}
    800018f2:	70e2                	ld	ra,56(sp)
    800018f4:	7442                	ld	s0,48(sp)
    800018f6:	74a2                	ld	s1,40(sp)
    800018f8:	7902                	ld	s2,32(sp)
    800018fa:	69e2                	ld	s3,24(sp)
    800018fc:	6a42                	ld	s4,16(sp)
    800018fe:	6aa2                	ld	s5,8(sp)
    80001900:	6b02                	ld	s6,0(sp)
    80001902:	6121                	addi	sp,sp,64
    80001904:	8082                	ret
      panic("kalloc");
    80001906:	00007517          	auipc	a0,0x7
    8000190a:	8d250513          	addi	a0,a0,-1838 # 800081d8 <digits+0x198>
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	c30080e7          	jalr	-976(ra) # 8000053e <panic>

0000000080001916 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001916:	7139                	addi	sp,sp,-64
    80001918:	fc06                	sd	ra,56(sp)
    8000191a:	f822                	sd	s0,48(sp)
    8000191c:	f426                	sd	s1,40(sp)
    8000191e:	f04a                	sd	s2,32(sp)
    80001920:	ec4e                	sd	s3,24(sp)
    80001922:	e852                	sd	s4,16(sp)
    80001924:	e456                	sd	s5,8(sp)
    80001926:	e05a                	sd	s6,0(sp)
    80001928:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000192a:	00007597          	auipc	a1,0x7
    8000192e:	8b658593          	addi	a1,a1,-1866 # 800081e0 <digits+0x1a0>
    80001932:	0000f517          	auipc	a0,0xf
    80001936:	37e50513          	addi	a0,a0,894 # 80010cb0 <pid_lock>
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	256080e7          	jalr	598(ra) # 80000b90 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	8a658593          	addi	a1,a1,-1882 # 800081e8 <digits+0x1a8>
    8000194a:	0000f517          	auipc	a0,0xf
    8000194e:	37e50513          	addi	a0,a0,894 # 80010cc8 <wait_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	23e080e7          	jalr	574(ra) # 80000b90 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	0000f497          	auipc	s1,0xf
    8000195e:	78648493          	addi	s1,s1,1926 # 800110e0 <proc>
      initlock(&p->lock, "proc");
    80001962:	00007b17          	auipc	s6,0x7
    80001966:	896b0b13          	addi	s6,s6,-1898 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000196a:	8aa6                	mv	s5,s1
    8000196c:	00006a17          	auipc	s4,0x6
    80001970:	694a0a13          	addi	s4,s4,1684 # 80008000 <etext>
    80001974:	04000937          	lui	s2,0x4000
    80001978:	197d                	addi	s2,s2,-1
    8000197a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00015997          	auipc	s3,0x15
    80001980:	36498993          	addi	s3,s3,868 # 80016ce0 <tickslock>
      initlock(&p->lock, "proc");
    80001984:	85da                	mv	a1,s6
    80001986:	8526                	mv	a0,s1
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	208080e7          	jalr	520(ra) # 80000b90 <initlock>
      p->state = UNUSED;
    80001990:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001994:	415487b3          	sub	a5,s1,s5
    80001998:	8791                	srai	a5,a5,0x4
    8000199a:	000a3703          	ld	a4,0(s4)
    8000199e:	02e787b3          	mul	a5,a5,a4
    800019a2:	2785                	addiw	a5,a5,1
    800019a4:	00d7979b          	slliw	a5,a5,0xd
    800019a8:	40f907b3          	sub	a5,s2,a5
    800019ac:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ae:	17048493          	addi	s1,s1,368
    800019b2:	fd3499e3          	bne	s1,s3,80001984 <procinit+0x6e>
  }
}
    800019b6:	70e2                	ld	ra,56(sp)
    800019b8:	7442                	ld	s0,48(sp)
    800019ba:	74a2                	ld	s1,40(sp)
    800019bc:	7902                	ld	s2,32(sp)
    800019be:	69e2                	ld	s3,24(sp)
    800019c0:	6a42                	ld	s4,16(sp)
    800019c2:	6aa2                	ld	s5,8(sp)
    800019c4:	6b02                	ld	s6,0(sp)
    800019c6:	6121                	addi	sp,sp,64
    800019c8:	8082                	ret

00000000800019ca <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019ca:	1141                	addi	sp,sp,-16
    800019cc:	e422                	sd	s0,8(sp)
    800019ce:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019d0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019d2:	2501                	sext.w	a0,a0
    800019d4:	6422                	ld	s0,8(sp)
    800019d6:	0141                	addi	sp,sp,16
    800019d8:	8082                	ret

00000000800019da <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019da:	1141                	addi	sp,sp,-16
    800019dc:	e422                	sd	s0,8(sp)
    800019de:	0800                	addi	s0,sp,16
    800019e0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019e6:	0000f517          	auipc	a0,0xf
    800019ea:	2fa50513          	addi	a0,a0,762 # 80010ce0 <cpus>
    800019ee:	953e                	add	a0,a0,a5
    800019f0:	6422                	ld	s0,8(sp)
    800019f2:	0141                	addi	sp,sp,16
    800019f4:	8082                	ret

00000000800019f6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019f6:	1101                	addi	sp,sp,-32
    800019f8:	ec06                	sd	ra,24(sp)
    800019fa:	e822                	sd	s0,16(sp)
    800019fc:	e426                	sd	s1,8(sp)
    800019fe:	1000                	addi	s0,sp,32
  push_off();
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	1d4080e7          	jalr	468(ra) # 80000bd4 <push_off>
    80001a08:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a0a:	2781                	sext.w	a5,a5
    80001a0c:	079e                	slli	a5,a5,0x7
    80001a0e:	0000f717          	auipc	a4,0xf
    80001a12:	2a270713          	addi	a4,a4,674 # 80010cb0 <pid_lock>
    80001a16:	97ba                	add	a5,a5,a4
    80001a18:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	25a080e7          	jalr	602(ra) # 80000c74 <pop_off>
  return p;
}
    80001a22:	8526                	mv	a0,s1
    80001a24:	60e2                	ld	ra,24(sp)
    80001a26:	6442                	ld	s0,16(sp)
    80001a28:	64a2                	ld	s1,8(sp)
    80001a2a:	6105                	addi	sp,sp,32
    80001a2c:	8082                	ret

0000000080001a2e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a2e:	1141                	addi	sp,sp,-16
    80001a30:	e406                	sd	ra,8(sp)
    80001a32:	e022                	sd	s0,0(sp)
    80001a34:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a36:	00000097          	auipc	ra,0x0
    80001a3a:	fc0080e7          	jalr	-64(ra) # 800019f6 <myproc>
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	296080e7          	jalr	662(ra) # 80000cd4 <release>

  if (first) {
    80001a46:	00007797          	auipc	a5,0x7
    80001a4a:	f7a7a783          	lw	a5,-134(a5) # 800089c0 <first.1>
    80001a4e:	eb89                	bnez	a5,80001a60 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a50:	00001097          	auipc	ra,0x1
    80001a54:	cbc080e7          	jalr	-836(ra) # 8000270c <usertrapret>
}
    80001a58:	60a2                	ld	ra,8(sp)
    80001a5a:	6402                	ld	s0,0(sp)
    80001a5c:	0141                	addi	sp,sp,16
    80001a5e:	8082                	ret
    first = 0;
    80001a60:	00007797          	auipc	a5,0x7
    80001a64:	f607a023          	sw	zero,-160(a5) # 800089c0 <first.1>
    fsinit(ROOTDEV);
    80001a68:	4505                	li	a0,1
    80001a6a:	00002097          	auipc	ra,0x2
    80001a6e:	ac2080e7          	jalr	-1342(ra) # 8000352c <fsinit>
    80001a72:	bff9                	j	80001a50 <forkret+0x22>

0000000080001a74 <allocpid>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a80:	0000f917          	auipc	s2,0xf
    80001a84:	23090913          	addi	s2,s2,560 # 80010cb0 <pid_lock>
    80001a88:	854a                	mv	a0,s2
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	196080e7          	jalr	406(ra) # 80000c20 <acquire>
  pid = nextpid;
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	f3278793          	addi	a5,a5,-206 # 800089c4 <nextpid>
    80001a9a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a9c:	0014871b          	addiw	a4,s1,1
    80001aa0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aa2:	854a                	mv	a0,s2
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	230080e7          	jalr	560(ra) # 80000cd4 <release>
}
    80001aac:	8526                	mv	a0,s1
    80001aae:	60e2                	ld	ra,24(sp)
    80001ab0:	6442                	ld	s0,16(sp)
    80001ab2:	64a2                	ld	s1,8(sp)
    80001ab4:	6902                	ld	s2,0(sp)
    80001ab6:	6105                	addi	sp,sp,32
    80001ab8:	8082                	ret

0000000080001aba <proc_pagetable>:
{
    80001aba:	1101                	addi	sp,sp,-32
    80001abc:	ec06                	sd	ra,24(sp)
    80001abe:	e822                	sd	s0,16(sp)
    80001ac0:	e426                	sd	s1,8(sp)
    80001ac2:	e04a                	sd	s2,0(sp)
    80001ac4:	1000                	addi	s0,sp,32
    80001ac6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ac8:	00000097          	auipc	ra,0x0
    80001acc:	8aa080e7          	jalr	-1878(ra) # 80001372 <uvmcreate>
    80001ad0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ad2:	c121                	beqz	a0,80001b12 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ad4:	4729                	li	a4,10
    80001ad6:	00005697          	auipc	a3,0x5
    80001ada:	52a68693          	addi	a3,a3,1322 # 80007000 <_trampoline>
    80001ade:	6605                	lui	a2,0x1
    80001ae0:	040005b7          	lui	a1,0x4000
    80001ae4:	15fd                	addi	a1,a1,-1
    80001ae6:	05b2                	slli	a1,a1,0xc
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	600080e7          	jalr	1536(ra) # 800010e8 <mappages>
    80001af0:	02054863          	bltz	a0,80001b20 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001af4:	4719                	li	a4,6
    80001af6:	05893683          	ld	a3,88(s2)
    80001afa:	6605                	lui	a2,0x1
    80001afc:	020005b7          	lui	a1,0x2000
    80001b00:	15fd                	addi	a1,a1,-1
    80001b02:	05b6                	slli	a1,a1,0xd
    80001b04:	8526                	mv	a0,s1
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	5e2080e7          	jalr	1506(ra) # 800010e8 <mappages>
    80001b0e:	02054163          	bltz	a0,80001b30 <proc_pagetable+0x76>
}
    80001b12:	8526                	mv	a0,s1
    80001b14:	60e2                	ld	ra,24(sp)
    80001b16:	6442                	ld	s0,16(sp)
    80001b18:	64a2                	ld	s1,8(sp)
    80001b1a:	6902                	ld	s2,0(sp)
    80001b1c:	6105                	addi	sp,sp,32
    80001b1e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b20:	4581                	li	a1,0
    80001b22:	8526                	mv	a0,s1
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	a52080e7          	jalr	-1454(ra) # 80001576 <uvmfree>
    return 0;
    80001b2c:	4481                	li	s1,0
    80001b2e:	b7d5                	j	80001b12 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	770080e7          	jalr	1904(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001b46:	4581                	li	a1,0
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	a2c080e7          	jalr	-1492(ra) # 80001576 <uvmfree>
    return 0;
    80001b52:	4481                	li	s1,0
    80001b54:	bf7d                	j	80001b12 <proc_pagetable+0x58>

0000000080001b56 <proc_freepagetable>:
{
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	e04a                	sd	s2,0(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
    80001b64:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b66:	4681                	li	a3,0
    80001b68:	4605                	li	a2,1
    80001b6a:	040005b7          	lui	a1,0x4000
    80001b6e:	15fd                	addi	a1,a1,-1
    80001b70:	05b2                	slli	a1,a1,0xc
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	73c080e7          	jalr	1852(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b7a:	4681                	li	a3,0
    80001b7c:	4605                	li	a2,1
    80001b7e:	020005b7          	lui	a1,0x2000
    80001b82:	15fd                	addi	a1,a1,-1
    80001b84:	05b6                	slli	a1,a1,0xd
    80001b86:	8526                	mv	a0,s1
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	726080e7          	jalr	1830(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001b90:	85ca                	mv	a1,s2
    80001b92:	8526                	mv	a0,s1
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	9e2080e7          	jalr	-1566(ra) # 80001576 <uvmfree>
}
    80001b9c:	60e2                	ld	ra,24(sp)
    80001b9e:	6442                	ld	s0,16(sp)
    80001ba0:	64a2                	ld	s1,8(sp)
    80001ba2:	6902                	ld	s2,0(sp)
    80001ba4:	6105                	addi	sp,sp,32
    80001ba6:	8082                	ret

0000000080001ba8 <freeproc>:
{
    80001ba8:	1101                	addi	sp,sp,-32
    80001baa:	ec06                	sd	ra,24(sp)
    80001bac:	e822                	sd	s0,16(sp)
    80001bae:	e426                	sd	s1,8(sp)
    80001bb0:	1000                	addi	s0,sp,32
    80001bb2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bb4:	6d28                	ld	a0,88(a0)
    80001bb6:	c509                	beqz	a0,80001bc0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	e32080e7          	jalr	-462(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001bc0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bc4:	68a8                	ld	a0,80(s1)
    80001bc6:	c511                	beqz	a0,80001bd2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc8:	64ac                	ld	a1,72(s1)
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	f8c080e7          	jalr	-116(ra) # 80001b56 <proc_freepagetable>
  p->pagetable = 0;
    80001bd2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bd6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bda:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bde:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001be2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001be6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bea:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bee:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bf2:	0004ac23          	sw	zero,24(s1)
  p->trace_mask = 0;
    80001bf6:	1604a423          	sw	zero,360(s1)
}
    80001bfa:	60e2                	ld	ra,24(sp)
    80001bfc:	6442                	ld	s0,16(sp)
    80001bfe:	64a2                	ld	s1,8(sp)
    80001c00:	6105                	addi	sp,sp,32
    80001c02:	8082                	ret

0000000080001c04 <allocproc>:
{
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	e04a                	sd	s2,0(sp)
    80001c0e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c10:	0000f497          	auipc	s1,0xf
    80001c14:	4d048493          	addi	s1,s1,1232 # 800110e0 <proc>
    80001c18:	00015917          	auipc	s2,0x15
    80001c1c:	0c890913          	addi	s2,s2,200 # 80016ce0 <tickslock>
    acquire(&p->lock);
    80001c20:	8526                	mv	a0,s1
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	ffe080e7          	jalr	-2(ra) # 80000c20 <acquire>
    if(p->state == UNUSED) {
    80001c2a:	4c9c                	lw	a5,24(s1)
    80001c2c:	cf81                	beqz	a5,80001c44 <allocproc+0x40>
      release(&p->lock);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0a4080e7          	jalr	164(ra) # 80000cd4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c38:	17048493          	addi	s1,s1,368
    80001c3c:	ff2492e3          	bne	s1,s2,80001c20 <allocproc+0x1c>
  return 0;
    80001c40:	4481                	li	s1,0
    80001c42:	a889                	j	80001c94 <allocproc+0x90>
  p->pid = allocpid();
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	e30080e7          	jalr	-464(ra) # 80001a74 <allocpid>
    80001c4c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c4e:	4785                	li	a5,1
    80001c50:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	e94080e7          	jalr	-364(ra) # 80000ae6 <kalloc>
    80001c5a:	892a                	mv	s2,a0
    80001c5c:	eca8                	sd	a0,88(s1)
    80001c5e:	c131                	beqz	a0,80001ca2 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	e58080e7          	jalr	-424(ra) # 80001aba <proc_pagetable>
    80001c6a:	892a                	mv	s2,a0
    80001c6c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c6e:	c531                	beqz	a0,80001cba <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c70:	07000613          	li	a2,112
    80001c74:	4581                	li	a1,0
    80001c76:	06048513          	addi	a0,s1,96
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	0a2080e7          	jalr	162(ra) # 80000d1c <memset>
  p->context.ra = (uint64)forkret;
    80001c82:	00000797          	auipc	a5,0x0
    80001c86:	dac78793          	addi	a5,a5,-596 # 80001a2e <forkret>
    80001c8a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c8c:	60bc                	ld	a5,64(s1)
    80001c8e:	6705                	lui	a4,0x1
    80001c90:	97ba                	add	a5,a5,a4
    80001c92:	f4bc                	sd	a5,104(s1)
}
    80001c94:	8526                	mv	a0,s1
    80001c96:	60e2                	ld	ra,24(sp)
    80001c98:	6442                	ld	s0,16(sp)
    80001c9a:	64a2                	ld	s1,8(sp)
    80001c9c:	6902                	ld	s2,0(sp)
    80001c9e:	6105                	addi	sp,sp,32
    80001ca0:	8082                	ret
    freeproc(p);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	f04080e7          	jalr	-252(ra) # 80001ba8 <freeproc>
    release(&p->lock);
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	026080e7          	jalr	38(ra) # 80000cd4 <release>
    return 0;
    80001cb6:	84ca                	mv	s1,s2
    80001cb8:	bff1                	j	80001c94 <allocproc+0x90>
    freeproc(p);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	eec080e7          	jalr	-276(ra) # 80001ba8 <freeproc>
    release(&p->lock);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	00e080e7          	jalr	14(ra) # 80000cd4 <release>
    return 0;
    80001cce:	84ca                	mv	s1,s2
    80001cd0:	b7d1                	j	80001c94 <allocproc+0x90>

0000000080001cd2 <userinit>:
{
    80001cd2:	1101                	addi	sp,sp,-32
    80001cd4:	ec06                	sd	ra,24(sp)
    80001cd6:	e822                	sd	s0,16(sp)
    80001cd8:	e426                	sd	s1,8(sp)
    80001cda:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	f28080e7          	jalr	-216(ra) # 80001c04 <allocproc>
    80001ce4:	84aa                	mv	s1,a0
  initproc = p;
    80001ce6:	00007797          	auipc	a5,0x7
    80001cea:	d4a7b923          	sd	a0,-686(a5) # 80008a38 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cee:	03400613          	li	a2,52
    80001cf2:	00007597          	auipc	a1,0x7
    80001cf6:	cde58593          	addi	a1,a1,-802 # 800089d0 <initcode>
    80001cfa:	6928                	ld	a0,80(a0)
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	6a4080e7          	jalr	1700(ra) # 800013a0 <uvmfirst>
  p->sz = PGSIZE;
    80001d04:	6785                	lui	a5,0x1
    80001d06:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d08:	6cb8                	ld	a4,88(s1)
    80001d0a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d0e:	6cb8                	ld	a4,88(s1)
    80001d10:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d12:	4641                	li	a2,16
    80001d14:	00006597          	auipc	a1,0x6
    80001d18:	4ec58593          	addi	a1,a1,1260 # 80008200 <digits+0x1c0>
    80001d1c:	15848513          	addi	a0,s1,344
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	146080e7          	jalr	326(ra) # 80000e66 <safestrcpy>
  p->cwd = namei("/");
    80001d28:	00006517          	auipc	a0,0x6
    80001d2c:	4e850513          	addi	a0,a0,1256 # 80008210 <digits+0x1d0>
    80001d30:	00002097          	auipc	ra,0x2
    80001d34:	21e080e7          	jalr	542(ra) # 80003f4e <namei>
    80001d38:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3c:	478d                	li	a5,3
    80001d3e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d40:	8526                	mv	a0,s1
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	f92080e7          	jalr	-110(ra) # 80000cd4 <release>
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret

0000000080001d54 <growproc>:
{
    80001d54:	1101                	addi	sp,sp,-32
    80001d56:	ec06                	sd	ra,24(sp)
    80001d58:	e822                	sd	s0,16(sp)
    80001d5a:	e426                	sd	s1,8(sp)
    80001d5c:	e04a                	sd	s2,0(sp)
    80001d5e:	1000                	addi	s0,sp,32
    80001d60:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d62:	00000097          	auipc	ra,0x0
    80001d66:	c94080e7          	jalr	-876(ra) # 800019f6 <myproc>
    80001d6a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d6c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d6e:	01204c63          	bgtz	s2,80001d86 <growproc+0x32>
  } else if(n < 0){
    80001d72:	02094663          	bltz	s2,80001d9e <growproc+0x4a>
  p->sz = sz;
    80001d76:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d78:	4501                	li	a0,0
}
    80001d7a:	60e2                	ld	ra,24(sp)
    80001d7c:	6442                	ld	s0,16(sp)
    80001d7e:	64a2                	ld	s1,8(sp)
    80001d80:	6902                	ld	s2,0(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d86:	4691                	li	a3,4
    80001d88:	00b90633          	add	a2,s2,a1
    80001d8c:	6928                	ld	a0,80(a0)
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	6cc080e7          	jalr	1740(ra) # 8000145a <uvmalloc>
    80001d96:	85aa                	mv	a1,a0
    80001d98:	fd79                	bnez	a0,80001d76 <growproc+0x22>
      return -1;
    80001d9a:	557d                	li	a0,-1
    80001d9c:	bff9                	j	80001d7a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9e:	00b90633          	add	a2,s2,a1
    80001da2:	6928                	ld	a0,80(a0)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	66e080e7          	jalr	1646(ra) # 80001412 <uvmdealloc>
    80001dac:	85aa                	mv	a1,a0
    80001dae:	b7e1                	j	80001d76 <growproc+0x22>

0000000080001db0 <fork>:
{
    80001db0:	7139                	addi	sp,sp,-64
    80001db2:	fc06                	sd	ra,56(sp)
    80001db4:	f822                	sd	s0,48(sp)
    80001db6:	f426                	sd	s1,40(sp)
    80001db8:	f04a                	sd	s2,32(sp)
    80001dba:	ec4e                	sd	s3,24(sp)
    80001dbc:	e852                	sd	s4,16(sp)
    80001dbe:	e456                	sd	s5,8(sp)
    80001dc0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	c34080e7          	jalr	-972(ra) # 800019f6 <myproc>
    80001dca:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	e38080e7          	jalr	-456(ra) # 80001c04 <allocproc>
    80001dd4:	12050063          	beqz	a0,80001ef4 <fork+0x144>
    80001dd8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dda:	048ab603          	ld	a2,72(s5)
    80001dde:	692c                	ld	a1,80(a0)
    80001de0:	050ab503          	ld	a0,80(s5)
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	7ca080e7          	jalr	1994(ra) # 800015ae <uvmcopy>
    80001dec:	04054c63          	bltz	a0,80001e44 <fork+0x94>
  np->sz = p->sz;
    80001df0:	048ab783          	ld	a5,72(s5)
    80001df4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001df8:	058ab683          	ld	a3,88(s5)
    80001dfc:	87b6                	mv	a5,a3
    80001dfe:	0589b703          	ld	a4,88(s3)
    80001e02:	12068693          	addi	a3,a3,288
    80001e06:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e0a:	6788                	ld	a0,8(a5)
    80001e0c:	6b8c                	ld	a1,16(a5)
    80001e0e:	6f90                	ld	a2,24(a5)
    80001e10:	01073023          	sd	a6,0(a4)
    80001e14:	e708                	sd	a0,8(a4)
    80001e16:	eb0c                	sd	a1,16(a4)
    80001e18:	ef10                	sd	a2,24(a4)
    80001e1a:	02078793          	addi	a5,a5,32
    80001e1e:	02070713          	addi	a4,a4,32
    80001e22:	fed792e3          	bne	a5,a3,80001e06 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e26:	0589b783          	ld	a5,88(s3)
    80001e2a:	0607b823          	sd	zero,112(a5)
  np->trace_mask = p->trace_mask;
    80001e2e:	168aa783          	lw	a5,360(s5)
    80001e32:	16f9a423          	sw	a5,360(s3)
  for(i = 0; i < NOFILE; i++)
    80001e36:	0d0a8493          	addi	s1,s5,208
    80001e3a:	0d098913          	addi	s2,s3,208
    80001e3e:	150a8a13          	addi	s4,s5,336
    80001e42:	a00d                	j	80001e64 <fork+0xb4>
    freeproc(np);
    80001e44:	854e                	mv	a0,s3
    80001e46:	00000097          	auipc	ra,0x0
    80001e4a:	d62080e7          	jalr	-670(ra) # 80001ba8 <freeproc>
    release(&np->lock);
    80001e4e:	854e                	mv	a0,s3
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	e84080e7          	jalr	-380(ra) # 80000cd4 <release>
    return -1;
    80001e58:	597d                	li	s2,-1
    80001e5a:	a059                	j	80001ee0 <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001e5c:	04a1                	addi	s1,s1,8
    80001e5e:	0921                	addi	s2,s2,8
    80001e60:	01448b63          	beq	s1,s4,80001e76 <fork+0xc6>
    if(p->ofile[i])
    80001e64:	6088                	ld	a0,0(s1)
    80001e66:	d97d                	beqz	a0,80001e5c <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e68:	00002097          	auipc	ra,0x2
    80001e6c:	77c080e7          	jalr	1916(ra) # 800045e4 <filedup>
    80001e70:	00a93023          	sd	a0,0(s2)
    80001e74:	b7e5                	j	80001e5c <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e76:	150ab503          	ld	a0,336(s5)
    80001e7a:	00002097          	auipc	ra,0x2
    80001e7e:	8f0080e7          	jalr	-1808(ra) # 8000376a <idup>
    80001e82:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e86:	4641                	li	a2,16
    80001e88:	158a8593          	addi	a1,s5,344
    80001e8c:	15898513          	addi	a0,s3,344
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	fd6080e7          	jalr	-42(ra) # 80000e66 <safestrcpy>
  pid = np->pid;
    80001e98:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e9c:	854e                	mv	a0,s3
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	e36080e7          	jalr	-458(ra) # 80000cd4 <release>
  acquire(&wait_lock);
    80001ea6:	0000f497          	auipc	s1,0xf
    80001eaa:	e2248493          	addi	s1,s1,-478 # 80010cc8 <wait_lock>
    80001eae:	8526                	mv	a0,s1
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	d70080e7          	jalr	-656(ra) # 80000c20 <acquire>
  np->parent = p;
    80001eb8:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	e16080e7          	jalr	-490(ra) # 80000cd4 <release>
  acquire(&np->lock);
    80001ec6:	854e                	mv	a0,s3
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	d58080e7          	jalr	-680(ra) # 80000c20 <acquire>
  np->state = RUNNABLE;
    80001ed0:	478d                	li	a5,3
    80001ed2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ed6:	854e                	mv	a0,s3
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	dfc080e7          	jalr	-516(ra) # 80000cd4 <release>
}
    80001ee0:	854a                	mv	a0,s2
    80001ee2:	70e2                	ld	ra,56(sp)
    80001ee4:	7442                	ld	s0,48(sp)
    80001ee6:	74a2                	ld	s1,40(sp)
    80001ee8:	7902                	ld	s2,32(sp)
    80001eea:	69e2                	ld	s3,24(sp)
    80001eec:	6a42                	ld	s4,16(sp)
    80001eee:	6aa2                	ld	s5,8(sp)
    80001ef0:	6121                	addi	sp,sp,64
    80001ef2:	8082                	ret
    return -1;
    80001ef4:	597d                	li	s2,-1
    80001ef6:	b7ed                	j	80001ee0 <fork+0x130>

0000000080001ef8 <scheduler>:
{
    80001ef8:	7139                	addi	sp,sp,-64
    80001efa:	fc06                	sd	ra,56(sp)
    80001efc:	f822                	sd	s0,48(sp)
    80001efe:	f426                	sd	s1,40(sp)
    80001f00:	f04a                	sd	s2,32(sp)
    80001f02:	ec4e                	sd	s3,24(sp)
    80001f04:	e852                	sd	s4,16(sp)
    80001f06:	e456                	sd	s5,8(sp)
    80001f08:	e05a                	sd	s6,0(sp)
    80001f0a:	0080                	addi	s0,sp,64
    80001f0c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f0e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f10:	00779a93          	slli	s5,a5,0x7
    80001f14:	0000f717          	auipc	a4,0xf
    80001f18:	d9c70713          	addi	a4,a4,-612 # 80010cb0 <pid_lock>
    80001f1c:	9756                	add	a4,a4,s5
    80001f1e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f22:	0000f717          	auipc	a4,0xf
    80001f26:	dc670713          	addi	a4,a4,-570 # 80010ce8 <cpus+0x8>
    80001f2a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f2c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f2e:	4b11                	li	s6,4
        c->proc = p;
    80001f30:	079e                	slli	a5,a5,0x7
    80001f32:	0000fa17          	auipc	s4,0xf
    80001f36:	d7ea0a13          	addi	s4,s4,-642 # 80010cb0 <pid_lock>
    80001f3a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3c:	00015917          	auipc	s2,0x15
    80001f40:	da490913          	addi	s2,s2,-604 # 80016ce0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f44:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f48:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f4c:	10079073          	csrw	sstatus,a5
    80001f50:	0000f497          	auipc	s1,0xf
    80001f54:	19048493          	addi	s1,s1,400 # 800110e0 <proc>
    80001f58:	a811                	j	80001f6c <scheduler+0x74>
      release(&p->lock);
    80001f5a:	8526                	mv	a0,s1
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	d78080e7          	jalr	-648(ra) # 80000cd4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f64:	17048493          	addi	s1,s1,368
    80001f68:	fd248ee3          	beq	s1,s2,80001f44 <scheduler+0x4c>
      acquire(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	cb2080e7          	jalr	-846(ra) # 80000c20 <acquire>
      if(p->state == RUNNABLE) {
    80001f76:	4c9c                	lw	a5,24(s1)
    80001f78:	ff3791e3          	bne	a5,s3,80001f5a <scheduler+0x62>
        p->state = RUNNING;
    80001f7c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f80:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f84:	06048593          	addi	a1,s1,96
    80001f88:	8556                	mv	a0,s5
    80001f8a:	00000097          	auipc	ra,0x0
    80001f8e:	6d8080e7          	jalr	1752(ra) # 80002662 <swtch>
        c->proc = 0;
    80001f92:	020a3823          	sd	zero,48(s4)
    80001f96:	b7d1                	j	80001f5a <scheduler+0x62>

0000000080001f98 <sched>:
{
    80001f98:	7179                	addi	sp,sp,-48
    80001f9a:	f406                	sd	ra,40(sp)
    80001f9c:	f022                	sd	s0,32(sp)
    80001f9e:	ec26                	sd	s1,24(sp)
    80001fa0:	e84a                	sd	s2,16(sp)
    80001fa2:	e44e                	sd	s3,8(sp)
    80001fa4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	a50080e7          	jalr	-1456(ra) # 800019f6 <myproc>
    80001fae:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	bf6080e7          	jalr	-1034(ra) # 80000ba6 <holding>
    80001fb8:	c93d                	beqz	a0,8000202e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fba:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fbc:	2781                	sext.w	a5,a5
    80001fbe:	079e                	slli	a5,a5,0x7
    80001fc0:	0000f717          	auipc	a4,0xf
    80001fc4:	cf070713          	addi	a4,a4,-784 # 80010cb0 <pid_lock>
    80001fc8:	97ba                	add	a5,a5,a4
    80001fca:	0a87a703          	lw	a4,168(a5)
    80001fce:	4785                	li	a5,1
    80001fd0:	06f71763          	bne	a4,a5,8000203e <sched+0xa6>
  if(p->state == RUNNING)
    80001fd4:	4c98                	lw	a4,24(s1)
    80001fd6:	4791                	li	a5,4
    80001fd8:	06f70b63          	beq	a4,a5,8000204e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fdc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fe0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fe2:	efb5                	bnez	a5,8000205e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fe6:	0000f917          	auipc	s2,0xf
    80001fea:	cca90913          	addi	s2,s2,-822 # 80010cb0 <pid_lock>
    80001fee:	2781                	sext.w	a5,a5
    80001ff0:	079e                	slli	a5,a5,0x7
    80001ff2:	97ca                	add	a5,a5,s2
    80001ff4:	0ac7a983          	lw	s3,172(a5)
    80001ff8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ffa:	2781                	sext.w	a5,a5
    80001ffc:	079e                	slli	a5,a5,0x7
    80001ffe:	0000f597          	auipc	a1,0xf
    80002002:	cea58593          	addi	a1,a1,-790 # 80010ce8 <cpus+0x8>
    80002006:	95be                	add	a1,a1,a5
    80002008:	06048513          	addi	a0,s1,96
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	656080e7          	jalr	1622(ra) # 80002662 <swtch>
    80002014:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002016:	2781                	sext.w	a5,a5
    80002018:	079e                	slli	a5,a5,0x7
    8000201a:	97ca                	add	a5,a5,s2
    8000201c:	0b37a623          	sw	s3,172(a5)
}
    80002020:	70a2                	ld	ra,40(sp)
    80002022:	7402                	ld	s0,32(sp)
    80002024:	64e2                	ld	s1,24(sp)
    80002026:	6942                	ld	s2,16(sp)
    80002028:	69a2                	ld	s3,8(sp)
    8000202a:	6145                	addi	sp,sp,48
    8000202c:	8082                	ret
    panic("sched p->lock");
    8000202e:	00006517          	auipc	a0,0x6
    80002032:	1ea50513          	addi	a0,a0,490 # 80008218 <digits+0x1d8>
    80002036:	ffffe097          	auipc	ra,0xffffe
    8000203a:	508080e7          	jalr	1288(ra) # 8000053e <panic>
    panic("sched locks");
    8000203e:	00006517          	auipc	a0,0x6
    80002042:	1ea50513          	addi	a0,a0,490 # 80008228 <digits+0x1e8>
    80002046:	ffffe097          	auipc	ra,0xffffe
    8000204a:	4f8080e7          	jalr	1272(ra) # 8000053e <panic>
    panic("sched running");
    8000204e:	00006517          	auipc	a0,0x6
    80002052:	1ea50513          	addi	a0,a0,490 # 80008238 <digits+0x1f8>
    80002056:	ffffe097          	auipc	ra,0xffffe
    8000205a:	4e8080e7          	jalr	1256(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000205e:	00006517          	auipc	a0,0x6
    80002062:	1ea50513          	addi	a0,a0,490 # 80008248 <digits+0x208>
    80002066:	ffffe097          	auipc	ra,0xffffe
    8000206a:	4d8080e7          	jalr	1240(ra) # 8000053e <panic>

000000008000206e <yield>:
{
    8000206e:	1101                	addi	sp,sp,-32
    80002070:	ec06                	sd	ra,24(sp)
    80002072:	e822                	sd	s0,16(sp)
    80002074:	e426                	sd	s1,8(sp)
    80002076:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	97e080e7          	jalr	-1666(ra) # 800019f6 <myproc>
    80002080:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	b9e080e7          	jalr	-1122(ra) # 80000c20 <acquire>
  p->state = RUNNABLE;
    8000208a:	478d                	li	a5,3
    8000208c:	cc9c                	sw	a5,24(s1)
  sched();
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	f0a080e7          	jalr	-246(ra) # 80001f98 <sched>
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	c3c080e7          	jalr	-964(ra) # 80000cd4 <release>
}
    800020a0:	60e2                	ld	ra,24(sp)
    800020a2:	6442                	ld	s0,16(sp)
    800020a4:	64a2                	ld	s1,8(sp)
    800020a6:	6105                	addi	sp,sp,32
    800020a8:	8082                	ret

00000000800020aa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020aa:	7179                	addi	sp,sp,-48
    800020ac:	f406                	sd	ra,40(sp)
    800020ae:	f022                	sd	s0,32(sp)
    800020b0:	ec26                	sd	s1,24(sp)
    800020b2:	e84a                	sd	s2,16(sp)
    800020b4:	e44e                	sd	s3,8(sp)
    800020b6:	1800                	addi	s0,sp,48
    800020b8:	89aa                	mv	s3,a0
    800020ba:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	93a080e7          	jalr	-1734(ra) # 800019f6 <myproc>
    800020c4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	b5a080e7          	jalr	-1190(ra) # 80000c20 <acquire>
  release(lk);
    800020ce:	854a                	mv	a0,s2
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	c04080e7          	jalr	-1020(ra) # 80000cd4 <release>

  // Go to sleep.
  p->chan = chan;
    800020d8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020dc:	4789                	li	a5,2
    800020de:	cc9c                	sw	a5,24(s1)

  sched();
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	eb8080e7          	jalr	-328(ra) # 80001f98 <sched>

  // Tidy up.
  p->chan = 0;
    800020e8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ec:	8526                	mv	a0,s1
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	be6080e7          	jalr	-1050(ra) # 80000cd4 <release>
  acquire(lk);
    800020f6:	854a                	mv	a0,s2
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	b28080e7          	jalr	-1240(ra) # 80000c20 <acquire>
}
    80002100:	70a2                	ld	ra,40(sp)
    80002102:	7402                	ld	s0,32(sp)
    80002104:	64e2                	ld	s1,24(sp)
    80002106:	6942                	ld	s2,16(sp)
    80002108:	69a2                	ld	s3,8(sp)
    8000210a:	6145                	addi	sp,sp,48
    8000210c:	8082                	ret

000000008000210e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000210e:	7139                	addi	sp,sp,-64
    80002110:	fc06                	sd	ra,56(sp)
    80002112:	f822                	sd	s0,48(sp)
    80002114:	f426                	sd	s1,40(sp)
    80002116:	f04a                	sd	s2,32(sp)
    80002118:	ec4e                	sd	s3,24(sp)
    8000211a:	e852                	sd	s4,16(sp)
    8000211c:	e456                	sd	s5,8(sp)
    8000211e:	0080                	addi	s0,sp,64
    80002120:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002122:	0000f497          	auipc	s1,0xf
    80002126:	fbe48493          	addi	s1,s1,-66 # 800110e0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000212a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000212c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000212e:	00015917          	auipc	s2,0x15
    80002132:	bb290913          	addi	s2,s2,-1102 # 80016ce0 <tickslock>
    80002136:	a811                	j	8000214a <wakeup+0x3c>
      }
      release(&p->lock);
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	b9a080e7          	jalr	-1126(ra) # 80000cd4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002142:	17048493          	addi	s1,s1,368
    80002146:	03248663          	beq	s1,s2,80002172 <wakeup+0x64>
    if(p != myproc()){
    8000214a:	00000097          	auipc	ra,0x0
    8000214e:	8ac080e7          	jalr	-1876(ra) # 800019f6 <myproc>
    80002152:	fea488e3          	beq	s1,a0,80002142 <wakeup+0x34>
      acquire(&p->lock);
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	ac8080e7          	jalr	-1336(ra) # 80000c20 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002160:	4c9c                	lw	a5,24(s1)
    80002162:	fd379be3          	bne	a5,s3,80002138 <wakeup+0x2a>
    80002166:	709c                	ld	a5,32(s1)
    80002168:	fd4798e3          	bne	a5,s4,80002138 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000216c:	0154ac23          	sw	s5,24(s1)
    80002170:	b7e1                	j	80002138 <wakeup+0x2a>
    }
  }
}
    80002172:	70e2                	ld	ra,56(sp)
    80002174:	7442                	ld	s0,48(sp)
    80002176:	74a2                	ld	s1,40(sp)
    80002178:	7902                	ld	s2,32(sp)
    8000217a:	69e2                	ld	s3,24(sp)
    8000217c:	6a42                	ld	s4,16(sp)
    8000217e:	6aa2                	ld	s5,8(sp)
    80002180:	6121                	addi	sp,sp,64
    80002182:	8082                	ret

0000000080002184 <reparent>:
{
    80002184:	7179                	addi	sp,sp,-48
    80002186:	f406                	sd	ra,40(sp)
    80002188:	f022                	sd	s0,32(sp)
    8000218a:	ec26                	sd	s1,24(sp)
    8000218c:	e84a                	sd	s2,16(sp)
    8000218e:	e44e                	sd	s3,8(sp)
    80002190:	e052                	sd	s4,0(sp)
    80002192:	1800                	addi	s0,sp,48
    80002194:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002196:	0000f497          	auipc	s1,0xf
    8000219a:	f4a48493          	addi	s1,s1,-182 # 800110e0 <proc>
      pp->parent = initproc;
    8000219e:	00007a17          	auipc	s4,0x7
    800021a2:	89aa0a13          	addi	s4,s4,-1894 # 80008a38 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021a6:	00015997          	auipc	s3,0x15
    800021aa:	b3a98993          	addi	s3,s3,-1222 # 80016ce0 <tickslock>
    800021ae:	a029                	j	800021b8 <reparent+0x34>
    800021b0:	17048493          	addi	s1,s1,368
    800021b4:	01348d63          	beq	s1,s3,800021ce <reparent+0x4a>
    if(pp->parent == p){
    800021b8:	7c9c                	ld	a5,56(s1)
    800021ba:	ff279be3          	bne	a5,s2,800021b0 <reparent+0x2c>
      pp->parent = initproc;
    800021be:	000a3503          	ld	a0,0(s4)
    800021c2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	f4a080e7          	jalr	-182(ra) # 8000210e <wakeup>
    800021cc:	b7d5                	j	800021b0 <reparent+0x2c>
}
    800021ce:	70a2                	ld	ra,40(sp)
    800021d0:	7402                	ld	s0,32(sp)
    800021d2:	64e2                	ld	s1,24(sp)
    800021d4:	6942                	ld	s2,16(sp)
    800021d6:	69a2                	ld	s3,8(sp)
    800021d8:	6a02                	ld	s4,0(sp)
    800021da:	6145                	addi	sp,sp,48
    800021dc:	8082                	ret

00000000800021de <exit>:
{
    800021de:	7179                	addi	sp,sp,-48
    800021e0:	f406                	sd	ra,40(sp)
    800021e2:	f022                	sd	s0,32(sp)
    800021e4:	ec26                	sd	s1,24(sp)
    800021e6:	e84a                	sd	s2,16(sp)
    800021e8:	e44e                	sd	s3,8(sp)
    800021ea:	e052                	sd	s4,0(sp)
    800021ec:	1800                	addi	s0,sp,48
    800021ee:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021f0:	00000097          	auipc	ra,0x0
    800021f4:	806080e7          	jalr	-2042(ra) # 800019f6 <myproc>
    800021f8:	89aa                	mv	s3,a0
  if(p == initproc)
    800021fa:	00007797          	auipc	a5,0x7
    800021fe:	83e7b783          	ld	a5,-1986(a5) # 80008a38 <initproc>
    80002202:	0d050493          	addi	s1,a0,208
    80002206:	15050913          	addi	s2,a0,336
    8000220a:	02a79363          	bne	a5,a0,80002230 <exit+0x52>
    panic("init exiting");
    8000220e:	00006517          	auipc	a0,0x6
    80002212:	05250513          	addi	a0,a0,82 # 80008260 <digits+0x220>
    80002216:	ffffe097          	auipc	ra,0xffffe
    8000221a:	328080e7          	jalr	808(ra) # 8000053e <panic>
      fileclose(f);
    8000221e:	00002097          	auipc	ra,0x2
    80002222:	418080e7          	jalr	1048(ra) # 80004636 <fileclose>
      p->ofile[fd] = 0;
    80002226:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000222a:	04a1                	addi	s1,s1,8
    8000222c:	01248563          	beq	s1,s2,80002236 <exit+0x58>
    if(p->ofile[fd]){
    80002230:	6088                	ld	a0,0(s1)
    80002232:	f575                	bnez	a0,8000221e <exit+0x40>
    80002234:	bfdd                	j	8000222a <exit+0x4c>
  begin_op();
    80002236:	00002097          	auipc	ra,0x2
    8000223a:	f34080e7          	jalr	-204(ra) # 8000416a <begin_op>
  iput(p->cwd);
    8000223e:	1509b503          	ld	a0,336(s3)
    80002242:	00001097          	auipc	ra,0x1
    80002246:	720080e7          	jalr	1824(ra) # 80003962 <iput>
  end_op();
    8000224a:	00002097          	auipc	ra,0x2
    8000224e:	fa0080e7          	jalr	-96(ra) # 800041ea <end_op>
  p->cwd = 0;
    80002252:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002256:	0000f497          	auipc	s1,0xf
    8000225a:	a7248493          	addi	s1,s1,-1422 # 80010cc8 <wait_lock>
    8000225e:	8526                	mv	a0,s1
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	9c0080e7          	jalr	-1600(ra) # 80000c20 <acquire>
  reparent(p);
    80002268:	854e                	mv	a0,s3
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	f1a080e7          	jalr	-230(ra) # 80002184 <reparent>
  wakeup(p->parent);
    80002272:	0389b503          	ld	a0,56(s3)
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	e98080e7          	jalr	-360(ra) # 8000210e <wakeup>
  acquire(&p->lock);
    8000227e:	854e                	mv	a0,s3
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	9a0080e7          	jalr	-1632(ra) # 80000c20 <acquire>
  p->xstate = status;
    80002288:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000228c:	4795                	li	a5,5
    8000228e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002292:	8526                	mv	a0,s1
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	a40080e7          	jalr	-1472(ra) # 80000cd4 <release>
  sched();
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	cfc080e7          	jalr	-772(ra) # 80001f98 <sched>
  panic("zombie exit");
    800022a4:	00006517          	auipc	a0,0x6
    800022a8:	fcc50513          	addi	a0,a0,-52 # 80008270 <digits+0x230>
    800022ac:	ffffe097          	auipc	ra,0xffffe
    800022b0:	292080e7          	jalr	658(ra) # 8000053e <panic>

00000000800022b4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022b4:	7179                	addi	sp,sp,-48
    800022b6:	f406                	sd	ra,40(sp)
    800022b8:	f022                	sd	s0,32(sp)
    800022ba:	ec26                	sd	s1,24(sp)
    800022bc:	e84a                	sd	s2,16(sp)
    800022be:	e44e                	sd	s3,8(sp)
    800022c0:	1800                	addi	s0,sp,48
    800022c2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022c4:	0000f497          	auipc	s1,0xf
    800022c8:	e1c48493          	addi	s1,s1,-484 # 800110e0 <proc>
    800022cc:	00015997          	auipc	s3,0x15
    800022d0:	a1498993          	addi	s3,s3,-1516 # 80016ce0 <tickslock>
    acquire(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	94a080e7          	jalr	-1718(ra) # 80000c20 <acquire>
    if(p->pid == pid){
    800022de:	589c                	lw	a5,48(s1)
    800022e0:	01278d63          	beq	a5,s2,800022fa <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022e4:	8526                	mv	a0,s1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	9ee080e7          	jalr	-1554(ra) # 80000cd4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ee:	17048493          	addi	s1,s1,368
    800022f2:	ff3491e3          	bne	s1,s3,800022d4 <kill+0x20>
  }
  return -1;
    800022f6:	557d                	li	a0,-1
    800022f8:	a829                	j	80002312 <kill+0x5e>
      p->killed = 1;
    800022fa:	4785                	li	a5,1
    800022fc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022fe:	4c98                	lw	a4,24(s1)
    80002300:	4789                	li	a5,2
    80002302:	00f70f63          	beq	a4,a5,80002320 <kill+0x6c>
      release(&p->lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	9cc080e7          	jalr	-1588(ra) # 80000cd4 <release>
      return 0;
    80002310:	4501                	li	a0,0
}
    80002312:	70a2                	ld	ra,40(sp)
    80002314:	7402                	ld	s0,32(sp)
    80002316:	64e2                	ld	s1,24(sp)
    80002318:	6942                	ld	s2,16(sp)
    8000231a:	69a2                	ld	s3,8(sp)
    8000231c:	6145                	addi	sp,sp,48
    8000231e:	8082                	ret
        p->state = RUNNABLE;
    80002320:	478d                	li	a5,3
    80002322:	cc9c                	sw	a5,24(s1)
    80002324:	b7cd                	j	80002306 <kill+0x52>

0000000080002326 <setkilled>:

void
setkilled(struct proc *p)
{
    80002326:	1101                	addi	sp,sp,-32
    80002328:	ec06                	sd	ra,24(sp)
    8000232a:	e822                	sd	s0,16(sp)
    8000232c:	e426                	sd	s1,8(sp)
    8000232e:	1000                	addi	s0,sp,32
    80002330:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	8ee080e7          	jalr	-1810(ra) # 80000c20 <acquire>
  p->killed = 1;
    8000233a:	4785                	li	a5,1
    8000233c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	994080e7          	jalr	-1644(ra) # 80000cd4 <release>
}
    80002348:	60e2                	ld	ra,24(sp)
    8000234a:	6442                	ld	s0,16(sp)
    8000234c:	64a2                	ld	s1,8(sp)
    8000234e:	6105                	addi	sp,sp,32
    80002350:	8082                	ret

0000000080002352 <killed>:

int
killed(struct proc *p)
{
    80002352:	1101                	addi	sp,sp,-32
    80002354:	ec06                	sd	ra,24(sp)
    80002356:	e822                	sd	s0,16(sp)
    80002358:	e426                	sd	s1,8(sp)
    8000235a:	e04a                	sd	s2,0(sp)
    8000235c:	1000                	addi	s0,sp,32
    8000235e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	8c0080e7          	jalr	-1856(ra) # 80000c20 <acquire>
  k = p->killed;
    80002368:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	966080e7          	jalr	-1690(ra) # 80000cd4 <release>
  return k;
}
    80002376:	854a                	mv	a0,s2
    80002378:	60e2                	ld	ra,24(sp)
    8000237a:	6442                	ld	s0,16(sp)
    8000237c:	64a2                	ld	s1,8(sp)
    8000237e:	6902                	ld	s2,0(sp)
    80002380:	6105                	addi	sp,sp,32
    80002382:	8082                	ret

0000000080002384 <wait>:
{
    80002384:	715d                	addi	sp,sp,-80
    80002386:	e486                	sd	ra,72(sp)
    80002388:	e0a2                	sd	s0,64(sp)
    8000238a:	fc26                	sd	s1,56(sp)
    8000238c:	f84a                	sd	s2,48(sp)
    8000238e:	f44e                	sd	s3,40(sp)
    80002390:	f052                	sd	s4,32(sp)
    80002392:	ec56                	sd	s5,24(sp)
    80002394:	e85a                	sd	s6,16(sp)
    80002396:	e45e                	sd	s7,8(sp)
    80002398:	e062                	sd	s8,0(sp)
    8000239a:	0880                	addi	s0,sp,80
    8000239c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	658080e7          	jalr	1624(ra) # 800019f6 <myproc>
    800023a6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023a8:	0000f517          	auipc	a0,0xf
    800023ac:	92050513          	addi	a0,a0,-1760 # 80010cc8 <wait_lock>
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	870080e7          	jalr	-1936(ra) # 80000c20 <acquire>
    havekids = 0;
    800023b8:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023ba:	4a15                	li	s4,5
        havekids = 1;
    800023bc:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023be:	00015997          	auipc	s3,0x15
    800023c2:	92298993          	addi	s3,s3,-1758 # 80016ce0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023c6:	0000fc17          	auipc	s8,0xf
    800023ca:	902c0c13          	addi	s8,s8,-1790 # 80010cc8 <wait_lock>
    havekids = 0;
    800023ce:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023d0:	0000f497          	auipc	s1,0xf
    800023d4:	d1048493          	addi	s1,s1,-752 # 800110e0 <proc>
    800023d8:	a0bd                	j	80002446 <wait+0xc2>
          pid = pp->pid;
    800023da:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023de:	000b0e63          	beqz	s6,800023fa <wait+0x76>
    800023e2:	4691                	li	a3,4
    800023e4:	02c48613          	addi	a2,s1,44
    800023e8:	85da                	mv	a1,s6
    800023ea:	05093503          	ld	a0,80(s2)
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	2c4080e7          	jalr	708(ra) # 800016b2 <copyout>
    800023f6:	02054563          	bltz	a0,80002420 <wait+0x9c>
          freeproc(pp);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	7ac080e7          	jalr	1964(ra) # 80001ba8 <freeproc>
          release(&pp->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	8ce080e7          	jalr	-1842(ra) # 80000cd4 <release>
          release(&wait_lock);
    8000240e:	0000f517          	auipc	a0,0xf
    80002412:	8ba50513          	addi	a0,a0,-1862 # 80010cc8 <wait_lock>
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	8be080e7          	jalr	-1858(ra) # 80000cd4 <release>
          return pid;
    8000241e:	a0b5                	j	8000248a <wait+0x106>
            release(&pp->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	8b2080e7          	jalr	-1870(ra) # 80000cd4 <release>
            release(&wait_lock);
    8000242a:	0000f517          	auipc	a0,0xf
    8000242e:	89e50513          	addi	a0,a0,-1890 # 80010cc8 <wait_lock>
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	8a2080e7          	jalr	-1886(ra) # 80000cd4 <release>
            return -1;
    8000243a:	59fd                	li	s3,-1
    8000243c:	a0b9                	j	8000248a <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000243e:	17048493          	addi	s1,s1,368
    80002442:	03348463          	beq	s1,s3,8000246a <wait+0xe6>
      if(pp->parent == p){
    80002446:	7c9c                	ld	a5,56(s1)
    80002448:	ff279be3          	bne	a5,s2,8000243e <wait+0xba>
        acquire(&pp->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	7d2080e7          	jalr	2002(ra) # 80000c20 <acquire>
        if(pp->state == ZOMBIE){
    80002456:	4c9c                	lw	a5,24(s1)
    80002458:	f94781e3          	beq	a5,s4,800023da <wait+0x56>
        release(&pp->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	876080e7          	jalr	-1930(ra) # 80000cd4 <release>
        havekids = 1;
    80002466:	8756                	mv	a4,s5
    80002468:	bfd9                	j	8000243e <wait+0xba>
    if(!havekids || killed(p)){
    8000246a:	c719                	beqz	a4,80002478 <wait+0xf4>
    8000246c:	854a                	mv	a0,s2
    8000246e:	00000097          	auipc	ra,0x0
    80002472:	ee4080e7          	jalr	-284(ra) # 80002352 <killed>
    80002476:	c51d                	beqz	a0,800024a4 <wait+0x120>
      release(&wait_lock);
    80002478:	0000f517          	auipc	a0,0xf
    8000247c:	85050513          	addi	a0,a0,-1968 # 80010cc8 <wait_lock>
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	854080e7          	jalr	-1964(ra) # 80000cd4 <release>
      return -1;
    80002488:	59fd                	li	s3,-1
}
    8000248a:	854e                	mv	a0,s3
    8000248c:	60a6                	ld	ra,72(sp)
    8000248e:	6406                	ld	s0,64(sp)
    80002490:	74e2                	ld	s1,56(sp)
    80002492:	7942                	ld	s2,48(sp)
    80002494:	79a2                	ld	s3,40(sp)
    80002496:	7a02                	ld	s4,32(sp)
    80002498:	6ae2                	ld	s5,24(sp)
    8000249a:	6b42                	ld	s6,16(sp)
    8000249c:	6ba2                	ld	s7,8(sp)
    8000249e:	6c02                	ld	s8,0(sp)
    800024a0:	6161                	addi	sp,sp,80
    800024a2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024a4:	85e2                	mv	a1,s8
    800024a6:	854a                	mv	a0,s2
    800024a8:	00000097          	auipc	ra,0x0
    800024ac:	c02080e7          	jalr	-1022(ra) # 800020aa <sleep>
    havekids = 0;
    800024b0:	bf39                	j	800023ce <wait+0x4a>

00000000800024b2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	84aa                	mv	s1,a0
    800024c4:	892e                	mv	s2,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	52c080e7          	jalr	1324(ra) # 800019f6 <myproc>
  if(user_dst){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	1d6080e7          	jalr	470(ra) # 800016b2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove((char *)dst, src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	87c080e7          	jalr	-1924(ra) # 80000d78 <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyout+0x32>

0000000080002508 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002508:	7179                	addi	sp,sp,-48
    8000250a:	f406                	sd	ra,40(sp)
    8000250c:	f022                	sd	s0,32(sp)
    8000250e:	ec26                	sd	s1,24(sp)
    80002510:	e84a                	sd	s2,16(sp)
    80002512:	e44e                	sd	s3,8(sp)
    80002514:	e052                	sd	s4,0(sp)
    80002516:	1800                	addi	s0,sp,48
    80002518:	892a                	mv	s2,a0
    8000251a:	84ae                	mv	s1,a1
    8000251c:	89b2                	mv	s3,a2
    8000251e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	4d6080e7          	jalr	1238(ra) # 800019f6 <myproc>
  if(user_src){
    80002528:	c08d                	beqz	s1,8000254a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000252a:	86d2                	mv	a3,s4
    8000252c:	864e                	mv	a2,s3
    8000252e:	85ca                	mv	a1,s2
    80002530:	6928                	ld	a0,80(a0)
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	20c080e7          	jalr	524(ra) # 8000173e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000253a:	70a2                	ld	ra,40(sp)
    8000253c:	7402                	ld	s0,32(sp)
    8000253e:	64e2                	ld	s1,24(sp)
    80002540:	6942                	ld	s2,16(sp)
    80002542:	69a2                	ld	s3,8(sp)
    80002544:	6a02                	ld	s4,0(sp)
    80002546:	6145                	addi	sp,sp,48
    80002548:	8082                	ret
    memmove(dst, (char*)src, len);
    8000254a:	000a061b          	sext.w	a2,s4
    8000254e:	85ce                	mv	a1,s3
    80002550:	854a                	mv	a0,s2
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	826080e7          	jalr	-2010(ra) # 80000d78 <memmove>
    return 0;
    8000255a:	8526                	mv	a0,s1
    8000255c:	bff9                	j	8000253a <either_copyin+0x32>

000000008000255e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000255e:	715d                	addi	sp,sp,-80
    80002560:	e486                	sd	ra,72(sp)
    80002562:	e0a2                	sd	s0,64(sp)
    80002564:	fc26                	sd	s1,56(sp)
    80002566:	f84a                	sd	s2,48(sp)
    80002568:	f44e                	sd	s3,40(sp)
    8000256a:	f052                	sd	s4,32(sp)
    8000256c:	ec56                	sd	s5,24(sp)
    8000256e:	e85a                	sd	s6,16(sp)
    80002570:	e45e                	sd	s7,8(sp)
    80002572:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002574:	00006517          	auipc	a0,0x6
    80002578:	b5450513          	addi	a0,a0,-1196 # 800080c8 <digits+0x88>
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	00c080e7          	jalr	12(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002584:	0000f497          	auipc	s1,0xf
    80002588:	cb448493          	addi	s1,s1,-844 # 80011238 <proc+0x158>
    8000258c:	00015917          	auipc	s2,0x15
    80002590:	8ac90913          	addi	s2,s2,-1876 # 80016e38 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002594:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002596:	00006997          	auipc	s3,0x6
    8000259a:	cea98993          	addi	s3,s3,-790 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000259e:	00006a97          	auipc	s5,0x6
    800025a2:	ceaa8a93          	addi	s5,s5,-790 # 80008288 <digits+0x248>
    printf("\n");
    800025a6:	00006a17          	auipc	s4,0x6
    800025aa:	b22a0a13          	addi	s4,s4,-1246 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ae:	00006b97          	auipc	s7,0x6
    800025b2:	d1ab8b93          	addi	s7,s7,-742 # 800082c8 <states.0>
    800025b6:	a00d                	j	800025d8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025b8:	ed86a583          	lw	a1,-296(a3)
    800025bc:	8556                	mv	a0,s5
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	fca080e7          	jalr	-54(ra) # 80000588 <printf>
    printf("\n");
    800025c6:	8552                	mv	a0,s4
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	fc0080e7          	jalr	-64(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d0:	17048493          	addi	s1,s1,368
    800025d4:	03248163          	beq	s1,s2,800025f6 <procdump+0x98>
    if(p->state == UNUSED)
    800025d8:	86a6                	mv	a3,s1
    800025da:	ec04a783          	lw	a5,-320(s1)
    800025de:	dbed                	beqz	a5,800025d0 <procdump+0x72>
      state = "???";
    800025e0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e2:	fcfb6be3          	bltu	s6,a5,800025b8 <procdump+0x5a>
    800025e6:	1782                	slli	a5,a5,0x20
    800025e8:	9381                	srli	a5,a5,0x20
    800025ea:	078e                	slli	a5,a5,0x3
    800025ec:	97de                	add	a5,a5,s7
    800025ee:	6390                	ld	a2,0(a5)
    800025f0:	f661                	bnez	a2,800025b8 <procdump+0x5a>
      state = "???";
    800025f2:	864e                	mv	a2,s3
    800025f4:	b7d1                	j	800025b8 <procdump+0x5a>
  }
}
    800025f6:	60a6                	ld	ra,72(sp)
    800025f8:	6406                	ld	s0,64(sp)
    800025fa:	74e2                	ld	s1,56(sp)
    800025fc:	7942                	ld	s2,48(sp)
    800025fe:	79a2                	ld	s3,40(sp)
    80002600:	7a02                	ld	s4,32(sp)
    80002602:	6ae2                	ld	s5,24(sp)
    80002604:	6b42                	ld	s6,16(sp)
    80002606:	6ba2                	ld	s7,8(sp)
    80002608:	6161                	addi	sp,sp,80
    8000260a:	8082                	ret

000000008000260c <acquire_nproc>:

//获取进程数量
uint64 acquire_nproc()
{
    8000260c:	7179                	addi	sp,sp,-48
    8000260e:	f406                	sd	ra,40(sp)
    80002610:	f022                	sd	s0,32(sp)
    80002612:	ec26                	sd	s1,24(sp)
    80002614:	e84a                	sd	s2,16(sp)
    80002616:	e44e                	sd	s3,8(sp)
    80002618:	1800                	addi	s0,sp,48
  struct proc *p;
  int cnt = 0;
    8000261a:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000261c:	0000f497          	auipc	s1,0xf
    80002620:	ac448493          	addi	s1,s1,-1340 # 800110e0 <proc>
    80002624:	00014997          	auipc	s3,0x14
    80002628:	6bc98993          	addi	s3,s3,1724 # 80016ce0 <tickslock>
    8000262c:	a811                	j	80002640 <acquire_nproc+0x34>
    acquire(&p->lock);
    if(p->state != UNUSED) {
      cnt++;
    }
      release(&p->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	6a4080e7          	jalr	1700(ra) # 80000cd4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002638:	17048493          	addi	s1,s1,368
    8000263c:	01348b63          	beq	s1,s3,80002652 <acquire_nproc+0x46>
    acquire(&p->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	5de080e7          	jalr	1502(ra) # 80000c20 <acquire>
    if(p->state != UNUSED) {
    8000264a:	4c9c                	lw	a5,24(s1)
    8000264c:	d3ed                	beqz	a5,8000262e <acquire_nproc+0x22>
      cnt++;
    8000264e:	2905                	addiw	s2,s2,1
    80002650:	bff9                	j	8000262e <acquire_nproc+0x22>
  }
  return cnt;
    80002652:	854a                	mv	a0,s2
    80002654:	70a2                	ld	ra,40(sp)
    80002656:	7402                	ld	s0,32(sp)
    80002658:	64e2                	ld	s1,24(sp)
    8000265a:	6942                	ld	s2,16(sp)
    8000265c:	69a2                	ld	s3,8(sp)
    8000265e:	6145                	addi	sp,sp,48
    80002660:	8082                	ret

0000000080002662 <swtch>:
    80002662:	00153023          	sd	ra,0(a0)
    80002666:	00253423          	sd	sp,8(a0)
    8000266a:	e900                	sd	s0,16(a0)
    8000266c:	ed04                	sd	s1,24(a0)
    8000266e:	03253023          	sd	s2,32(a0)
    80002672:	03353423          	sd	s3,40(a0)
    80002676:	03453823          	sd	s4,48(a0)
    8000267a:	03553c23          	sd	s5,56(a0)
    8000267e:	05653023          	sd	s6,64(a0)
    80002682:	05753423          	sd	s7,72(a0)
    80002686:	05853823          	sd	s8,80(a0)
    8000268a:	05953c23          	sd	s9,88(a0)
    8000268e:	07a53023          	sd	s10,96(a0)
    80002692:	07b53423          	sd	s11,104(a0)
    80002696:	0005b083          	ld	ra,0(a1)
    8000269a:	0085b103          	ld	sp,8(a1)
    8000269e:	6980                	ld	s0,16(a1)
    800026a0:	6d84                	ld	s1,24(a1)
    800026a2:	0205b903          	ld	s2,32(a1)
    800026a6:	0285b983          	ld	s3,40(a1)
    800026aa:	0305ba03          	ld	s4,48(a1)
    800026ae:	0385ba83          	ld	s5,56(a1)
    800026b2:	0405bb03          	ld	s6,64(a1)
    800026b6:	0485bb83          	ld	s7,72(a1)
    800026ba:	0505bc03          	ld	s8,80(a1)
    800026be:	0585bc83          	ld	s9,88(a1)
    800026c2:	0605bd03          	ld	s10,96(a1)
    800026c6:	0685bd83          	ld	s11,104(a1)
    800026ca:	8082                	ret

00000000800026cc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026cc:	1141                	addi	sp,sp,-16
    800026ce:	e406                	sd	ra,8(sp)
    800026d0:	e022                	sd	s0,0(sp)
    800026d2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d4:	00006597          	auipc	a1,0x6
    800026d8:	c2458593          	addi	a1,a1,-988 # 800082f8 <states.0+0x30>
    800026dc:	00014517          	auipc	a0,0x14
    800026e0:	60450513          	addi	a0,a0,1540 # 80016ce0 <tickslock>
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	4ac080e7          	jalr	1196(ra) # 80000b90 <initlock>
}
    800026ec:	60a2                	ld	ra,8(sp)
    800026ee:	6402                	ld	s0,0(sp)
    800026f0:	0141                	addi	sp,sp,16
    800026f2:	8082                	ret

00000000800026f4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f4:	1141                	addi	sp,sp,-16
    800026f6:	e422                	sd	s0,8(sp)
    800026f8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fa:	00003797          	auipc	a5,0x3
    800026fe:	58678793          	addi	a5,a5,1414 # 80005c80 <kernelvec>
    80002702:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002706:	6422                	ld	s0,8(sp)
    80002708:	0141                	addi	sp,sp,16
    8000270a:	8082                	ret

000000008000270c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000270c:	1141                	addi	sp,sp,-16
    8000270e:	e406                	sd	ra,8(sp)
    80002710:	e022                	sd	s0,0(sp)
    80002712:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	2e2080e7          	jalr	738(ra) # 800019f6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000271c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002720:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002722:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002726:	00005617          	auipc	a2,0x5
    8000272a:	8da60613          	addi	a2,a2,-1830 # 80007000 <_trampoline>
    8000272e:	00005697          	auipc	a3,0x5
    80002732:	8d268693          	addi	a3,a3,-1838 # 80007000 <_trampoline>
    80002736:	8e91                	sub	a3,a3,a2
    80002738:	040007b7          	lui	a5,0x4000
    8000273c:	17fd                	addi	a5,a5,-1
    8000273e:	07b2                	slli	a5,a5,0xc
    80002740:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002742:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002746:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002748:	180026f3          	csrr	a3,satp
    8000274c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274e:	6d38                	ld	a4,88(a0)
    80002750:	6134                	ld	a3,64(a0)
    80002752:	6585                	lui	a1,0x1
    80002754:	96ae                	add	a3,a3,a1
    80002756:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002758:	6d38                	ld	a4,88(a0)
    8000275a:	00000697          	auipc	a3,0x0
    8000275e:	13068693          	addi	a3,a3,304 # 8000288a <usertrap>
    80002762:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002764:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002766:	8692                	mv	a3,tp
    80002768:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002772:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002776:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000277a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000277c:	6f18                	ld	a4,24(a4)
    8000277e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002782:	6928                	ld	a0,80(a0)
    80002784:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002786:	00005717          	auipc	a4,0x5
    8000278a:	91670713          	addi	a4,a4,-1770 # 8000709c <userret>
    8000278e:	8f11                	sub	a4,a4,a2
    80002790:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002792:	577d                	li	a4,-1
    80002794:	177e                	slli	a4,a4,0x3f
    80002796:	8d59                	or	a0,a0,a4
    80002798:	9782                	jalr	a5
}
    8000279a:	60a2                	ld	ra,8(sp)
    8000279c:	6402                	ld	s0,0(sp)
    8000279e:	0141                	addi	sp,sp,16
    800027a0:	8082                	ret

00000000800027a2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027a2:	1101                	addi	sp,sp,-32
    800027a4:	ec06                	sd	ra,24(sp)
    800027a6:	e822                	sd	s0,16(sp)
    800027a8:	e426                	sd	s1,8(sp)
    800027aa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027ac:	00014497          	auipc	s1,0x14
    800027b0:	53448493          	addi	s1,s1,1332 # 80016ce0 <tickslock>
    800027b4:	8526                	mv	a0,s1
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	46a080e7          	jalr	1130(ra) # 80000c20 <acquire>
  ticks++;
    800027be:	00006517          	auipc	a0,0x6
    800027c2:	28250513          	addi	a0,a0,642 # 80008a40 <ticks>
    800027c6:	411c                	lw	a5,0(a0)
    800027c8:	2785                	addiw	a5,a5,1
    800027ca:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027cc:	00000097          	auipc	ra,0x0
    800027d0:	942080e7          	jalr	-1726(ra) # 8000210e <wakeup>
  release(&tickslock);
    800027d4:	8526                	mv	a0,s1
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	4fe080e7          	jalr	1278(ra) # 80000cd4 <release>
}
    800027de:	60e2                	ld	ra,24(sp)
    800027e0:	6442                	ld	s0,16(sp)
    800027e2:	64a2                	ld	s1,8(sp)
    800027e4:	6105                	addi	sp,sp,32
    800027e6:	8082                	ret

00000000800027e8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027e8:	1101                	addi	sp,sp,-32
    800027ea:	ec06                	sd	ra,24(sp)
    800027ec:	e822                	sd	s0,16(sp)
    800027ee:	e426                	sd	s1,8(sp)
    800027f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027f6:	00074d63          	bltz	a4,80002810 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027fa:	57fd                	li	a5,-1
    800027fc:	17fe                	slli	a5,a5,0x3f
    800027fe:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002800:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002802:	06f70363          	beq	a4,a5,80002868 <devintr+0x80>
  }
}
    80002806:	60e2                	ld	ra,24(sp)
    80002808:	6442                	ld	s0,16(sp)
    8000280a:	64a2                	ld	s1,8(sp)
    8000280c:	6105                	addi	sp,sp,32
    8000280e:	8082                	ret
     (scause & 0xff) == 9){
    80002810:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002814:	46a5                	li	a3,9
    80002816:	fed792e3          	bne	a5,a3,800027fa <devintr+0x12>
    int irq = plic_claim();
    8000281a:	00003097          	auipc	ra,0x3
    8000281e:	56e080e7          	jalr	1390(ra) # 80005d88 <plic_claim>
    80002822:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002824:	47a9                	li	a5,10
    80002826:	02f50763          	beq	a0,a5,80002854 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000282a:	4785                	li	a5,1
    8000282c:	02f50963          	beq	a0,a5,8000285e <devintr+0x76>
    return 1;
    80002830:	4505                	li	a0,1
    } else if(irq){
    80002832:	d8f1                	beqz	s1,80002806 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002834:	85a6                	mv	a1,s1
    80002836:	00006517          	auipc	a0,0x6
    8000283a:	aca50513          	addi	a0,a0,-1334 # 80008300 <states.0+0x38>
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	d4a080e7          	jalr	-694(ra) # 80000588 <printf>
      plic_complete(irq);
    80002846:	8526                	mv	a0,s1
    80002848:	00003097          	auipc	ra,0x3
    8000284c:	564080e7          	jalr	1380(ra) # 80005dac <plic_complete>
    return 1;
    80002850:	4505                	li	a0,1
    80002852:	bf55                	j	80002806 <devintr+0x1e>
      uartintr();
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	146080e7          	jalr	326(ra) # 8000099a <uartintr>
    8000285c:	b7ed                	j	80002846 <devintr+0x5e>
      virtio_disk_intr();
    8000285e:	00004097          	auipc	ra,0x4
    80002862:	a1a080e7          	jalr	-1510(ra) # 80006278 <virtio_disk_intr>
    80002866:	b7c5                	j	80002846 <devintr+0x5e>
    if(cpuid() == 0){
    80002868:	fffff097          	auipc	ra,0xfffff
    8000286c:	162080e7          	jalr	354(ra) # 800019ca <cpuid>
    80002870:	c901                	beqz	a0,80002880 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002872:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002876:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002878:	14479073          	csrw	sip,a5
    return 2;
    8000287c:	4509                	li	a0,2
    8000287e:	b761                	j	80002806 <devintr+0x1e>
      clockintr();
    80002880:	00000097          	auipc	ra,0x0
    80002884:	f22080e7          	jalr	-222(ra) # 800027a2 <clockintr>
    80002888:	b7ed                	j	80002872 <devintr+0x8a>

000000008000288a <usertrap>:
{
    8000288a:	1101                	addi	sp,sp,-32
    8000288c:	ec06                	sd	ra,24(sp)
    8000288e:	e822                	sd	s0,16(sp)
    80002890:	e426                	sd	s1,8(sp)
    80002892:	e04a                	sd	s2,0(sp)
    80002894:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002896:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289a:	1007f793          	andi	a5,a5,256
    8000289e:	e3b1                	bnez	a5,800028e2 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a0:	00003797          	auipc	a5,0x3
    800028a4:	3e078793          	addi	a5,a5,992 # 80005c80 <kernelvec>
    800028a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	14a080e7          	jalr	330(ra) # 800019f6 <myproc>
    800028b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b8:	14102773          	csrr	a4,sepc
    800028bc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028be:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028c2:	47a1                	li	a5,8
    800028c4:	02f70763          	beq	a4,a5,800028f2 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	f20080e7          	jalr	-224(ra) # 800027e8 <devintr>
    800028d0:	892a                	mv	s2,a0
    800028d2:	c151                	beqz	a0,80002956 <usertrap+0xcc>
  if(killed(p))
    800028d4:	8526                	mv	a0,s1
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	a7c080e7          	jalr	-1412(ra) # 80002352 <killed>
    800028de:	c929                	beqz	a0,80002930 <usertrap+0xa6>
    800028e0:	a099                	j	80002926 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	a3e50513          	addi	a0,a0,-1474 # 80008320 <states.0+0x58>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c54080e7          	jalr	-940(ra) # 8000053e <panic>
    if(killed(p))
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	a60080e7          	jalr	-1440(ra) # 80002352 <killed>
    800028fa:	e921                	bnez	a0,8000294a <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028fc:	6cb8                	ld	a4,88(s1)
    800028fe:	6f1c                	ld	a5,24(a4)
    80002900:	0791                	addi	a5,a5,4
    80002902:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002904:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002908:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290c:	10079073          	csrw	sstatus,a5
    syscall();
    80002910:	00000097          	auipc	ra,0x0
    80002914:	2d4080e7          	jalr	724(ra) # 80002be4 <syscall>
  if(killed(p))
    80002918:	8526                	mv	a0,s1
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	a38080e7          	jalr	-1480(ra) # 80002352 <killed>
    80002922:	c911                	beqz	a0,80002936 <usertrap+0xac>
    80002924:	4901                	li	s2,0
    exit(-1);
    80002926:	557d                	li	a0,-1
    80002928:	00000097          	auipc	ra,0x0
    8000292c:	8b6080e7          	jalr	-1866(ra) # 800021de <exit>
  if(which_dev == 2)
    80002930:	4789                	li	a5,2
    80002932:	04f90f63          	beq	s2,a5,80002990 <usertrap+0x106>
  usertrapret();
    80002936:	00000097          	auipc	ra,0x0
    8000293a:	dd6080e7          	jalr	-554(ra) # 8000270c <usertrapret>
}
    8000293e:	60e2                	ld	ra,24(sp)
    80002940:	6442                	ld	s0,16(sp)
    80002942:	64a2                	ld	s1,8(sp)
    80002944:	6902                	ld	s2,0(sp)
    80002946:	6105                	addi	sp,sp,32
    80002948:	8082                	ret
      exit(-1);
    8000294a:	557d                	li	a0,-1
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	892080e7          	jalr	-1902(ra) # 800021de <exit>
    80002954:	b765                	j	800028fc <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002956:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000295a:	5890                	lw	a2,48(s1)
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	9e450513          	addi	a0,a0,-1564 # 80008340 <states.0+0x78>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c24080e7          	jalr	-988(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000296c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002970:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002974:	00006517          	auipc	a0,0x6
    80002978:	9fc50513          	addi	a0,a0,-1540 # 80008370 <states.0+0xa8>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	c0c080e7          	jalr	-1012(ra) # 80000588 <printf>
    setkilled(p);
    80002984:	8526                	mv	a0,s1
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	9a0080e7          	jalr	-1632(ra) # 80002326 <setkilled>
    8000298e:	b769                	j	80002918 <usertrap+0x8e>
    yield();
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	6de080e7          	jalr	1758(ra) # 8000206e <yield>
    80002998:	bf79                	j	80002936 <usertrap+0xac>

000000008000299a <kerneltrap>:
{
    8000299a:	7179                	addi	sp,sp,-48
    8000299c:	f406                	sd	ra,40(sp)
    8000299e:	f022                	sd	s0,32(sp)
    800029a0:	ec26                	sd	s1,24(sp)
    800029a2:	e84a                	sd	s2,16(sp)
    800029a4:	e44e                	sd	s3,8(sp)
    800029a6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029a8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029b4:	1004f793          	andi	a5,s1,256
    800029b8:	cb85                	beqz	a5,800029e8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029be:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029c0:	ef85                	bnez	a5,800029f8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029c2:	00000097          	auipc	ra,0x0
    800029c6:	e26080e7          	jalr	-474(ra) # 800027e8 <devintr>
    800029ca:	cd1d                	beqz	a0,80002a08 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029cc:	4789                	li	a5,2
    800029ce:	06f50a63          	beq	a0,a5,80002a42 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d6:	10049073          	csrw	sstatus,s1
}
    800029da:	70a2                	ld	ra,40(sp)
    800029dc:	7402                	ld	s0,32(sp)
    800029de:	64e2                	ld	s1,24(sp)
    800029e0:	6942                	ld	s2,16(sp)
    800029e2:	69a2                	ld	s3,8(sp)
    800029e4:	6145                	addi	sp,sp,48
    800029e6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029e8:	00006517          	auipc	a0,0x6
    800029ec:	9a850513          	addi	a0,a0,-1624 # 80008390 <states.0+0xc8>
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	b4e080e7          	jalr	-1202(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800029f8:	00006517          	auipc	a0,0x6
    800029fc:	9c050513          	addi	a0,a0,-1600 # 800083b8 <states.0+0xf0>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b3e080e7          	jalr	-1218(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a08:	85ce                	mv	a1,s3
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	9ce50513          	addi	a0,a0,-1586 # 800083d8 <states.0+0x110>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b76080e7          	jalr	-1162(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a1e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	9c650513          	addi	a0,a0,-1594 # 800083e8 <states.0+0x120>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b5e080e7          	jalr	-1186(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a32:	00006517          	auipc	a0,0x6
    80002a36:	9ce50513          	addi	a0,a0,-1586 # 80008400 <states.0+0x138>
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	b04080e7          	jalr	-1276(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	fb4080e7          	jalr	-76(ra) # 800019f6 <myproc>
    80002a4a:	d541                	beqz	a0,800029d2 <kerneltrap+0x38>
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	faa080e7          	jalr	-86(ra) # 800019f6 <myproc>
    80002a54:	4d18                	lw	a4,24(a0)
    80002a56:	4791                	li	a5,4
    80002a58:	f6f71de3          	bne	a4,a5,800029d2 <kerneltrap+0x38>
    yield();
    80002a5c:	fffff097          	auipc	ra,0xfffff
    80002a60:	612080e7          	jalr	1554(ra) # 8000206e <yield>
    80002a64:	b7bd                	j	800029d2 <kerneltrap+0x38>

0000000080002a66 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a66:	1101                	addi	sp,sp,-32
    80002a68:	ec06                	sd	ra,24(sp)
    80002a6a:	e822                	sd	s0,16(sp)
    80002a6c:	e426                	sd	s1,8(sp)
    80002a6e:	1000                	addi	s0,sp,32
    80002a70:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	f84080e7          	jalr	-124(ra) # 800019f6 <myproc>
  switch (n) {
    80002a7a:	4795                	li	a5,5
    80002a7c:	0497e163          	bltu	a5,s1,80002abe <argraw+0x58>
    80002a80:	048a                	slli	s1,s1,0x2
    80002a82:	00006717          	auipc	a4,0x6
    80002a86:	a7670713          	addi	a4,a4,-1418 # 800084f8 <states.0+0x230>
    80002a8a:	94ba                	add	s1,s1,a4
    80002a8c:	409c                	lw	a5,0(s1)
    80002a8e:	97ba                	add	a5,a5,a4
    80002a90:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a92:	6d3c                	ld	a5,88(a0)
    80002a94:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	64a2                	ld	s1,8(sp)
    80002a9c:	6105                	addi	sp,sp,32
    80002a9e:	8082                	ret
    return p->trapframe->a1;
    80002aa0:	6d3c                	ld	a5,88(a0)
    80002aa2:	7fa8                	ld	a0,120(a5)
    80002aa4:	bfcd                	j	80002a96 <argraw+0x30>
    return p->trapframe->a2;
    80002aa6:	6d3c                	ld	a5,88(a0)
    80002aa8:	63c8                	ld	a0,128(a5)
    80002aaa:	b7f5                	j	80002a96 <argraw+0x30>
    return p->trapframe->a3;
    80002aac:	6d3c                	ld	a5,88(a0)
    80002aae:	67c8                	ld	a0,136(a5)
    80002ab0:	b7dd                	j	80002a96 <argraw+0x30>
    return p->trapframe->a4;
    80002ab2:	6d3c                	ld	a5,88(a0)
    80002ab4:	6bc8                	ld	a0,144(a5)
    80002ab6:	b7c5                	j	80002a96 <argraw+0x30>
    return p->trapframe->a5;
    80002ab8:	6d3c                	ld	a5,88(a0)
    80002aba:	6fc8                	ld	a0,152(a5)
    80002abc:	bfe9                	j	80002a96 <argraw+0x30>
  panic("argraw");
    80002abe:	00006517          	auipc	a0,0x6
    80002ac2:	95250513          	addi	a0,a0,-1710 # 80008410 <states.0+0x148>
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	a78080e7          	jalr	-1416(ra) # 8000053e <panic>

0000000080002ace <fetchaddr>:
{
    80002ace:	1101                	addi	sp,sp,-32
    80002ad0:	ec06                	sd	ra,24(sp)
    80002ad2:	e822                	sd	s0,16(sp)
    80002ad4:	e426                	sd	s1,8(sp)
    80002ad6:	e04a                	sd	s2,0(sp)
    80002ad8:	1000                	addi	s0,sp,32
    80002ada:	84aa                	mv	s1,a0
    80002adc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	f18080e7          	jalr	-232(ra) # 800019f6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ae6:	653c                	ld	a5,72(a0)
    80002ae8:	02f4f863          	bgeu	s1,a5,80002b18 <fetchaddr+0x4a>
    80002aec:	00848713          	addi	a4,s1,8
    80002af0:	02e7e663          	bltu	a5,a4,80002b1c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002af4:	46a1                	li	a3,8
    80002af6:	8626                	mv	a2,s1
    80002af8:	85ca                	mv	a1,s2
    80002afa:	6928                	ld	a0,80(a0)
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	c42080e7          	jalr	-958(ra) # 8000173e <copyin>
    80002b04:	00a03533          	snez	a0,a0
    80002b08:	40a00533          	neg	a0,a0
}
    80002b0c:	60e2                	ld	ra,24(sp)
    80002b0e:	6442                	ld	s0,16(sp)
    80002b10:	64a2                	ld	s1,8(sp)
    80002b12:	6902                	ld	s2,0(sp)
    80002b14:	6105                	addi	sp,sp,32
    80002b16:	8082                	ret
    return -1;
    80002b18:	557d                	li	a0,-1
    80002b1a:	bfcd                	j	80002b0c <fetchaddr+0x3e>
    80002b1c:	557d                	li	a0,-1
    80002b1e:	b7fd                	j	80002b0c <fetchaddr+0x3e>

0000000080002b20 <fetchstr>:
{
    80002b20:	7179                	addi	sp,sp,-48
    80002b22:	f406                	sd	ra,40(sp)
    80002b24:	f022                	sd	s0,32(sp)
    80002b26:	ec26                	sd	s1,24(sp)
    80002b28:	e84a                	sd	s2,16(sp)
    80002b2a:	e44e                	sd	s3,8(sp)
    80002b2c:	1800                	addi	s0,sp,48
    80002b2e:	892a                	mv	s2,a0
    80002b30:	84ae                	mv	s1,a1
    80002b32:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	ec2080e7          	jalr	-318(ra) # 800019f6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b3c:	86ce                	mv	a3,s3
    80002b3e:	864a                	mv	a2,s2
    80002b40:	85a6                	mv	a1,s1
    80002b42:	6928                	ld	a0,80(a0)
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	c88080e7          	jalr	-888(ra) # 800017cc <copyinstr>
    80002b4c:	00054e63          	bltz	a0,80002b68 <fetchstr+0x48>
  return strlen(buf);
    80002b50:	8526                	mv	a0,s1
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	346080e7          	jalr	838(ra) # 80000e98 <strlen>
}
    80002b5a:	70a2                	ld	ra,40(sp)
    80002b5c:	7402                	ld	s0,32(sp)
    80002b5e:	64e2                	ld	s1,24(sp)
    80002b60:	6942                	ld	s2,16(sp)
    80002b62:	69a2                	ld	s3,8(sp)
    80002b64:	6145                	addi	sp,sp,48
    80002b66:	8082                	ret
    return -1;
    80002b68:	557d                	li	a0,-1
    80002b6a:	bfc5                	j	80002b5a <fetchstr+0x3a>

0000000080002b6c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b6c:	1101                	addi	sp,sp,-32
    80002b6e:	ec06                	sd	ra,24(sp)
    80002b70:	e822                	sd	s0,16(sp)
    80002b72:	e426                	sd	s1,8(sp)
    80002b74:	1000                	addi	s0,sp,32
    80002b76:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b78:	00000097          	auipc	ra,0x0
    80002b7c:	eee080e7          	jalr	-274(ra) # 80002a66 <argraw>
    80002b80:	c088                	sw	a0,0(s1)
}
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	64a2                	ld	s1,8(sp)
    80002b88:	6105                	addi	sp,sp,32
    80002b8a:	8082                	ret

0000000080002b8c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b8c:	1101                	addi	sp,sp,-32
    80002b8e:	ec06                	sd	ra,24(sp)
    80002b90:	e822                	sd	s0,16(sp)
    80002b92:	e426                	sd	s1,8(sp)
    80002b94:	1000                	addi	s0,sp,32
    80002b96:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	ece080e7          	jalr	-306(ra) # 80002a66 <argraw>
    80002ba0:	e088                	sd	a0,0(s1)
}
    80002ba2:	60e2                	ld	ra,24(sp)
    80002ba4:	6442                	ld	s0,16(sp)
    80002ba6:	64a2                	ld	s1,8(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret

0000000080002bac <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bac:	7179                	addi	sp,sp,-48
    80002bae:	f406                	sd	ra,40(sp)
    80002bb0:	f022                	sd	s0,32(sp)
    80002bb2:	ec26                	sd	s1,24(sp)
    80002bb4:	e84a                	sd	s2,16(sp)
    80002bb6:	1800                	addi	s0,sp,48
    80002bb8:	84ae                	mv	s1,a1
    80002bba:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bbc:	fd840593          	addi	a1,s0,-40
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	fcc080e7          	jalr	-52(ra) # 80002b8c <argaddr>
  return fetchstr(addr, buf, max);
    80002bc8:	864a                	mv	a2,s2
    80002bca:	85a6                	mv	a1,s1
    80002bcc:	fd843503          	ld	a0,-40(s0)
    80002bd0:	00000097          	auipc	ra,0x0
    80002bd4:	f50080e7          	jalr	-176(ra) # 80002b20 <fetchstr>
}
    80002bd8:	70a2                	ld	ra,40(sp)
    80002bda:	7402                	ld	s0,32(sp)
    80002bdc:	64e2                	ld	s1,24(sp)
    80002bde:	6942                	ld	s2,16(sp)
    80002be0:	6145                	addi	sp,sp,48
    80002be2:	8082                	ret

0000000080002be4 <syscall>:
  "fork","exit","wait","pipe","read","kill","exec","fstat","chdir","dup","getpid","sbrk","sleep","uptime",
  "open","write","mknod","unlink","link","mkdir","close","trace"
};
void
syscall(void)
{
    80002be4:	7179                	addi	sp,sp,-48
    80002be6:	f406                	sd	ra,40(sp)
    80002be8:	f022                	sd	s0,32(sp)
    80002bea:	ec26                	sd	s1,24(sp)
    80002bec:	e84a                	sd	s2,16(sp)
    80002bee:	e44e                	sd	s3,8(sp)
    80002bf0:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	e04080e7          	jalr	-508(ra) # 800019f6 <myproc>
    80002bfa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bfc:	05853903          	ld	s2,88(a0)
    80002c00:	0a893783          	ld	a5,168(s2)
    80002c04:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c08:	37fd                	addiw	a5,a5,-1
    80002c0a:	4759                	li	a4,22
    80002c0c:	04f76a63          	bltu	a4,a5,80002c60 <syscall+0x7c>
    80002c10:	00399713          	slli	a4,s3,0x3
    80002c14:	00006797          	auipc	a5,0x6
    80002c18:	8fc78793          	addi	a5,a5,-1796 # 80008510 <syscalls>
    80002c1c:	97ba                	add	a5,a5,a4
    80002c1e:	639c                	ld	a5,0(a5)
    80002c20:	c3a1                	beqz	a5,80002c60 <syscall+0x7c>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c22:	9782                	jalr	a5
    80002c24:	06a93823          	sd	a0,112(s2)
    int trace_mask = p->trace_mask;
    if((trace_mask >> num) & 1)
    80002c28:	1684a783          	lw	a5,360(s1)
    80002c2c:	4137d7bb          	sraw	a5,a5,s3
    80002c30:	8b85                	andi	a5,a5,1
    80002c32:	c7b1                	beqz	a5,80002c7e <syscall+0x9a>
    {
      //trace 32 grep hello README
      //syscall read -> 1023
      printf("%d: syscall %s -> %d\n",p->pid,syscall_names[num-1],p->trapframe->a0);
    80002c34:	6cb8                	ld	a4,88(s1)
    80002c36:	39fd                	addiw	s3,s3,-1
    80002c38:	00399793          	slli	a5,s3,0x3
    80002c3c:	00006997          	auipc	s3,0x6
    80002c40:	8d498993          	addi	s3,s3,-1836 # 80008510 <syscalls>
    80002c44:	99be                	add	s3,s3,a5
    80002c46:	7b34                	ld	a3,112(a4)
    80002c48:	0c09b603          	ld	a2,192(s3)
    80002c4c:	588c                	lw	a1,48(s1)
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	7ca50513          	addi	a0,a0,1994 # 80008418 <states.0+0x150>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	932080e7          	jalr	-1742(ra) # 80000588 <printf>
    80002c5e:	a005                	j	80002c7e <syscall+0x9a>

    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c60:	86ce                	mv	a3,s3
    80002c62:	15848613          	addi	a2,s1,344
    80002c66:	588c                	lw	a1,48(s1)
    80002c68:	00005517          	auipc	a0,0x5
    80002c6c:	7c850513          	addi	a0,a0,1992 # 80008430 <states.0+0x168>
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	918080e7          	jalr	-1768(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c78:	6cbc                	ld	a5,88(s1)
    80002c7a:	577d                	li	a4,-1
    80002c7c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c7e:	70a2                	ld	ra,40(sp)
    80002c80:	7402                	ld	s0,32(sp)
    80002c82:	64e2                	ld	s1,24(sp)
    80002c84:	6942                	ld	s2,16(sp)
    80002c86:	69a2                	ld	s3,8(sp)
    80002c88:	6145                	addi	sp,sp,48
    80002c8a:	8082                	ret

0000000080002c8c <sys_exit>:
uint64 acquire_freemem();
uint64 acquire_nproc();

uint64
sys_exit(void)
{
    80002c8c:	1101                	addi	sp,sp,-32
    80002c8e:	ec06                	sd	ra,24(sp)
    80002c90:	e822                	sd	s0,16(sp)
    80002c92:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c94:	fec40593          	addi	a1,s0,-20
    80002c98:	4501                	li	a0,0
    80002c9a:	00000097          	auipc	ra,0x0
    80002c9e:	ed2080e7          	jalr	-302(ra) # 80002b6c <argint>
  exit(n);
    80002ca2:	fec42503          	lw	a0,-20(s0)
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	538080e7          	jalr	1336(ra) # 800021de <exit>
  return 0;  // not reached
}
    80002cae:	4501                	li	a0,0
    80002cb0:	60e2                	ld	ra,24(sp)
    80002cb2:	6442                	ld	s0,16(sp)
    80002cb4:	6105                	addi	sp,sp,32
    80002cb6:	8082                	ret

0000000080002cb8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cb8:	1141                	addi	sp,sp,-16
    80002cba:	e406                	sd	ra,8(sp)
    80002cbc:	e022                	sd	s0,0(sp)
    80002cbe:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	d36080e7          	jalr	-714(ra) # 800019f6 <myproc>
}
    80002cc8:	5908                	lw	a0,48(a0)
    80002cca:	60a2                	ld	ra,8(sp)
    80002ccc:	6402                	ld	s0,0(sp)
    80002cce:	0141                	addi	sp,sp,16
    80002cd0:	8082                	ret

0000000080002cd2 <sys_fork>:

uint64
sys_fork(void)
{
    80002cd2:	1141                	addi	sp,sp,-16
    80002cd4:	e406                	sd	ra,8(sp)
    80002cd6:	e022                	sd	s0,0(sp)
    80002cd8:	0800                	addi	s0,sp,16
  return fork();
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	0d6080e7          	jalr	214(ra) # 80001db0 <fork>
}
    80002ce2:	60a2                	ld	ra,8(sp)
    80002ce4:	6402                	ld	s0,0(sp)
    80002ce6:	0141                	addi	sp,sp,16
    80002ce8:	8082                	ret

0000000080002cea <sys_wait>:

uint64
sys_wait(void)
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cf2:	fe840593          	addi	a1,s0,-24
    80002cf6:	4501                	li	a0,0
    80002cf8:	00000097          	auipc	ra,0x0
    80002cfc:	e94080e7          	jalr	-364(ra) # 80002b8c <argaddr>
  return wait(p);
    80002d00:	fe843503          	ld	a0,-24(s0)
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	680080e7          	jalr	1664(ra) # 80002384 <wait>
}
    80002d0c:	60e2                	ld	ra,24(sp)
    80002d0e:	6442                	ld	s0,16(sp)
    80002d10:	6105                	addi	sp,sp,32
    80002d12:	8082                	ret

0000000080002d14 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d14:	7179                	addi	sp,sp,-48
    80002d16:	f406                	sd	ra,40(sp)
    80002d18:	f022                	sd	s0,32(sp)
    80002d1a:	ec26                	sd	s1,24(sp)
    80002d1c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d1e:	fdc40593          	addi	a1,s0,-36
    80002d22:	4501                	li	a0,0
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	e48080e7          	jalr	-440(ra) # 80002b6c <argint>
  addr = myproc()->sz;
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	cca080e7          	jalr	-822(ra) # 800019f6 <myproc>
    80002d34:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d36:	fdc42503          	lw	a0,-36(s0)
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	01a080e7          	jalr	26(ra) # 80001d54 <growproc>
    80002d42:	00054863          	bltz	a0,80002d52 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d46:	8526                	mv	a0,s1
    80002d48:	70a2                	ld	ra,40(sp)
    80002d4a:	7402                	ld	s0,32(sp)
    80002d4c:	64e2                	ld	s1,24(sp)
    80002d4e:	6145                	addi	sp,sp,48
    80002d50:	8082                	ret
    return -1;
    80002d52:	54fd                	li	s1,-1
    80002d54:	bfcd                	j	80002d46 <sys_sbrk+0x32>

0000000080002d56 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d56:	7139                	addi	sp,sp,-64
    80002d58:	fc06                	sd	ra,56(sp)
    80002d5a:	f822                	sd	s0,48(sp)
    80002d5c:	f426                	sd	s1,40(sp)
    80002d5e:	f04a                	sd	s2,32(sp)
    80002d60:	ec4e                	sd	s3,24(sp)
    80002d62:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d64:	fcc40593          	addi	a1,s0,-52
    80002d68:	4501                	li	a0,0
    80002d6a:	00000097          	auipc	ra,0x0
    80002d6e:	e02080e7          	jalr	-510(ra) # 80002b6c <argint>
  acquire(&tickslock);
    80002d72:	00014517          	auipc	a0,0x14
    80002d76:	f6e50513          	addi	a0,a0,-146 # 80016ce0 <tickslock>
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	ea6080e7          	jalr	-346(ra) # 80000c20 <acquire>
  ticks0 = ticks;
    80002d82:	00006917          	auipc	s2,0x6
    80002d86:	cbe92903          	lw	s2,-834(s2) # 80008a40 <ticks>
  while(ticks - ticks0 < n){
    80002d8a:	fcc42783          	lw	a5,-52(s0)
    80002d8e:	cf9d                	beqz	a5,80002dcc <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d90:	00014997          	auipc	s3,0x14
    80002d94:	f5098993          	addi	s3,s3,-176 # 80016ce0 <tickslock>
    80002d98:	00006497          	auipc	s1,0x6
    80002d9c:	ca848493          	addi	s1,s1,-856 # 80008a40 <ticks>
    if(killed(myproc())){
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	c56080e7          	jalr	-938(ra) # 800019f6 <myproc>
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	5aa080e7          	jalr	1450(ra) # 80002352 <killed>
    80002db0:	ed15                	bnez	a0,80002dec <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002db2:	85ce                	mv	a1,s3
    80002db4:	8526                	mv	a0,s1
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	2f4080e7          	jalr	756(ra) # 800020aa <sleep>
  while(ticks - ticks0 < n){
    80002dbe:	409c                	lw	a5,0(s1)
    80002dc0:	412787bb          	subw	a5,a5,s2
    80002dc4:	fcc42703          	lw	a4,-52(s0)
    80002dc8:	fce7ece3          	bltu	a5,a4,80002da0 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002dcc:	00014517          	auipc	a0,0x14
    80002dd0:	f1450513          	addi	a0,a0,-236 # 80016ce0 <tickslock>
    80002dd4:	ffffe097          	auipc	ra,0xffffe
    80002dd8:	f00080e7          	jalr	-256(ra) # 80000cd4 <release>
  return 0;
    80002ddc:	4501                	li	a0,0
}
    80002dde:	70e2                	ld	ra,56(sp)
    80002de0:	7442                	ld	s0,48(sp)
    80002de2:	74a2                	ld	s1,40(sp)
    80002de4:	7902                	ld	s2,32(sp)
    80002de6:	69e2                	ld	s3,24(sp)
    80002de8:	6121                	addi	sp,sp,64
    80002dea:	8082                	ret
      release(&tickslock);
    80002dec:	00014517          	auipc	a0,0x14
    80002df0:	ef450513          	addi	a0,a0,-268 # 80016ce0 <tickslock>
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	ee0080e7          	jalr	-288(ra) # 80000cd4 <release>
      return -1;
    80002dfc:	557d                	li	a0,-1
    80002dfe:	b7c5                	j	80002dde <sys_sleep+0x88>

0000000080002e00 <sys_kill>:

uint64
sys_kill(void)
{
    80002e00:	1101                	addi	sp,sp,-32
    80002e02:	ec06                	sd	ra,24(sp)
    80002e04:	e822                	sd	s0,16(sp)
    80002e06:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e08:	fec40593          	addi	a1,s0,-20
    80002e0c:	4501                	li	a0,0
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	d5e080e7          	jalr	-674(ra) # 80002b6c <argint>
  return kill(pid);
    80002e16:	fec42503          	lw	a0,-20(s0)
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	49a080e7          	jalr	1178(ra) # 800022b4 <kill>
}
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	6105                	addi	sp,sp,32
    80002e28:	8082                	ret

0000000080002e2a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e2a:	1101                	addi	sp,sp,-32
    80002e2c:	ec06                	sd	ra,24(sp)
    80002e2e:	e822                	sd	s0,16(sp)
    80002e30:	e426                	sd	s1,8(sp)
    80002e32:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e34:	00014517          	auipc	a0,0x14
    80002e38:	eac50513          	addi	a0,a0,-340 # 80016ce0 <tickslock>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	de4080e7          	jalr	-540(ra) # 80000c20 <acquire>
  xticks = ticks;
    80002e44:	00006497          	auipc	s1,0x6
    80002e48:	bfc4a483          	lw	s1,-1028(s1) # 80008a40 <ticks>
  release(&tickslock);
    80002e4c:	00014517          	auipc	a0,0x14
    80002e50:	e9450513          	addi	a0,a0,-364 # 80016ce0 <tickslock>
    80002e54:	ffffe097          	auipc	ra,0xffffe
    80002e58:	e80080e7          	jalr	-384(ra) # 80000cd4 <release>
  return xticks;
}
    80002e5c:	02049513          	slli	a0,s1,0x20
    80002e60:	9101                	srli	a0,a0,0x20
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	64a2                	ld	s1,8(sp)
    80002e68:	6105                	addi	sp,sp,32
    80002e6a:	8082                	ret

0000000080002e6c <sys_trace>:

uint64
sys_trace(void)
{
    80002e6c:	1101                	addi	sp,sp,-32
    80002e6e:	ec06                	sd	ra,24(sp)
    80002e70:	e822                	sd	s0,16(sp)
    80002e72:	1000                	addi	s0,sp,32
  int mask;
  argint(0,&mask);
    80002e74:	fec40593          	addi	a1,s0,-20
    80002e78:	4501                	li	a0,0
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	cf2080e7          	jalr	-782(ra) # 80002b6c <argint>
  if( mask < 0)
    80002e82:	fec42783          	lw	a5,-20(s0)
    return -1;
    80002e86:	557d                	li	a0,-1
  if( mask < 0)
    80002e88:	0007cb63          	bltz	a5,80002e9e <sys_trace+0x32>
  struct proc *p = myproc();
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	b6a080e7          	jalr	-1174(ra) # 800019f6 <myproc>
  p->trace_mask = mask;
    80002e94:	fec42783          	lw	a5,-20(s0)
    80002e98:	16f52423          	sw	a5,360(a0)
  return 0;
    80002e9c:	4501                	li	a0,0
}
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	6105                	addi	sp,sp,32
    80002ea4:	8082                	ret

0000000080002ea6 <sys_sysinfo>:

uint64
sys_sysinfo(void)
{
    80002ea6:	7139                	addi	sp,sp,-64
    80002ea8:	fc06                	sd	ra,56(sp)
    80002eaa:	f822                	sd	s0,48(sp)
    80002eac:	f426                	sd	s1,40(sp)
    80002eae:	0080                	addi	s0,sp,64
  struct sysinfo info;
  uint64 addr;// user pointer to struct stat
  struct proc *p = myproc();
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	b46080e7          	jalr	-1210(ra) # 800019f6 <myproc>
    80002eb8:	84aa                	mv	s1,a0
  argaddr(0 , &addr);//接受第0个参数，用户空间获取第0个参数(即缓冲区地址)
    80002eba:	fc840593          	addi	a1,s0,-56
    80002ebe:	4501                	li	a0,0
    80002ec0:	00000097          	auipc	ra,0x0
    80002ec4:	ccc080e7          	jalr	-820(ra) # 80002b8c <argaddr>
  if(addr < 0)
    return -1;
  info.nproc = acquire_nproc();
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	744080e7          	jalr	1860(ra) # 8000260c <acquire_nproc>
    80002ed0:	fca43c23          	sd	a0,-40(s0)
  info.freemem = acquire_freemem();
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	c72080e7          	jalr	-910(ra) # 80000b46 <acquire_freemem>
    80002edc:	fca43823          	sd	a0,-48(s0)
  //把info信息拷到addr处
  if(copyout(p->pagetable, addr, (char *)&info, sizeof(info)) < 0)
    80002ee0:	46c1                	li	a3,16
    80002ee2:	fd040613          	addi	a2,s0,-48
    80002ee6:	fc843583          	ld	a1,-56(s0)
    80002eea:	68a8                	ld	a0,80(s1)
    80002eec:	ffffe097          	auipc	ra,0xffffe
    80002ef0:	7c6080e7          	jalr	1990(ra) # 800016b2 <copyout>
    return -1;
  return 0;
    80002ef4:	957d                	srai	a0,a0,0x3f
    80002ef6:	70e2                	ld	ra,56(sp)
    80002ef8:	7442                	ld	s0,48(sp)
    80002efa:	74a2                	ld	s1,40(sp)
    80002efc:	6121                	addi	sp,sp,64
    80002efe:	8082                	ret

0000000080002f00 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f00:	7179                	addi	sp,sp,-48
    80002f02:	f406                	sd	ra,40(sp)
    80002f04:	f022                	sd	s0,32(sp)
    80002f06:	ec26                	sd	s1,24(sp)
    80002f08:	e84a                	sd	s2,16(sp)
    80002f0a:	e44e                	sd	s3,8(sp)
    80002f0c:	e052                	sd	s4,0(sp)
    80002f0e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f10:	00005597          	auipc	a1,0x5
    80002f14:	77058593          	addi	a1,a1,1904 # 80008680 <syscall_names+0xb0>
    80002f18:	00014517          	auipc	a0,0x14
    80002f1c:	de050513          	addi	a0,a0,-544 # 80016cf8 <bcache>
    80002f20:	ffffe097          	auipc	ra,0xffffe
    80002f24:	c70080e7          	jalr	-912(ra) # 80000b90 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f28:	0001c797          	auipc	a5,0x1c
    80002f2c:	dd078793          	addi	a5,a5,-560 # 8001ecf8 <bcache+0x8000>
    80002f30:	0001c717          	auipc	a4,0x1c
    80002f34:	03070713          	addi	a4,a4,48 # 8001ef60 <bcache+0x8268>
    80002f38:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f3c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f40:	00014497          	auipc	s1,0x14
    80002f44:	dd048493          	addi	s1,s1,-560 # 80016d10 <bcache+0x18>
    b->next = bcache.head.next;
    80002f48:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f4a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f4c:	00005a17          	auipc	s4,0x5
    80002f50:	73ca0a13          	addi	s4,s4,1852 # 80008688 <syscall_names+0xb8>
    b->next = bcache.head.next;
    80002f54:	2b893783          	ld	a5,696(s2)
    80002f58:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f5a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f5e:	85d2                	mv	a1,s4
    80002f60:	01048513          	addi	a0,s1,16
    80002f64:	00001097          	auipc	ra,0x1
    80002f68:	4c4080e7          	jalr	1220(ra) # 80004428 <initsleeplock>
    bcache.head.next->prev = b;
    80002f6c:	2b893783          	ld	a5,696(s2)
    80002f70:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f72:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f76:	45848493          	addi	s1,s1,1112
    80002f7a:	fd349de3          	bne	s1,s3,80002f54 <binit+0x54>
  }
}
    80002f7e:	70a2                	ld	ra,40(sp)
    80002f80:	7402                	ld	s0,32(sp)
    80002f82:	64e2                	ld	s1,24(sp)
    80002f84:	6942                	ld	s2,16(sp)
    80002f86:	69a2                	ld	s3,8(sp)
    80002f88:	6a02                	ld	s4,0(sp)
    80002f8a:	6145                	addi	sp,sp,48
    80002f8c:	8082                	ret

0000000080002f8e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f8e:	7179                	addi	sp,sp,-48
    80002f90:	f406                	sd	ra,40(sp)
    80002f92:	f022                	sd	s0,32(sp)
    80002f94:	ec26                	sd	s1,24(sp)
    80002f96:	e84a                	sd	s2,16(sp)
    80002f98:	e44e                	sd	s3,8(sp)
    80002f9a:	1800                	addi	s0,sp,48
    80002f9c:	892a                	mv	s2,a0
    80002f9e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fa0:	00014517          	auipc	a0,0x14
    80002fa4:	d5850513          	addi	a0,a0,-680 # 80016cf8 <bcache>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	c78080e7          	jalr	-904(ra) # 80000c20 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb0:	0001c497          	auipc	s1,0x1c
    80002fb4:	0004b483          	ld	s1,0(s1) # 8001efb0 <bcache+0x82b8>
    80002fb8:	0001c797          	auipc	a5,0x1c
    80002fbc:	fa878793          	addi	a5,a5,-88 # 8001ef60 <bcache+0x8268>
    80002fc0:	02f48f63          	beq	s1,a5,80002ffe <bread+0x70>
    80002fc4:	873e                	mv	a4,a5
    80002fc6:	a021                	j	80002fce <bread+0x40>
    80002fc8:	68a4                	ld	s1,80(s1)
    80002fca:	02e48a63          	beq	s1,a4,80002ffe <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fce:	449c                	lw	a5,8(s1)
    80002fd0:	ff279ce3          	bne	a5,s2,80002fc8 <bread+0x3a>
    80002fd4:	44dc                	lw	a5,12(s1)
    80002fd6:	ff3799e3          	bne	a5,s3,80002fc8 <bread+0x3a>
      b->refcnt++;
    80002fda:	40bc                	lw	a5,64(s1)
    80002fdc:	2785                	addiw	a5,a5,1
    80002fde:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe0:	00014517          	auipc	a0,0x14
    80002fe4:	d1850513          	addi	a0,a0,-744 # 80016cf8 <bcache>
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	cec080e7          	jalr	-788(ra) # 80000cd4 <release>
      acquiresleep(&b->lock);
    80002ff0:	01048513          	addi	a0,s1,16
    80002ff4:	00001097          	auipc	ra,0x1
    80002ff8:	46e080e7          	jalr	1134(ra) # 80004462 <acquiresleep>
      return b;
    80002ffc:	a8b9                	j	8000305a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ffe:	0001c497          	auipc	s1,0x1c
    80003002:	faa4b483          	ld	s1,-86(s1) # 8001efa8 <bcache+0x82b0>
    80003006:	0001c797          	auipc	a5,0x1c
    8000300a:	f5a78793          	addi	a5,a5,-166 # 8001ef60 <bcache+0x8268>
    8000300e:	00f48863          	beq	s1,a5,8000301e <bread+0x90>
    80003012:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003014:	40bc                	lw	a5,64(s1)
    80003016:	cf81                	beqz	a5,8000302e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003018:	64a4                	ld	s1,72(s1)
    8000301a:	fee49de3          	bne	s1,a4,80003014 <bread+0x86>
  panic("bget: no buffers");
    8000301e:	00005517          	auipc	a0,0x5
    80003022:	67250513          	addi	a0,a0,1650 # 80008690 <syscall_names+0xc0>
    80003026:	ffffd097          	auipc	ra,0xffffd
    8000302a:	518080e7          	jalr	1304(ra) # 8000053e <panic>
      b->dev = dev;
    8000302e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003032:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003036:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000303a:	4785                	li	a5,1
    8000303c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000303e:	00014517          	auipc	a0,0x14
    80003042:	cba50513          	addi	a0,a0,-838 # 80016cf8 <bcache>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	c8e080e7          	jalr	-882(ra) # 80000cd4 <release>
      acquiresleep(&b->lock);
    8000304e:	01048513          	addi	a0,s1,16
    80003052:	00001097          	auipc	ra,0x1
    80003056:	410080e7          	jalr	1040(ra) # 80004462 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000305a:	409c                	lw	a5,0(s1)
    8000305c:	cb89                	beqz	a5,8000306e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000305e:	8526                	mv	a0,s1
    80003060:	70a2                	ld	ra,40(sp)
    80003062:	7402                	ld	s0,32(sp)
    80003064:	64e2                	ld	s1,24(sp)
    80003066:	6942                	ld	s2,16(sp)
    80003068:	69a2                	ld	s3,8(sp)
    8000306a:	6145                	addi	sp,sp,48
    8000306c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000306e:	4581                	li	a1,0
    80003070:	8526                	mv	a0,s1
    80003072:	00003097          	auipc	ra,0x3
    80003076:	fd2080e7          	jalr	-46(ra) # 80006044 <virtio_disk_rw>
    b->valid = 1;
    8000307a:	4785                	li	a5,1
    8000307c:	c09c                	sw	a5,0(s1)
  return b;
    8000307e:	b7c5                	j	8000305e <bread+0xd0>

0000000080003080 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003080:	1101                	addi	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	e426                	sd	s1,8(sp)
    80003088:	1000                	addi	s0,sp,32
    8000308a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000308c:	0541                	addi	a0,a0,16
    8000308e:	00001097          	auipc	ra,0x1
    80003092:	46e080e7          	jalr	1134(ra) # 800044fc <holdingsleep>
    80003096:	cd01                	beqz	a0,800030ae <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003098:	4585                	li	a1,1
    8000309a:	8526                	mv	a0,s1
    8000309c:	00003097          	auipc	ra,0x3
    800030a0:	fa8080e7          	jalr	-88(ra) # 80006044 <virtio_disk_rw>
}
    800030a4:	60e2                	ld	ra,24(sp)
    800030a6:	6442                	ld	s0,16(sp)
    800030a8:	64a2                	ld	s1,8(sp)
    800030aa:	6105                	addi	sp,sp,32
    800030ac:	8082                	ret
    panic("bwrite");
    800030ae:	00005517          	auipc	a0,0x5
    800030b2:	5fa50513          	addi	a0,a0,1530 # 800086a8 <syscall_names+0xd8>
    800030b6:	ffffd097          	auipc	ra,0xffffd
    800030ba:	488080e7          	jalr	1160(ra) # 8000053e <panic>

00000000800030be <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030be:	1101                	addi	sp,sp,-32
    800030c0:	ec06                	sd	ra,24(sp)
    800030c2:	e822                	sd	s0,16(sp)
    800030c4:	e426                	sd	s1,8(sp)
    800030c6:	e04a                	sd	s2,0(sp)
    800030c8:	1000                	addi	s0,sp,32
    800030ca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030cc:	01050913          	addi	s2,a0,16
    800030d0:	854a                	mv	a0,s2
    800030d2:	00001097          	auipc	ra,0x1
    800030d6:	42a080e7          	jalr	1066(ra) # 800044fc <holdingsleep>
    800030da:	c92d                	beqz	a0,8000314c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030dc:	854a                	mv	a0,s2
    800030de:	00001097          	auipc	ra,0x1
    800030e2:	3da080e7          	jalr	986(ra) # 800044b8 <releasesleep>

  acquire(&bcache.lock);
    800030e6:	00014517          	auipc	a0,0x14
    800030ea:	c1250513          	addi	a0,a0,-1006 # 80016cf8 <bcache>
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	b32080e7          	jalr	-1230(ra) # 80000c20 <acquire>
  b->refcnt--;
    800030f6:	40bc                	lw	a5,64(s1)
    800030f8:	37fd                	addiw	a5,a5,-1
    800030fa:	0007871b          	sext.w	a4,a5
    800030fe:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003100:	eb05                	bnez	a4,80003130 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003102:	68bc                	ld	a5,80(s1)
    80003104:	64b8                	ld	a4,72(s1)
    80003106:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003108:	64bc                	ld	a5,72(s1)
    8000310a:	68b8                	ld	a4,80(s1)
    8000310c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000310e:	0001c797          	auipc	a5,0x1c
    80003112:	bea78793          	addi	a5,a5,-1046 # 8001ecf8 <bcache+0x8000>
    80003116:	2b87b703          	ld	a4,696(a5)
    8000311a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000311c:	0001c717          	auipc	a4,0x1c
    80003120:	e4470713          	addi	a4,a4,-444 # 8001ef60 <bcache+0x8268>
    80003124:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003126:	2b87b703          	ld	a4,696(a5)
    8000312a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000312c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003130:	00014517          	auipc	a0,0x14
    80003134:	bc850513          	addi	a0,a0,-1080 # 80016cf8 <bcache>
    80003138:	ffffe097          	auipc	ra,0xffffe
    8000313c:	b9c080e7          	jalr	-1124(ra) # 80000cd4 <release>
}
    80003140:	60e2                	ld	ra,24(sp)
    80003142:	6442                	ld	s0,16(sp)
    80003144:	64a2                	ld	s1,8(sp)
    80003146:	6902                	ld	s2,0(sp)
    80003148:	6105                	addi	sp,sp,32
    8000314a:	8082                	ret
    panic("brelse");
    8000314c:	00005517          	auipc	a0,0x5
    80003150:	56450513          	addi	a0,a0,1380 # 800086b0 <syscall_names+0xe0>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	3ea080e7          	jalr	1002(ra) # 8000053e <panic>

000000008000315c <bpin>:

void
bpin(struct buf *b) {
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	e426                	sd	s1,8(sp)
    80003164:	1000                	addi	s0,sp,32
    80003166:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003168:	00014517          	auipc	a0,0x14
    8000316c:	b9050513          	addi	a0,a0,-1136 # 80016cf8 <bcache>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	ab0080e7          	jalr	-1360(ra) # 80000c20 <acquire>
  b->refcnt++;
    80003178:	40bc                	lw	a5,64(s1)
    8000317a:	2785                	addiw	a5,a5,1
    8000317c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000317e:	00014517          	auipc	a0,0x14
    80003182:	b7a50513          	addi	a0,a0,-1158 # 80016cf8 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	b4e080e7          	jalr	-1202(ra) # 80000cd4 <release>
}
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	64a2                	ld	s1,8(sp)
    80003194:	6105                	addi	sp,sp,32
    80003196:	8082                	ret

0000000080003198 <bunpin>:

void
bunpin(struct buf *b) {
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	e426                	sd	s1,8(sp)
    800031a0:	1000                	addi	s0,sp,32
    800031a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	b5450513          	addi	a0,a0,-1196 # 80016cf8 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	a74080e7          	jalr	-1420(ra) # 80000c20 <acquire>
  b->refcnt--;
    800031b4:	40bc                	lw	a5,64(s1)
    800031b6:	37fd                	addiw	a5,a5,-1
    800031b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ba:	00014517          	auipc	a0,0x14
    800031be:	b3e50513          	addi	a0,a0,-1218 # 80016cf8 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	b12080e7          	jalr	-1262(ra) # 80000cd4 <release>
}
    800031ca:	60e2                	ld	ra,24(sp)
    800031cc:	6442                	ld	s0,16(sp)
    800031ce:	64a2                	ld	s1,8(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret

00000000800031d4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031d4:	1101                	addi	sp,sp,-32
    800031d6:	ec06                	sd	ra,24(sp)
    800031d8:	e822                	sd	s0,16(sp)
    800031da:	e426                	sd	s1,8(sp)
    800031dc:	e04a                	sd	s2,0(sp)
    800031de:	1000                	addi	s0,sp,32
    800031e0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031e2:	00d5d59b          	srliw	a1,a1,0xd
    800031e6:	0001c797          	auipc	a5,0x1c
    800031ea:	1ee7a783          	lw	a5,494(a5) # 8001f3d4 <sb+0x1c>
    800031ee:	9dbd                	addw	a1,a1,a5
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	d9e080e7          	jalr	-610(ra) # 80002f8e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031f8:	0074f713          	andi	a4,s1,7
    800031fc:	4785                	li	a5,1
    800031fe:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003202:	14ce                	slli	s1,s1,0x33
    80003204:	90d9                	srli	s1,s1,0x36
    80003206:	00950733          	add	a4,a0,s1
    8000320a:	05874703          	lbu	a4,88(a4)
    8000320e:	00e7f6b3          	and	a3,a5,a4
    80003212:	c69d                	beqz	a3,80003240 <bfree+0x6c>
    80003214:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003216:	94aa                	add	s1,s1,a0
    80003218:	fff7c793          	not	a5,a5
    8000321c:	8ff9                	and	a5,a5,a4
    8000321e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003222:	00001097          	auipc	ra,0x1
    80003226:	120080e7          	jalr	288(ra) # 80004342 <log_write>
  brelse(bp);
    8000322a:	854a                	mv	a0,s2
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	e92080e7          	jalr	-366(ra) # 800030be <brelse>
}
    80003234:	60e2                	ld	ra,24(sp)
    80003236:	6442                	ld	s0,16(sp)
    80003238:	64a2                	ld	s1,8(sp)
    8000323a:	6902                	ld	s2,0(sp)
    8000323c:	6105                	addi	sp,sp,32
    8000323e:	8082                	ret
    panic("freeing free block");
    80003240:	00005517          	auipc	a0,0x5
    80003244:	47850513          	addi	a0,a0,1144 # 800086b8 <syscall_names+0xe8>
    80003248:	ffffd097          	auipc	ra,0xffffd
    8000324c:	2f6080e7          	jalr	758(ra) # 8000053e <panic>

0000000080003250 <balloc>:
{
    80003250:	711d                	addi	sp,sp,-96
    80003252:	ec86                	sd	ra,88(sp)
    80003254:	e8a2                	sd	s0,80(sp)
    80003256:	e4a6                	sd	s1,72(sp)
    80003258:	e0ca                	sd	s2,64(sp)
    8000325a:	fc4e                	sd	s3,56(sp)
    8000325c:	f852                	sd	s4,48(sp)
    8000325e:	f456                	sd	s5,40(sp)
    80003260:	f05a                	sd	s6,32(sp)
    80003262:	ec5e                	sd	s7,24(sp)
    80003264:	e862                	sd	s8,16(sp)
    80003266:	e466                	sd	s9,8(sp)
    80003268:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000326a:	0001c797          	auipc	a5,0x1c
    8000326e:	1527a783          	lw	a5,338(a5) # 8001f3bc <sb+0x4>
    80003272:	10078163          	beqz	a5,80003374 <balloc+0x124>
    80003276:	8baa                	mv	s7,a0
    80003278:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000327a:	0001cb17          	auipc	s6,0x1c
    8000327e:	13eb0b13          	addi	s6,s6,318 # 8001f3b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003282:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003284:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003286:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003288:	6c89                	lui	s9,0x2
    8000328a:	a061                	j	80003312 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000328c:	974a                	add	a4,a4,s2
    8000328e:	8fd5                	or	a5,a5,a3
    80003290:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003294:	854a                	mv	a0,s2
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	0ac080e7          	jalr	172(ra) # 80004342 <log_write>
        brelse(bp);
    8000329e:	854a                	mv	a0,s2
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	e1e080e7          	jalr	-482(ra) # 800030be <brelse>
  bp = bread(dev, bno);
    800032a8:	85a6                	mv	a1,s1
    800032aa:	855e                	mv	a0,s7
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	ce2080e7          	jalr	-798(ra) # 80002f8e <bread>
    800032b4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032b6:	40000613          	li	a2,1024
    800032ba:	4581                	li	a1,0
    800032bc:	05850513          	addi	a0,a0,88
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	a5c080e7          	jalr	-1444(ra) # 80000d1c <memset>
  log_write(bp);
    800032c8:	854a                	mv	a0,s2
    800032ca:	00001097          	auipc	ra,0x1
    800032ce:	078080e7          	jalr	120(ra) # 80004342 <log_write>
  brelse(bp);
    800032d2:	854a                	mv	a0,s2
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	dea080e7          	jalr	-534(ra) # 800030be <brelse>
}
    800032dc:	8526                	mv	a0,s1
    800032de:	60e6                	ld	ra,88(sp)
    800032e0:	6446                	ld	s0,80(sp)
    800032e2:	64a6                	ld	s1,72(sp)
    800032e4:	6906                	ld	s2,64(sp)
    800032e6:	79e2                	ld	s3,56(sp)
    800032e8:	7a42                	ld	s4,48(sp)
    800032ea:	7aa2                	ld	s5,40(sp)
    800032ec:	7b02                	ld	s6,32(sp)
    800032ee:	6be2                	ld	s7,24(sp)
    800032f0:	6c42                	ld	s8,16(sp)
    800032f2:	6ca2                	ld	s9,8(sp)
    800032f4:	6125                	addi	sp,sp,96
    800032f6:	8082                	ret
    brelse(bp);
    800032f8:	854a                	mv	a0,s2
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	dc4080e7          	jalr	-572(ra) # 800030be <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003302:	015c87bb          	addw	a5,s9,s5
    80003306:	00078a9b          	sext.w	s5,a5
    8000330a:	004b2703          	lw	a4,4(s6)
    8000330e:	06eaf363          	bgeu	s5,a4,80003374 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003312:	41fad79b          	sraiw	a5,s5,0x1f
    80003316:	0137d79b          	srliw	a5,a5,0x13
    8000331a:	015787bb          	addw	a5,a5,s5
    8000331e:	40d7d79b          	sraiw	a5,a5,0xd
    80003322:	01cb2583          	lw	a1,28(s6)
    80003326:	9dbd                	addw	a1,a1,a5
    80003328:	855e                	mv	a0,s7
    8000332a:	00000097          	auipc	ra,0x0
    8000332e:	c64080e7          	jalr	-924(ra) # 80002f8e <bread>
    80003332:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003334:	004b2503          	lw	a0,4(s6)
    80003338:	000a849b          	sext.w	s1,s5
    8000333c:	8662                	mv	a2,s8
    8000333e:	faa4fde3          	bgeu	s1,a0,800032f8 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003342:	41f6579b          	sraiw	a5,a2,0x1f
    80003346:	01d7d69b          	srliw	a3,a5,0x1d
    8000334a:	00c6873b          	addw	a4,a3,a2
    8000334e:	00777793          	andi	a5,a4,7
    80003352:	9f95                	subw	a5,a5,a3
    80003354:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003358:	4037571b          	sraiw	a4,a4,0x3
    8000335c:	00e906b3          	add	a3,s2,a4
    80003360:	0586c683          	lbu	a3,88(a3)
    80003364:	00d7f5b3          	and	a1,a5,a3
    80003368:	d195                	beqz	a1,8000328c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000336a:	2605                	addiw	a2,a2,1
    8000336c:	2485                	addiw	s1,s1,1
    8000336e:	fd4618e3          	bne	a2,s4,8000333e <balloc+0xee>
    80003372:	b759                	j	800032f8 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003374:	00005517          	auipc	a0,0x5
    80003378:	35c50513          	addi	a0,a0,860 # 800086d0 <syscall_names+0x100>
    8000337c:	ffffd097          	auipc	ra,0xffffd
    80003380:	20c080e7          	jalr	524(ra) # 80000588 <printf>
  return 0;
    80003384:	4481                	li	s1,0
    80003386:	bf99                	j	800032dc <balloc+0x8c>

0000000080003388 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003388:	7179                	addi	sp,sp,-48
    8000338a:	f406                	sd	ra,40(sp)
    8000338c:	f022                	sd	s0,32(sp)
    8000338e:	ec26                	sd	s1,24(sp)
    80003390:	e84a                	sd	s2,16(sp)
    80003392:	e44e                	sd	s3,8(sp)
    80003394:	e052                	sd	s4,0(sp)
    80003396:	1800                	addi	s0,sp,48
    80003398:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000339a:	47ad                	li	a5,11
    8000339c:	02b7e763          	bltu	a5,a1,800033ca <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033a0:	02059493          	slli	s1,a1,0x20
    800033a4:	9081                	srli	s1,s1,0x20
    800033a6:	048a                	slli	s1,s1,0x2
    800033a8:	94aa                	add	s1,s1,a0
    800033aa:	0504a903          	lw	s2,80(s1)
    800033ae:	06091e63          	bnez	s2,8000342a <bmap+0xa2>
      addr = balloc(ip->dev);
    800033b2:	4108                	lw	a0,0(a0)
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	e9c080e7          	jalr	-356(ra) # 80003250 <balloc>
    800033bc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033c0:	06090563          	beqz	s2,8000342a <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033c4:	0524a823          	sw	s2,80(s1)
    800033c8:	a08d                	j	8000342a <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033ca:	ff45849b          	addiw	s1,a1,-12
    800033ce:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033d2:	0ff00793          	li	a5,255
    800033d6:	08e7e563          	bltu	a5,a4,80003460 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033da:	08052903          	lw	s2,128(a0)
    800033de:	00091d63          	bnez	s2,800033f8 <bmap+0x70>
      addr = balloc(ip->dev);
    800033e2:	4108                	lw	a0,0(a0)
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	e6c080e7          	jalr	-404(ra) # 80003250 <balloc>
    800033ec:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033f0:	02090d63          	beqz	s2,8000342a <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033f4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033f8:	85ca                	mv	a1,s2
    800033fa:	0009a503          	lw	a0,0(s3)
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	b90080e7          	jalr	-1136(ra) # 80002f8e <bread>
    80003406:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003408:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000340c:	02049593          	slli	a1,s1,0x20
    80003410:	9181                	srli	a1,a1,0x20
    80003412:	058a                	slli	a1,a1,0x2
    80003414:	00b784b3          	add	s1,a5,a1
    80003418:	0004a903          	lw	s2,0(s1)
    8000341c:	02090063          	beqz	s2,8000343c <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003420:	8552                	mv	a0,s4
    80003422:	00000097          	auipc	ra,0x0
    80003426:	c9c080e7          	jalr	-868(ra) # 800030be <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000342a:	854a                	mv	a0,s2
    8000342c:	70a2                	ld	ra,40(sp)
    8000342e:	7402                	ld	s0,32(sp)
    80003430:	64e2                	ld	s1,24(sp)
    80003432:	6942                	ld	s2,16(sp)
    80003434:	69a2                	ld	s3,8(sp)
    80003436:	6a02                	ld	s4,0(sp)
    80003438:	6145                	addi	sp,sp,48
    8000343a:	8082                	ret
      addr = balloc(ip->dev);
    8000343c:	0009a503          	lw	a0,0(s3)
    80003440:	00000097          	auipc	ra,0x0
    80003444:	e10080e7          	jalr	-496(ra) # 80003250 <balloc>
    80003448:	0005091b          	sext.w	s2,a0
      if(addr){
    8000344c:	fc090ae3          	beqz	s2,80003420 <bmap+0x98>
        a[bn] = addr;
    80003450:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003454:	8552                	mv	a0,s4
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	eec080e7          	jalr	-276(ra) # 80004342 <log_write>
    8000345e:	b7c9                	j	80003420 <bmap+0x98>
  panic("bmap: out of range");
    80003460:	00005517          	auipc	a0,0x5
    80003464:	28850513          	addi	a0,a0,648 # 800086e8 <syscall_names+0x118>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	0d6080e7          	jalr	214(ra) # 8000053e <panic>

0000000080003470 <iget>:
{
    80003470:	7179                	addi	sp,sp,-48
    80003472:	f406                	sd	ra,40(sp)
    80003474:	f022                	sd	s0,32(sp)
    80003476:	ec26                	sd	s1,24(sp)
    80003478:	e84a                	sd	s2,16(sp)
    8000347a:	e44e                	sd	s3,8(sp)
    8000347c:	e052                	sd	s4,0(sp)
    8000347e:	1800                	addi	s0,sp,48
    80003480:	89aa                	mv	s3,a0
    80003482:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003484:	0001c517          	auipc	a0,0x1c
    80003488:	f5450513          	addi	a0,a0,-172 # 8001f3d8 <itable>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	794080e7          	jalr	1940(ra) # 80000c20 <acquire>
  empty = 0;
    80003494:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003496:	0001c497          	auipc	s1,0x1c
    8000349a:	f5a48493          	addi	s1,s1,-166 # 8001f3f0 <itable+0x18>
    8000349e:	0001e697          	auipc	a3,0x1e
    800034a2:	9e268693          	addi	a3,a3,-1566 # 80020e80 <log>
    800034a6:	a039                	j	800034b4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034a8:	02090b63          	beqz	s2,800034de <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034ac:	08848493          	addi	s1,s1,136
    800034b0:	02d48a63          	beq	s1,a3,800034e4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034b4:	449c                	lw	a5,8(s1)
    800034b6:	fef059e3          	blez	a5,800034a8 <iget+0x38>
    800034ba:	4098                	lw	a4,0(s1)
    800034bc:	ff3716e3          	bne	a4,s3,800034a8 <iget+0x38>
    800034c0:	40d8                	lw	a4,4(s1)
    800034c2:	ff4713e3          	bne	a4,s4,800034a8 <iget+0x38>
      ip->ref++;
    800034c6:	2785                	addiw	a5,a5,1
    800034c8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034ca:	0001c517          	auipc	a0,0x1c
    800034ce:	f0e50513          	addi	a0,a0,-242 # 8001f3d8 <itable>
    800034d2:	ffffe097          	auipc	ra,0xffffe
    800034d6:	802080e7          	jalr	-2046(ra) # 80000cd4 <release>
      return ip;
    800034da:	8926                	mv	s2,s1
    800034dc:	a03d                	j	8000350a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034de:	f7f9                	bnez	a5,800034ac <iget+0x3c>
    800034e0:	8926                	mv	s2,s1
    800034e2:	b7e9                	j	800034ac <iget+0x3c>
  if(empty == 0)
    800034e4:	02090c63          	beqz	s2,8000351c <iget+0xac>
  ip->dev = dev;
    800034e8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034ec:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034f0:	4785                	li	a5,1
    800034f2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034f6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034fa:	0001c517          	auipc	a0,0x1c
    800034fe:	ede50513          	addi	a0,a0,-290 # 8001f3d8 <itable>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	7d2080e7          	jalr	2002(ra) # 80000cd4 <release>
}
    8000350a:	854a                	mv	a0,s2
    8000350c:	70a2                	ld	ra,40(sp)
    8000350e:	7402                	ld	s0,32(sp)
    80003510:	64e2                	ld	s1,24(sp)
    80003512:	6942                	ld	s2,16(sp)
    80003514:	69a2                	ld	s3,8(sp)
    80003516:	6a02                	ld	s4,0(sp)
    80003518:	6145                	addi	sp,sp,48
    8000351a:	8082                	ret
    panic("iget: no inodes");
    8000351c:	00005517          	auipc	a0,0x5
    80003520:	1e450513          	addi	a0,a0,484 # 80008700 <syscall_names+0x130>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	01a080e7          	jalr	26(ra) # 8000053e <panic>

000000008000352c <fsinit>:
fsinit(int dev) {
    8000352c:	7179                	addi	sp,sp,-48
    8000352e:	f406                	sd	ra,40(sp)
    80003530:	f022                	sd	s0,32(sp)
    80003532:	ec26                	sd	s1,24(sp)
    80003534:	e84a                	sd	s2,16(sp)
    80003536:	e44e                	sd	s3,8(sp)
    80003538:	1800                	addi	s0,sp,48
    8000353a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000353c:	4585                	li	a1,1
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	a50080e7          	jalr	-1456(ra) # 80002f8e <bread>
    80003546:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003548:	0001c997          	auipc	s3,0x1c
    8000354c:	e7098993          	addi	s3,s3,-400 # 8001f3b8 <sb>
    80003550:	02000613          	li	a2,32
    80003554:	05850593          	addi	a1,a0,88
    80003558:	854e                	mv	a0,s3
    8000355a:	ffffe097          	auipc	ra,0xffffe
    8000355e:	81e080e7          	jalr	-2018(ra) # 80000d78 <memmove>
  brelse(bp);
    80003562:	8526                	mv	a0,s1
    80003564:	00000097          	auipc	ra,0x0
    80003568:	b5a080e7          	jalr	-1190(ra) # 800030be <brelse>
  if(sb.magic != FSMAGIC)
    8000356c:	0009a703          	lw	a4,0(s3)
    80003570:	102037b7          	lui	a5,0x10203
    80003574:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003578:	02f71263          	bne	a4,a5,8000359c <fsinit+0x70>
  initlog(dev, &sb);
    8000357c:	0001c597          	auipc	a1,0x1c
    80003580:	e3c58593          	addi	a1,a1,-452 # 8001f3b8 <sb>
    80003584:	854a                	mv	a0,s2
    80003586:	00001097          	auipc	ra,0x1
    8000358a:	b40080e7          	jalr	-1216(ra) # 800040c6 <initlog>
}
    8000358e:	70a2                	ld	ra,40(sp)
    80003590:	7402                	ld	s0,32(sp)
    80003592:	64e2                	ld	s1,24(sp)
    80003594:	6942                	ld	s2,16(sp)
    80003596:	69a2                	ld	s3,8(sp)
    80003598:	6145                	addi	sp,sp,48
    8000359a:	8082                	ret
    panic("invalid file system");
    8000359c:	00005517          	auipc	a0,0x5
    800035a0:	17450513          	addi	a0,a0,372 # 80008710 <syscall_names+0x140>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	f9a080e7          	jalr	-102(ra) # 8000053e <panic>

00000000800035ac <iinit>:
{
    800035ac:	7179                	addi	sp,sp,-48
    800035ae:	f406                	sd	ra,40(sp)
    800035b0:	f022                	sd	s0,32(sp)
    800035b2:	ec26                	sd	s1,24(sp)
    800035b4:	e84a                	sd	s2,16(sp)
    800035b6:	e44e                	sd	s3,8(sp)
    800035b8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035ba:	00005597          	auipc	a1,0x5
    800035be:	16e58593          	addi	a1,a1,366 # 80008728 <syscall_names+0x158>
    800035c2:	0001c517          	auipc	a0,0x1c
    800035c6:	e1650513          	addi	a0,a0,-490 # 8001f3d8 <itable>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	5c6080e7          	jalr	1478(ra) # 80000b90 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035d2:	0001c497          	auipc	s1,0x1c
    800035d6:	e2e48493          	addi	s1,s1,-466 # 8001f400 <itable+0x28>
    800035da:	0001e997          	auipc	s3,0x1e
    800035de:	8b698993          	addi	s3,s3,-1866 # 80020e90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035e2:	00005917          	auipc	s2,0x5
    800035e6:	14e90913          	addi	s2,s2,334 # 80008730 <syscall_names+0x160>
    800035ea:	85ca                	mv	a1,s2
    800035ec:	8526                	mv	a0,s1
    800035ee:	00001097          	auipc	ra,0x1
    800035f2:	e3a080e7          	jalr	-454(ra) # 80004428 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035f6:	08848493          	addi	s1,s1,136
    800035fa:	ff3498e3          	bne	s1,s3,800035ea <iinit+0x3e>
}
    800035fe:	70a2                	ld	ra,40(sp)
    80003600:	7402                	ld	s0,32(sp)
    80003602:	64e2                	ld	s1,24(sp)
    80003604:	6942                	ld	s2,16(sp)
    80003606:	69a2                	ld	s3,8(sp)
    80003608:	6145                	addi	sp,sp,48
    8000360a:	8082                	ret

000000008000360c <ialloc>:
{
    8000360c:	715d                	addi	sp,sp,-80
    8000360e:	e486                	sd	ra,72(sp)
    80003610:	e0a2                	sd	s0,64(sp)
    80003612:	fc26                	sd	s1,56(sp)
    80003614:	f84a                	sd	s2,48(sp)
    80003616:	f44e                	sd	s3,40(sp)
    80003618:	f052                	sd	s4,32(sp)
    8000361a:	ec56                	sd	s5,24(sp)
    8000361c:	e85a                	sd	s6,16(sp)
    8000361e:	e45e                	sd	s7,8(sp)
    80003620:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003622:	0001c717          	auipc	a4,0x1c
    80003626:	da272703          	lw	a4,-606(a4) # 8001f3c4 <sb+0xc>
    8000362a:	4785                	li	a5,1
    8000362c:	04e7fa63          	bgeu	a5,a4,80003680 <ialloc+0x74>
    80003630:	8aaa                	mv	s5,a0
    80003632:	8bae                	mv	s7,a1
    80003634:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003636:	0001ca17          	auipc	s4,0x1c
    8000363a:	d82a0a13          	addi	s4,s4,-638 # 8001f3b8 <sb>
    8000363e:	00048b1b          	sext.w	s6,s1
    80003642:	0044d793          	srli	a5,s1,0x4
    80003646:	018a2583          	lw	a1,24(s4)
    8000364a:	9dbd                	addw	a1,a1,a5
    8000364c:	8556                	mv	a0,s5
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	940080e7          	jalr	-1728(ra) # 80002f8e <bread>
    80003656:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003658:	05850993          	addi	s3,a0,88
    8000365c:	00f4f793          	andi	a5,s1,15
    80003660:	079a                	slli	a5,a5,0x6
    80003662:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003664:	00099783          	lh	a5,0(s3)
    80003668:	c3a1                	beqz	a5,800036a8 <ialloc+0x9c>
    brelse(bp);
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	a54080e7          	jalr	-1452(ra) # 800030be <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003672:	0485                	addi	s1,s1,1
    80003674:	00ca2703          	lw	a4,12(s4)
    80003678:	0004879b          	sext.w	a5,s1
    8000367c:	fce7e1e3          	bltu	a5,a4,8000363e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003680:	00005517          	auipc	a0,0x5
    80003684:	0b850513          	addi	a0,a0,184 # 80008738 <syscall_names+0x168>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	f00080e7          	jalr	-256(ra) # 80000588 <printf>
  return 0;
    80003690:	4501                	li	a0,0
}
    80003692:	60a6                	ld	ra,72(sp)
    80003694:	6406                	ld	s0,64(sp)
    80003696:	74e2                	ld	s1,56(sp)
    80003698:	7942                	ld	s2,48(sp)
    8000369a:	79a2                	ld	s3,40(sp)
    8000369c:	7a02                	ld	s4,32(sp)
    8000369e:	6ae2                	ld	s5,24(sp)
    800036a0:	6b42                	ld	s6,16(sp)
    800036a2:	6ba2                	ld	s7,8(sp)
    800036a4:	6161                	addi	sp,sp,80
    800036a6:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036a8:	04000613          	li	a2,64
    800036ac:	4581                	li	a1,0
    800036ae:	854e                	mv	a0,s3
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	66c080e7          	jalr	1644(ra) # 80000d1c <memset>
      dip->type = type;
    800036b8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036bc:	854a                	mv	a0,s2
    800036be:	00001097          	auipc	ra,0x1
    800036c2:	c84080e7          	jalr	-892(ra) # 80004342 <log_write>
      brelse(bp);
    800036c6:	854a                	mv	a0,s2
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	9f6080e7          	jalr	-1546(ra) # 800030be <brelse>
      return iget(dev, inum);
    800036d0:	85da                	mv	a1,s6
    800036d2:	8556                	mv	a0,s5
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	d9c080e7          	jalr	-612(ra) # 80003470 <iget>
    800036dc:	bf5d                	j	80003692 <ialloc+0x86>

00000000800036de <iupdate>:
{
    800036de:	1101                	addi	sp,sp,-32
    800036e0:	ec06                	sd	ra,24(sp)
    800036e2:	e822                	sd	s0,16(sp)
    800036e4:	e426                	sd	s1,8(sp)
    800036e6:	e04a                	sd	s2,0(sp)
    800036e8:	1000                	addi	s0,sp,32
    800036ea:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ec:	415c                	lw	a5,4(a0)
    800036ee:	0047d79b          	srliw	a5,a5,0x4
    800036f2:	0001c597          	auipc	a1,0x1c
    800036f6:	cde5a583          	lw	a1,-802(a1) # 8001f3d0 <sb+0x18>
    800036fa:	9dbd                	addw	a1,a1,a5
    800036fc:	4108                	lw	a0,0(a0)
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	890080e7          	jalr	-1904(ra) # 80002f8e <bread>
    80003706:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003708:	05850793          	addi	a5,a0,88
    8000370c:	40c8                	lw	a0,4(s1)
    8000370e:	893d                	andi	a0,a0,15
    80003710:	051a                	slli	a0,a0,0x6
    80003712:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003714:	04449703          	lh	a4,68(s1)
    80003718:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000371c:	04649703          	lh	a4,70(s1)
    80003720:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003724:	04849703          	lh	a4,72(s1)
    80003728:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000372c:	04a49703          	lh	a4,74(s1)
    80003730:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003734:	44f8                	lw	a4,76(s1)
    80003736:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003738:	03400613          	li	a2,52
    8000373c:	05048593          	addi	a1,s1,80
    80003740:	0531                	addi	a0,a0,12
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	636080e7          	jalr	1590(ra) # 80000d78 <memmove>
  log_write(bp);
    8000374a:	854a                	mv	a0,s2
    8000374c:	00001097          	auipc	ra,0x1
    80003750:	bf6080e7          	jalr	-1034(ra) # 80004342 <log_write>
  brelse(bp);
    80003754:	854a                	mv	a0,s2
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	968080e7          	jalr	-1688(ra) # 800030be <brelse>
}
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6902                	ld	s2,0(sp)
    80003766:	6105                	addi	sp,sp,32
    80003768:	8082                	ret

000000008000376a <idup>:
{
    8000376a:	1101                	addi	sp,sp,-32
    8000376c:	ec06                	sd	ra,24(sp)
    8000376e:	e822                	sd	s0,16(sp)
    80003770:	e426                	sd	s1,8(sp)
    80003772:	1000                	addi	s0,sp,32
    80003774:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003776:	0001c517          	auipc	a0,0x1c
    8000377a:	c6250513          	addi	a0,a0,-926 # 8001f3d8 <itable>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	4a2080e7          	jalr	1186(ra) # 80000c20 <acquire>
  ip->ref++;
    80003786:	449c                	lw	a5,8(s1)
    80003788:	2785                	addiw	a5,a5,1
    8000378a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000378c:	0001c517          	auipc	a0,0x1c
    80003790:	c4c50513          	addi	a0,a0,-948 # 8001f3d8 <itable>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	540080e7          	jalr	1344(ra) # 80000cd4 <release>
}
    8000379c:	8526                	mv	a0,s1
    8000379e:	60e2                	ld	ra,24(sp)
    800037a0:	6442                	ld	s0,16(sp)
    800037a2:	64a2                	ld	s1,8(sp)
    800037a4:	6105                	addi	sp,sp,32
    800037a6:	8082                	ret

00000000800037a8 <ilock>:
{
    800037a8:	1101                	addi	sp,sp,-32
    800037aa:	ec06                	sd	ra,24(sp)
    800037ac:	e822                	sd	s0,16(sp)
    800037ae:	e426                	sd	s1,8(sp)
    800037b0:	e04a                	sd	s2,0(sp)
    800037b2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037b4:	c115                	beqz	a0,800037d8 <ilock+0x30>
    800037b6:	84aa                	mv	s1,a0
    800037b8:	451c                	lw	a5,8(a0)
    800037ba:	00f05f63          	blez	a5,800037d8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037be:	0541                	addi	a0,a0,16
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	ca2080e7          	jalr	-862(ra) # 80004462 <acquiresleep>
  if(ip->valid == 0){
    800037c8:	40bc                	lw	a5,64(s1)
    800037ca:	cf99                	beqz	a5,800037e8 <ilock+0x40>
}
    800037cc:	60e2                	ld	ra,24(sp)
    800037ce:	6442                	ld	s0,16(sp)
    800037d0:	64a2                	ld	s1,8(sp)
    800037d2:	6902                	ld	s2,0(sp)
    800037d4:	6105                	addi	sp,sp,32
    800037d6:	8082                	ret
    panic("ilock");
    800037d8:	00005517          	auipc	a0,0x5
    800037dc:	f7850513          	addi	a0,a0,-136 # 80008750 <syscall_names+0x180>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	d5e080e7          	jalr	-674(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037e8:	40dc                	lw	a5,4(s1)
    800037ea:	0047d79b          	srliw	a5,a5,0x4
    800037ee:	0001c597          	auipc	a1,0x1c
    800037f2:	be25a583          	lw	a1,-1054(a1) # 8001f3d0 <sb+0x18>
    800037f6:	9dbd                	addw	a1,a1,a5
    800037f8:	4088                	lw	a0,0(s1)
    800037fa:	fffff097          	auipc	ra,0xfffff
    800037fe:	794080e7          	jalr	1940(ra) # 80002f8e <bread>
    80003802:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003804:	05850593          	addi	a1,a0,88
    80003808:	40dc                	lw	a5,4(s1)
    8000380a:	8bbd                	andi	a5,a5,15
    8000380c:	079a                	slli	a5,a5,0x6
    8000380e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003810:	00059783          	lh	a5,0(a1)
    80003814:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003818:	00259783          	lh	a5,2(a1)
    8000381c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003820:	00459783          	lh	a5,4(a1)
    80003824:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003828:	00659783          	lh	a5,6(a1)
    8000382c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003830:	459c                	lw	a5,8(a1)
    80003832:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003834:	03400613          	li	a2,52
    80003838:	05b1                	addi	a1,a1,12
    8000383a:	05048513          	addi	a0,s1,80
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	53a080e7          	jalr	1338(ra) # 80000d78 <memmove>
    brelse(bp);
    80003846:	854a                	mv	a0,s2
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	876080e7          	jalr	-1930(ra) # 800030be <brelse>
    ip->valid = 1;
    80003850:	4785                	li	a5,1
    80003852:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003854:	04449783          	lh	a5,68(s1)
    80003858:	fbb5                	bnez	a5,800037cc <ilock+0x24>
      panic("ilock: no type");
    8000385a:	00005517          	auipc	a0,0x5
    8000385e:	efe50513          	addi	a0,a0,-258 # 80008758 <syscall_names+0x188>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	cdc080e7          	jalr	-804(ra) # 8000053e <panic>

000000008000386a <iunlock>:
{
    8000386a:	1101                	addi	sp,sp,-32
    8000386c:	ec06                	sd	ra,24(sp)
    8000386e:	e822                	sd	s0,16(sp)
    80003870:	e426                	sd	s1,8(sp)
    80003872:	e04a                	sd	s2,0(sp)
    80003874:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003876:	c905                	beqz	a0,800038a6 <iunlock+0x3c>
    80003878:	84aa                	mv	s1,a0
    8000387a:	01050913          	addi	s2,a0,16
    8000387e:	854a                	mv	a0,s2
    80003880:	00001097          	auipc	ra,0x1
    80003884:	c7c080e7          	jalr	-900(ra) # 800044fc <holdingsleep>
    80003888:	cd19                	beqz	a0,800038a6 <iunlock+0x3c>
    8000388a:	449c                	lw	a5,8(s1)
    8000388c:	00f05d63          	blez	a5,800038a6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003890:	854a                	mv	a0,s2
    80003892:	00001097          	auipc	ra,0x1
    80003896:	c26080e7          	jalr	-986(ra) # 800044b8 <releasesleep>
}
    8000389a:	60e2                	ld	ra,24(sp)
    8000389c:	6442                	ld	s0,16(sp)
    8000389e:	64a2                	ld	s1,8(sp)
    800038a0:	6902                	ld	s2,0(sp)
    800038a2:	6105                	addi	sp,sp,32
    800038a4:	8082                	ret
    panic("iunlock");
    800038a6:	00005517          	auipc	a0,0x5
    800038aa:	ec250513          	addi	a0,a0,-318 # 80008768 <syscall_names+0x198>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	c90080e7          	jalr	-880(ra) # 8000053e <panic>

00000000800038b6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038b6:	7179                	addi	sp,sp,-48
    800038b8:	f406                	sd	ra,40(sp)
    800038ba:	f022                	sd	s0,32(sp)
    800038bc:	ec26                	sd	s1,24(sp)
    800038be:	e84a                	sd	s2,16(sp)
    800038c0:	e44e                	sd	s3,8(sp)
    800038c2:	e052                	sd	s4,0(sp)
    800038c4:	1800                	addi	s0,sp,48
    800038c6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038c8:	05050493          	addi	s1,a0,80
    800038cc:	08050913          	addi	s2,a0,128
    800038d0:	a021                	j	800038d8 <itrunc+0x22>
    800038d2:	0491                	addi	s1,s1,4
    800038d4:	01248d63          	beq	s1,s2,800038ee <itrunc+0x38>
    if(ip->addrs[i]){
    800038d8:	408c                	lw	a1,0(s1)
    800038da:	dde5                	beqz	a1,800038d2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038dc:	0009a503          	lw	a0,0(s3)
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	8f4080e7          	jalr	-1804(ra) # 800031d4 <bfree>
      ip->addrs[i] = 0;
    800038e8:	0004a023          	sw	zero,0(s1)
    800038ec:	b7dd                	j	800038d2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ee:	0809a583          	lw	a1,128(s3)
    800038f2:	e185                	bnez	a1,80003912 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038f4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038f8:	854e                	mv	a0,s3
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	de4080e7          	jalr	-540(ra) # 800036de <iupdate>
}
    80003902:	70a2                	ld	ra,40(sp)
    80003904:	7402                	ld	s0,32(sp)
    80003906:	64e2                	ld	s1,24(sp)
    80003908:	6942                	ld	s2,16(sp)
    8000390a:	69a2                	ld	s3,8(sp)
    8000390c:	6a02                	ld	s4,0(sp)
    8000390e:	6145                	addi	sp,sp,48
    80003910:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003912:	0009a503          	lw	a0,0(s3)
    80003916:	fffff097          	auipc	ra,0xfffff
    8000391a:	678080e7          	jalr	1656(ra) # 80002f8e <bread>
    8000391e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003920:	05850493          	addi	s1,a0,88
    80003924:	45850913          	addi	s2,a0,1112
    80003928:	a021                	j	80003930 <itrunc+0x7a>
    8000392a:	0491                	addi	s1,s1,4
    8000392c:	01248b63          	beq	s1,s2,80003942 <itrunc+0x8c>
      if(a[j])
    80003930:	408c                	lw	a1,0(s1)
    80003932:	dde5                	beqz	a1,8000392a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003934:	0009a503          	lw	a0,0(s3)
    80003938:	00000097          	auipc	ra,0x0
    8000393c:	89c080e7          	jalr	-1892(ra) # 800031d4 <bfree>
    80003940:	b7ed                	j	8000392a <itrunc+0x74>
    brelse(bp);
    80003942:	8552                	mv	a0,s4
    80003944:	fffff097          	auipc	ra,0xfffff
    80003948:	77a080e7          	jalr	1914(ra) # 800030be <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000394c:	0809a583          	lw	a1,128(s3)
    80003950:	0009a503          	lw	a0,0(s3)
    80003954:	00000097          	auipc	ra,0x0
    80003958:	880080e7          	jalr	-1920(ra) # 800031d4 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000395c:	0809a023          	sw	zero,128(s3)
    80003960:	bf51                	j	800038f4 <itrunc+0x3e>

0000000080003962 <iput>:
{
    80003962:	1101                	addi	sp,sp,-32
    80003964:	ec06                	sd	ra,24(sp)
    80003966:	e822                	sd	s0,16(sp)
    80003968:	e426                	sd	s1,8(sp)
    8000396a:	e04a                	sd	s2,0(sp)
    8000396c:	1000                	addi	s0,sp,32
    8000396e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003970:	0001c517          	auipc	a0,0x1c
    80003974:	a6850513          	addi	a0,a0,-1432 # 8001f3d8 <itable>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	2a8080e7          	jalr	680(ra) # 80000c20 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003980:	4498                	lw	a4,8(s1)
    80003982:	4785                	li	a5,1
    80003984:	02f70363          	beq	a4,a5,800039aa <iput+0x48>
  ip->ref--;
    80003988:	449c                	lw	a5,8(s1)
    8000398a:	37fd                	addiw	a5,a5,-1
    8000398c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000398e:	0001c517          	auipc	a0,0x1c
    80003992:	a4a50513          	addi	a0,a0,-1462 # 8001f3d8 <itable>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	33e080e7          	jalr	830(ra) # 80000cd4 <release>
}
    8000399e:	60e2                	ld	ra,24(sp)
    800039a0:	6442                	ld	s0,16(sp)
    800039a2:	64a2                	ld	s1,8(sp)
    800039a4:	6902                	ld	s2,0(sp)
    800039a6:	6105                	addi	sp,sp,32
    800039a8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039aa:	40bc                	lw	a5,64(s1)
    800039ac:	dff1                	beqz	a5,80003988 <iput+0x26>
    800039ae:	04a49783          	lh	a5,74(s1)
    800039b2:	fbf9                	bnez	a5,80003988 <iput+0x26>
    acquiresleep(&ip->lock);
    800039b4:	01048913          	addi	s2,s1,16
    800039b8:	854a                	mv	a0,s2
    800039ba:	00001097          	auipc	ra,0x1
    800039be:	aa8080e7          	jalr	-1368(ra) # 80004462 <acquiresleep>
    release(&itable.lock);
    800039c2:	0001c517          	auipc	a0,0x1c
    800039c6:	a1650513          	addi	a0,a0,-1514 # 8001f3d8 <itable>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	30a080e7          	jalr	778(ra) # 80000cd4 <release>
    itrunc(ip);
    800039d2:	8526                	mv	a0,s1
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	ee2080e7          	jalr	-286(ra) # 800038b6 <itrunc>
    ip->type = 0;
    800039dc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039e0:	8526                	mv	a0,s1
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	cfc080e7          	jalr	-772(ra) # 800036de <iupdate>
    ip->valid = 0;
    800039ea:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039ee:	854a                	mv	a0,s2
    800039f0:	00001097          	auipc	ra,0x1
    800039f4:	ac8080e7          	jalr	-1336(ra) # 800044b8 <releasesleep>
    acquire(&itable.lock);
    800039f8:	0001c517          	auipc	a0,0x1c
    800039fc:	9e050513          	addi	a0,a0,-1568 # 8001f3d8 <itable>
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	220080e7          	jalr	544(ra) # 80000c20 <acquire>
    80003a08:	b741                	j	80003988 <iput+0x26>

0000000080003a0a <iunlockput>:
{
    80003a0a:	1101                	addi	sp,sp,-32
    80003a0c:	ec06                	sd	ra,24(sp)
    80003a0e:	e822                	sd	s0,16(sp)
    80003a10:	e426                	sd	s1,8(sp)
    80003a12:	1000                	addi	s0,sp,32
    80003a14:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	e54080e7          	jalr	-428(ra) # 8000386a <iunlock>
  iput(ip);
    80003a1e:	8526                	mv	a0,s1
    80003a20:	00000097          	auipc	ra,0x0
    80003a24:	f42080e7          	jalr	-190(ra) # 80003962 <iput>
}
    80003a28:	60e2                	ld	ra,24(sp)
    80003a2a:	6442                	ld	s0,16(sp)
    80003a2c:	64a2                	ld	s1,8(sp)
    80003a2e:	6105                	addi	sp,sp,32
    80003a30:	8082                	ret

0000000080003a32 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a32:	1141                	addi	sp,sp,-16
    80003a34:	e422                	sd	s0,8(sp)
    80003a36:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a38:	411c                	lw	a5,0(a0)
    80003a3a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a3c:	415c                	lw	a5,4(a0)
    80003a3e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a40:	04451783          	lh	a5,68(a0)
    80003a44:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a48:	04a51783          	lh	a5,74(a0)
    80003a4c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a50:	04c56783          	lwu	a5,76(a0)
    80003a54:	e99c                	sd	a5,16(a1)
}
    80003a56:	6422                	ld	s0,8(sp)
    80003a58:	0141                	addi	sp,sp,16
    80003a5a:	8082                	ret

0000000080003a5c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a5c:	457c                	lw	a5,76(a0)
    80003a5e:	0ed7e963          	bltu	a5,a3,80003b50 <readi+0xf4>
{
    80003a62:	7159                	addi	sp,sp,-112
    80003a64:	f486                	sd	ra,104(sp)
    80003a66:	f0a2                	sd	s0,96(sp)
    80003a68:	eca6                	sd	s1,88(sp)
    80003a6a:	e8ca                	sd	s2,80(sp)
    80003a6c:	e4ce                	sd	s3,72(sp)
    80003a6e:	e0d2                	sd	s4,64(sp)
    80003a70:	fc56                	sd	s5,56(sp)
    80003a72:	f85a                	sd	s6,48(sp)
    80003a74:	f45e                	sd	s7,40(sp)
    80003a76:	f062                	sd	s8,32(sp)
    80003a78:	ec66                	sd	s9,24(sp)
    80003a7a:	e86a                	sd	s10,16(sp)
    80003a7c:	e46e                	sd	s11,8(sp)
    80003a7e:	1880                	addi	s0,sp,112
    80003a80:	8b2a                	mv	s6,a0
    80003a82:	8bae                	mv	s7,a1
    80003a84:	8a32                	mv	s4,a2
    80003a86:	84b6                	mv	s1,a3
    80003a88:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a8a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a8c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a8e:	0ad76063          	bltu	a4,a3,80003b2e <readi+0xd2>
  if(off + n > ip->size)
    80003a92:	00e7f463          	bgeu	a5,a4,80003a9a <readi+0x3e>
    n = ip->size - off;
    80003a96:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a9a:	0a0a8963          	beqz	s5,80003b4c <readi+0xf0>
    80003a9e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa0:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aa4:	5c7d                	li	s8,-1
    80003aa6:	a82d                	j	80003ae0 <readi+0x84>
    80003aa8:	020d1d93          	slli	s11,s10,0x20
    80003aac:	020ddd93          	srli	s11,s11,0x20
    80003ab0:	05890793          	addi	a5,s2,88
    80003ab4:	86ee                	mv	a3,s11
    80003ab6:	963e                	add	a2,a2,a5
    80003ab8:	85d2                	mv	a1,s4
    80003aba:	855e                	mv	a0,s7
    80003abc:	fffff097          	auipc	ra,0xfffff
    80003ac0:	9f6080e7          	jalr	-1546(ra) # 800024b2 <either_copyout>
    80003ac4:	05850d63          	beq	a0,s8,80003b1e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ac8:	854a                	mv	a0,s2
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	5f4080e7          	jalr	1524(ra) # 800030be <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad2:	013d09bb          	addw	s3,s10,s3
    80003ad6:	009d04bb          	addw	s1,s10,s1
    80003ada:	9a6e                	add	s4,s4,s11
    80003adc:	0559f763          	bgeu	s3,s5,80003b2a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ae0:	00a4d59b          	srliw	a1,s1,0xa
    80003ae4:	855a                	mv	a0,s6
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	8a2080e7          	jalr	-1886(ra) # 80003388 <bmap>
    80003aee:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003af2:	cd85                	beqz	a1,80003b2a <readi+0xce>
    bp = bread(ip->dev, addr);
    80003af4:	000b2503          	lw	a0,0(s6)
    80003af8:	fffff097          	auipc	ra,0xfffff
    80003afc:	496080e7          	jalr	1174(ra) # 80002f8e <bread>
    80003b00:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b02:	3ff4f613          	andi	a2,s1,1023
    80003b06:	40cc87bb          	subw	a5,s9,a2
    80003b0a:	413a873b          	subw	a4,s5,s3
    80003b0e:	8d3e                	mv	s10,a5
    80003b10:	2781                	sext.w	a5,a5
    80003b12:	0007069b          	sext.w	a3,a4
    80003b16:	f8f6f9e3          	bgeu	a3,a5,80003aa8 <readi+0x4c>
    80003b1a:	8d3a                	mv	s10,a4
    80003b1c:	b771                	j	80003aa8 <readi+0x4c>
      brelse(bp);
    80003b1e:	854a                	mv	a0,s2
    80003b20:	fffff097          	auipc	ra,0xfffff
    80003b24:	59e080e7          	jalr	1438(ra) # 800030be <brelse>
      tot = -1;
    80003b28:	59fd                	li	s3,-1
  }
  return tot;
    80003b2a:	0009851b          	sext.w	a0,s3
}
    80003b2e:	70a6                	ld	ra,104(sp)
    80003b30:	7406                	ld	s0,96(sp)
    80003b32:	64e6                	ld	s1,88(sp)
    80003b34:	6946                	ld	s2,80(sp)
    80003b36:	69a6                	ld	s3,72(sp)
    80003b38:	6a06                	ld	s4,64(sp)
    80003b3a:	7ae2                	ld	s5,56(sp)
    80003b3c:	7b42                	ld	s6,48(sp)
    80003b3e:	7ba2                	ld	s7,40(sp)
    80003b40:	7c02                	ld	s8,32(sp)
    80003b42:	6ce2                	ld	s9,24(sp)
    80003b44:	6d42                	ld	s10,16(sp)
    80003b46:	6da2                	ld	s11,8(sp)
    80003b48:	6165                	addi	sp,sp,112
    80003b4a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b4c:	89d6                	mv	s3,s5
    80003b4e:	bff1                	j	80003b2a <readi+0xce>
    return 0;
    80003b50:	4501                	li	a0,0
}
    80003b52:	8082                	ret

0000000080003b54 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b54:	457c                	lw	a5,76(a0)
    80003b56:	10d7e863          	bltu	a5,a3,80003c66 <writei+0x112>
{
    80003b5a:	7159                	addi	sp,sp,-112
    80003b5c:	f486                	sd	ra,104(sp)
    80003b5e:	f0a2                	sd	s0,96(sp)
    80003b60:	eca6                	sd	s1,88(sp)
    80003b62:	e8ca                	sd	s2,80(sp)
    80003b64:	e4ce                	sd	s3,72(sp)
    80003b66:	e0d2                	sd	s4,64(sp)
    80003b68:	fc56                	sd	s5,56(sp)
    80003b6a:	f85a                	sd	s6,48(sp)
    80003b6c:	f45e                	sd	s7,40(sp)
    80003b6e:	f062                	sd	s8,32(sp)
    80003b70:	ec66                	sd	s9,24(sp)
    80003b72:	e86a                	sd	s10,16(sp)
    80003b74:	e46e                	sd	s11,8(sp)
    80003b76:	1880                	addi	s0,sp,112
    80003b78:	8aaa                	mv	s5,a0
    80003b7a:	8bae                	mv	s7,a1
    80003b7c:	8a32                	mv	s4,a2
    80003b7e:	8936                	mv	s2,a3
    80003b80:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b82:	00e687bb          	addw	a5,a3,a4
    80003b86:	0ed7e263          	bltu	a5,a3,80003c6a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b8a:	00043737          	lui	a4,0x43
    80003b8e:	0ef76063          	bltu	a4,a5,80003c6e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b92:	0c0b0863          	beqz	s6,80003c62 <writei+0x10e>
    80003b96:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b98:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b9c:	5c7d                	li	s8,-1
    80003b9e:	a091                	j	80003be2 <writei+0x8e>
    80003ba0:	020d1d93          	slli	s11,s10,0x20
    80003ba4:	020ddd93          	srli	s11,s11,0x20
    80003ba8:	05848793          	addi	a5,s1,88
    80003bac:	86ee                	mv	a3,s11
    80003bae:	8652                	mv	a2,s4
    80003bb0:	85de                	mv	a1,s7
    80003bb2:	953e                	add	a0,a0,a5
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	954080e7          	jalr	-1708(ra) # 80002508 <either_copyin>
    80003bbc:	07850263          	beq	a0,s8,80003c20 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bc0:	8526                	mv	a0,s1
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	780080e7          	jalr	1920(ra) # 80004342 <log_write>
    brelse(bp);
    80003bca:	8526                	mv	a0,s1
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	4f2080e7          	jalr	1266(ra) # 800030be <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bd4:	013d09bb          	addw	s3,s10,s3
    80003bd8:	012d093b          	addw	s2,s10,s2
    80003bdc:	9a6e                	add	s4,s4,s11
    80003bde:	0569f663          	bgeu	s3,s6,80003c2a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003be2:	00a9559b          	srliw	a1,s2,0xa
    80003be6:	8556                	mv	a0,s5
    80003be8:	fffff097          	auipc	ra,0xfffff
    80003bec:	7a0080e7          	jalr	1952(ra) # 80003388 <bmap>
    80003bf0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bf4:	c99d                	beqz	a1,80003c2a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bf6:	000aa503          	lw	a0,0(s5)
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	394080e7          	jalr	916(ra) # 80002f8e <bread>
    80003c02:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c04:	3ff97513          	andi	a0,s2,1023
    80003c08:	40ac87bb          	subw	a5,s9,a0
    80003c0c:	413b073b          	subw	a4,s6,s3
    80003c10:	8d3e                	mv	s10,a5
    80003c12:	2781                	sext.w	a5,a5
    80003c14:	0007069b          	sext.w	a3,a4
    80003c18:	f8f6f4e3          	bgeu	a3,a5,80003ba0 <writei+0x4c>
    80003c1c:	8d3a                	mv	s10,a4
    80003c1e:	b749                	j	80003ba0 <writei+0x4c>
      brelse(bp);
    80003c20:	8526                	mv	a0,s1
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	49c080e7          	jalr	1180(ra) # 800030be <brelse>
  }

  if(off > ip->size)
    80003c2a:	04caa783          	lw	a5,76(s5)
    80003c2e:	0127f463          	bgeu	a5,s2,80003c36 <writei+0xe2>
    ip->size = off;
    80003c32:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c36:	8556                	mv	a0,s5
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	aa6080e7          	jalr	-1370(ra) # 800036de <iupdate>

  return tot;
    80003c40:	0009851b          	sext.w	a0,s3
}
    80003c44:	70a6                	ld	ra,104(sp)
    80003c46:	7406                	ld	s0,96(sp)
    80003c48:	64e6                	ld	s1,88(sp)
    80003c4a:	6946                	ld	s2,80(sp)
    80003c4c:	69a6                	ld	s3,72(sp)
    80003c4e:	6a06                	ld	s4,64(sp)
    80003c50:	7ae2                	ld	s5,56(sp)
    80003c52:	7b42                	ld	s6,48(sp)
    80003c54:	7ba2                	ld	s7,40(sp)
    80003c56:	7c02                	ld	s8,32(sp)
    80003c58:	6ce2                	ld	s9,24(sp)
    80003c5a:	6d42                	ld	s10,16(sp)
    80003c5c:	6da2                	ld	s11,8(sp)
    80003c5e:	6165                	addi	sp,sp,112
    80003c60:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c62:	89da                	mv	s3,s6
    80003c64:	bfc9                	j	80003c36 <writei+0xe2>
    return -1;
    80003c66:	557d                	li	a0,-1
}
    80003c68:	8082                	ret
    return -1;
    80003c6a:	557d                	li	a0,-1
    80003c6c:	bfe1                	j	80003c44 <writei+0xf0>
    return -1;
    80003c6e:	557d                	li	a0,-1
    80003c70:	bfd1                	j	80003c44 <writei+0xf0>

0000000080003c72 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c72:	1141                	addi	sp,sp,-16
    80003c74:	e406                	sd	ra,8(sp)
    80003c76:	e022                	sd	s0,0(sp)
    80003c78:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c7a:	4639                	li	a2,14
    80003c7c:	ffffd097          	auipc	ra,0xffffd
    80003c80:	170080e7          	jalr	368(ra) # 80000dec <strncmp>
}
    80003c84:	60a2                	ld	ra,8(sp)
    80003c86:	6402                	ld	s0,0(sp)
    80003c88:	0141                	addi	sp,sp,16
    80003c8a:	8082                	ret

0000000080003c8c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c8c:	7139                	addi	sp,sp,-64
    80003c8e:	fc06                	sd	ra,56(sp)
    80003c90:	f822                	sd	s0,48(sp)
    80003c92:	f426                	sd	s1,40(sp)
    80003c94:	f04a                	sd	s2,32(sp)
    80003c96:	ec4e                	sd	s3,24(sp)
    80003c98:	e852                	sd	s4,16(sp)
    80003c9a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c9c:	04451703          	lh	a4,68(a0)
    80003ca0:	4785                	li	a5,1
    80003ca2:	00f71a63          	bne	a4,a5,80003cb6 <dirlookup+0x2a>
    80003ca6:	892a                	mv	s2,a0
    80003ca8:	89ae                	mv	s3,a1
    80003caa:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cac:	457c                	lw	a5,76(a0)
    80003cae:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cb0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb2:	e79d                	bnez	a5,80003ce0 <dirlookup+0x54>
    80003cb4:	a8a5                	j	80003d2c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cb6:	00005517          	auipc	a0,0x5
    80003cba:	aba50513          	addi	a0,a0,-1350 # 80008770 <syscall_names+0x1a0>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cc6:	00005517          	auipc	a0,0x5
    80003cca:	ac250513          	addi	a0,a0,-1342 # 80008788 <syscall_names+0x1b8>
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	870080e7          	jalr	-1936(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd6:	24c1                	addiw	s1,s1,16
    80003cd8:	04c92783          	lw	a5,76(s2)
    80003cdc:	04f4f763          	bgeu	s1,a5,80003d2a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ce0:	4741                	li	a4,16
    80003ce2:	86a6                	mv	a3,s1
    80003ce4:	fc040613          	addi	a2,s0,-64
    80003ce8:	4581                	li	a1,0
    80003cea:	854a                	mv	a0,s2
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	d70080e7          	jalr	-656(ra) # 80003a5c <readi>
    80003cf4:	47c1                	li	a5,16
    80003cf6:	fcf518e3          	bne	a0,a5,80003cc6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cfa:	fc045783          	lhu	a5,-64(s0)
    80003cfe:	dfe1                	beqz	a5,80003cd6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d00:	fc240593          	addi	a1,s0,-62
    80003d04:	854e                	mv	a0,s3
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	f6c080e7          	jalr	-148(ra) # 80003c72 <namecmp>
    80003d0e:	f561                	bnez	a0,80003cd6 <dirlookup+0x4a>
      if(poff)
    80003d10:	000a0463          	beqz	s4,80003d18 <dirlookup+0x8c>
        *poff = off;
    80003d14:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d18:	fc045583          	lhu	a1,-64(s0)
    80003d1c:	00092503          	lw	a0,0(s2)
    80003d20:	fffff097          	auipc	ra,0xfffff
    80003d24:	750080e7          	jalr	1872(ra) # 80003470 <iget>
    80003d28:	a011                	j	80003d2c <dirlookup+0xa0>
  return 0;
    80003d2a:	4501                	li	a0,0
}
    80003d2c:	70e2                	ld	ra,56(sp)
    80003d2e:	7442                	ld	s0,48(sp)
    80003d30:	74a2                	ld	s1,40(sp)
    80003d32:	7902                	ld	s2,32(sp)
    80003d34:	69e2                	ld	s3,24(sp)
    80003d36:	6a42                	ld	s4,16(sp)
    80003d38:	6121                	addi	sp,sp,64
    80003d3a:	8082                	ret

0000000080003d3c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d3c:	711d                	addi	sp,sp,-96
    80003d3e:	ec86                	sd	ra,88(sp)
    80003d40:	e8a2                	sd	s0,80(sp)
    80003d42:	e4a6                	sd	s1,72(sp)
    80003d44:	e0ca                	sd	s2,64(sp)
    80003d46:	fc4e                	sd	s3,56(sp)
    80003d48:	f852                	sd	s4,48(sp)
    80003d4a:	f456                	sd	s5,40(sp)
    80003d4c:	f05a                	sd	s6,32(sp)
    80003d4e:	ec5e                	sd	s7,24(sp)
    80003d50:	e862                	sd	s8,16(sp)
    80003d52:	e466                	sd	s9,8(sp)
    80003d54:	1080                	addi	s0,sp,96
    80003d56:	84aa                	mv	s1,a0
    80003d58:	8aae                	mv	s5,a1
    80003d5a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d5c:	00054703          	lbu	a4,0(a0)
    80003d60:	02f00793          	li	a5,47
    80003d64:	02f70363          	beq	a4,a5,80003d8a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d68:	ffffe097          	auipc	ra,0xffffe
    80003d6c:	c8e080e7          	jalr	-882(ra) # 800019f6 <myproc>
    80003d70:	15053503          	ld	a0,336(a0)
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	9f6080e7          	jalr	-1546(ra) # 8000376a <idup>
    80003d7c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d7e:	02f00913          	li	s2,47
  len = path - s;
    80003d82:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d84:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d86:	4b85                	li	s7,1
    80003d88:	a865                	j	80003e40 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d8a:	4585                	li	a1,1
    80003d8c:	4505                	li	a0,1
    80003d8e:	fffff097          	auipc	ra,0xfffff
    80003d92:	6e2080e7          	jalr	1762(ra) # 80003470 <iget>
    80003d96:	89aa                	mv	s3,a0
    80003d98:	b7dd                	j	80003d7e <namex+0x42>
      iunlockput(ip);
    80003d9a:	854e                	mv	a0,s3
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	c6e080e7          	jalr	-914(ra) # 80003a0a <iunlockput>
      return 0;
    80003da4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003da6:	854e                	mv	a0,s3
    80003da8:	60e6                	ld	ra,88(sp)
    80003daa:	6446                	ld	s0,80(sp)
    80003dac:	64a6                	ld	s1,72(sp)
    80003dae:	6906                	ld	s2,64(sp)
    80003db0:	79e2                	ld	s3,56(sp)
    80003db2:	7a42                	ld	s4,48(sp)
    80003db4:	7aa2                	ld	s5,40(sp)
    80003db6:	7b02                	ld	s6,32(sp)
    80003db8:	6be2                	ld	s7,24(sp)
    80003dba:	6c42                	ld	s8,16(sp)
    80003dbc:	6ca2                	ld	s9,8(sp)
    80003dbe:	6125                	addi	sp,sp,96
    80003dc0:	8082                	ret
      iunlock(ip);
    80003dc2:	854e                	mv	a0,s3
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	aa6080e7          	jalr	-1370(ra) # 8000386a <iunlock>
      return ip;
    80003dcc:	bfe9                	j	80003da6 <namex+0x6a>
      iunlockput(ip);
    80003dce:	854e                	mv	a0,s3
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	c3a080e7          	jalr	-966(ra) # 80003a0a <iunlockput>
      return 0;
    80003dd8:	89e6                	mv	s3,s9
    80003dda:	b7f1                	j	80003da6 <namex+0x6a>
  len = path - s;
    80003ddc:	40b48633          	sub	a2,s1,a1
    80003de0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003de4:	099c5463          	bge	s8,s9,80003e6c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003de8:	4639                	li	a2,14
    80003dea:	8552                	mv	a0,s4
    80003dec:	ffffd097          	auipc	ra,0xffffd
    80003df0:	f8c080e7          	jalr	-116(ra) # 80000d78 <memmove>
  while(*path == '/')
    80003df4:	0004c783          	lbu	a5,0(s1)
    80003df8:	01279763          	bne	a5,s2,80003e06 <namex+0xca>
    path++;
    80003dfc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dfe:	0004c783          	lbu	a5,0(s1)
    80003e02:	ff278de3          	beq	a5,s2,80003dfc <namex+0xc0>
    ilock(ip);
    80003e06:	854e                	mv	a0,s3
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	9a0080e7          	jalr	-1632(ra) # 800037a8 <ilock>
    if(ip->type != T_DIR){
    80003e10:	04499783          	lh	a5,68(s3)
    80003e14:	f97793e3          	bne	a5,s7,80003d9a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e18:	000a8563          	beqz	s5,80003e22 <namex+0xe6>
    80003e1c:	0004c783          	lbu	a5,0(s1)
    80003e20:	d3cd                	beqz	a5,80003dc2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e22:	865a                	mv	a2,s6
    80003e24:	85d2                	mv	a1,s4
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	e64080e7          	jalr	-412(ra) # 80003c8c <dirlookup>
    80003e30:	8caa                	mv	s9,a0
    80003e32:	dd51                	beqz	a0,80003dce <namex+0x92>
    iunlockput(ip);
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	bd4080e7          	jalr	-1068(ra) # 80003a0a <iunlockput>
    ip = next;
    80003e3e:	89e6                	mv	s3,s9
  while(*path == '/')
    80003e40:	0004c783          	lbu	a5,0(s1)
    80003e44:	05279763          	bne	a5,s2,80003e92 <namex+0x156>
    path++;
    80003e48:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e4a:	0004c783          	lbu	a5,0(s1)
    80003e4e:	ff278de3          	beq	a5,s2,80003e48 <namex+0x10c>
  if(*path == 0)
    80003e52:	c79d                	beqz	a5,80003e80 <namex+0x144>
    path++;
    80003e54:	85a6                	mv	a1,s1
  len = path - s;
    80003e56:	8cda                	mv	s9,s6
    80003e58:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e5a:	01278963          	beq	a5,s2,80003e6c <namex+0x130>
    80003e5e:	dfbd                	beqz	a5,80003ddc <namex+0xa0>
    path++;
    80003e60:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e62:	0004c783          	lbu	a5,0(s1)
    80003e66:	ff279ce3          	bne	a5,s2,80003e5e <namex+0x122>
    80003e6a:	bf8d                	j	80003ddc <namex+0xa0>
    memmove(name, s, len);
    80003e6c:	2601                	sext.w	a2,a2
    80003e6e:	8552                	mv	a0,s4
    80003e70:	ffffd097          	auipc	ra,0xffffd
    80003e74:	f08080e7          	jalr	-248(ra) # 80000d78 <memmove>
    name[len] = 0;
    80003e78:	9cd2                	add	s9,s9,s4
    80003e7a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e7e:	bf9d                	j	80003df4 <namex+0xb8>
  if(nameiparent){
    80003e80:	f20a83e3          	beqz	s5,80003da6 <namex+0x6a>
    iput(ip);
    80003e84:	854e                	mv	a0,s3
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	adc080e7          	jalr	-1316(ra) # 80003962 <iput>
    return 0;
    80003e8e:	4981                	li	s3,0
    80003e90:	bf19                	j	80003da6 <namex+0x6a>
  if(*path == 0)
    80003e92:	d7fd                	beqz	a5,80003e80 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e94:	0004c783          	lbu	a5,0(s1)
    80003e98:	85a6                	mv	a1,s1
    80003e9a:	b7d1                	j	80003e5e <namex+0x122>

0000000080003e9c <dirlink>:
{
    80003e9c:	7139                	addi	sp,sp,-64
    80003e9e:	fc06                	sd	ra,56(sp)
    80003ea0:	f822                	sd	s0,48(sp)
    80003ea2:	f426                	sd	s1,40(sp)
    80003ea4:	f04a                	sd	s2,32(sp)
    80003ea6:	ec4e                	sd	s3,24(sp)
    80003ea8:	e852                	sd	s4,16(sp)
    80003eaa:	0080                	addi	s0,sp,64
    80003eac:	892a                	mv	s2,a0
    80003eae:	8a2e                	mv	s4,a1
    80003eb0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eb2:	4601                	li	a2,0
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	dd8080e7          	jalr	-552(ra) # 80003c8c <dirlookup>
    80003ebc:	e93d                	bnez	a0,80003f32 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ebe:	04c92483          	lw	s1,76(s2)
    80003ec2:	c49d                	beqz	s1,80003ef0 <dirlink+0x54>
    80003ec4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec6:	4741                	li	a4,16
    80003ec8:	86a6                	mv	a3,s1
    80003eca:	fc040613          	addi	a2,s0,-64
    80003ece:	4581                	li	a1,0
    80003ed0:	854a                	mv	a0,s2
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	b8a080e7          	jalr	-1142(ra) # 80003a5c <readi>
    80003eda:	47c1                	li	a5,16
    80003edc:	06f51163          	bne	a0,a5,80003f3e <dirlink+0xa2>
    if(de.inum == 0)
    80003ee0:	fc045783          	lhu	a5,-64(s0)
    80003ee4:	c791                	beqz	a5,80003ef0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee6:	24c1                	addiw	s1,s1,16
    80003ee8:	04c92783          	lw	a5,76(s2)
    80003eec:	fcf4ede3          	bltu	s1,a5,80003ec6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ef0:	4639                	li	a2,14
    80003ef2:	85d2                	mv	a1,s4
    80003ef4:	fc240513          	addi	a0,s0,-62
    80003ef8:	ffffd097          	auipc	ra,0xffffd
    80003efc:	f30080e7          	jalr	-208(ra) # 80000e28 <strncpy>
  de.inum = inum;
    80003f00:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f04:	4741                	li	a4,16
    80003f06:	86a6                	mv	a3,s1
    80003f08:	fc040613          	addi	a2,s0,-64
    80003f0c:	4581                	li	a1,0
    80003f0e:	854a                	mv	a0,s2
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	c44080e7          	jalr	-956(ra) # 80003b54 <writei>
    80003f18:	1541                	addi	a0,a0,-16
    80003f1a:	00a03533          	snez	a0,a0
    80003f1e:	40a00533          	neg	a0,a0
}
    80003f22:	70e2                	ld	ra,56(sp)
    80003f24:	7442                	ld	s0,48(sp)
    80003f26:	74a2                	ld	s1,40(sp)
    80003f28:	7902                	ld	s2,32(sp)
    80003f2a:	69e2                	ld	s3,24(sp)
    80003f2c:	6a42                	ld	s4,16(sp)
    80003f2e:	6121                	addi	sp,sp,64
    80003f30:	8082                	ret
    iput(ip);
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	a30080e7          	jalr	-1488(ra) # 80003962 <iput>
    return -1;
    80003f3a:	557d                	li	a0,-1
    80003f3c:	b7dd                	j	80003f22 <dirlink+0x86>
      panic("dirlink read");
    80003f3e:	00005517          	auipc	a0,0x5
    80003f42:	85a50513          	addi	a0,a0,-1958 # 80008798 <syscall_names+0x1c8>
    80003f46:	ffffc097          	auipc	ra,0xffffc
    80003f4a:	5f8080e7          	jalr	1528(ra) # 8000053e <panic>

0000000080003f4e <namei>:

struct inode*
namei(char *path)
{
    80003f4e:	1101                	addi	sp,sp,-32
    80003f50:	ec06                	sd	ra,24(sp)
    80003f52:	e822                	sd	s0,16(sp)
    80003f54:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f56:	fe040613          	addi	a2,s0,-32
    80003f5a:	4581                	li	a1,0
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	de0080e7          	jalr	-544(ra) # 80003d3c <namex>
}
    80003f64:	60e2                	ld	ra,24(sp)
    80003f66:	6442                	ld	s0,16(sp)
    80003f68:	6105                	addi	sp,sp,32
    80003f6a:	8082                	ret

0000000080003f6c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f6c:	1141                	addi	sp,sp,-16
    80003f6e:	e406                	sd	ra,8(sp)
    80003f70:	e022                	sd	s0,0(sp)
    80003f72:	0800                	addi	s0,sp,16
    80003f74:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f76:	4585                	li	a1,1
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	dc4080e7          	jalr	-572(ra) # 80003d3c <namex>
}
    80003f80:	60a2                	ld	ra,8(sp)
    80003f82:	6402                	ld	s0,0(sp)
    80003f84:	0141                	addi	sp,sp,16
    80003f86:	8082                	ret

0000000080003f88 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f88:	1101                	addi	sp,sp,-32
    80003f8a:	ec06                	sd	ra,24(sp)
    80003f8c:	e822                	sd	s0,16(sp)
    80003f8e:	e426                	sd	s1,8(sp)
    80003f90:	e04a                	sd	s2,0(sp)
    80003f92:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f94:	0001d917          	auipc	s2,0x1d
    80003f98:	eec90913          	addi	s2,s2,-276 # 80020e80 <log>
    80003f9c:	01892583          	lw	a1,24(s2)
    80003fa0:	02892503          	lw	a0,40(s2)
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	fea080e7          	jalr	-22(ra) # 80002f8e <bread>
    80003fac:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fae:	02c92683          	lw	a3,44(s2)
    80003fb2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fb4:	02d05763          	blez	a3,80003fe2 <write_head+0x5a>
    80003fb8:	0001d797          	auipc	a5,0x1d
    80003fbc:	ef878793          	addi	a5,a5,-264 # 80020eb0 <log+0x30>
    80003fc0:	05c50713          	addi	a4,a0,92
    80003fc4:	36fd                	addiw	a3,a3,-1
    80003fc6:	1682                	slli	a3,a3,0x20
    80003fc8:	9281                	srli	a3,a3,0x20
    80003fca:	068a                	slli	a3,a3,0x2
    80003fcc:	0001d617          	auipc	a2,0x1d
    80003fd0:	ee860613          	addi	a2,a2,-280 # 80020eb4 <log+0x34>
    80003fd4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fd6:	4390                	lw	a2,0(a5)
    80003fd8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fda:	0791                	addi	a5,a5,4
    80003fdc:	0711                	addi	a4,a4,4
    80003fde:	fed79ce3          	bne	a5,a3,80003fd6 <write_head+0x4e>
  }
  bwrite(buf);
    80003fe2:	8526                	mv	a0,s1
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	09c080e7          	jalr	156(ra) # 80003080 <bwrite>
  brelse(buf);
    80003fec:	8526                	mv	a0,s1
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	0d0080e7          	jalr	208(ra) # 800030be <brelse>
}
    80003ff6:	60e2                	ld	ra,24(sp)
    80003ff8:	6442                	ld	s0,16(sp)
    80003ffa:	64a2                	ld	s1,8(sp)
    80003ffc:	6902                	ld	s2,0(sp)
    80003ffe:	6105                	addi	sp,sp,32
    80004000:	8082                	ret

0000000080004002 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004002:	0001d797          	auipc	a5,0x1d
    80004006:	eaa7a783          	lw	a5,-342(a5) # 80020eac <log+0x2c>
    8000400a:	0af05d63          	blez	a5,800040c4 <install_trans+0xc2>
{
    8000400e:	7139                	addi	sp,sp,-64
    80004010:	fc06                	sd	ra,56(sp)
    80004012:	f822                	sd	s0,48(sp)
    80004014:	f426                	sd	s1,40(sp)
    80004016:	f04a                	sd	s2,32(sp)
    80004018:	ec4e                	sd	s3,24(sp)
    8000401a:	e852                	sd	s4,16(sp)
    8000401c:	e456                	sd	s5,8(sp)
    8000401e:	e05a                	sd	s6,0(sp)
    80004020:	0080                	addi	s0,sp,64
    80004022:	8b2a                	mv	s6,a0
    80004024:	0001da97          	auipc	s5,0x1d
    80004028:	e8ca8a93          	addi	s5,s5,-372 # 80020eb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000402c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000402e:	0001d997          	auipc	s3,0x1d
    80004032:	e5298993          	addi	s3,s3,-430 # 80020e80 <log>
    80004036:	a00d                	j	80004058 <install_trans+0x56>
    brelse(lbuf);
    80004038:	854a                	mv	a0,s2
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	084080e7          	jalr	132(ra) # 800030be <brelse>
    brelse(dbuf);
    80004042:	8526                	mv	a0,s1
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	07a080e7          	jalr	122(ra) # 800030be <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000404c:	2a05                	addiw	s4,s4,1
    8000404e:	0a91                	addi	s5,s5,4
    80004050:	02c9a783          	lw	a5,44(s3)
    80004054:	04fa5e63          	bge	s4,a5,800040b0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004058:	0189a583          	lw	a1,24(s3)
    8000405c:	014585bb          	addw	a1,a1,s4
    80004060:	2585                	addiw	a1,a1,1
    80004062:	0289a503          	lw	a0,40(s3)
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	f28080e7          	jalr	-216(ra) # 80002f8e <bread>
    8000406e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004070:	000aa583          	lw	a1,0(s5)
    80004074:	0289a503          	lw	a0,40(s3)
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	f16080e7          	jalr	-234(ra) # 80002f8e <bread>
    80004080:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004082:	40000613          	li	a2,1024
    80004086:	05890593          	addi	a1,s2,88
    8000408a:	05850513          	addi	a0,a0,88
    8000408e:	ffffd097          	auipc	ra,0xffffd
    80004092:	cea080e7          	jalr	-790(ra) # 80000d78 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004096:	8526                	mv	a0,s1
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	fe8080e7          	jalr	-24(ra) # 80003080 <bwrite>
    if(recovering == 0)
    800040a0:	f80b1ce3          	bnez	s6,80004038 <install_trans+0x36>
      bunpin(dbuf);
    800040a4:	8526                	mv	a0,s1
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	0f2080e7          	jalr	242(ra) # 80003198 <bunpin>
    800040ae:	b769                	j	80004038 <install_trans+0x36>
}
    800040b0:	70e2                	ld	ra,56(sp)
    800040b2:	7442                	ld	s0,48(sp)
    800040b4:	74a2                	ld	s1,40(sp)
    800040b6:	7902                	ld	s2,32(sp)
    800040b8:	69e2                	ld	s3,24(sp)
    800040ba:	6a42                	ld	s4,16(sp)
    800040bc:	6aa2                	ld	s5,8(sp)
    800040be:	6b02                	ld	s6,0(sp)
    800040c0:	6121                	addi	sp,sp,64
    800040c2:	8082                	ret
    800040c4:	8082                	ret

00000000800040c6 <initlog>:
{
    800040c6:	7179                	addi	sp,sp,-48
    800040c8:	f406                	sd	ra,40(sp)
    800040ca:	f022                	sd	s0,32(sp)
    800040cc:	ec26                	sd	s1,24(sp)
    800040ce:	e84a                	sd	s2,16(sp)
    800040d0:	e44e                	sd	s3,8(sp)
    800040d2:	1800                	addi	s0,sp,48
    800040d4:	892a                	mv	s2,a0
    800040d6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040d8:	0001d497          	auipc	s1,0x1d
    800040dc:	da848493          	addi	s1,s1,-600 # 80020e80 <log>
    800040e0:	00004597          	auipc	a1,0x4
    800040e4:	6c858593          	addi	a1,a1,1736 # 800087a8 <syscall_names+0x1d8>
    800040e8:	8526                	mv	a0,s1
    800040ea:	ffffd097          	auipc	ra,0xffffd
    800040ee:	aa6080e7          	jalr	-1370(ra) # 80000b90 <initlock>
  log.start = sb->logstart;
    800040f2:	0149a583          	lw	a1,20(s3)
    800040f6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040f8:	0109a783          	lw	a5,16(s3)
    800040fc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040fe:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004102:	854a                	mv	a0,s2
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	e8a080e7          	jalr	-374(ra) # 80002f8e <bread>
  log.lh.n = lh->n;
    8000410c:	4d34                	lw	a3,88(a0)
    8000410e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004110:	02d05563          	blez	a3,8000413a <initlog+0x74>
    80004114:	05c50793          	addi	a5,a0,92
    80004118:	0001d717          	auipc	a4,0x1d
    8000411c:	d9870713          	addi	a4,a4,-616 # 80020eb0 <log+0x30>
    80004120:	36fd                	addiw	a3,a3,-1
    80004122:	1682                	slli	a3,a3,0x20
    80004124:	9281                	srli	a3,a3,0x20
    80004126:	068a                	slli	a3,a3,0x2
    80004128:	06050613          	addi	a2,a0,96
    8000412c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000412e:	4390                	lw	a2,0(a5)
    80004130:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004132:	0791                	addi	a5,a5,4
    80004134:	0711                	addi	a4,a4,4
    80004136:	fed79ce3          	bne	a5,a3,8000412e <initlog+0x68>
  brelse(buf);
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	f84080e7          	jalr	-124(ra) # 800030be <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004142:	4505                	li	a0,1
    80004144:	00000097          	auipc	ra,0x0
    80004148:	ebe080e7          	jalr	-322(ra) # 80004002 <install_trans>
  log.lh.n = 0;
    8000414c:	0001d797          	auipc	a5,0x1d
    80004150:	d607a023          	sw	zero,-672(a5) # 80020eac <log+0x2c>
  write_head(); // clear the log
    80004154:	00000097          	auipc	ra,0x0
    80004158:	e34080e7          	jalr	-460(ra) # 80003f88 <write_head>
}
    8000415c:	70a2                	ld	ra,40(sp)
    8000415e:	7402                	ld	s0,32(sp)
    80004160:	64e2                	ld	s1,24(sp)
    80004162:	6942                	ld	s2,16(sp)
    80004164:	69a2                	ld	s3,8(sp)
    80004166:	6145                	addi	sp,sp,48
    80004168:	8082                	ret

000000008000416a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000416a:	1101                	addi	sp,sp,-32
    8000416c:	ec06                	sd	ra,24(sp)
    8000416e:	e822                	sd	s0,16(sp)
    80004170:	e426                	sd	s1,8(sp)
    80004172:	e04a                	sd	s2,0(sp)
    80004174:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004176:	0001d517          	auipc	a0,0x1d
    8000417a:	d0a50513          	addi	a0,a0,-758 # 80020e80 <log>
    8000417e:	ffffd097          	auipc	ra,0xffffd
    80004182:	aa2080e7          	jalr	-1374(ra) # 80000c20 <acquire>
  while(1){
    if(log.committing){
    80004186:	0001d497          	auipc	s1,0x1d
    8000418a:	cfa48493          	addi	s1,s1,-774 # 80020e80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000418e:	4979                	li	s2,30
    80004190:	a039                	j	8000419e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004192:	85a6                	mv	a1,s1
    80004194:	8526                	mv	a0,s1
    80004196:	ffffe097          	auipc	ra,0xffffe
    8000419a:	f14080e7          	jalr	-236(ra) # 800020aa <sleep>
    if(log.committing){
    8000419e:	50dc                	lw	a5,36(s1)
    800041a0:	fbed                	bnez	a5,80004192 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a2:	509c                	lw	a5,32(s1)
    800041a4:	0017871b          	addiw	a4,a5,1
    800041a8:	0007069b          	sext.w	a3,a4
    800041ac:	0027179b          	slliw	a5,a4,0x2
    800041b0:	9fb9                	addw	a5,a5,a4
    800041b2:	0017979b          	slliw	a5,a5,0x1
    800041b6:	54d8                	lw	a4,44(s1)
    800041b8:	9fb9                	addw	a5,a5,a4
    800041ba:	00f95963          	bge	s2,a5,800041cc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041be:	85a6                	mv	a1,s1
    800041c0:	8526                	mv	a0,s1
    800041c2:	ffffe097          	auipc	ra,0xffffe
    800041c6:	ee8080e7          	jalr	-280(ra) # 800020aa <sleep>
    800041ca:	bfd1                	j	8000419e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041cc:	0001d517          	auipc	a0,0x1d
    800041d0:	cb450513          	addi	a0,a0,-844 # 80020e80 <log>
    800041d4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	afe080e7          	jalr	-1282(ra) # 80000cd4 <release>
      break;
    }
  }
}
    800041de:	60e2                	ld	ra,24(sp)
    800041e0:	6442                	ld	s0,16(sp)
    800041e2:	64a2                	ld	s1,8(sp)
    800041e4:	6902                	ld	s2,0(sp)
    800041e6:	6105                	addi	sp,sp,32
    800041e8:	8082                	ret

00000000800041ea <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041ea:	7139                	addi	sp,sp,-64
    800041ec:	fc06                	sd	ra,56(sp)
    800041ee:	f822                	sd	s0,48(sp)
    800041f0:	f426                	sd	s1,40(sp)
    800041f2:	f04a                	sd	s2,32(sp)
    800041f4:	ec4e                	sd	s3,24(sp)
    800041f6:	e852                	sd	s4,16(sp)
    800041f8:	e456                	sd	s5,8(sp)
    800041fa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041fc:	0001d497          	auipc	s1,0x1d
    80004200:	c8448493          	addi	s1,s1,-892 # 80020e80 <log>
    80004204:	8526                	mv	a0,s1
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	a1a080e7          	jalr	-1510(ra) # 80000c20 <acquire>
  log.outstanding -= 1;
    8000420e:	509c                	lw	a5,32(s1)
    80004210:	37fd                	addiw	a5,a5,-1
    80004212:	0007891b          	sext.w	s2,a5
    80004216:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004218:	50dc                	lw	a5,36(s1)
    8000421a:	e7b9                	bnez	a5,80004268 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000421c:	04091e63          	bnez	s2,80004278 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004220:	0001d497          	auipc	s1,0x1d
    80004224:	c6048493          	addi	s1,s1,-928 # 80020e80 <log>
    80004228:	4785                	li	a5,1
    8000422a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000422c:	8526                	mv	a0,s1
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	aa6080e7          	jalr	-1370(ra) # 80000cd4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004236:	54dc                	lw	a5,44(s1)
    80004238:	06f04763          	bgtz	a5,800042a6 <end_op+0xbc>
    acquire(&log.lock);
    8000423c:	0001d497          	auipc	s1,0x1d
    80004240:	c4448493          	addi	s1,s1,-956 # 80020e80 <log>
    80004244:	8526                	mv	a0,s1
    80004246:	ffffd097          	auipc	ra,0xffffd
    8000424a:	9da080e7          	jalr	-1574(ra) # 80000c20 <acquire>
    log.committing = 0;
    8000424e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004252:	8526                	mv	a0,s1
    80004254:	ffffe097          	auipc	ra,0xffffe
    80004258:	eba080e7          	jalr	-326(ra) # 8000210e <wakeup>
    release(&log.lock);
    8000425c:	8526                	mv	a0,s1
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	a76080e7          	jalr	-1418(ra) # 80000cd4 <release>
}
    80004266:	a03d                	j	80004294 <end_op+0xaa>
    panic("log.committing");
    80004268:	00004517          	auipc	a0,0x4
    8000426c:	54850513          	addi	a0,a0,1352 # 800087b0 <syscall_names+0x1e0>
    80004270:	ffffc097          	auipc	ra,0xffffc
    80004274:	2ce080e7          	jalr	718(ra) # 8000053e <panic>
    wakeup(&log);
    80004278:	0001d497          	auipc	s1,0x1d
    8000427c:	c0848493          	addi	s1,s1,-1016 # 80020e80 <log>
    80004280:	8526                	mv	a0,s1
    80004282:	ffffe097          	auipc	ra,0xffffe
    80004286:	e8c080e7          	jalr	-372(ra) # 8000210e <wakeup>
  release(&log.lock);
    8000428a:	8526                	mv	a0,s1
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	a48080e7          	jalr	-1464(ra) # 80000cd4 <release>
}
    80004294:	70e2                	ld	ra,56(sp)
    80004296:	7442                	ld	s0,48(sp)
    80004298:	74a2                	ld	s1,40(sp)
    8000429a:	7902                	ld	s2,32(sp)
    8000429c:	69e2                	ld	s3,24(sp)
    8000429e:	6a42                	ld	s4,16(sp)
    800042a0:	6aa2                	ld	s5,8(sp)
    800042a2:	6121                	addi	sp,sp,64
    800042a4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a6:	0001da97          	auipc	s5,0x1d
    800042aa:	c0aa8a93          	addi	s5,s5,-1014 # 80020eb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042ae:	0001da17          	auipc	s4,0x1d
    800042b2:	bd2a0a13          	addi	s4,s4,-1070 # 80020e80 <log>
    800042b6:	018a2583          	lw	a1,24(s4)
    800042ba:	012585bb          	addw	a1,a1,s2
    800042be:	2585                	addiw	a1,a1,1
    800042c0:	028a2503          	lw	a0,40(s4)
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	cca080e7          	jalr	-822(ra) # 80002f8e <bread>
    800042cc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ce:	000aa583          	lw	a1,0(s5)
    800042d2:	028a2503          	lw	a0,40(s4)
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	cb8080e7          	jalr	-840(ra) # 80002f8e <bread>
    800042de:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042e0:	40000613          	li	a2,1024
    800042e4:	05850593          	addi	a1,a0,88
    800042e8:	05848513          	addi	a0,s1,88
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	a8c080e7          	jalr	-1396(ra) # 80000d78 <memmove>
    bwrite(to);  // write the log
    800042f4:	8526                	mv	a0,s1
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	d8a080e7          	jalr	-630(ra) # 80003080 <bwrite>
    brelse(from);
    800042fe:	854e                	mv	a0,s3
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	dbe080e7          	jalr	-578(ra) # 800030be <brelse>
    brelse(to);
    80004308:	8526                	mv	a0,s1
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	db4080e7          	jalr	-588(ra) # 800030be <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004312:	2905                	addiw	s2,s2,1
    80004314:	0a91                	addi	s5,s5,4
    80004316:	02ca2783          	lw	a5,44(s4)
    8000431a:	f8f94ee3          	blt	s2,a5,800042b6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	c6a080e7          	jalr	-918(ra) # 80003f88 <write_head>
    install_trans(0); // Now install writes to home locations
    80004326:	4501                	li	a0,0
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	cda080e7          	jalr	-806(ra) # 80004002 <install_trans>
    log.lh.n = 0;
    80004330:	0001d797          	auipc	a5,0x1d
    80004334:	b607ae23          	sw	zero,-1156(a5) # 80020eac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004338:	00000097          	auipc	ra,0x0
    8000433c:	c50080e7          	jalr	-944(ra) # 80003f88 <write_head>
    80004340:	bdf5                	j	8000423c <end_op+0x52>

0000000080004342 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004342:	1101                	addi	sp,sp,-32
    80004344:	ec06                	sd	ra,24(sp)
    80004346:	e822                	sd	s0,16(sp)
    80004348:	e426                	sd	s1,8(sp)
    8000434a:	e04a                	sd	s2,0(sp)
    8000434c:	1000                	addi	s0,sp,32
    8000434e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004350:	0001d917          	auipc	s2,0x1d
    80004354:	b3090913          	addi	s2,s2,-1232 # 80020e80 <log>
    80004358:	854a                	mv	a0,s2
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	8c6080e7          	jalr	-1850(ra) # 80000c20 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004362:	02c92603          	lw	a2,44(s2)
    80004366:	47f5                	li	a5,29
    80004368:	06c7c563          	blt	a5,a2,800043d2 <log_write+0x90>
    8000436c:	0001d797          	auipc	a5,0x1d
    80004370:	b307a783          	lw	a5,-1232(a5) # 80020e9c <log+0x1c>
    80004374:	37fd                	addiw	a5,a5,-1
    80004376:	04f65e63          	bge	a2,a5,800043d2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000437a:	0001d797          	auipc	a5,0x1d
    8000437e:	b267a783          	lw	a5,-1242(a5) # 80020ea0 <log+0x20>
    80004382:	06f05063          	blez	a5,800043e2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004386:	4781                	li	a5,0
    80004388:	06c05563          	blez	a2,800043f2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000438c:	44cc                	lw	a1,12(s1)
    8000438e:	0001d717          	auipc	a4,0x1d
    80004392:	b2270713          	addi	a4,a4,-1246 # 80020eb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004396:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004398:	4314                	lw	a3,0(a4)
    8000439a:	04b68c63          	beq	a3,a1,800043f2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000439e:	2785                	addiw	a5,a5,1
    800043a0:	0711                	addi	a4,a4,4
    800043a2:	fef61be3          	bne	a2,a5,80004398 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043a6:	0621                	addi	a2,a2,8
    800043a8:	060a                	slli	a2,a2,0x2
    800043aa:	0001d797          	auipc	a5,0x1d
    800043ae:	ad678793          	addi	a5,a5,-1322 # 80020e80 <log>
    800043b2:	963e                	add	a2,a2,a5
    800043b4:	44dc                	lw	a5,12(s1)
    800043b6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043b8:	8526                	mv	a0,s1
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	da2080e7          	jalr	-606(ra) # 8000315c <bpin>
    log.lh.n++;
    800043c2:	0001d717          	auipc	a4,0x1d
    800043c6:	abe70713          	addi	a4,a4,-1346 # 80020e80 <log>
    800043ca:	575c                	lw	a5,44(a4)
    800043cc:	2785                	addiw	a5,a5,1
    800043ce:	d75c                	sw	a5,44(a4)
    800043d0:	a835                	j	8000440c <log_write+0xca>
    panic("too big a transaction");
    800043d2:	00004517          	auipc	a0,0x4
    800043d6:	3ee50513          	addi	a0,a0,1006 # 800087c0 <syscall_names+0x1f0>
    800043da:	ffffc097          	auipc	ra,0xffffc
    800043de:	164080e7          	jalr	356(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043e2:	00004517          	auipc	a0,0x4
    800043e6:	3f650513          	addi	a0,a0,1014 # 800087d8 <syscall_names+0x208>
    800043ea:	ffffc097          	auipc	ra,0xffffc
    800043ee:	154080e7          	jalr	340(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800043f2:	00878713          	addi	a4,a5,8
    800043f6:	00271693          	slli	a3,a4,0x2
    800043fa:	0001d717          	auipc	a4,0x1d
    800043fe:	a8670713          	addi	a4,a4,-1402 # 80020e80 <log>
    80004402:	9736                	add	a4,a4,a3
    80004404:	44d4                	lw	a3,12(s1)
    80004406:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004408:	faf608e3          	beq	a2,a5,800043b8 <log_write+0x76>
  }
  release(&log.lock);
    8000440c:	0001d517          	auipc	a0,0x1d
    80004410:	a7450513          	addi	a0,a0,-1420 # 80020e80 <log>
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	8c0080e7          	jalr	-1856(ra) # 80000cd4 <release>
}
    8000441c:	60e2                	ld	ra,24(sp)
    8000441e:	6442                	ld	s0,16(sp)
    80004420:	64a2                	ld	s1,8(sp)
    80004422:	6902                	ld	s2,0(sp)
    80004424:	6105                	addi	sp,sp,32
    80004426:	8082                	ret

0000000080004428 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004428:	1101                	addi	sp,sp,-32
    8000442a:	ec06                	sd	ra,24(sp)
    8000442c:	e822                	sd	s0,16(sp)
    8000442e:	e426                	sd	s1,8(sp)
    80004430:	e04a                	sd	s2,0(sp)
    80004432:	1000                	addi	s0,sp,32
    80004434:	84aa                	mv	s1,a0
    80004436:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004438:	00004597          	auipc	a1,0x4
    8000443c:	3c058593          	addi	a1,a1,960 # 800087f8 <syscall_names+0x228>
    80004440:	0521                	addi	a0,a0,8
    80004442:	ffffc097          	auipc	ra,0xffffc
    80004446:	74e080e7          	jalr	1870(ra) # 80000b90 <initlock>
  lk->name = name;
    8000444a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000444e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004452:	0204a423          	sw	zero,40(s1)
}
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	64a2                	ld	s1,8(sp)
    8000445c:	6902                	ld	s2,0(sp)
    8000445e:	6105                	addi	sp,sp,32
    80004460:	8082                	ret

0000000080004462 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004462:	1101                	addi	sp,sp,-32
    80004464:	ec06                	sd	ra,24(sp)
    80004466:	e822                	sd	s0,16(sp)
    80004468:	e426                	sd	s1,8(sp)
    8000446a:	e04a                	sd	s2,0(sp)
    8000446c:	1000                	addi	s0,sp,32
    8000446e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004470:	00850913          	addi	s2,a0,8
    80004474:	854a                	mv	a0,s2
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	7aa080e7          	jalr	1962(ra) # 80000c20 <acquire>
  while (lk->locked) {
    8000447e:	409c                	lw	a5,0(s1)
    80004480:	cb89                	beqz	a5,80004492 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004482:	85ca                	mv	a1,s2
    80004484:	8526                	mv	a0,s1
    80004486:	ffffe097          	auipc	ra,0xffffe
    8000448a:	c24080e7          	jalr	-988(ra) # 800020aa <sleep>
  while (lk->locked) {
    8000448e:	409c                	lw	a5,0(s1)
    80004490:	fbed                	bnez	a5,80004482 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004492:	4785                	li	a5,1
    80004494:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	560080e7          	jalr	1376(ra) # 800019f6 <myproc>
    8000449e:	591c                	lw	a5,48(a0)
    800044a0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044a2:	854a                	mv	a0,s2
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	830080e7          	jalr	-2000(ra) # 80000cd4 <release>
}
    800044ac:	60e2                	ld	ra,24(sp)
    800044ae:	6442                	ld	s0,16(sp)
    800044b0:	64a2                	ld	s1,8(sp)
    800044b2:	6902                	ld	s2,0(sp)
    800044b4:	6105                	addi	sp,sp,32
    800044b6:	8082                	ret

00000000800044b8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044b8:	1101                	addi	sp,sp,-32
    800044ba:	ec06                	sd	ra,24(sp)
    800044bc:	e822                	sd	s0,16(sp)
    800044be:	e426                	sd	s1,8(sp)
    800044c0:	e04a                	sd	s2,0(sp)
    800044c2:	1000                	addi	s0,sp,32
    800044c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044c6:	00850913          	addi	s2,a0,8
    800044ca:	854a                	mv	a0,s2
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	754080e7          	jalr	1876(ra) # 80000c20 <acquire>
  lk->locked = 0;
    800044d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044d8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044dc:	8526                	mv	a0,s1
    800044de:	ffffe097          	auipc	ra,0xffffe
    800044e2:	c30080e7          	jalr	-976(ra) # 8000210e <wakeup>
  release(&lk->lk);
    800044e6:	854a                	mv	a0,s2
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	7ec080e7          	jalr	2028(ra) # 80000cd4 <release>
}
    800044f0:	60e2                	ld	ra,24(sp)
    800044f2:	6442                	ld	s0,16(sp)
    800044f4:	64a2                	ld	s1,8(sp)
    800044f6:	6902                	ld	s2,0(sp)
    800044f8:	6105                	addi	sp,sp,32
    800044fa:	8082                	ret

00000000800044fc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044fc:	7179                	addi	sp,sp,-48
    800044fe:	f406                	sd	ra,40(sp)
    80004500:	f022                	sd	s0,32(sp)
    80004502:	ec26                	sd	s1,24(sp)
    80004504:	e84a                	sd	s2,16(sp)
    80004506:	e44e                	sd	s3,8(sp)
    80004508:	1800                	addi	s0,sp,48
    8000450a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000450c:	00850913          	addi	s2,a0,8
    80004510:	854a                	mv	a0,s2
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	70e080e7          	jalr	1806(ra) # 80000c20 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000451a:	409c                	lw	a5,0(s1)
    8000451c:	ef99                	bnez	a5,8000453a <holdingsleep+0x3e>
    8000451e:	4481                	li	s1,0
  release(&lk->lk);
    80004520:	854a                	mv	a0,s2
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	7b2080e7          	jalr	1970(ra) # 80000cd4 <release>
  return r;
}
    8000452a:	8526                	mv	a0,s1
    8000452c:	70a2                	ld	ra,40(sp)
    8000452e:	7402                	ld	s0,32(sp)
    80004530:	64e2                	ld	s1,24(sp)
    80004532:	6942                	ld	s2,16(sp)
    80004534:	69a2                	ld	s3,8(sp)
    80004536:	6145                	addi	sp,sp,48
    80004538:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000453a:	0284a983          	lw	s3,40(s1)
    8000453e:	ffffd097          	auipc	ra,0xffffd
    80004542:	4b8080e7          	jalr	1208(ra) # 800019f6 <myproc>
    80004546:	5904                	lw	s1,48(a0)
    80004548:	413484b3          	sub	s1,s1,s3
    8000454c:	0014b493          	seqz	s1,s1
    80004550:	bfc1                	j	80004520 <holdingsleep+0x24>

0000000080004552 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004552:	1141                	addi	sp,sp,-16
    80004554:	e406                	sd	ra,8(sp)
    80004556:	e022                	sd	s0,0(sp)
    80004558:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000455a:	00004597          	auipc	a1,0x4
    8000455e:	2ae58593          	addi	a1,a1,686 # 80008808 <syscall_names+0x238>
    80004562:	0001d517          	auipc	a0,0x1d
    80004566:	a6650513          	addi	a0,a0,-1434 # 80020fc8 <ftable>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	626080e7          	jalr	1574(ra) # 80000b90 <initlock>
}
    80004572:	60a2                	ld	ra,8(sp)
    80004574:	6402                	ld	s0,0(sp)
    80004576:	0141                	addi	sp,sp,16
    80004578:	8082                	ret

000000008000457a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000457a:	1101                	addi	sp,sp,-32
    8000457c:	ec06                	sd	ra,24(sp)
    8000457e:	e822                	sd	s0,16(sp)
    80004580:	e426                	sd	s1,8(sp)
    80004582:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004584:	0001d517          	auipc	a0,0x1d
    80004588:	a4450513          	addi	a0,a0,-1468 # 80020fc8 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	694080e7          	jalr	1684(ra) # 80000c20 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004594:	0001d497          	auipc	s1,0x1d
    80004598:	a4c48493          	addi	s1,s1,-1460 # 80020fe0 <ftable+0x18>
    8000459c:	0001e717          	auipc	a4,0x1e
    800045a0:	9e470713          	addi	a4,a4,-1564 # 80021f80 <disk>
    if(f->ref == 0){
    800045a4:	40dc                	lw	a5,4(s1)
    800045a6:	cf99                	beqz	a5,800045c4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a8:	02848493          	addi	s1,s1,40
    800045ac:	fee49ce3          	bne	s1,a4,800045a4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045b0:	0001d517          	auipc	a0,0x1d
    800045b4:	a1850513          	addi	a0,a0,-1512 # 80020fc8 <ftable>
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	71c080e7          	jalr	1820(ra) # 80000cd4 <release>
  return 0;
    800045c0:	4481                	li	s1,0
    800045c2:	a819                	j	800045d8 <filealloc+0x5e>
      f->ref = 1;
    800045c4:	4785                	li	a5,1
    800045c6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045c8:	0001d517          	auipc	a0,0x1d
    800045cc:	a0050513          	addi	a0,a0,-1536 # 80020fc8 <ftable>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	704080e7          	jalr	1796(ra) # 80000cd4 <release>
}
    800045d8:	8526                	mv	a0,s1
    800045da:	60e2                	ld	ra,24(sp)
    800045dc:	6442                	ld	s0,16(sp)
    800045de:	64a2                	ld	s1,8(sp)
    800045e0:	6105                	addi	sp,sp,32
    800045e2:	8082                	ret

00000000800045e4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045e4:	1101                	addi	sp,sp,-32
    800045e6:	ec06                	sd	ra,24(sp)
    800045e8:	e822                	sd	s0,16(sp)
    800045ea:	e426                	sd	s1,8(sp)
    800045ec:	1000                	addi	s0,sp,32
    800045ee:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045f0:	0001d517          	auipc	a0,0x1d
    800045f4:	9d850513          	addi	a0,a0,-1576 # 80020fc8 <ftable>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	628080e7          	jalr	1576(ra) # 80000c20 <acquire>
  if(f->ref < 1)
    80004600:	40dc                	lw	a5,4(s1)
    80004602:	02f05263          	blez	a5,80004626 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004606:	2785                	addiw	a5,a5,1
    80004608:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000460a:	0001d517          	auipc	a0,0x1d
    8000460e:	9be50513          	addi	a0,a0,-1602 # 80020fc8 <ftable>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	6c2080e7          	jalr	1730(ra) # 80000cd4 <release>
  return f;
}
    8000461a:	8526                	mv	a0,s1
    8000461c:	60e2                	ld	ra,24(sp)
    8000461e:	6442                	ld	s0,16(sp)
    80004620:	64a2                	ld	s1,8(sp)
    80004622:	6105                	addi	sp,sp,32
    80004624:	8082                	ret
    panic("filedup");
    80004626:	00004517          	auipc	a0,0x4
    8000462a:	1ea50513          	addi	a0,a0,490 # 80008810 <syscall_names+0x240>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>

0000000080004636 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004636:	7139                	addi	sp,sp,-64
    80004638:	fc06                	sd	ra,56(sp)
    8000463a:	f822                	sd	s0,48(sp)
    8000463c:	f426                	sd	s1,40(sp)
    8000463e:	f04a                	sd	s2,32(sp)
    80004640:	ec4e                	sd	s3,24(sp)
    80004642:	e852                	sd	s4,16(sp)
    80004644:	e456                	sd	s5,8(sp)
    80004646:	0080                	addi	s0,sp,64
    80004648:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000464a:	0001d517          	auipc	a0,0x1d
    8000464e:	97e50513          	addi	a0,a0,-1666 # 80020fc8 <ftable>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	5ce080e7          	jalr	1486(ra) # 80000c20 <acquire>
  if(f->ref < 1)
    8000465a:	40dc                	lw	a5,4(s1)
    8000465c:	06f05163          	blez	a5,800046be <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004660:	37fd                	addiw	a5,a5,-1
    80004662:	0007871b          	sext.w	a4,a5
    80004666:	c0dc                	sw	a5,4(s1)
    80004668:	06e04363          	bgtz	a4,800046ce <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000466c:	0004a903          	lw	s2,0(s1)
    80004670:	0094ca83          	lbu	s5,9(s1)
    80004674:	0104ba03          	ld	s4,16(s1)
    80004678:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000467c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004680:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004684:	0001d517          	auipc	a0,0x1d
    80004688:	94450513          	addi	a0,a0,-1724 # 80020fc8 <ftable>
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	648080e7          	jalr	1608(ra) # 80000cd4 <release>

  if(ff.type == FD_PIPE){
    80004694:	4785                	li	a5,1
    80004696:	04f90d63          	beq	s2,a5,800046f0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000469a:	3979                	addiw	s2,s2,-2
    8000469c:	4785                	li	a5,1
    8000469e:	0527e063          	bltu	a5,s2,800046de <fileclose+0xa8>
    begin_op();
    800046a2:	00000097          	auipc	ra,0x0
    800046a6:	ac8080e7          	jalr	-1336(ra) # 8000416a <begin_op>
    iput(ff.ip);
    800046aa:	854e                	mv	a0,s3
    800046ac:	fffff097          	auipc	ra,0xfffff
    800046b0:	2b6080e7          	jalr	694(ra) # 80003962 <iput>
    end_op();
    800046b4:	00000097          	auipc	ra,0x0
    800046b8:	b36080e7          	jalr	-1226(ra) # 800041ea <end_op>
    800046bc:	a00d                	j	800046de <fileclose+0xa8>
    panic("fileclose");
    800046be:	00004517          	auipc	a0,0x4
    800046c2:	15a50513          	addi	a0,a0,346 # 80008818 <syscall_names+0x248>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	e78080e7          	jalr	-392(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046ce:	0001d517          	auipc	a0,0x1d
    800046d2:	8fa50513          	addi	a0,a0,-1798 # 80020fc8 <ftable>
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	5fe080e7          	jalr	1534(ra) # 80000cd4 <release>
  }
}
    800046de:	70e2                	ld	ra,56(sp)
    800046e0:	7442                	ld	s0,48(sp)
    800046e2:	74a2                	ld	s1,40(sp)
    800046e4:	7902                	ld	s2,32(sp)
    800046e6:	69e2                	ld	s3,24(sp)
    800046e8:	6a42                	ld	s4,16(sp)
    800046ea:	6aa2                	ld	s5,8(sp)
    800046ec:	6121                	addi	sp,sp,64
    800046ee:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046f0:	85d6                	mv	a1,s5
    800046f2:	8552                	mv	a0,s4
    800046f4:	00000097          	auipc	ra,0x0
    800046f8:	34c080e7          	jalr	844(ra) # 80004a40 <pipeclose>
    800046fc:	b7cd                	j	800046de <fileclose+0xa8>

00000000800046fe <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046fe:	715d                	addi	sp,sp,-80
    80004700:	e486                	sd	ra,72(sp)
    80004702:	e0a2                	sd	s0,64(sp)
    80004704:	fc26                	sd	s1,56(sp)
    80004706:	f84a                	sd	s2,48(sp)
    80004708:	f44e                	sd	s3,40(sp)
    8000470a:	0880                	addi	s0,sp,80
    8000470c:	84aa                	mv	s1,a0
    8000470e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004710:	ffffd097          	auipc	ra,0xffffd
    80004714:	2e6080e7          	jalr	742(ra) # 800019f6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004718:	409c                	lw	a5,0(s1)
    8000471a:	37f9                	addiw	a5,a5,-2
    8000471c:	4705                	li	a4,1
    8000471e:	04f76763          	bltu	a4,a5,8000476c <filestat+0x6e>
    80004722:	892a                	mv	s2,a0
    ilock(f->ip);
    80004724:	6c88                	ld	a0,24(s1)
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	082080e7          	jalr	130(ra) # 800037a8 <ilock>
    stati(f->ip, &st);
    8000472e:	fb840593          	addi	a1,s0,-72
    80004732:	6c88                	ld	a0,24(s1)
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	2fe080e7          	jalr	766(ra) # 80003a32 <stati>
    iunlock(f->ip);
    8000473c:	6c88                	ld	a0,24(s1)
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	12c080e7          	jalr	300(ra) # 8000386a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004746:	46e1                	li	a3,24
    80004748:	fb840613          	addi	a2,s0,-72
    8000474c:	85ce                	mv	a1,s3
    8000474e:	05093503          	ld	a0,80(s2)
    80004752:	ffffd097          	auipc	ra,0xffffd
    80004756:	f60080e7          	jalr	-160(ra) # 800016b2 <copyout>
    8000475a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000475e:	60a6                	ld	ra,72(sp)
    80004760:	6406                	ld	s0,64(sp)
    80004762:	74e2                	ld	s1,56(sp)
    80004764:	7942                	ld	s2,48(sp)
    80004766:	79a2                	ld	s3,40(sp)
    80004768:	6161                	addi	sp,sp,80
    8000476a:	8082                	ret
  return -1;
    8000476c:	557d                	li	a0,-1
    8000476e:	bfc5                	j	8000475e <filestat+0x60>

0000000080004770 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004770:	7179                	addi	sp,sp,-48
    80004772:	f406                	sd	ra,40(sp)
    80004774:	f022                	sd	s0,32(sp)
    80004776:	ec26                	sd	s1,24(sp)
    80004778:	e84a                	sd	s2,16(sp)
    8000477a:	e44e                	sd	s3,8(sp)
    8000477c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000477e:	00854783          	lbu	a5,8(a0)
    80004782:	c3d5                	beqz	a5,80004826 <fileread+0xb6>
    80004784:	84aa                	mv	s1,a0
    80004786:	89ae                	mv	s3,a1
    80004788:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000478a:	411c                	lw	a5,0(a0)
    8000478c:	4705                	li	a4,1
    8000478e:	04e78963          	beq	a5,a4,800047e0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004792:	470d                	li	a4,3
    80004794:	04e78d63          	beq	a5,a4,800047ee <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004798:	4709                	li	a4,2
    8000479a:	06e79e63          	bne	a5,a4,80004816 <fileread+0xa6>
    ilock(f->ip);
    8000479e:	6d08                	ld	a0,24(a0)
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	008080e7          	jalr	8(ra) # 800037a8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047a8:	874a                	mv	a4,s2
    800047aa:	5094                	lw	a3,32(s1)
    800047ac:	864e                	mv	a2,s3
    800047ae:	4585                	li	a1,1
    800047b0:	6c88                	ld	a0,24(s1)
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	2aa080e7          	jalr	682(ra) # 80003a5c <readi>
    800047ba:	892a                	mv	s2,a0
    800047bc:	00a05563          	blez	a0,800047c6 <fileread+0x56>
      f->off += r;
    800047c0:	509c                	lw	a5,32(s1)
    800047c2:	9fa9                	addw	a5,a5,a0
    800047c4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047c6:	6c88                	ld	a0,24(s1)
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	0a2080e7          	jalr	162(ra) # 8000386a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047d0:	854a                	mv	a0,s2
    800047d2:	70a2                	ld	ra,40(sp)
    800047d4:	7402                	ld	s0,32(sp)
    800047d6:	64e2                	ld	s1,24(sp)
    800047d8:	6942                	ld	s2,16(sp)
    800047da:	69a2                	ld	s3,8(sp)
    800047dc:	6145                	addi	sp,sp,48
    800047de:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047e0:	6908                	ld	a0,16(a0)
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	3c6080e7          	jalr	966(ra) # 80004ba8 <piperead>
    800047ea:	892a                	mv	s2,a0
    800047ec:	b7d5                	j	800047d0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047ee:	02451783          	lh	a5,36(a0)
    800047f2:	03079693          	slli	a3,a5,0x30
    800047f6:	92c1                	srli	a3,a3,0x30
    800047f8:	4725                	li	a4,9
    800047fa:	02d76863          	bltu	a4,a3,8000482a <fileread+0xba>
    800047fe:	0792                	slli	a5,a5,0x4
    80004800:	0001c717          	auipc	a4,0x1c
    80004804:	72870713          	addi	a4,a4,1832 # 80020f28 <devsw>
    80004808:	97ba                	add	a5,a5,a4
    8000480a:	639c                	ld	a5,0(a5)
    8000480c:	c38d                	beqz	a5,8000482e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000480e:	4505                	li	a0,1
    80004810:	9782                	jalr	a5
    80004812:	892a                	mv	s2,a0
    80004814:	bf75                	j	800047d0 <fileread+0x60>
    panic("fileread");
    80004816:	00004517          	auipc	a0,0x4
    8000481a:	01250513          	addi	a0,a0,18 # 80008828 <syscall_names+0x258>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	d20080e7          	jalr	-736(ra) # 8000053e <panic>
    return -1;
    80004826:	597d                	li	s2,-1
    80004828:	b765                	j	800047d0 <fileread+0x60>
      return -1;
    8000482a:	597d                	li	s2,-1
    8000482c:	b755                	j	800047d0 <fileread+0x60>
    8000482e:	597d                	li	s2,-1
    80004830:	b745                	j	800047d0 <fileread+0x60>

0000000080004832 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004832:	715d                	addi	sp,sp,-80
    80004834:	e486                	sd	ra,72(sp)
    80004836:	e0a2                	sd	s0,64(sp)
    80004838:	fc26                	sd	s1,56(sp)
    8000483a:	f84a                	sd	s2,48(sp)
    8000483c:	f44e                	sd	s3,40(sp)
    8000483e:	f052                	sd	s4,32(sp)
    80004840:	ec56                	sd	s5,24(sp)
    80004842:	e85a                	sd	s6,16(sp)
    80004844:	e45e                	sd	s7,8(sp)
    80004846:	e062                	sd	s8,0(sp)
    80004848:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000484a:	00954783          	lbu	a5,9(a0)
    8000484e:	10078663          	beqz	a5,8000495a <filewrite+0x128>
    80004852:	892a                	mv	s2,a0
    80004854:	8aae                	mv	s5,a1
    80004856:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004858:	411c                	lw	a5,0(a0)
    8000485a:	4705                	li	a4,1
    8000485c:	02e78263          	beq	a5,a4,80004880 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004860:	470d                	li	a4,3
    80004862:	02e78663          	beq	a5,a4,8000488e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004866:	4709                	li	a4,2
    80004868:	0ee79163          	bne	a5,a4,8000494a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000486c:	0ac05d63          	blez	a2,80004926 <filewrite+0xf4>
    int i = 0;
    80004870:	4981                	li	s3,0
    80004872:	6b05                	lui	s6,0x1
    80004874:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004878:	6b85                	lui	s7,0x1
    8000487a:	c00b8b9b          	addiw	s7,s7,-1024
    8000487e:	a861                	j	80004916 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004880:	6908                	ld	a0,16(a0)
    80004882:	00000097          	auipc	ra,0x0
    80004886:	22e080e7          	jalr	558(ra) # 80004ab0 <pipewrite>
    8000488a:	8a2a                	mv	s4,a0
    8000488c:	a045                	j	8000492c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000488e:	02451783          	lh	a5,36(a0)
    80004892:	03079693          	slli	a3,a5,0x30
    80004896:	92c1                	srli	a3,a3,0x30
    80004898:	4725                	li	a4,9
    8000489a:	0cd76263          	bltu	a4,a3,8000495e <filewrite+0x12c>
    8000489e:	0792                	slli	a5,a5,0x4
    800048a0:	0001c717          	auipc	a4,0x1c
    800048a4:	68870713          	addi	a4,a4,1672 # 80020f28 <devsw>
    800048a8:	97ba                	add	a5,a5,a4
    800048aa:	679c                	ld	a5,8(a5)
    800048ac:	cbdd                	beqz	a5,80004962 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048ae:	4505                	li	a0,1
    800048b0:	9782                	jalr	a5
    800048b2:	8a2a                	mv	s4,a0
    800048b4:	a8a5                	j	8000492c <filewrite+0xfa>
    800048b6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ba:	00000097          	auipc	ra,0x0
    800048be:	8b0080e7          	jalr	-1872(ra) # 8000416a <begin_op>
      ilock(f->ip);
    800048c2:	01893503          	ld	a0,24(s2)
    800048c6:	fffff097          	auipc	ra,0xfffff
    800048ca:	ee2080e7          	jalr	-286(ra) # 800037a8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048ce:	8762                	mv	a4,s8
    800048d0:	02092683          	lw	a3,32(s2)
    800048d4:	01598633          	add	a2,s3,s5
    800048d8:	4585                	li	a1,1
    800048da:	01893503          	ld	a0,24(s2)
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	276080e7          	jalr	630(ra) # 80003b54 <writei>
    800048e6:	84aa                	mv	s1,a0
    800048e8:	00a05763          	blez	a0,800048f6 <filewrite+0xc4>
        f->off += r;
    800048ec:	02092783          	lw	a5,32(s2)
    800048f0:	9fa9                	addw	a5,a5,a0
    800048f2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048f6:	01893503          	ld	a0,24(s2)
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	f70080e7          	jalr	-144(ra) # 8000386a <iunlock>
      end_op();
    80004902:	00000097          	auipc	ra,0x0
    80004906:	8e8080e7          	jalr	-1816(ra) # 800041ea <end_op>

      if(r != n1){
    8000490a:	009c1f63          	bne	s8,s1,80004928 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000490e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004912:	0149db63          	bge	s3,s4,80004928 <filewrite+0xf6>
      int n1 = n - i;
    80004916:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000491a:	84be                	mv	s1,a5
    8000491c:	2781                	sext.w	a5,a5
    8000491e:	f8fb5ce3          	bge	s6,a5,800048b6 <filewrite+0x84>
    80004922:	84de                	mv	s1,s7
    80004924:	bf49                	j	800048b6 <filewrite+0x84>
    int i = 0;
    80004926:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004928:	013a1f63          	bne	s4,s3,80004946 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000492c:	8552                	mv	a0,s4
    8000492e:	60a6                	ld	ra,72(sp)
    80004930:	6406                	ld	s0,64(sp)
    80004932:	74e2                	ld	s1,56(sp)
    80004934:	7942                	ld	s2,48(sp)
    80004936:	79a2                	ld	s3,40(sp)
    80004938:	7a02                	ld	s4,32(sp)
    8000493a:	6ae2                	ld	s5,24(sp)
    8000493c:	6b42                	ld	s6,16(sp)
    8000493e:	6ba2                	ld	s7,8(sp)
    80004940:	6c02                	ld	s8,0(sp)
    80004942:	6161                	addi	sp,sp,80
    80004944:	8082                	ret
    ret = (i == n ? n : -1);
    80004946:	5a7d                	li	s4,-1
    80004948:	b7d5                	j	8000492c <filewrite+0xfa>
    panic("filewrite");
    8000494a:	00004517          	auipc	a0,0x4
    8000494e:	eee50513          	addi	a0,a0,-274 # 80008838 <syscall_names+0x268>
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	bec080e7          	jalr	-1044(ra) # 8000053e <panic>
    return -1;
    8000495a:	5a7d                	li	s4,-1
    8000495c:	bfc1                	j	8000492c <filewrite+0xfa>
      return -1;
    8000495e:	5a7d                	li	s4,-1
    80004960:	b7f1                	j	8000492c <filewrite+0xfa>
    80004962:	5a7d                	li	s4,-1
    80004964:	b7e1                	j	8000492c <filewrite+0xfa>

0000000080004966 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004966:	7179                	addi	sp,sp,-48
    80004968:	f406                	sd	ra,40(sp)
    8000496a:	f022                	sd	s0,32(sp)
    8000496c:	ec26                	sd	s1,24(sp)
    8000496e:	e84a                	sd	s2,16(sp)
    80004970:	e44e                	sd	s3,8(sp)
    80004972:	e052                	sd	s4,0(sp)
    80004974:	1800                	addi	s0,sp,48
    80004976:	84aa                	mv	s1,a0
    80004978:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000497a:	0005b023          	sd	zero,0(a1)
    8000497e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004982:	00000097          	auipc	ra,0x0
    80004986:	bf8080e7          	jalr	-1032(ra) # 8000457a <filealloc>
    8000498a:	e088                	sd	a0,0(s1)
    8000498c:	c551                	beqz	a0,80004a18 <pipealloc+0xb2>
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	bec080e7          	jalr	-1044(ra) # 8000457a <filealloc>
    80004996:	00aa3023          	sd	a0,0(s4)
    8000499a:	c92d                	beqz	a0,80004a0c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	14a080e7          	jalr	330(ra) # 80000ae6 <kalloc>
    800049a4:	892a                	mv	s2,a0
    800049a6:	c125                	beqz	a0,80004a06 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049a8:	4985                	li	s3,1
    800049aa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049ae:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049b2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049b6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049ba:	00004597          	auipc	a1,0x4
    800049be:	aae58593          	addi	a1,a1,-1362 # 80008468 <states.0+0x1a0>
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	1ce080e7          	jalr	462(ra) # 80000b90 <initlock>
  (*f0)->type = FD_PIPE;
    800049ca:	609c                	ld	a5,0(s1)
    800049cc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049d0:	609c                	ld	a5,0(s1)
    800049d2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049d6:	609c                	ld	a5,0(s1)
    800049d8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049dc:	609c                	ld	a5,0(s1)
    800049de:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049e2:	000a3783          	ld	a5,0(s4)
    800049e6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049ea:	000a3783          	ld	a5,0(s4)
    800049ee:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049f2:	000a3783          	ld	a5,0(s4)
    800049f6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049fa:	000a3783          	ld	a5,0(s4)
    800049fe:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a02:	4501                	li	a0,0
    80004a04:	a025                	j	80004a2c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a06:	6088                	ld	a0,0(s1)
    80004a08:	e501                	bnez	a0,80004a10 <pipealloc+0xaa>
    80004a0a:	a039                	j	80004a18 <pipealloc+0xb2>
    80004a0c:	6088                	ld	a0,0(s1)
    80004a0e:	c51d                	beqz	a0,80004a3c <pipealloc+0xd6>
    fileclose(*f0);
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	c26080e7          	jalr	-986(ra) # 80004636 <fileclose>
  if(*f1)
    80004a18:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a1c:	557d                	li	a0,-1
  if(*f1)
    80004a1e:	c799                	beqz	a5,80004a2c <pipealloc+0xc6>
    fileclose(*f1);
    80004a20:	853e                	mv	a0,a5
    80004a22:	00000097          	auipc	ra,0x0
    80004a26:	c14080e7          	jalr	-1004(ra) # 80004636 <fileclose>
  return -1;
    80004a2a:	557d                	li	a0,-1
}
    80004a2c:	70a2                	ld	ra,40(sp)
    80004a2e:	7402                	ld	s0,32(sp)
    80004a30:	64e2                	ld	s1,24(sp)
    80004a32:	6942                	ld	s2,16(sp)
    80004a34:	69a2                	ld	s3,8(sp)
    80004a36:	6a02                	ld	s4,0(sp)
    80004a38:	6145                	addi	sp,sp,48
    80004a3a:	8082                	ret
  return -1;
    80004a3c:	557d                	li	a0,-1
    80004a3e:	b7fd                	j	80004a2c <pipealloc+0xc6>

0000000080004a40 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a40:	1101                	addi	sp,sp,-32
    80004a42:	ec06                	sd	ra,24(sp)
    80004a44:	e822                	sd	s0,16(sp)
    80004a46:	e426                	sd	s1,8(sp)
    80004a48:	e04a                	sd	s2,0(sp)
    80004a4a:	1000                	addi	s0,sp,32
    80004a4c:	84aa                	mv	s1,a0
    80004a4e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	1d0080e7          	jalr	464(ra) # 80000c20 <acquire>
  if(writable){
    80004a58:	02090d63          	beqz	s2,80004a92 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a5c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a60:	21848513          	addi	a0,s1,536
    80004a64:	ffffd097          	auipc	ra,0xffffd
    80004a68:	6aa080e7          	jalr	1706(ra) # 8000210e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a6c:	2204b783          	ld	a5,544(s1)
    80004a70:	eb95                	bnez	a5,80004aa4 <pipeclose+0x64>
    release(&pi->lock);
    80004a72:	8526                	mv	a0,s1
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	260080e7          	jalr	608(ra) # 80000cd4 <release>
    kfree((char*)pi);
    80004a7c:	8526                	mv	a0,s1
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	f6c080e7          	jalr	-148(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004a86:	60e2                	ld	ra,24(sp)
    80004a88:	6442                	ld	s0,16(sp)
    80004a8a:	64a2                	ld	s1,8(sp)
    80004a8c:	6902                	ld	s2,0(sp)
    80004a8e:	6105                	addi	sp,sp,32
    80004a90:	8082                	ret
    pi->readopen = 0;
    80004a92:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a96:	21c48513          	addi	a0,s1,540
    80004a9a:	ffffd097          	auipc	ra,0xffffd
    80004a9e:	674080e7          	jalr	1652(ra) # 8000210e <wakeup>
    80004aa2:	b7e9                	j	80004a6c <pipeclose+0x2c>
    release(&pi->lock);
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	22e080e7          	jalr	558(ra) # 80000cd4 <release>
}
    80004aae:	bfe1                	j	80004a86 <pipeclose+0x46>

0000000080004ab0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ab0:	711d                	addi	sp,sp,-96
    80004ab2:	ec86                	sd	ra,88(sp)
    80004ab4:	e8a2                	sd	s0,80(sp)
    80004ab6:	e4a6                	sd	s1,72(sp)
    80004ab8:	e0ca                	sd	s2,64(sp)
    80004aba:	fc4e                	sd	s3,56(sp)
    80004abc:	f852                	sd	s4,48(sp)
    80004abe:	f456                	sd	s5,40(sp)
    80004ac0:	f05a                	sd	s6,32(sp)
    80004ac2:	ec5e                	sd	s7,24(sp)
    80004ac4:	e862                	sd	s8,16(sp)
    80004ac6:	1080                	addi	s0,sp,96
    80004ac8:	84aa                	mv	s1,a0
    80004aca:	8aae                	mv	s5,a1
    80004acc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ace:	ffffd097          	auipc	ra,0xffffd
    80004ad2:	f28080e7          	jalr	-216(ra) # 800019f6 <myproc>
    80004ad6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	146080e7          	jalr	326(ra) # 80000c20 <acquire>
  while(i < n){
    80004ae2:	0b405663          	blez	s4,80004b8e <pipewrite+0xde>
  int i = 0;
    80004ae6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ae8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004aea:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004aee:	21c48b93          	addi	s7,s1,540
    80004af2:	a089                	j	80004b34 <pipewrite+0x84>
      release(&pi->lock);
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	1de080e7          	jalr	478(ra) # 80000cd4 <release>
      return -1;
    80004afe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b00:	854a                	mv	a0,s2
    80004b02:	60e6                	ld	ra,88(sp)
    80004b04:	6446                	ld	s0,80(sp)
    80004b06:	64a6                	ld	s1,72(sp)
    80004b08:	6906                	ld	s2,64(sp)
    80004b0a:	79e2                	ld	s3,56(sp)
    80004b0c:	7a42                	ld	s4,48(sp)
    80004b0e:	7aa2                	ld	s5,40(sp)
    80004b10:	7b02                	ld	s6,32(sp)
    80004b12:	6be2                	ld	s7,24(sp)
    80004b14:	6c42                	ld	s8,16(sp)
    80004b16:	6125                	addi	sp,sp,96
    80004b18:	8082                	ret
      wakeup(&pi->nread);
    80004b1a:	8562                	mv	a0,s8
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	5f2080e7          	jalr	1522(ra) # 8000210e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b24:	85a6                	mv	a1,s1
    80004b26:	855e                	mv	a0,s7
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	582080e7          	jalr	1410(ra) # 800020aa <sleep>
  while(i < n){
    80004b30:	07495063          	bge	s2,s4,80004b90 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b34:	2204a783          	lw	a5,544(s1)
    80004b38:	dfd5                	beqz	a5,80004af4 <pipewrite+0x44>
    80004b3a:	854e                	mv	a0,s3
    80004b3c:	ffffe097          	auipc	ra,0xffffe
    80004b40:	816080e7          	jalr	-2026(ra) # 80002352 <killed>
    80004b44:	f945                	bnez	a0,80004af4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b46:	2184a783          	lw	a5,536(s1)
    80004b4a:	21c4a703          	lw	a4,540(s1)
    80004b4e:	2007879b          	addiw	a5,a5,512
    80004b52:	fcf704e3          	beq	a4,a5,80004b1a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b56:	4685                	li	a3,1
    80004b58:	01590633          	add	a2,s2,s5
    80004b5c:	faf40593          	addi	a1,s0,-81
    80004b60:	0509b503          	ld	a0,80(s3)
    80004b64:	ffffd097          	auipc	ra,0xffffd
    80004b68:	bda080e7          	jalr	-1062(ra) # 8000173e <copyin>
    80004b6c:	03650263          	beq	a0,s6,80004b90 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b70:	21c4a783          	lw	a5,540(s1)
    80004b74:	0017871b          	addiw	a4,a5,1
    80004b78:	20e4ae23          	sw	a4,540(s1)
    80004b7c:	1ff7f793          	andi	a5,a5,511
    80004b80:	97a6                	add	a5,a5,s1
    80004b82:	faf44703          	lbu	a4,-81(s0)
    80004b86:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b8a:	2905                	addiw	s2,s2,1
    80004b8c:	b755                	j	80004b30 <pipewrite+0x80>
  int i = 0;
    80004b8e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b90:	21848513          	addi	a0,s1,536
    80004b94:	ffffd097          	auipc	ra,0xffffd
    80004b98:	57a080e7          	jalr	1402(ra) # 8000210e <wakeup>
  release(&pi->lock);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	136080e7          	jalr	310(ra) # 80000cd4 <release>
  return i;
    80004ba6:	bfa9                	j	80004b00 <pipewrite+0x50>

0000000080004ba8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ba8:	715d                	addi	sp,sp,-80
    80004baa:	e486                	sd	ra,72(sp)
    80004bac:	e0a2                	sd	s0,64(sp)
    80004bae:	fc26                	sd	s1,56(sp)
    80004bb0:	f84a                	sd	s2,48(sp)
    80004bb2:	f44e                	sd	s3,40(sp)
    80004bb4:	f052                	sd	s4,32(sp)
    80004bb6:	ec56                	sd	s5,24(sp)
    80004bb8:	e85a                	sd	s6,16(sp)
    80004bba:	0880                	addi	s0,sp,80
    80004bbc:	84aa                	mv	s1,a0
    80004bbe:	892e                	mv	s2,a1
    80004bc0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	e34080e7          	jalr	-460(ra) # 800019f6 <myproc>
    80004bca:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	052080e7          	jalr	82(ra) # 80000c20 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd6:	2184a703          	lw	a4,536(s1)
    80004bda:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bde:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be2:	02f71763          	bne	a4,a5,80004c10 <piperead+0x68>
    80004be6:	2244a783          	lw	a5,548(s1)
    80004bea:	c39d                	beqz	a5,80004c10 <piperead+0x68>
    if(killed(pr)){
    80004bec:	8552                	mv	a0,s4
    80004bee:	ffffd097          	auipc	ra,0xffffd
    80004bf2:	764080e7          	jalr	1892(ra) # 80002352 <killed>
    80004bf6:	e941                	bnez	a0,80004c86 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf8:	85a6                	mv	a1,s1
    80004bfa:	854e                	mv	a0,s3
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	4ae080e7          	jalr	1198(ra) # 800020aa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c04:	2184a703          	lw	a4,536(s1)
    80004c08:	21c4a783          	lw	a5,540(s1)
    80004c0c:	fcf70de3          	beq	a4,a5,80004be6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c10:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c12:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c14:	05505363          	blez	s5,80004c5a <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004c18:	2184a783          	lw	a5,536(s1)
    80004c1c:	21c4a703          	lw	a4,540(s1)
    80004c20:	02f70d63          	beq	a4,a5,80004c5a <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c24:	0017871b          	addiw	a4,a5,1
    80004c28:	20e4ac23          	sw	a4,536(s1)
    80004c2c:	1ff7f793          	andi	a5,a5,511
    80004c30:	97a6                	add	a5,a5,s1
    80004c32:	0187c783          	lbu	a5,24(a5)
    80004c36:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c3a:	4685                	li	a3,1
    80004c3c:	fbf40613          	addi	a2,s0,-65
    80004c40:	85ca                	mv	a1,s2
    80004c42:	050a3503          	ld	a0,80(s4)
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	a6c080e7          	jalr	-1428(ra) # 800016b2 <copyout>
    80004c4e:	01650663          	beq	a0,s6,80004c5a <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c52:	2985                	addiw	s3,s3,1
    80004c54:	0905                	addi	s2,s2,1
    80004c56:	fd3a91e3          	bne	s5,s3,80004c18 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c5a:	21c48513          	addi	a0,s1,540
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	4b0080e7          	jalr	1200(ra) # 8000210e <wakeup>
  release(&pi->lock);
    80004c66:	8526                	mv	a0,s1
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	06c080e7          	jalr	108(ra) # 80000cd4 <release>
  return i;
}
    80004c70:	854e                	mv	a0,s3
    80004c72:	60a6                	ld	ra,72(sp)
    80004c74:	6406                	ld	s0,64(sp)
    80004c76:	74e2                	ld	s1,56(sp)
    80004c78:	7942                	ld	s2,48(sp)
    80004c7a:	79a2                	ld	s3,40(sp)
    80004c7c:	7a02                	ld	s4,32(sp)
    80004c7e:	6ae2                	ld	s5,24(sp)
    80004c80:	6b42                	ld	s6,16(sp)
    80004c82:	6161                	addi	sp,sp,80
    80004c84:	8082                	ret
      release(&pi->lock);
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	04c080e7          	jalr	76(ra) # 80000cd4 <release>
      return -1;
    80004c90:	59fd                	li	s3,-1
    80004c92:	bff9                	j	80004c70 <piperead+0xc8>

0000000080004c94 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c94:	1141                	addi	sp,sp,-16
    80004c96:	e422                	sd	s0,8(sp)
    80004c98:	0800                	addi	s0,sp,16
    80004c9a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c9c:	8905                	andi	a0,a0,1
    80004c9e:	c111                	beqz	a0,80004ca2 <flags2perm+0xe>
      perm = PTE_X;
    80004ca0:	4521                	li	a0,8
    if(flags & 0x2)
    80004ca2:	8b89                	andi	a5,a5,2
    80004ca4:	c399                	beqz	a5,80004caa <flags2perm+0x16>
      perm |= PTE_W;
    80004ca6:	00456513          	ori	a0,a0,4
    return perm;
}
    80004caa:	6422                	ld	s0,8(sp)
    80004cac:	0141                	addi	sp,sp,16
    80004cae:	8082                	ret

0000000080004cb0 <exec>:

int
exec(char *path, char **argv)
{
    80004cb0:	de010113          	addi	sp,sp,-544
    80004cb4:	20113c23          	sd	ra,536(sp)
    80004cb8:	20813823          	sd	s0,528(sp)
    80004cbc:	20913423          	sd	s1,520(sp)
    80004cc0:	21213023          	sd	s2,512(sp)
    80004cc4:	ffce                	sd	s3,504(sp)
    80004cc6:	fbd2                	sd	s4,496(sp)
    80004cc8:	f7d6                	sd	s5,488(sp)
    80004cca:	f3da                	sd	s6,480(sp)
    80004ccc:	efde                	sd	s7,472(sp)
    80004cce:	ebe2                	sd	s8,464(sp)
    80004cd0:	e7e6                	sd	s9,456(sp)
    80004cd2:	e3ea                	sd	s10,448(sp)
    80004cd4:	ff6e                	sd	s11,440(sp)
    80004cd6:	1400                	addi	s0,sp,544
    80004cd8:	892a                	mv	s2,a0
    80004cda:	dea43423          	sd	a0,-536(s0)
    80004cde:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	d14080e7          	jalr	-748(ra) # 800019f6 <myproc>
    80004cea:	84aa                	mv	s1,a0

  begin_op();
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	47e080e7          	jalr	1150(ra) # 8000416a <begin_op>

  if((ip = namei(path)) == 0){
    80004cf4:	854a                	mv	a0,s2
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	258080e7          	jalr	600(ra) # 80003f4e <namei>
    80004cfe:	c93d                	beqz	a0,80004d74 <exec+0xc4>
    80004d00:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	aa6080e7          	jalr	-1370(ra) # 800037a8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d0a:	04000713          	li	a4,64
    80004d0e:	4681                	li	a3,0
    80004d10:	e5040613          	addi	a2,s0,-432
    80004d14:	4581                	li	a1,0
    80004d16:	8556                	mv	a0,s5
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	d44080e7          	jalr	-700(ra) # 80003a5c <readi>
    80004d20:	04000793          	li	a5,64
    80004d24:	00f51a63          	bne	a0,a5,80004d38 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d28:	e5042703          	lw	a4,-432(s0)
    80004d2c:	464c47b7          	lui	a5,0x464c4
    80004d30:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d34:	04f70663          	beq	a4,a5,80004d80 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d38:	8556                	mv	a0,s5
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	cd0080e7          	jalr	-816(ra) # 80003a0a <iunlockput>
    end_op();
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	4a8080e7          	jalr	1192(ra) # 800041ea <end_op>
  }
  return -1;
    80004d4a:	557d                	li	a0,-1
}
    80004d4c:	21813083          	ld	ra,536(sp)
    80004d50:	21013403          	ld	s0,528(sp)
    80004d54:	20813483          	ld	s1,520(sp)
    80004d58:	20013903          	ld	s2,512(sp)
    80004d5c:	79fe                	ld	s3,504(sp)
    80004d5e:	7a5e                	ld	s4,496(sp)
    80004d60:	7abe                	ld	s5,488(sp)
    80004d62:	7b1e                	ld	s6,480(sp)
    80004d64:	6bfe                	ld	s7,472(sp)
    80004d66:	6c5e                	ld	s8,464(sp)
    80004d68:	6cbe                	ld	s9,456(sp)
    80004d6a:	6d1e                	ld	s10,448(sp)
    80004d6c:	7dfa                	ld	s11,440(sp)
    80004d6e:	22010113          	addi	sp,sp,544
    80004d72:	8082                	ret
    end_op();
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	476080e7          	jalr	1142(ra) # 800041ea <end_op>
    return -1;
    80004d7c:	557d                	li	a0,-1
    80004d7e:	b7f9                	j	80004d4c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d80:	8526                	mv	a0,s1
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	d38080e7          	jalr	-712(ra) # 80001aba <proc_pagetable>
    80004d8a:	8b2a                	mv	s6,a0
    80004d8c:	d555                	beqz	a0,80004d38 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d8e:	e7042783          	lw	a5,-400(s0)
    80004d92:	e8845703          	lhu	a4,-376(s0)
    80004d96:	c735                	beqz	a4,80004e02 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d98:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9a:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d9e:	6a05                	lui	s4,0x1
    80004da0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004da4:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004da8:	6d85                	lui	s11,0x1
    80004daa:	7d7d                	lui	s10,0xfffff
    80004dac:	a481                	j	80004fec <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dae:	00004517          	auipc	a0,0x4
    80004db2:	a9a50513          	addi	a0,a0,-1382 # 80008848 <syscall_names+0x278>
    80004db6:	ffffb097          	auipc	ra,0xffffb
    80004dba:	788080e7          	jalr	1928(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dbe:	874a                	mv	a4,s2
    80004dc0:	009c86bb          	addw	a3,s9,s1
    80004dc4:	4581                	li	a1,0
    80004dc6:	8556                	mv	a0,s5
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	c94080e7          	jalr	-876(ra) # 80003a5c <readi>
    80004dd0:	2501                	sext.w	a0,a0
    80004dd2:	1aa91a63          	bne	s2,a0,80004f86 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dd6:	009d84bb          	addw	s1,s11,s1
    80004dda:	013d09bb          	addw	s3,s10,s3
    80004dde:	1f74f763          	bgeu	s1,s7,80004fcc <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004de2:	02049593          	slli	a1,s1,0x20
    80004de6:	9181                	srli	a1,a1,0x20
    80004de8:	95e2                	add	a1,a1,s8
    80004dea:	855a                	mv	a0,s6
    80004dec:	ffffc097          	auipc	ra,0xffffc
    80004df0:	2ba080e7          	jalr	698(ra) # 800010a6 <walkaddr>
    80004df4:	862a                	mv	a2,a0
    if(pa == 0)
    80004df6:	dd45                	beqz	a0,80004dae <exec+0xfe>
      n = PGSIZE;
    80004df8:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dfa:	fd49f2e3          	bgeu	s3,s4,80004dbe <exec+0x10e>
      n = sz - i;
    80004dfe:	894e                	mv	s2,s3
    80004e00:	bf7d                	j	80004dbe <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e02:	4901                	li	s2,0
  iunlockput(ip);
    80004e04:	8556                	mv	a0,s5
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	c04080e7          	jalr	-1020(ra) # 80003a0a <iunlockput>
  end_op();
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	3dc080e7          	jalr	988(ra) # 800041ea <end_op>
  p = myproc();
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	be0080e7          	jalr	-1056(ra) # 800019f6 <myproc>
    80004e1e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e20:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e24:	6785                	lui	a5,0x1
    80004e26:	17fd                	addi	a5,a5,-1
    80004e28:	993e                	add	s2,s2,a5
    80004e2a:	77fd                	lui	a5,0xfffff
    80004e2c:	00f977b3          	and	a5,s2,a5
    80004e30:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e34:	4691                	li	a3,4
    80004e36:	6609                	lui	a2,0x2
    80004e38:	963e                	add	a2,a2,a5
    80004e3a:	85be                	mv	a1,a5
    80004e3c:	855a                	mv	a0,s6
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	61c080e7          	jalr	1564(ra) # 8000145a <uvmalloc>
    80004e46:	8c2a                	mv	s8,a0
  ip = 0;
    80004e48:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e4a:	12050e63          	beqz	a0,80004f86 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e4e:	75f9                	lui	a1,0xffffe
    80004e50:	95aa                	add	a1,a1,a0
    80004e52:	855a                	mv	a0,s6
    80004e54:	ffffd097          	auipc	ra,0xffffd
    80004e58:	82c080e7          	jalr	-2004(ra) # 80001680 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e5c:	7afd                	lui	s5,0xfffff
    80004e5e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e60:	df043783          	ld	a5,-528(s0)
    80004e64:	6388                	ld	a0,0(a5)
    80004e66:	c925                	beqz	a0,80004ed6 <exec+0x226>
    80004e68:	e9040993          	addi	s3,s0,-368
    80004e6c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e70:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e72:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	024080e7          	jalr	36(ra) # 80000e98 <strlen>
    80004e7c:	0015079b          	addiw	a5,a0,1
    80004e80:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e84:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e88:	13596663          	bltu	s2,s5,80004fb4 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e8c:	df043d83          	ld	s11,-528(s0)
    80004e90:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e94:	8552                	mv	a0,s4
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	002080e7          	jalr	2(ra) # 80000e98 <strlen>
    80004e9e:	0015069b          	addiw	a3,a0,1
    80004ea2:	8652                	mv	a2,s4
    80004ea4:	85ca                	mv	a1,s2
    80004ea6:	855a                	mv	a0,s6
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	80a080e7          	jalr	-2038(ra) # 800016b2 <copyout>
    80004eb0:	10054663          	bltz	a0,80004fbc <exec+0x30c>
    ustack[argc] = sp;
    80004eb4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eb8:	0485                	addi	s1,s1,1
    80004eba:	008d8793          	addi	a5,s11,8
    80004ebe:	def43823          	sd	a5,-528(s0)
    80004ec2:	008db503          	ld	a0,8(s11)
    80004ec6:	c911                	beqz	a0,80004eda <exec+0x22a>
    if(argc >= MAXARG)
    80004ec8:	09a1                	addi	s3,s3,8
    80004eca:	fb3c95e3          	bne	s9,s3,80004e74 <exec+0x1c4>
  sz = sz1;
    80004ece:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ed2:	4a81                	li	s5,0
    80004ed4:	a84d                	j	80004f86 <exec+0x2d6>
  sp = sz;
    80004ed6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ed8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eda:	00349793          	slli	a5,s1,0x3
    80004ede:	f9040713          	addi	a4,s0,-112
    80004ee2:	97ba                	add	a5,a5,a4
    80004ee4:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdce40>
  sp -= (argc+1) * sizeof(uint64);
    80004ee8:	00148693          	addi	a3,s1,1
    80004eec:	068e                	slli	a3,a3,0x3
    80004eee:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ef2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ef6:	01597663          	bgeu	s2,s5,80004f02 <exec+0x252>
  sz = sz1;
    80004efa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004efe:	4a81                	li	s5,0
    80004f00:	a059                	j	80004f86 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f02:	e9040613          	addi	a2,s0,-368
    80004f06:	85ca                	mv	a1,s2
    80004f08:	855a                	mv	a0,s6
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	7a8080e7          	jalr	1960(ra) # 800016b2 <copyout>
    80004f12:	0a054963          	bltz	a0,80004fc4 <exec+0x314>
  p->trapframe->a1 = sp;
    80004f16:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f1a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f1e:	de843783          	ld	a5,-536(s0)
    80004f22:	0007c703          	lbu	a4,0(a5)
    80004f26:	cf11                	beqz	a4,80004f42 <exec+0x292>
    80004f28:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f2a:	02f00693          	li	a3,47
    80004f2e:	a039                	j	80004f3c <exec+0x28c>
      last = s+1;
    80004f30:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f34:	0785                	addi	a5,a5,1
    80004f36:	fff7c703          	lbu	a4,-1(a5)
    80004f3a:	c701                	beqz	a4,80004f42 <exec+0x292>
    if(*s == '/')
    80004f3c:	fed71ce3          	bne	a4,a3,80004f34 <exec+0x284>
    80004f40:	bfc5                	j	80004f30 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f42:	4641                	li	a2,16
    80004f44:	de843583          	ld	a1,-536(s0)
    80004f48:	158b8513          	addi	a0,s7,344
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	f1a080e7          	jalr	-230(ra) # 80000e66 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f54:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f58:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f5c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f60:	058bb783          	ld	a5,88(s7)
    80004f64:	e6843703          	ld	a4,-408(s0)
    80004f68:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f6a:	058bb783          	ld	a5,88(s7)
    80004f6e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f72:	85ea                	mv	a1,s10
    80004f74:	ffffd097          	auipc	ra,0xffffd
    80004f78:	be2080e7          	jalr	-1054(ra) # 80001b56 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f7c:	0004851b          	sext.w	a0,s1
    80004f80:	b3f1                	j	80004d4c <exec+0x9c>
    80004f82:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f86:	df843583          	ld	a1,-520(s0)
    80004f8a:	855a                	mv	a0,s6
    80004f8c:	ffffd097          	auipc	ra,0xffffd
    80004f90:	bca080e7          	jalr	-1078(ra) # 80001b56 <proc_freepagetable>
  if(ip){
    80004f94:	da0a92e3          	bnez	s5,80004d38 <exec+0x88>
  return -1;
    80004f98:	557d                	li	a0,-1
    80004f9a:	bb4d                	j	80004d4c <exec+0x9c>
    80004f9c:	df243c23          	sd	s2,-520(s0)
    80004fa0:	b7dd                	j	80004f86 <exec+0x2d6>
    80004fa2:	df243c23          	sd	s2,-520(s0)
    80004fa6:	b7c5                	j	80004f86 <exec+0x2d6>
    80004fa8:	df243c23          	sd	s2,-520(s0)
    80004fac:	bfe9                	j	80004f86 <exec+0x2d6>
    80004fae:	df243c23          	sd	s2,-520(s0)
    80004fb2:	bfd1                	j	80004f86 <exec+0x2d6>
  sz = sz1;
    80004fb4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fb8:	4a81                	li	s5,0
    80004fba:	b7f1                	j	80004f86 <exec+0x2d6>
  sz = sz1;
    80004fbc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fc0:	4a81                	li	s5,0
    80004fc2:	b7d1                	j	80004f86 <exec+0x2d6>
  sz = sz1;
    80004fc4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fc8:	4a81                	li	s5,0
    80004fca:	bf75                	j	80004f86 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fcc:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd0:	e0843783          	ld	a5,-504(s0)
    80004fd4:	0017869b          	addiw	a3,a5,1
    80004fd8:	e0d43423          	sd	a3,-504(s0)
    80004fdc:	e0043783          	ld	a5,-512(s0)
    80004fe0:	0387879b          	addiw	a5,a5,56
    80004fe4:	e8845703          	lhu	a4,-376(s0)
    80004fe8:	e0e6dee3          	bge	a3,a4,80004e04 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fec:	2781                	sext.w	a5,a5
    80004fee:	e0f43023          	sd	a5,-512(s0)
    80004ff2:	03800713          	li	a4,56
    80004ff6:	86be                	mv	a3,a5
    80004ff8:	e1840613          	addi	a2,s0,-488
    80004ffc:	4581                	li	a1,0
    80004ffe:	8556                	mv	a0,s5
    80005000:	fffff097          	auipc	ra,0xfffff
    80005004:	a5c080e7          	jalr	-1444(ra) # 80003a5c <readi>
    80005008:	03800793          	li	a5,56
    8000500c:	f6f51be3          	bne	a0,a5,80004f82 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005010:	e1842783          	lw	a5,-488(s0)
    80005014:	4705                	li	a4,1
    80005016:	fae79de3          	bne	a5,a4,80004fd0 <exec+0x320>
    if(ph.memsz < ph.filesz)
    8000501a:	e4043483          	ld	s1,-448(s0)
    8000501e:	e3843783          	ld	a5,-456(s0)
    80005022:	f6f4ede3          	bltu	s1,a5,80004f9c <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005026:	e2843783          	ld	a5,-472(s0)
    8000502a:	94be                	add	s1,s1,a5
    8000502c:	f6f4ebe3          	bltu	s1,a5,80004fa2 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005030:	de043703          	ld	a4,-544(s0)
    80005034:	8ff9                	and	a5,a5,a4
    80005036:	fbad                	bnez	a5,80004fa8 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005038:	e1c42503          	lw	a0,-484(s0)
    8000503c:	00000097          	auipc	ra,0x0
    80005040:	c58080e7          	jalr	-936(ra) # 80004c94 <flags2perm>
    80005044:	86aa                	mv	a3,a0
    80005046:	8626                	mv	a2,s1
    80005048:	85ca                	mv	a1,s2
    8000504a:	855a                	mv	a0,s6
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	40e080e7          	jalr	1038(ra) # 8000145a <uvmalloc>
    80005054:	dea43c23          	sd	a0,-520(s0)
    80005058:	d939                	beqz	a0,80004fae <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000505a:	e2843c03          	ld	s8,-472(s0)
    8000505e:	e2042c83          	lw	s9,-480(s0)
    80005062:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005066:	f60b83e3          	beqz	s7,80004fcc <exec+0x31c>
    8000506a:	89de                	mv	s3,s7
    8000506c:	4481                	li	s1,0
    8000506e:	bb95                	j	80004de2 <exec+0x132>

0000000080005070 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005070:	7179                	addi	sp,sp,-48
    80005072:	f406                	sd	ra,40(sp)
    80005074:	f022                	sd	s0,32(sp)
    80005076:	ec26                	sd	s1,24(sp)
    80005078:	e84a                	sd	s2,16(sp)
    8000507a:	1800                	addi	s0,sp,48
    8000507c:	892e                	mv	s2,a1
    8000507e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005080:	fdc40593          	addi	a1,s0,-36
    80005084:	ffffe097          	auipc	ra,0xffffe
    80005088:	ae8080e7          	jalr	-1304(ra) # 80002b6c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000508c:	fdc42703          	lw	a4,-36(s0)
    80005090:	47bd                	li	a5,15
    80005092:	02e7eb63          	bltu	a5,a4,800050c8 <argfd+0x58>
    80005096:	ffffd097          	auipc	ra,0xffffd
    8000509a:	960080e7          	jalr	-1696(ra) # 800019f6 <myproc>
    8000509e:	fdc42703          	lw	a4,-36(s0)
    800050a2:	01a70793          	addi	a5,a4,26
    800050a6:	078e                	slli	a5,a5,0x3
    800050a8:	953e                	add	a0,a0,a5
    800050aa:	611c                	ld	a5,0(a0)
    800050ac:	c385                	beqz	a5,800050cc <argfd+0x5c>
    return -1;
  if(pfd)
    800050ae:	00090463          	beqz	s2,800050b6 <argfd+0x46>
    *pfd = fd;
    800050b2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050b6:	4501                	li	a0,0
  if(pf)
    800050b8:	c091                	beqz	s1,800050bc <argfd+0x4c>
    *pf = f;
    800050ba:	e09c                	sd	a5,0(s1)
}
    800050bc:	70a2                	ld	ra,40(sp)
    800050be:	7402                	ld	s0,32(sp)
    800050c0:	64e2                	ld	s1,24(sp)
    800050c2:	6942                	ld	s2,16(sp)
    800050c4:	6145                	addi	sp,sp,48
    800050c6:	8082                	ret
    return -1;
    800050c8:	557d                	li	a0,-1
    800050ca:	bfcd                	j	800050bc <argfd+0x4c>
    800050cc:	557d                	li	a0,-1
    800050ce:	b7fd                	j	800050bc <argfd+0x4c>

00000000800050d0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050d0:	1101                	addi	sp,sp,-32
    800050d2:	ec06                	sd	ra,24(sp)
    800050d4:	e822                	sd	s0,16(sp)
    800050d6:	e426                	sd	s1,8(sp)
    800050d8:	1000                	addi	s0,sp,32
    800050da:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	91a080e7          	jalr	-1766(ra) # 800019f6 <myproc>
    800050e4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050e6:	0d050793          	addi	a5,a0,208
    800050ea:	4501                	li	a0,0
    800050ec:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ee:	6398                	ld	a4,0(a5)
    800050f0:	cb19                	beqz	a4,80005106 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050f2:	2505                	addiw	a0,a0,1
    800050f4:	07a1                	addi	a5,a5,8
    800050f6:	fed51ce3          	bne	a0,a3,800050ee <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050fa:	557d                	li	a0,-1
}
    800050fc:	60e2                	ld	ra,24(sp)
    800050fe:	6442                	ld	s0,16(sp)
    80005100:	64a2                	ld	s1,8(sp)
    80005102:	6105                	addi	sp,sp,32
    80005104:	8082                	ret
      p->ofile[fd] = f;
    80005106:	01a50793          	addi	a5,a0,26
    8000510a:	078e                	slli	a5,a5,0x3
    8000510c:	963e                	add	a2,a2,a5
    8000510e:	e204                	sd	s1,0(a2)
      return fd;
    80005110:	b7f5                	j	800050fc <fdalloc+0x2c>

0000000080005112 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005112:	715d                	addi	sp,sp,-80
    80005114:	e486                	sd	ra,72(sp)
    80005116:	e0a2                	sd	s0,64(sp)
    80005118:	fc26                	sd	s1,56(sp)
    8000511a:	f84a                	sd	s2,48(sp)
    8000511c:	f44e                	sd	s3,40(sp)
    8000511e:	f052                	sd	s4,32(sp)
    80005120:	ec56                	sd	s5,24(sp)
    80005122:	e85a                	sd	s6,16(sp)
    80005124:	0880                	addi	s0,sp,80
    80005126:	8b2e                	mv	s6,a1
    80005128:	89b2                	mv	s3,a2
    8000512a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000512c:	fb040593          	addi	a1,s0,-80
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	e3c080e7          	jalr	-452(ra) # 80003f6c <nameiparent>
    80005138:	84aa                	mv	s1,a0
    8000513a:	14050f63          	beqz	a0,80005298 <create+0x186>
    return 0;

  ilock(dp);
    8000513e:	ffffe097          	auipc	ra,0xffffe
    80005142:	66a080e7          	jalr	1642(ra) # 800037a8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005146:	4601                	li	a2,0
    80005148:	fb040593          	addi	a1,s0,-80
    8000514c:	8526                	mv	a0,s1
    8000514e:	fffff097          	auipc	ra,0xfffff
    80005152:	b3e080e7          	jalr	-1218(ra) # 80003c8c <dirlookup>
    80005156:	8aaa                	mv	s5,a0
    80005158:	c931                	beqz	a0,800051ac <create+0x9a>
    iunlockput(dp);
    8000515a:	8526                	mv	a0,s1
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	8ae080e7          	jalr	-1874(ra) # 80003a0a <iunlockput>
    ilock(ip);
    80005164:	8556                	mv	a0,s5
    80005166:	ffffe097          	auipc	ra,0xffffe
    8000516a:	642080e7          	jalr	1602(ra) # 800037a8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000516e:	000b059b          	sext.w	a1,s6
    80005172:	4789                	li	a5,2
    80005174:	02f59563          	bne	a1,a5,8000519e <create+0x8c>
    80005178:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdcf84>
    8000517c:	37f9                	addiw	a5,a5,-2
    8000517e:	17c2                	slli	a5,a5,0x30
    80005180:	93c1                	srli	a5,a5,0x30
    80005182:	4705                	li	a4,1
    80005184:	00f76d63          	bltu	a4,a5,8000519e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005188:	8556                	mv	a0,s5
    8000518a:	60a6                	ld	ra,72(sp)
    8000518c:	6406                	ld	s0,64(sp)
    8000518e:	74e2                	ld	s1,56(sp)
    80005190:	7942                	ld	s2,48(sp)
    80005192:	79a2                	ld	s3,40(sp)
    80005194:	7a02                	ld	s4,32(sp)
    80005196:	6ae2                	ld	s5,24(sp)
    80005198:	6b42                	ld	s6,16(sp)
    8000519a:	6161                	addi	sp,sp,80
    8000519c:	8082                	ret
    iunlockput(ip);
    8000519e:	8556                	mv	a0,s5
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	86a080e7          	jalr	-1942(ra) # 80003a0a <iunlockput>
    return 0;
    800051a8:	4a81                	li	s5,0
    800051aa:	bff9                	j	80005188 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051ac:	85da                	mv	a1,s6
    800051ae:	4088                	lw	a0,0(s1)
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	45c080e7          	jalr	1116(ra) # 8000360c <ialloc>
    800051b8:	8a2a                	mv	s4,a0
    800051ba:	c539                	beqz	a0,80005208 <create+0xf6>
  ilock(ip);
    800051bc:	ffffe097          	auipc	ra,0xffffe
    800051c0:	5ec080e7          	jalr	1516(ra) # 800037a8 <ilock>
  ip->major = major;
    800051c4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051c8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051cc:	4905                	li	s2,1
    800051ce:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051d2:	8552                	mv	a0,s4
    800051d4:	ffffe097          	auipc	ra,0xffffe
    800051d8:	50a080e7          	jalr	1290(ra) # 800036de <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051dc:	000b059b          	sext.w	a1,s6
    800051e0:	03258b63          	beq	a1,s2,80005216 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051e4:	004a2603          	lw	a2,4(s4)
    800051e8:	fb040593          	addi	a1,s0,-80
    800051ec:	8526                	mv	a0,s1
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	cae080e7          	jalr	-850(ra) # 80003e9c <dirlink>
    800051f6:	06054f63          	bltz	a0,80005274 <create+0x162>
  iunlockput(dp);
    800051fa:	8526                	mv	a0,s1
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	80e080e7          	jalr	-2034(ra) # 80003a0a <iunlockput>
  return ip;
    80005204:	8ad2                	mv	s5,s4
    80005206:	b749                	j	80005188 <create+0x76>
    iunlockput(dp);
    80005208:	8526                	mv	a0,s1
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	800080e7          	jalr	-2048(ra) # 80003a0a <iunlockput>
    return 0;
    80005212:	8ad2                	mv	s5,s4
    80005214:	bf95                	j	80005188 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005216:	004a2603          	lw	a2,4(s4)
    8000521a:	00003597          	auipc	a1,0x3
    8000521e:	64e58593          	addi	a1,a1,1614 # 80008868 <syscall_names+0x298>
    80005222:	8552                	mv	a0,s4
    80005224:	fffff097          	auipc	ra,0xfffff
    80005228:	c78080e7          	jalr	-904(ra) # 80003e9c <dirlink>
    8000522c:	04054463          	bltz	a0,80005274 <create+0x162>
    80005230:	40d0                	lw	a2,4(s1)
    80005232:	00003597          	auipc	a1,0x3
    80005236:	63e58593          	addi	a1,a1,1598 # 80008870 <syscall_names+0x2a0>
    8000523a:	8552                	mv	a0,s4
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	c60080e7          	jalr	-928(ra) # 80003e9c <dirlink>
    80005244:	02054863          	bltz	a0,80005274 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005248:	004a2603          	lw	a2,4(s4)
    8000524c:	fb040593          	addi	a1,s0,-80
    80005250:	8526                	mv	a0,s1
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	c4a080e7          	jalr	-950(ra) # 80003e9c <dirlink>
    8000525a:	00054d63          	bltz	a0,80005274 <create+0x162>
    dp->nlink++;  // for ".."
    8000525e:	04a4d783          	lhu	a5,74(s1)
    80005262:	2785                	addiw	a5,a5,1
    80005264:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005268:	8526                	mv	a0,s1
    8000526a:	ffffe097          	auipc	ra,0xffffe
    8000526e:	474080e7          	jalr	1140(ra) # 800036de <iupdate>
    80005272:	b761                	j	800051fa <create+0xe8>
  ip->nlink = 0;
    80005274:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005278:	8552                	mv	a0,s4
    8000527a:	ffffe097          	auipc	ra,0xffffe
    8000527e:	464080e7          	jalr	1124(ra) # 800036de <iupdate>
  iunlockput(ip);
    80005282:	8552                	mv	a0,s4
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	786080e7          	jalr	1926(ra) # 80003a0a <iunlockput>
  iunlockput(dp);
    8000528c:	8526                	mv	a0,s1
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	77c080e7          	jalr	1916(ra) # 80003a0a <iunlockput>
  return 0;
    80005296:	bdcd                	j	80005188 <create+0x76>
    return 0;
    80005298:	8aaa                	mv	s5,a0
    8000529a:	b5fd                	j	80005188 <create+0x76>

000000008000529c <sys_dup>:
{
    8000529c:	7179                	addi	sp,sp,-48
    8000529e:	f406                	sd	ra,40(sp)
    800052a0:	f022                	sd	s0,32(sp)
    800052a2:	ec26                	sd	s1,24(sp)
    800052a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052a6:	fd840613          	addi	a2,s0,-40
    800052aa:	4581                	li	a1,0
    800052ac:	4501                	li	a0,0
    800052ae:	00000097          	auipc	ra,0x0
    800052b2:	dc2080e7          	jalr	-574(ra) # 80005070 <argfd>
    return -1;
    800052b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052b8:	02054363          	bltz	a0,800052de <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052bc:	fd843503          	ld	a0,-40(s0)
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	e10080e7          	jalr	-496(ra) # 800050d0 <fdalloc>
    800052c8:	84aa                	mv	s1,a0
    return -1;
    800052ca:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052cc:	00054963          	bltz	a0,800052de <sys_dup+0x42>
  filedup(f);
    800052d0:	fd843503          	ld	a0,-40(s0)
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	310080e7          	jalr	784(ra) # 800045e4 <filedup>
  return fd;
    800052dc:	87a6                	mv	a5,s1
}
    800052de:	853e                	mv	a0,a5
    800052e0:	70a2                	ld	ra,40(sp)
    800052e2:	7402                	ld	s0,32(sp)
    800052e4:	64e2                	ld	s1,24(sp)
    800052e6:	6145                	addi	sp,sp,48
    800052e8:	8082                	ret

00000000800052ea <sys_read>:
{
    800052ea:	7179                	addi	sp,sp,-48
    800052ec:	f406                	sd	ra,40(sp)
    800052ee:	f022                	sd	s0,32(sp)
    800052f0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052f2:	fd840593          	addi	a1,s0,-40
    800052f6:	4505                	li	a0,1
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	894080e7          	jalr	-1900(ra) # 80002b8c <argaddr>
  argint(2, &n);
    80005300:	fe440593          	addi	a1,s0,-28
    80005304:	4509                	li	a0,2
    80005306:	ffffe097          	auipc	ra,0xffffe
    8000530a:	866080e7          	jalr	-1946(ra) # 80002b6c <argint>
  if(argfd(0, 0, &f) < 0)
    8000530e:	fe840613          	addi	a2,s0,-24
    80005312:	4581                	li	a1,0
    80005314:	4501                	li	a0,0
    80005316:	00000097          	auipc	ra,0x0
    8000531a:	d5a080e7          	jalr	-678(ra) # 80005070 <argfd>
    8000531e:	87aa                	mv	a5,a0
    return -1;
    80005320:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005322:	0007cc63          	bltz	a5,8000533a <sys_read+0x50>
  return fileread(f, p, n);
    80005326:	fe442603          	lw	a2,-28(s0)
    8000532a:	fd843583          	ld	a1,-40(s0)
    8000532e:	fe843503          	ld	a0,-24(s0)
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	43e080e7          	jalr	1086(ra) # 80004770 <fileread>
}
    8000533a:	70a2                	ld	ra,40(sp)
    8000533c:	7402                	ld	s0,32(sp)
    8000533e:	6145                	addi	sp,sp,48
    80005340:	8082                	ret

0000000080005342 <sys_write>:
{
    80005342:	7179                	addi	sp,sp,-48
    80005344:	f406                	sd	ra,40(sp)
    80005346:	f022                	sd	s0,32(sp)
    80005348:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000534a:	fd840593          	addi	a1,s0,-40
    8000534e:	4505                	li	a0,1
    80005350:	ffffe097          	auipc	ra,0xffffe
    80005354:	83c080e7          	jalr	-1988(ra) # 80002b8c <argaddr>
  argint(2, &n);
    80005358:	fe440593          	addi	a1,s0,-28
    8000535c:	4509                	li	a0,2
    8000535e:	ffffe097          	auipc	ra,0xffffe
    80005362:	80e080e7          	jalr	-2034(ra) # 80002b6c <argint>
  if(argfd(0, 0, &f) < 0)
    80005366:	fe840613          	addi	a2,s0,-24
    8000536a:	4581                	li	a1,0
    8000536c:	4501                	li	a0,0
    8000536e:	00000097          	auipc	ra,0x0
    80005372:	d02080e7          	jalr	-766(ra) # 80005070 <argfd>
    80005376:	87aa                	mv	a5,a0
    return -1;
    80005378:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000537a:	0007cc63          	bltz	a5,80005392 <sys_write+0x50>
  return filewrite(f, p, n);
    8000537e:	fe442603          	lw	a2,-28(s0)
    80005382:	fd843583          	ld	a1,-40(s0)
    80005386:	fe843503          	ld	a0,-24(s0)
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	4a8080e7          	jalr	1192(ra) # 80004832 <filewrite>
}
    80005392:	70a2                	ld	ra,40(sp)
    80005394:	7402                	ld	s0,32(sp)
    80005396:	6145                	addi	sp,sp,48
    80005398:	8082                	ret

000000008000539a <sys_close>:
{
    8000539a:	1101                	addi	sp,sp,-32
    8000539c:	ec06                	sd	ra,24(sp)
    8000539e:	e822                	sd	s0,16(sp)
    800053a0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053a2:	fe040613          	addi	a2,s0,-32
    800053a6:	fec40593          	addi	a1,s0,-20
    800053aa:	4501                	li	a0,0
    800053ac:	00000097          	auipc	ra,0x0
    800053b0:	cc4080e7          	jalr	-828(ra) # 80005070 <argfd>
    return -1;
    800053b4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053b6:	02054463          	bltz	a0,800053de <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053ba:	ffffc097          	auipc	ra,0xffffc
    800053be:	63c080e7          	jalr	1596(ra) # 800019f6 <myproc>
    800053c2:	fec42783          	lw	a5,-20(s0)
    800053c6:	07e9                	addi	a5,a5,26
    800053c8:	078e                	slli	a5,a5,0x3
    800053ca:	97aa                	add	a5,a5,a0
    800053cc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053d0:	fe043503          	ld	a0,-32(s0)
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	262080e7          	jalr	610(ra) # 80004636 <fileclose>
  return 0;
    800053dc:	4781                	li	a5,0
}
    800053de:	853e                	mv	a0,a5
    800053e0:	60e2                	ld	ra,24(sp)
    800053e2:	6442                	ld	s0,16(sp)
    800053e4:	6105                	addi	sp,sp,32
    800053e6:	8082                	ret

00000000800053e8 <sys_fstat>:
{
    800053e8:	1101                	addi	sp,sp,-32
    800053ea:	ec06                	sd	ra,24(sp)
    800053ec:	e822                	sd	s0,16(sp)
    800053ee:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053f0:	fe040593          	addi	a1,s0,-32
    800053f4:	4505                	li	a0,1
    800053f6:	ffffd097          	auipc	ra,0xffffd
    800053fa:	796080e7          	jalr	1942(ra) # 80002b8c <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053fe:	fe840613          	addi	a2,s0,-24
    80005402:	4581                	li	a1,0
    80005404:	4501                	li	a0,0
    80005406:	00000097          	auipc	ra,0x0
    8000540a:	c6a080e7          	jalr	-918(ra) # 80005070 <argfd>
    8000540e:	87aa                	mv	a5,a0
    return -1;
    80005410:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005412:	0007ca63          	bltz	a5,80005426 <sys_fstat+0x3e>
  return filestat(f, st);
    80005416:	fe043583          	ld	a1,-32(s0)
    8000541a:	fe843503          	ld	a0,-24(s0)
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	2e0080e7          	jalr	736(ra) # 800046fe <filestat>
}
    80005426:	60e2                	ld	ra,24(sp)
    80005428:	6442                	ld	s0,16(sp)
    8000542a:	6105                	addi	sp,sp,32
    8000542c:	8082                	ret

000000008000542e <sys_link>:
{
    8000542e:	7169                	addi	sp,sp,-304
    80005430:	f606                	sd	ra,296(sp)
    80005432:	f222                	sd	s0,288(sp)
    80005434:	ee26                	sd	s1,280(sp)
    80005436:	ea4a                	sd	s2,272(sp)
    80005438:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543a:	08000613          	li	a2,128
    8000543e:	ed040593          	addi	a1,s0,-304
    80005442:	4501                	li	a0,0
    80005444:	ffffd097          	auipc	ra,0xffffd
    80005448:	768080e7          	jalr	1896(ra) # 80002bac <argstr>
    return -1;
    8000544c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000544e:	10054e63          	bltz	a0,8000556a <sys_link+0x13c>
    80005452:	08000613          	li	a2,128
    80005456:	f5040593          	addi	a1,s0,-176
    8000545a:	4505                	li	a0,1
    8000545c:	ffffd097          	auipc	ra,0xffffd
    80005460:	750080e7          	jalr	1872(ra) # 80002bac <argstr>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005466:	10054263          	bltz	a0,8000556a <sys_link+0x13c>
  begin_op();
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	d00080e7          	jalr	-768(ra) # 8000416a <begin_op>
  if((ip = namei(old)) == 0){
    80005472:	ed040513          	addi	a0,s0,-304
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	ad8080e7          	jalr	-1320(ra) # 80003f4e <namei>
    8000547e:	84aa                	mv	s1,a0
    80005480:	c551                	beqz	a0,8000550c <sys_link+0xde>
  ilock(ip);
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	326080e7          	jalr	806(ra) # 800037a8 <ilock>
  if(ip->type == T_DIR){
    8000548a:	04449703          	lh	a4,68(s1)
    8000548e:	4785                	li	a5,1
    80005490:	08f70463          	beq	a4,a5,80005518 <sys_link+0xea>
  ip->nlink++;
    80005494:	04a4d783          	lhu	a5,74(s1)
    80005498:	2785                	addiw	a5,a5,1
    8000549a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000549e:	8526                	mv	a0,s1
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	23e080e7          	jalr	574(ra) # 800036de <iupdate>
  iunlock(ip);
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	3c0080e7          	jalr	960(ra) # 8000386a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054b2:	fd040593          	addi	a1,s0,-48
    800054b6:	f5040513          	addi	a0,s0,-176
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	ab2080e7          	jalr	-1358(ra) # 80003f6c <nameiparent>
    800054c2:	892a                	mv	s2,a0
    800054c4:	c935                	beqz	a0,80005538 <sys_link+0x10a>
  ilock(dp);
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	2e2080e7          	jalr	738(ra) # 800037a8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ce:	00092703          	lw	a4,0(s2)
    800054d2:	409c                	lw	a5,0(s1)
    800054d4:	04f71d63          	bne	a4,a5,8000552e <sys_link+0x100>
    800054d8:	40d0                	lw	a2,4(s1)
    800054da:	fd040593          	addi	a1,s0,-48
    800054de:	854a                	mv	a0,s2
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	9bc080e7          	jalr	-1604(ra) # 80003e9c <dirlink>
    800054e8:	04054363          	bltz	a0,8000552e <sys_link+0x100>
  iunlockput(dp);
    800054ec:	854a                	mv	a0,s2
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	51c080e7          	jalr	1308(ra) # 80003a0a <iunlockput>
  iput(ip);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	46a080e7          	jalr	1130(ra) # 80003962 <iput>
  end_op();
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	cea080e7          	jalr	-790(ra) # 800041ea <end_op>
  return 0;
    80005508:	4781                	li	a5,0
    8000550a:	a085                	j	8000556a <sys_link+0x13c>
    end_op();
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	cde080e7          	jalr	-802(ra) # 800041ea <end_op>
    return -1;
    80005514:	57fd                	li	a5,-1
    80005516:	a891                	j	8000556a <sys_link+0x13c>
    iunlockput(ip);
    80005518:	8526                	mv	a0,s1
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	4f0080e7          	jalr	1264(ra) # 80003a0a <iunlockput>
    end_op();
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	cc8080e7          	jalr	-824(ra) # 800041ea <end_op>
    return -1;
    8000552a:	57fd                	li	a5,-1
    8000552c:	a83d                	j	8000556a <sys_link+0x13c>
    iunlockput(dp);
    8000552e:	854a                	mv	a0,s2
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	4da080e7          	jalr	1242(ra) # 80003a0a <iunlockput>
  ilock(ip);
    80005538:	8526                	mv	a0,s1
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	26e080e7          	jalr	622(ra) # 800037a8 <ilock>
  ip->nlink--;
    80005542:	04a4d783          	lhu	a5,74(s1)
    80005546:	37fd                	addiw	a5,a5,-1
    80005548:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	190080e7          	jalr	400(ra) # 800036de <iupdate>
  iunlockput(ip);
    80005556:	8526                	mv	a0,s1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	4b2080e7          	jalr	1202(ra) # 80003a0a <iunlockput>
  end_op();
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	c8a080e7          	jalr	-886(ra) # 800041ea <end_op>
  return -1;
    80005568:	57fd                	li	a5,-1
}
    8000556a:	853e                	mv	a0,a5
    8000556c:	70b2                	ld	ra,296(sp)
    8000556e:	7412                	ld	s0,288(sp)
    80005570:	64f2                	ld	s1,280(sp)
    80005572:	6952                	ld	s2,272(sp)
    80005574:	6155                	addi	sp,sp,304
    80005576:	8082                	ret

0000000080005578 <sys_unlink>:
{
    80005578:	7151                	addi	sp,sp,-240
    8000557a:	f586                	sd	ra,232(sp)
    8000557c:	f1a2                	sd	s0,224(sp)
    8000557e:	eda6                	sd	s1,216(sp)
    80005580:	e9ca                	sd	s2,208(sp)
    80005582:	e5ce                	sd	s3,200(sp)
    80005584:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005586:	08000613          	li	a2,128
    8000558a:	f3040593          	addi	a1,s0,-208
    8000558e:	4501                	li	a0,0
    80005590:	ffffd097          	auipc	ra,0xffffd
    80005594:	61c080e7          	jalr	1564(ra) # 80002bac <argstr>
    80005598:	18054163          	bltz	a0,8000571a <sys_unlink+0x1a2>
  begin_op();
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	bce080e7          	jalr	-1074(ra) # 8000416a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055a4:	fb040593          	addi	a1,s0,-80
    800055a8:	f3040513          	addi	a0,s0,-208
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	9c0080e7          	jalr	-1600(ra) # 80003f6c <nameiparent>
    800055b4:	84aa                	mv	s1,a0
    800055b6:	c979                	beqz	a0,8000568c <sys_unlink+0x114>
  ilock(dp);
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	1f0080e7          	jalr	496(ra) # 800037a8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055c0:	00003597          	auipc	a1,0x3
    800055c4:	2a858593          	addi	a1,a1,680 # 80008868 <syscall_names+0x298>
    800055c8:	fb040513          	addi	a0,s0,-80
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	6a6080e7          	jalr	1702(ra) # 80003c72 <namecmp>
    800055d4:	14050a63          	beqz	a0,80005728 <sys_unlink+0x1b0>
    800055d8:	00003597          	auipc	a1,0x3
    800055dc:	29858593          	addi	a1,a1,664 # 80008870 <syscall_names+0x2a0>
    800055e0:	fb040513          	addi	a0,s0,-80
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	68e080e7          	jalr	1678(ra) # 80003c72 <namecmp>
    800055ec:	12050e63          	beqz	a0,80005728 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055f0:	f2c40613          	addi	a2,s0,-212
    800055f4:	fb040593          	addi	a1,s0,-80
    800055f8:	8526                	mv	a0,s1
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	692080e7          	jalr	1682(ra) # 80003c8c <dirlookup>
    80005602:	892a                	mv	s2,a0
    80005604:	12050263          	beqz	a0,80005728 <sys_unlink+0x1b0>
  ilock(ip);
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	1a0080e7          	jalr	416(ra) # 800037a8 <ilock>
  if(ip->nlink < 1)
    80005610:	04a91783          	lh	a5,74(s2)
    80005614:	08f05263          	blez	a5,80005698 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005618:	04491703          	lh	a4,68(s2)
    8000561c:	4785                	li	a5,1
    8000561e:	08f70563          	beq	a4,a5,800056a8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005622:	4641                	li	a2,16
    80005624:	4581                	li	a1,0
    80005626:	fc040513          	addi	a0,s0,-64
    8000562a:	ffffb097          	auipc	ra,0xffffb
    8000562e:	6f2080e7          	jalr	1778(ra) # 80000d1c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005632:	4741                	li	a4,16
    80005634:	f2c42683          	lw	a3,-212(s0)
    80005638:	fc040613          	addi	a2,s0,-64
    8000563c:	4581                	li	a1,0
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	514080e7          	jalr	1300(ra) # 80003b54 <writei>
    80005648:	47c1                	li	a5,16
    8000564a:	0af51563          	bne	a0,a5,800056f4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000564e:	04491703          	lh	a4,68(s2)
    80005652:	4785                	li	a5,1
    80005654:	0af70863          	beq	a4,a5,80005704 <sys_unlink+0x18c>
  iunlockput(dp);
    80005658:	8526                	mv	a0,s1
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	3b0080e7          	jalr	944(ra) # 80003a0a <iunlockput>
  ip->nlink--;
    80005662:	04a95783          	lhu	a5,74(s2)
    80005666:	37fd                	addiw	a5,a5,-1
    80005668:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000566c:	854a                	mv	a0,s2
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	070080e7          	jalr	112(ra) # 800036de <iupdate>
  iunlockput(ip);
    80005676:	854a                	mv	a0,s2
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	392080e7          	jalr	914(ra) # 80003a0a <iunlockput>
  end_op();
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	b6a080e7          	jalr	-1174(ra) # 800041ea <end_op>
  return 0;
    80005688:	4501                	li	a0,0
    8000568a:	a84d                	j	8000573c <sys_unlink+0x1c4>
    end_op();
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	b5e080e7          	jalr	-1186(ra) # 800041ea <end_op>
    return -1;
    80005694:	557d                	li	a0,-1
    80005696:	a05d                	j	8000573c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005698:	00003517          	auipc	a0,0x3
    8000569c:	1e050513          	addi	a0,a0,480 # 80008878 <syscall_names+0x2a8>
    800056a0:	ffffb097          	auipc	ra,0xffffb
    800056a4:	e9e080e7          	jalr	-354(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056a8:	04c92703          	lw	a4,76(s2)
    800056ac:	02000793          	li	a5,32
    800056b0:	f6e7f9e3          	bgeu	a5,a4,80005622 <sys_unlink+0xaa>
    800056b4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056b8:	4741                	li	a4,16
    800056ba:	86ce                	mv	a3,s3
    800056bc:	f1840613          	addi	a2,s0,-232
    800056c0:	4581                	li	a1,0
    800056c2:	854a                	mv	a0,s2
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	398080e7          	jalr	920(ra) # 80003a5c <readi>
    800056cc:	47c1                	li	a5,16
    800056ce:	00f51b63          	bne	a0,a5,800056e4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056d2:	f1845783          	lhu	a5,-232(s0)
    800056d6:	e7a1                	bnez	a5,8000571e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056d8:	29c1                	addiw	s3,s3,16
    800056da:	04c92783          	lw	a5,76(s2)
    800056de:	fcf9ede3          	bltu	s3,a5,800056b8 <sys_unlink+0x140>
    800056e2:	b781                	j	80005622 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056e4:	00003517          	auipc	a0,0x3
    800056e8:	1ac50513          	addi	a0,a0,428 # 80008890 <syscall_names+0x2c0>
    800056ec:	ffffb097          	auipc	ra,0xffffb
    800056f0:	e52080e7          	jalr	-430(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056f4:	00003517          	auipc	a0,0x3
    800056f8:	1b450513          	addi	a0,a0,436 # 800088a8 <syscall_names+0x2d8>
    800056fc:	ffffb097          	auipc	ra,0xffffb
    80005700:	e42080e7          	jalr	-446(ra) # 8000053e <panic>
    dp->nlink--;
    80005704:	04a4d783          	lhu	a5,74(s1)
    80005708:	37fd                	addiw	a5,a5,-1
    8000570a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	fce080e7          	jalr	-50(ra) # 800036de <iupdate>
    80005718:	b781                	j	80005658 <sys_unlink+0xe0>
    return -1;
    8000571a:	557d                	li	a0,-1
    8000571c:	a005                	j	8000573c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000571e:	854a                	mv	a0,s2
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	2ea080e7          	jalr	746(ra) # 80003a0a <iunlockput>
  iunlockput(dp);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	2e0080e7          	jalr	736(ra) # 80003a0a <iunlockput>
  end_op();
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	ab8080e7          	jalr	-1352(ra) # 800041ea <end_op>
  return -1;
    8000573a:	557d                	li	a0,-1
}
    8000573c:	70ae                	ld	ra,232(sp)
    8000573e:	740e                	ld	s0,224(sp)
    80005740:	64ee                	ld	s1,216(sp)
    80005742:	694e                	ld	s2,208(sp)
    80005744:	69ae                	ld	s3,200(sp)
    80005746:	616d                	addi	sp,sp,240
    80005748:	8082                	ret

000000008000574a <sys_open>:

uint64
sys_open(void)
{
    8000574a:	7131                	addi	sp,sp,-192
    8000574c:	fd06                	sd	ra,184(sp)
    8000574e:	f922                	sd	s0,176(sp)
    80005750:	f526                	sd	s1,168(sp)
    80005752:	f14a                	sd	s2,160(sp)
    80005754:	ed4e                	sd	s3,152(sp)
    80005756:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005758:	f4c40593          	addi	a1,s0,-180
    8000575c:	4505                	li	a0,1
    8000575e:	ffffd097          	auipc	ra,0xffffd
    80005762:	40e080e7          	jalr	1038(ra) # 80002b6c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005766:	08000613          	li	a2,128
    8000576a:	f5040593          	addi	a1,s0,-176
    8000576e:	4501                	li	a0,0
    80005770:	ffffd097          	auipc	ra,0xffffd
    80005774:	43c080e7          	jalr	1084(ra) # 80002bac <argstr>
    80005778:	87aa                	mv	a5,a0
    return -1;
    8000577a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000577c:	0a07c963          	bltz	a5,8000582e <sys_open+0xe4>

  begin_op();
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	9ea080e7          	jalr	-1558(ra) # 8000416a <begin_op>

  if(omode & O_CREATE){
    80005788:	f4c42783          	lw	a5,-180(s0)
    8000578c:	2007f793          	andi	a5,a5,512
    80005790:	cfc5                	beqz	a5,80005848 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005792:	4681                	li	a3,0
    80005794:	4601                	li	a2,0
    80005796:	4589                	li	a1,2
    80005798:	f5040513          	addi	a0,s0,-176
    8000579c:	00000097          	auipc	ra,0x0
    800057a0:	976080e7          	jalr	-1674(ra) # 80005112 <create>
    800057a4:	84aa                	mv	s1,a0
    if(ip == 0){
    800057a6:	c959                	beqz	a0,8000583c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057a8:	04449703          	lh	a4,68(s1)
    800057ac:	478d                	li	a5,3
    800057ae:	00f71763          	bne	a4,a5,800057bc <sys_open+0x72>
    800057b2:	0464d703          	lhu	a4,70(s1)
    800057b6:	47a5                	li	a5,9
    800057b8:	0ce7ed63          	bltu	a5,a4,80005892 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057bc:	fffff097          	auipc	ra,0xfffff
    800057c0:	dbe080e7          	jalr	-578(ra) # 8000457a <filealloc>
    800057c4:	89aa                	mv	s3,a0
    800057c6:	10050363          	beqz	a0,800058cc <sys_open+0x182>
    800057ca:	00000097          	auipc	ra,0x0
    800057ce:	906080e7          	jalr	-1786(ra) # 800050d0 <fdalloc>
    800057d2:	892a                	mv	s2,a0
    800057d4:	0e054763          	bltz	a0,800058c2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057d8:	04449703          	lh	a4,68(s1)
    800057dc:	478d                	li	a5,3
    800057de:	0cf70563          	beq	a4,a5,800058a8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057e2:	4789                	li	a5,2
    800057e4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057e8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057ec:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057f0:	f4c42783          	lw	a5,-180(s0)
    800057f4:	0017c713          	xori	a4,a5,1
    800057f8:	8b05                	andi	a4,a4,1
    800057fa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057fe:	0037f713          	andi	a4,a5,3
    80005802:	00e03733          	snez	a4,a4
    80005806:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000580a:	4007f793          	andi	a5,a5,1024
    8000580e:	c791                	beqz	a5,8000581a <sys_open+0xd0>
    80005810:	04449703          	lh	a4,68(s1)
    80005814:	4789                	li	a5,2
    80005816:	0af70063          	beq	a4,a5,800058b6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	04e080e7          	jalr	78(ra) # 8000386a <iunlock>
  end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	9c6080e7          	jalr	-1594(ra) # 800041ea <end_op>

  return fd;
    8000582c:	854a                	mv	a0,s2
}
    8000582e:	70ea                	ld	ra,184(sp)
    80005830:	744a                	ld	s0,176(sp)
    80005832:	74aa                	ld	s1,168(sp)
    80005834:	790a                	ld	s2,160(sp)
    80005836:	69ea                	ld	s3,152(sp)
    80005838:	6129                	addi	sp,sp,192
    8000583a:	8082                	ret
      end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	9ae080e7          	jalr	-1618(ra) # 800041ea <end_op>
      return -1;
    80005844:	557d                	li	a0,-1
    80005846:	b7e5                	j	8000582e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005848:	f5040513          	addi	a0,s0,-176
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	702080e7          	jalr	1794(ra) # 80003f4e <namei>
    80005854:	84aa                	mv	s1,a0
    80005856:	c905                	beqz	a0,80005886 <sys_open+0x13c>
    ilock(ip);
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	f50080e7          	jalr	-176(ra) # 800037a8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005860:	04449703          	lh	a4,68(s1)
    80005864:	4785                	li	a5,1
    80005866:	f4f711e3          	bne	a4,a5,800057a8 <sys_open+0x5e>
    8000586a:	f4c42783          	lw	a5,-180(s0)
    8000586e:	d7b9                	beqz	a5,800057bc <sys_open+0x72>
      iunlockput(ip);
    80005870:	8526                	mv	a0,s1
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	198080e7          	jalr	408(ra) # 80003a0a <iunlockput>
      end_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	970080e7          	jalr	-1680(ra) # 800041ea <end_op>
      return -1;
    80005882:	557d                	li	a0,-1
    80005884:	b76d                	j	8000582e <sys_open+0xe4>
      end_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	964080e7          	jalr	-1692(ra) # 800041ea <end_op>
      return -1;
    8000588e:	557d                	li	a0,-1
    80005890:	bf79                	j	8000582e <sys_open+0xe4>
    iunlockput(ip);
    80005892:	8526                	mv	a0,s1
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	176080e7          	jalr	374(ra) # 80003a0a <iunlockput>
    end_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	94e080e7          	jalr	-1714(ra) # 800041ea <end_op>
    return -1;
    800058a4:	557d                	li	a0,-1
    800058a6:	b761                	j	8000582e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058a8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058ac:	04649783          	lh	a5,70(s1)
    800058b0:	02f99223          	sh	a5,36(s3)
    800058b4:	bf25                	j	800057ec <sys_open+0xa2>
    itrunc(ip);
    800058b6:	8526                	mv	a0,s1
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	ffe080e7          	jalr	-2(ra) # 800038b6 <itrunc>
    800058c0:	bfa9                	j	8000581a <sys_open+0xd0>
      fileclose(f);
    800058c2:	854e                	mv	a0,s3
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	d72080e7          	jalr	-654(ra) # 80004636 <fileclose>
    iunlockput(ip);
    800058cc:	8526                	mv	a0,s1
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	13c080e7          	jalr	316(ra) # 80003a0a <iunlockput>
    end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	914080e7          	jalr	-1772(ra) # 800041ea <end_op>
    return -1;
    800058de:	557d                	li	a0,-1
    800058e0:	b7b9                	j	8000582e <sys_open+0xe4>

00000000800058e2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058e2:	7175                	addi	sp,sp,-144
    800058e4:	e506                	sd	ra,136(sp)
    800058e6:	e122                	sd	s0,128(sp)
    800058e8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	880080e7          	jalr	-1920(ra) # 8000416a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058f2:	08000613          	li	a2,128
    800058f6:	f7040593          	addi	a1,s0,-144
    800058fa:	4501                	li	a0,0
    800058fc:	ffffd097          	auipc	ra,0xffffd
    80005900:	2b0080e7          	jalr	688(ra) # 80002bac <argstr>
    80005904:	02054963          	bltz	a0,80005936 <sys_mkdir+0x54>
    80005908:	4681                	li	a3,0
    8000590a:	4601                	li	a2,0
    8000590c:	4585                	li	a1,1
    8000590e:	f7040513          	addi	a0,s0,-144
    80005912:	00000097          	auipc	ra,0x0
    80005916:	800080e7          	jalr	-2048(ra) # 80005112 <create>
    8000591a:	cd11                	beqz	a0,80005936 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	0ee080e7          	jalr	238(ra) # 80003a0a <iunlockput>
  end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	8c6080e7          	jalr	-1850(ra) # 800041ea <end_op>
  return 0;
    8000592c:	4501                	li	a0,0
}
    8000592e:	60aa                	ld	ra,136(sp)
    80005930:	640a                	ld	s0,128(sp)
    80005932:	6149                	addi	sp,sp,144
    80005934:	8082                	ret
    end_op();
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	8b4080e7          	jalr	-1868(ra) # 800041ea <end_op>
    return -1;
    8000593e:	557d                	li	a0,-1
    80005940:	b7fd                	j	8000592e <sys_mkdir+0x4c>

0000000080005942 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005942:	7135                	addi	sp,sp,-160
    80005944:	ed06                	sd	ra,152(sp)
    80005946:	e922                	sd	s0,144(sp)
    80005948:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	820080e7          	jalr	-2016(ra) # 8000416a <begin_op>
  argint(1, &major);
    80005952:	f6c40593          	addi	a1,s0,-148
    80005956:	4505                	li	a0,1
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	214080e7          	jalr	532(ra) # 80002b6c <argint>
  argint(2, &minor);
    80005960:	f6840593          	addi	a1,s0,-152
    80005964:	4509                	li	a0,2
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	206080e7          	jalr	518(ra) # 80002b6c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000596e:	08000613          	li	a2,128
    80005972:	f7040593          	addi	a1,s0,-144
    80005976:	4501                	li	a0,0
    80005978:	ffffd097          	auipc	ra,0xffffd
    8000597c:	234080e7          	jalr	564(ra) # 80002bac <argstr>
    80005980:	02054b63          	bltz	a0,800059b6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005984:	f6841683          	lh	a3,-152(s0)
    80005988:	f6c41603          	lh	a2,-148(s0)
    8000598c:	458d                	li	a1,3
    8000598e:	f7040513          	addi	a0,s0,-144
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	780080e7          	jalr	1920(ra) # 80005112 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000599a:	cd11                	beqz	a0,800059b6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	06e080e7          	jalr	110(ra) # 80003a0a <iunlockput>
  end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	846080e7          	jalr	-1978(ra) # 800041ea <end_op>
  return 0;
    800059ac:	4501                	li	a0,0
}
    800059ae:	60ea                	ld	ra,152(sp)
    800059b0:	644a                	ld	s0,144(sp)
    800059b2:	610d                	addi	sp,sp,160
    800059b4:	8082                	ret
    end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	834080e7          	jalr	-1996(ra) # 800041ea <end_op>
    return -1;
    800059be:	557d                	li	a0,-1
    800059c0:	b7fd                	j	800059ae <sys_mknod+0x6c>

00000000800059c2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059c2:	7135                	addi	sp,sp,-160
    800059c4:	ed06                	sd	ra,152(sp)
    800059c6:	e922                	sd	s0,144(sp)
    800059c8:	e526                	sd	s1,136(sp)
    800059ca:	e14a                	sd	s2,128(sp)
    800059cc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059ce:	ffffc097          	auipc	ra,0xffffc
    800059d2:	028080e7          	jalr	40(ra) # 800019f6 <myproc>
    800059d6:	892a                	mv	s2,a0
  
  begin_op();
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	792080e7          	jalr	1938(ra) # 8000416a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059e0:	08000613          	li	a2,128
    800059e4:	f6040593          	addi	a1,s0,-160
    800059e8:	4501                	li	a0,0
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	1c2080e7          	jalr	450(ra) # 80002bac <argstr>
    800059f2:	04054b63          	bltz	a0,80005a48 <sys_chdir+0x86>
    800059f6:	f6040513          	addi	a0,s0,-160
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	554080e7          	jalr	1364(ra) # 80003f4e <namei>
    80005a02:	84aa                	mv	s1,a0
    80005a04:	c131                	beqz	a0,80005a48 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	da2080e7          	jalr	-606(ra) # 800037a8 <ilock>
  if(ip->type != T_DIR){
    80005a0e:	04449703          	lh	a4,68(s1)
    80005a12:	4785                	li	a5,1
    80005a14:	04f71063          	bne	a4,a5,80005a54 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a18:	8526                	mv	a0,s1
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	e50080e7          	jalr	-432(ra) # 8000386a <iunlock>
  iput(p->cwd);
    80005a22:	15093503          	ld	a0,336(s2)
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	f3c080e7          	jalr	-196(ra) # 80003962 <iput>
  end_op();
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	7bc080e7          	jalr	1980(ra) # 800041ea <end_op>
  p->cwd = ip;
    80005a36:	14993823          	sd	s1,336(s2)
  return 0;
    80005a3a:	4501                	li	a0,0
}
    80005a3c:	60ea                	ld	ra,152(sp)
    80005a3e:	644a                	ld	s0,144(sp)
    80005a40:	64aa                	ld	s1,136(sp)
    80005a42:	690a                	ld	s2,128(sp)
    80005a44:	610d                	addi	sp,sp,160
    80005a46:	8082                	ret
    end_op();
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	7a2080e7          	jalr	1954(ra) # 800041ea <end_op>
    return -1;
    80005a50:	557d                	li	a0,-1
    80005a52:	b7ed                	j	80005a3c <sys_chdir+0x7a>
    iunlockput(ip);
    80005a54:	8526                	mv	a0,s1
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	fb4080e7          	jalr	-76(ra) # 80003a0a <iunlockput>
    end_op();
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	78c080e7          	jalr	1932(ra) # 800041ea <end_op>
    return -1;
    80005a66:	557d                	li	a0,-1
    80005a68:	bfd1                	j	80005a3c <sys_chdir+0x7a>

0000000080005a6a <sys_exec>:

uint64
sys_exec(void)
{
    80005a6a:	7145                	addi	sp,sp,-464
    80005a6c:	e786                	sd	ra,456(sp)
    80005a6e:	e3a2                	sd	s0,448(sp)
    80005a70:	ff26                	sd	s1,440(sp)
    80005a72:	fb4a                	sd	s2,432(sp)
    80005a74:	f74e                	sd	s3,424(sp)
    80005a76:	f352                	sd	s4,416(sp)
    80005a78:	ef56                	sd	s5,408(sp)
    80005a7a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a7c:	e3840593          	addi	a1,s0,-456
    80005a80:	4505                	li	a0,1
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	10a080e7          	jalr	266(ra) # 80002b8c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a8a:	08000613          	li	a2,128
    80005a8e:	f4040593          	addi	a1,s0,-192
    80005a92:	4501                	li	a0,0
    80005a94:	ffffd097          	auipc	ra,0xffffd
    80005a98:	118080e7          	jalr	280(ra) # 80002bac <argstr>
    80005a9c:	87aa                	mv	a5,a0
    return -1;
    80005a9e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005aa0:	0c07c263          	bltz	a5,80005b64 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005aa4:	10000613          	li	a2,256
    80005aa8:	4581                	li	a1,0
    80005aaa:	e4040513          	addi	a0,s0,-448
    80005aae:	ffffb097          	auipc	ra,0xffffb
    80005ab2:	26e080e7          	jalr	622(ra) # 80000d1c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ab6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005aba:	89a6                	mv	s3,s1
    80005abc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005abe:	02000a13          	li	s4,32
    80005ac2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ac6:	00391793          	slli	a5,s2,0x3
    80005aca:	e3040593          	addi	a1,s0,-464
    80005ace:	e3843503          	ld	a0,-456(s0)
    80005ad2:	953e                	add	a0,a0,a5
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	ffa080e7          	jalr	-6(ra) # 80002ace <fetchaddr>
    80005adc:	02054a63          	bltz	a0,80005b10 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ae0:	e3043783          	ld	a5,-464(s0)
    80005ae4:	c3b9                	beqz	a5,80005b2a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ae6:	ffffb097          	auipc	ra,0xffffb
    80005aea:	000080e7          	jalr	ra # 80000ae6 <kalloc>
    80005aee:	85aa                	mv	a1,a0
    80005af0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005af4:	cd11                	beqz	a0,80005b10 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005af6:	6605                	lui	a2,0x1
    80005af8:	e3043503          	ld	a0,-464(s0)
    80005afc:	ffffd097          	auipc	ra,0xffffd
    80005b00:	024080e7          	jalr	36(ra) # 80002b20 <fetchstr>
    80005b04:	00054663          	bltz	a0,80005b10 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b08:	0905                	addi	s2,s2,1
    80005b0a:	09a1                	addi	s3,s3,8
    80005b0c:	fb491be3          	bne	s2,s4,80005ac2 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b10:	10048913          	addi	s2,s1,256
    80005b14:	6088                	ld	a0,0(s1)
    80005b16:	c531                	beqz	a0,80005b62 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b18:	ffffb097          	auipc	ra,0xffffb
    80005b1c:	ed2080e7          	jalr	-302(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b20:	04a1                	addi	s1,s1,8
    80005b22:	ff2499e3          	bne	s1,s2,80005b14 <sys_exec+0xaa>
  return -1;
    80005b26:	557d                	li	a0,-1
    80005b28:	a835                	j	80005b64 <sys_exec+0xfa>
      argv[i] = 0;
    80005b2a:	0a8e                	slli	s5,s5,0x3
    80005b2c:	fc040793          	addi	a5,s0,-64
    80005b30:	9abe                	add	s5,s5,a5
    80005b32:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b36:	e4040593          	addi	a1,s0,-448
    80005b3a:	f4040513          	addi	a0,s0,-192
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	172080e7          	jalr	370(ra) # 80004cb0 <exec>
    80005b46:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b48:	10048993          	addi	s3,s1,256
    80005b4c:	6088                	ld	a0,0(s1)
    80005b4e:	c901                	beqz	a0,80005b5e <sys_exec+0xf4>
    kfree(argv[i]);
    80005b50:	ffffb097          	auipc	ra,0xffffb
    80005b54:	e9a080e7          	jalr	-358(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b58:	04a1                	addi	s1,s1,8
    80005b5a:	ff3499e3          	bne	s1,s3,80005b4c <sys_exec+0xe2>
  return ret;
    80005b5e:	854a                	mv	a0,s2
    80005b60:	a011                	j	80005b64 <sys_exec+0xfa>
  return -1;
    80005b62:	557d                	li	a0,-1
}
    80005b64:	60be                	ld	ra,456(sp)
    80005b66:	641e                	ld	s0,448(sp)
    80005b68:	74fa                	ld	s1,440(sp)
    80005b6a:	795a                	ld	s2,432(sp)
    80005b6c:	79ba                	ld	s3,424(sp)
    80005b6e:	7a1a                	ld	s4,416(sp)
    80005b70:	6afa                	ld	s5,408(sp)
    80005b72:	6179                	addi	sp,sp,464
    80005b74:	8082                	ret

0000000080005b76 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b76:	7139                	addi	sp,sp,-64
    80005b78:	fc06                	sd	ra,56(sp)
    80005b7a:	f822                	sd	s0,48(sp)
    80005b7c:	f426                	sd	s1,40(sp)
    80005b7e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b80:	ffffc097          	auipc	ra,0xffffc
    80005b84:	e76080e7          	jalr	-394(ra) # 800019f6 <myproc>
    80005b88:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b8a:	fd840593          	addi	a1,s0,-40
    80005b8e:	4501                	li	a0,0
    80005b90:	ffffd097          	auipc	ra,0xffffd
    80005b94:	ffc080e7          	jalr	-4(ra) # 80002b8c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b98:	fc840593          	addi	a1,s0,-56
    80005b9c:	fd040513          	addi	a0,s0,-48
    80005ba0:	fffff097          	auipc	ra,0xfffff
    80005ba4:	dc6080e7          	jalr	-570(ra) # 80004966 <pipealloc>
    return -1;
    80005ba8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005baa:	0c054463          	bltz	a0,80005c72 <sys_pipe+0xfc>
  fd0 = -1;
    80005bae:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bb2:	fd043503          	ld	a0,-48(s0)
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	51a080e7          	jalr	1306(ra) # 800050d0 <fdalloc>
    80005bbe:	fca42223          	sw	a0,-60(s0)
    80005bc2:	08054b63          	bltz	a0,80005c58 <sys_pipe+0xe2>
    80005bc6:	fc843503          	ld	a0,-56(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	506080e7          	jalr	1286(ra) # 800050d0 <fdalloc>
    80005bd2:	fca42023          	sw	a0,-64(s0)
    80005bd6:	06054863          	bltz	a0,80005c46 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bda:	4691                	li	a3,4
    80005bdc:	fc440613          	addi	a2,s0,-60
    80005be0:	fd843583          	ld	a1,-40(s0)
    80005be4:	68a8                	ld	a0,80(s1)
    80005be6:	ffffc097          	auipc	ra,0xffffc
    80005bea:	acc080e7          	jalr	-1332(ra) # 800016b2 <copyout>
    80005bee:	02054063          	bltz	a0,80005c0e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bf2:	4691                	li	a3,4
    80005bf4:	fc040613          	addi	a2,s0,-64
    80005bf8:	fd843583          	ld	a1,-40(s0)
    80005bfc:	0591                	addi	a1,a1,4
    80005bfe:	68a8                	ld	a0,80(s1)
    80005c00:	ffffc097          	auipc	ra,0xffffc
    80005c04:	ab2080e7          	jalr	-1358(ra) # 800016b2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c08:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c0a:	06055463          	bgez	a0,80005c72 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c0e:	fc442783          	lw	a5,-60(s0)
    80005c12:	07e9                	addi	a5,a5,26
    80005c14:	078e                	slli	a5,a5,0x3
    80005c16:	97a6                	add	a5,a5,s1
    80005c18:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c1c:	fc042503          	lw	a0,-64(s0)
    80005c20:	0569                	addi	a0,a0,26
    80005c22:	050e                	slli	a0,a0,0x3
    80005c24:	94aa                	add	s1,s1,a0
    80005c26:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c2a:	fd043503          	ld	a0,-48(s0)
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	a08080e7          	jalr	-1528(ra) # 80004636 <fileclose>
    fileclose(wf);
    80005c36:	fc843503          	ld	a0,-56(s0)
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	9fc080e7          	jalr	-1540(ra) # 80004636 <fileclose>
    return -1;
    80005c42:	57fd                	li	a5,-1
    80005c44:	a03d                	j	80005c72 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c46:	fc442783          	lw	a5,-60(s0)
    80005c4a:	0007c763          	bltz	a5,80005c58 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c4e:	07e9                	addi	a5,a5,26
    80005c50:	078e                	slli	a5,a5,0x3
    80005c52:	94be                	add	s1,s1,a5
    80005c54:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c58:	fd043503          	ld	a0,-48(s0)
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	9da080e7          	jalr	-1574(ra) # 80004636 <fileclose>
    fileclose(wf);
    80005c64:	fc843503          	ld	a0,-56(s0)
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	9ce080e7          	jalr	-1586(ra) # 80004636 <fileclose>
    return -1;
    80005c70:	57fd                	li	a5,-1
}
    80005c72:	853e                	mv	a0,a5
    80005c74:	70e2                	ld	ra,56(sp)
    80005c76:	7442                	ld	s0,48(sp)
    80005c78:	74a2                	ld	s1,40(sp)
    80005c7a:	6121                	addi	sp,sp,64
    80005c7c:	8082                	ret
	...

0000000080005c80 <kernelvec>:
    80005c80:	7111                	addi	sp,sp,-256
    80005c82:	e006                	sd	ra,0(sp)
    80005c84:	e40a                	sd	sp,8(sp)
    80005c86:	e80e                	sd	gp,16(sp)
    80005c88:	ec12                	sd	tp,24(sp)
    80005c8a:	f016                	sd	t0,32(sp)
    80005c8c:	f41a                	sd	t1,40(sp)
    80005c8e:	f81e                	sd	t2,48(sp)
    80005c90:	fc22                	sd	s0,56(sp)
    80005c92:	e0a6                	sd	s1,64(sp)
    80005c94:	e4aa                	sd	a0,72(sp)
    80005c96:	e8ae                	sd	a1,80(sp)
    80005c98:	ecb2                	sd	a2,88(sp)
    80005c9a:	f0b6                	sd	a3,96(sp)
    80005c9c:	f4ba                	sd	a4,104(sp)
    80005c9e:	f8be                	sd	a5,112(sp)
    80005ca0:	fcc2                	sd	a6,120(sp)
    80005ca2:	e146                	sd	a7,128(sp)
    80005ca4:	e54a                	sd	s2,136(sp)
    80005ca6:	e94e                	sd	s3,144(sp)
    80005ca8:	ed52                	sd	s4,152(sp)
    80005caa:	f156                	sd	s5,160(sp)
    80005cac:	f55a                	sd	s6,168(sp)
    80005cae:	f95e                	sd	s7,176(sp)
    80005cb0:	fd62                	sd	s8,184(sp)
    80005cb2:	e1e6                	sd	s9,192(sp)
    80005cb4:	e5ea                	sd	s10,200(sp)
    80005cb6:	e9ee                	sd	s11,208(sp)
    80005cb8:	edf2                	sd	t3,216(sp)
    80005cba:	f1f6                	sd	t4,224(sp)
    80005cbc:	f5fa                	sd	t5,232(sp)
    80005cbe:	f9fe                	sd	t6,240(sp)
    80005cc0:	cdbfc0ef          	jal	ra,8000299a <kerneltrap>
    80005cc4:	6082                	ld	ra,0(sp)
    80005cc6:	6122                	ld	sp,8(sp)
    80005cc8:	61c2                	ld	gp,16(sp)
    80005cca:	7282                	ld	t0,32(sp)
    80005ccc:	7322                	ld	t1,40(sp)
    80005cce:	73c2                	ld	t2,48(sp)
    80005cd0:	7462                	ld	s0,56(sp)
    80005cd2:	6486                	ld	s1,64(sp)
    80005cd4:	6526                	ld	a0,72(sp)
    80005cd6:	65c6                	ld	a1,80(sp)
    80005cd8:	6666                	ld	a2,88(sp)
    80005cda:	7686                	ld	a3,96(sp)
    80005cdc:	7726                	ld	a4,104(sp)
    80005cde:	77c6                	ld	a5,112(sp)
    80005ce0:	7866                	ld	a6,120(sp)
    80005ce2:	688a                	ld	a7,128(sp)
    80005ce4:	692a                	ld	s2,136(sp)
    80005ce6:	69ca                	ld	s3,144(sp)
    80005ce8:	6a6a                	ld	s4,152(sp)
    80005cea:	7a8a                	ld	s5,160(sp)
    80005cec:	7b2a                	ld	s6,168(sp)
    80005cee:	7bca                	ld	s7,176(sp)
    80005cf0:	7c6a                	ld	s8,184(sp)
    80005cf2:	6c8e                	ld	s9,192(sp)
    80005cf4:	6d2e                	ld	s10,200(sp)
    80005cf6:	6dce                	ld	s11,208(sp)
    80005cf8:	6e6e                	ld	t3,216(sp)
    80005cfa:	7e8e                	ld	t4,224(sp)
    80005cfc:	7f2e                	ld	t5,232(sp)
    80005cfe:	7fce                	ld	t6,240(sp)
    80005d00:	6111                	addi	sp,sp,256
    80005d02:	10200073          	sret
    80005d06:	00000013          	nop
    80005d0a:	00000013          	nop
    80005d0e:	0001                	nop

0000000080005d10 <timervec>:
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	e10c                	sd	a1,0(a0)
    80005d16:	e510                	sd	a2,8(a0)
    80005d18:	e914                	sd	a3,16(a0)
    80005d1a:	6d0c                	ld	a1,24(a0)
    80005d1c:	7110                	ld	a2,32(a0)
    80005d1e:	6194                	ld	a3,0(a1)
    80005d20:	96b2                	add	a3,a3,a2
    80005d22:	e194                	sd	a3,0(a1)
    80005d24:	4589                	li	a1,2
    80005d26:	14459073          	csrw	sip,a1
    80005d2a:	6914                	ld	a3,16(a0)
    80005d2c:	6510                	ld	a2,8(a0)
    80005d2e:	610c                	ld	a1,0(a0)
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	30200073          	mret
	...

0000000080005d3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d3a:	1141                	addi	sp,sp,-16
    80005d3c:	e422                	sd	s0,8(sp)
    80005d3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d40:	0c0007b7          	lui	a5,0xc000
    80005d44:	4705                	li	a4,1
    80005d46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d48:	c3d8                	sw	a4,4(a5)
}
    80005d4a:	6422                	ld	s0,8(sp)
    80005d4c:	0141                	addi	sp,sp,16
    80005d4e:	8082                	ret

0000000080005d50 <plicinithart>:

void
plicinithart(void)
{
    80005d50:	1141                	addi	sp,sp,-16
    80005d52:	e406                	sd	ra,8(sp)
    80005d54:	e022                	sd	s0,0(sp)
    80005d56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	c72080e7          	jalr	-910(ra) # 800019ca <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d60:	0085171b          	slliw	a4,a0,0x8
    80005d64:	0c0027b7          	lui	a5,0xc002
    80005d68:	97ba                	add	a5,a5,a4
    80005d6a:	40200713          	li	a4,1026
    80005d6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d72:	00d5151b          	slliw	a0,a0,0xd
    80005d76:	0c2017b7          	lui	a5,0xc201
    80005d7a:	953e                	add	a0,a0,a5
    80005d7c:	00052023          	sw	zero,0(a0)
}
    80005d80:	60a2                	ld	ra,8(sp)
    80005d82:	6402                	ld	s0,0(sp)
    80005d84:	0141                	addi	sp,sp,16
    80005d86:	8082                	ret

0000000080005d88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d88:	1141                	addi	sp,sp,-16
    80005d8a:	e406                	sd	ra,8(sp)
    80005d8c:	e022                	sd	s0,0(sp)
    80005d8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d90:	ffffc097          	auipc	ra,0xffffc
    80005d94:	c3a080e7          	jalr	-966(ra) # 800019ca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d98:	00d5179b          	slliw	a5,a0,0xd
    80005d9c:	0c201537          	lui	a0,0xc201
    80005da0:	953e                	add	a0,a0,a5
  return irq;
}
    80005da2:	4148                	lw	a0,4(a0)
    80005da4:	60a2                	ld	ra,8(sp)
    80005da6:	6402                	ld	s0,0(sp)
    80005da8:	0141                	addi	sp,sp,16
    80005daa:	8082                	ret

0000000080005dac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dac:	1101                	addi	sp,sp,-32
    80005dae:	ec06                	sd	ra,24(sp)
    80005db0:	e822                	sd	s0,16(sp)
    80005db2:	e426                	sd	s1,8(sp)
    80005db4:	1000                	addi	s0,sp,32
    80005db6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	c12080e7          	jalr	-1006(ra) # 800019ca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dc0:	00d5151b          	slliw	a0,a0,0xd
    80005dc4:	0c2017b7          	lui	a5,0xc201
    80005dc8:	97aa                	add	a5,a5,a0
    80005dca:	c3c4                	sw	s1,4(a5)
}
    80005dcc:	60e2                	ld	ra,24(sp)
    80005dce:	6442                	ld	s0,16(sp)
    80005dd0:	64a2                	ld	s1,8(sp)
    80005dd2:	6105                	addi	sp,sp,32
    80005dd4:	8082                	ret

0000000080005dd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dd6:	1141                	addi	sp,sp,-16
    80005dd8:	e406                	sd	ra,8(sp)
    80005dda:	e022                	sd	s0,0(sp)
    80005ddc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dde:	479d                	li	a5,7
    80005de0:	04a7cc63          	blt	a5,a0,80005e38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005de4:	0001c797          	auipc	a5,0x1c
    80005de8:	19c78793          	addi	a5,a5,412 # 80021f80 <disk>
    80005dec:	97aa                	add	a5,a5,a0
    80005dee:	0187c783          	lbu	a5,24(a5)
    80005df2:	ebb9                	bnez	a5,80005e48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005df4:	00451613          	slli	a2,a0,0x4
    80005df8:	0001c797          	auipc	a5,0x1c
    80005dfc:	18878793          	addi	a5,a5,392 # 80021f80 <disk>
    80005e00:	6394                	ld	a3,0(a5)
    80005e02:	96b2                	add	a3,a3,a2
    80005e04:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e08:	6398                	ld	a4,0(a5)
    80005e0a:	9732                	add	a4,a4,a2
    80005e0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e18:	953e                	add	a0,a0,a5
    80005e1a:	4785                	li	a5,1
    80005e1c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e20:	0001c517          	auipc	a0,0x1c
    80005e24:	17850513          	addi	a0,a0,376 # 80021f98 <disk+0x18>
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	2e6080e7          	jalr	742(ra) # 8000210e <wakeup>
}
    80005e30:	60a2                	ld	ra,8(sp)
    80005e32:	6402                	ld	s0,0(sp)
    80005e34:	0141                	addi	sp,sp,16
    80005e36:	8082                	ret
    panic("free_desc 1");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	a8050513          	addi	a0,a0,-1408 # 800088b8 <syscall_names+0x2e8>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	6fe080e7          	jalr	1790(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e48:	00003517          	auipc	a0,0x3
    80005e4c:	a8050513          	addi	a0,a0,-1408 # 800088c8 <syscall_names+0x2f8>
    80005e50:	ffffa097          	auipc	ra,0xffffa
    80005e54:	6ee080e7          	jalr	1774(ra) # 8000053e <panic>

0000000080005e58 <virtio_disk_init>:
{
    80005e58:	1101                	addi	sp,sp,-32
    80005e5a:	ec06                	sd	ra,24(sp)
    80005e5c:	e822                	sd	s0,16(sp)
    80005e5e:	e426                	sd	s1,8(sp)
    80005e60:	e04a                	sd	s2,0(sp)
    80005e62:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e64:	00003597          	auipc	a1,0x3
    80005e68:	a7458593          	addi	a1,a1,-1420 # 800088d8 <syscall_names+0x308>
    80005e6c:	0001c517          	auipc	a0,0x1c
    80005e70:	23c50513          	addi	a0,a0,572 # 800220a8 <disk+0x128>
    80005e74:	ffffb097          	auipc	ra,0xffffb
    80005e78:	d1c080e7          	jalr	-740(ra) # 80000b90 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e7c:	100017b7          	lui	a5,0x10001
    80005e80:	4398                	lw	a4,0(a5)
    80005e82:	2701                	sext.w	a4,a4
    80005e84:	747277b7          	lui	a5,0x74727
    80005e88:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e8c:	14f71c63          	bne	a4,a5,80005fe4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e90:	100017b7          	lui	a5,0x10001
    80005e94:	43dc                	lw	a5,4(a5)
    80005e96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e98:	4709                	li	a4,2
    80005e9a:	14e79563          	bne	a5,a4,80005fe4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	479c                	lw	a5,8(a5)
    80005ea4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ea6:	12e79f63          	bne	a5,a4,80005fe4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eaa:	100017b7          	lui	a5,0x10001
    80005eae:	47d8                	lw	a4,12(a5)
    80005eb0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eb2:	554d47b7          	lui	a5,0x554d4
    80005eb6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eba:	12f71563          	bne	a4,a5,80005fe4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec6:	4705                	li	a4,1
    80005ec8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eca:	470d                	li	a4,3
    80005ecc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ece:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ed0:	c7ffe737          	lui	a4,0xc7ffe
    80005ed4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc69f>
    80005ed8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eda:	2701                	sext.w	a4,a4
    80005edc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ede:	472d                	li	a4,11
    80005ee0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ee2:	5bbc                	lw	a5,112(a5)
    80005ee4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ee8:	8ba1                	andi	a5,a5,8
    80005eea:	10078563          	beqz	a5,80005ff4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eee:	100017b7          	lui	a5,0x10001
    80005ef2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ef6:	43fc                	lw	a5,68(a5)
    80005ef8:	2781                	sext.w	a5,a5
    80005efa:	10079563          	bnez	a5,80006004 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005efe:	100017b7          	lui	a5,0x10001
    80005f02:	5bdc                	lw	a5,52(a5)
    80005f04:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f06:	10078763          	beqz	a5,80006014 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005f0a:	471d                	li	a4,7
    80005f0c:	10f77c63          	bgeu	a4,a5,80006024 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005f10:	ffffb097          	auipc	ra,0xffffb
    80005f14:	bd6080e7          	jalr	-1066(ra) # 80000ae6 <kalloc>
    80005f18:	0001c497          	auipc	s1,0x1c
    80005f1c:	06848493          	addi	s1,s1,104 # 80021f80 <disk>
    80005f20:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f22:	ffffb097          	auipc	ra,0xffffb
    80005f26:	bc4080e7          	jalr	-1084(ra) # 80000ae6 <kalloc>
    80005f2a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f2c:	ffffb097          	auipc	ra,0xffffb
    80005f30:	bba080e7          	jalr	-1094(ra) # 80000ae6 <kalloc>
    80005f34:	87aa                	mv	a5,a0
    80005f36:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f38:	6088                	ld	a0,0(s1)
    80005f3a:	cd6d                	beqz	a0,80006034 <virtio_disk_init+0x1dc>
    80005f3c:	0001c717          	auipc	a4,0x1c
    80005f40:	04c73703          	ld	a4,76(a4) # 80021f88 <disk+0x8>
    80005f44:	cb65                	beqz	a4,80006034 <virtio_disk_init+0x1dc>
    80005f46:	c7fd                	beqz	a5,80006034 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005f48:	6605                	lui	a2,0x1
    80005f4a:	4581                	li	a1,0
    80005f4c:	ffffb097          	auipc	ra,0xffffb
    80005f50:	dd0080e7          	jalr	-560(ra) # 80000d1c <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f54:	0001c497          	auipc	s1,0x1c
    80005f58:	02c48493          	addi	s1,s1,44 # 80021f80 <disk>
    80005f5c:	6605                	lui	a2,0x1
    80005f5e:	4581                	li	a1,0
    80005f60:	6488                	ld	a0,8(s1)
    80005f62:	ffffb097          	auipc	ra,0xffffb
    80005f66:	dba080e7          	jalr	-582(ra) # 80000d1c <memset>
  memset(disk.used, 0, PGSIZE);
    80005f6a:	6605                	lui	a2,0x1
    80005f6c:	4581                	li	a1,0
    80005f6e:	6888                	ld	a0,16(s1)
    80005f70:	ffffb097          	auipc	ra,0xffffb
    80005f74:	dac080e7          	jalr	-596(ra) # 80000d1c <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f78:	100017b7          	lui	a5,0x10001
    80005f7c:	4721                	li	a4,8
    80005f7e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f80:	4098                	lw	a4,0(s1)
    80005f82:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f86:	40d8                	lw	a4,4(s1)
    80005f88:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f8c:	6498                	ld	a4,8(s1)
    80005f8e:	0007069b          	sext.w	a3,a4
    80005f92:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f96:	9701                	srai	a4,a4,0x20
    80005f98:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f9c:	6898                	ld	a4,16(s1)
    80005f9e:	0007069b          	sext.w	a3,a4
    80005fa2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fa6:	9701                	srai	a4,a4,0x20
    80005fa8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fac:	4705                	li	a4,1
    80005fae:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fb0:	00e48c23          	sb	a4,24(s1)
    80005fb4:	00e48ca3          	sb	a4,25(s1)
    80005fb8:	00e48d23          	sb	a4,26(s1)
    80005fbc:	00e48da3          	sb	a4,27(s1)
    80005fc0:	00e48e23          	sb	a4,28(s1)
    80005fc4:	00e48ea3          	sb	a4,29(s1)
    80005fc8:	00e48f23          	sb	a4,30(s1)
    80005fcc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fd0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd4:	0727a823          	sw	s2,112(a5)
}
    80005fd8:	60e2                	ld	ra,24(sp)
    80005fda:	6442                	ld	s0,16(sp)
    80005fdc:	64a2                	ld	s1,8(sp)
    80005fde:	6902                	ld	s2,0(sp)
    80005fe0:	6105                	addi	sp,sp,32
    80005fe2:	8082                	ret
    panic("could not find virtio disk");
    80005fe4:	00003517          	auipc	a0,0x3
    80005fe8:	90450513          	addi	a0,a0,-1788 # 800088e8 <syscall_names+0x318>
    80005fec:	ffffa097          	auipc	ra,0xffffa
    80005ff0:	552080e7          	jalr	1362(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ff4:	00003517          	auipc	a0,0x3
    80005ff8:	91450513          	addi	a0,a0,-1772 # 80008908 <syscall_names+0x338>
    80005ffc:	ffffa097          	auipc	ra,0xffffa
    80006000:	542080e7          	jalr	1346(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006004:	00003517          	auipc	a0,0x3
    80006008:	92450513          	addi	a0,a0,-1756 # 80008928 <syscall_names+0x358>
    8000600c:	ffffa097          	auipc	ra,0xffffa
    80006010:	532080e7          	jalr	1330(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006014:	00003517          	auipc	a0,0x3
    80006018:	93450513          	addi	a0,a0,-1740 # 80008948 <syscall_names+0x378>
    8000601c:	ffffa097          	auipc	ra,0xffffa
    80006020:	522080e7          	jalr	1314(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006024:	00003517          	auipc	a0,0x3
    80006028:	94450513          	addi	a0,a0,-1724 # 80008968 <syscall_names+0x398>
    8000602c:	ffffa097          	auipc	ra,0xffffa
    80006030:	512080e7          	jalr	1298(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006034:	00003517          	auipc	a0,0x3
    80006038:	95450513          	addi	a0,a0,-1708 # 80008988 <syscall_names+0x3b8>
    8000603c:	ffffa097          	auipc	ra,0xffffa
    80006040:	502080e7          	jalr	1282(ra) # 8000053e <panic>

0000000080006044 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006044:	7119                	addi	sp,sp,-128
    80006046:	fc86                	sd	ra,120(sp)
    80006048:	f8a2                	sd	s0,112(sp)
    8000604a:	f4a6                	sd	s1,104(sp)
    8000604c:	f0ca                	sd	s2,96(sp)
    8000604e:	ecce                	sd	s3,88(sp)
    80006050:	e8d2                	sd	s4,80(sp)
    80006052:	e4d6                	sd	s5,72(sp)
    80006054:	e0da                	sd	s6,64(sp)
    80006056:	fc5e                	sd	s7,56(sp)
    80006058:	f862                	sd	s8,48(sp)
    8000605a:	f466                	sd	s9,40(sp)
    8000605c:	f06a                	sd	s10,32(sp)
    8000605e:	ec6e                	sd	s11,24(sp)
    80006060:	0100                	addi	s0,sp,128
    80006062:	8aaa                	mv	s5,a0
    80006064:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006066:	00c52d03          	lw	s10,12(a0)
    8000606a:	001d1d1b          	slliw	s10,s10,0x1
    8000606e:	1d02                	slli	s10,s10,0x20
    80006070:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006074:	0001c517          	auipc	a0,0x1c
    80006078:	03450513          	addi	a0,a0,52 # 800220a8 <disk+0x128>
    8000607c:	ffffb097          	auipc	ra,0xffffb
    80006080:	ba4080e7          	jalr	-1116(ra) # 80000c20 <acquire>
  for(int i = 0; i < 3; i++){
    80006084:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006086:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006088:	0001cb97          	auipc	s7,0x1c
    8000608c:	ef8b8b93          	addi	s7,s7,-264 # 80021f80 <disk>
  for(int i = 0; i < 3; i++){
    80006090:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006092:	0001cc97          	auipc	s9,0x1c
    80006096:	016c8c93          	addi	s9,s9,22 # 800220a8 <disk+0x128>
    8000609a:	a08d                	j	800060fc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000609c:	00fb8733          	add	a4,s7,a5
    800060a0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060a4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060a6:	0207c563          	bltz	a5,800060d0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060aa:	2905                	addiw	s2,s2,1
    800060ac:	0611                	addi	a2,a2,4
    800060ae:	05690c63          	beq	s2,s6,80006106 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060b2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060b4:	0001c717          	auipc	a4,0x1c
    800060b8:	ecc70713          	addi	a4,a4,-308 # 80021f80 <disk>
    800060bc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060be:	01874683          	lbu	a3,24(a4)
    800060c2:	fee9                	bnez	a3,8000609c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060c4:	2785                	addiw	a5,a5,1
    800060c6:	0705                	addi	a4,a4,1
    800060c8:	fe979be3          	bne	a5,s1,800060be <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060cc:	57fd                	li	a5,-1
    800060ce:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060d0:	01205d63          	blez	s2,800060ea <virtio_disk_rw+0xa6>
    800060d4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060d6:	000a2503          	lw	a0,0(s4)
    800060da:	00000097          	auipc	ra,0x0
    800060de:	cfc080e7          	jalr	-772(ra) # 80005dd6 <free_desc>
      for(int j = 0; j < i; j++)
    800060e2:	2d85                	addiw	s11,s11,1
    800060e4:	0a11                	addi	s4,s4,4
    800060e6:	ffb918e3          	bne	s2,s11,800060d6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060ea:	85e6                	mv	a1,s9
    800060ec:	0001c517          	auipc	a0,0x1c
    800060f0:	eac50513          	addi	a0,a0,-340 # 80021f98 <disk+0x18>
    800060f4:	ffffc097          	auipc	ra,0xffffc
    800060f8:	fb6080e7          	jalr	-74(ra) # 800020aa <sleep>
  for(int i = 0; i < 3; i++){
    800060fc:	f8040a13          	addi	s4,s0,-128
{
    80006100:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006102:	894e                	mv	s2,s3
    80006104:	b77d                	j	800060b2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006106:	f8042583          	lw	a1,-128(s0)
    8000610a:	00a58793          	addi	a5,a1,10
    8000610e:	0792                	slli	a5,a5,0x4

  if(write)
    80006110:	0001c617          	auipc	a2,0x1c
    80006114:	e7060613          	addi	a2,a2,-400 # 80021f80 <disk>
    80006118:	00f60733          	add	a4,a2,a5
    8000611c:	018036b3          	snez	a3,s8
    80006120:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006122:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006126:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000612a:	f6078693          	addi	a3,a5,-160
    8000612e:	6218                	ld	a4,0(a2)
    80006130:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006132:	00878513          	addi	a0,a5,8
    80006136:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006138:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000613a:	6208                	ld	a0,0(a2)
    8000613c:	96aa                	add	a3,a3,a0
    8000613e:	4741                	li	a4,16
    80006140:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006142:	4705                	li	a4,1
    80006144:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006148:	f8442703          	lw	a4,-124(s0)
    8000614c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006150:	0712                	slli	a4,a4,0x4
    80006152:	953a                	add	a0,a0,a4
    80006154:	058a8693          	addi	a3,s5,88
    80006158:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000615a:	6208                	ld	a0,0(a2)
    8000615c:	972a                	add	a4,a4,a0
    8000615e:	40000693          	li	a3,1024
    80006162:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006164:	001c3c13          	seqz	s8,s8
    80006168:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000616a:	001c6c13          	ori	s8,s8,1
    8000616e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006172:	f8842603          	lw	a2,-120(s0)
    80006176:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000617a:	0001c697          	auipc	a3,0x1c
    8000617e:	e0668693          	addi	a3,a3,-506 # 80021f80 <disk>
    80006182:	00258713          	addi	a4,a1,2
    80006186:	0712                	slli	a4,a4,0x4
    80006188:	9736                	add	a4,a4,a3
    8000618a:	587d                	li	a6,-1
    8000618c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006190:	0612                	slli	a2,a2,0x4
    80006192:	9532                	add	a0,a0,a2
    80006194:	f9078793          	addi	a5,a5,-112
    80006198:	97b6                	add	a5,a5,a3
    8000619a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000619c:	629c                	ld	a5,0(a3)
    8000619e:	97b2                	add	a5,a5,a2
    800061a0:	4605                	li	a2,1
    800061a2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061a4:	4509                	li	a0,2
    800061a6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800061aa:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061ae:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800061b2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061b6:	6698                	ld	a4,8(a3)
    800061b8:	00275783          	lhu	a5,2(a4)
    800061bc:	8b9d                	andi	a5,a5,7
    800061be:	0786                	slli	a5,a5,0x1
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800061c6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061ca:	6698                	ld	a4,8(a3)
    800061cc:	00275783          	lhu	a5,2(a4)
    800061d0:	2785                	addiw	a5,a5,1
    800061d2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061d6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061da:	100017b7          	lui	a5,0x10001
    800061de:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061e2:	004aa783          	lw	a5,4(s5)
    800061e6:	02c79163          	bne	a5,a2,80006208 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800061ea:	0001c917          	auipc	s2,0x1c
    800061ee:	ebe90913          	addi	s2,s2,-322 # 800220a8 <disk+0x128>
  while(b->disk == 1) {
    800061f2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061f4:	85ca                	mv	a1,s2
    800061f6:	8556                	mv	a0,s5
    800061f8:	ffffc097          	auipc	ra,0xffffc
    800061fc:	eb2080e7          	jalr	-334(ra) # 800020aa <sleep>
  while(b->disk == 1) {
    80006200:	004aa783          	lw	a5,4(s5)
    80006204:	fe9788e3          	beq	a5,s1,800061f4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006208:	f8042903          	lw	s2,-128(s0)
    8000620c:	00290793          	addi	a5,s2,2
    80006210:	00479713          	slli	a4,a5,0x4
    80006214:	0001c797          	auipc	a5,0x1c
    80006218:	d6c78793          	addi	a5,a5,-660 # 80021f80 <disk>
    8000621c:	97ba                	add	a5,a5,a4
    8000621e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006222:	0001c997          	auipc	s3,0x1c
    80006226:	d5e98993          	addi	s3,s3,-674 # 80021f80 <disk>
    8000622a:	00491713          	slli	a4,s2,0x4
    8000622e:	0009b783          	ld	a5,0(s3)
    80006232:	97ba                	add	a5,a5,a4
    80006234:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006238:	854a                	mv	a0,s2
    8000623a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000623e:	00000097          	auipc	ra,0x0
    80006242:	b98080e7          	jalr	-1128(ra) # 80005dd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006246:	8885                	andi	s1,s1,1
    80006248:	f0ed                	bnez	s1,8000622a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000624a:	0001c517          	auipc	a0,0x1c
    8000624e:	e5e50513          	addi	a0,a0,-418 # 800220a8 <disk+0x128>
    80006252:	ffffb097          	auipc	ra,0xffffb
    80006256:	a82080e7          	jalr	-1406(ra) # 80000cd4 <release>
}
    8000625a:	70e6                	ld	ra,120(sp)
    8000625c:	7446                	ld	s0,112(sp)
    8000625e:	74a6                	ld	s1,104(sp)
    80006260:	7906                	ld	s2,96(sp)
    80006262:	69e6                	ld	s3,88(sp)
    80006264:	6a46                	ld	s4,80(sp)
    80006266:	6aa6                	ld	s5,72(sp)
    80006268:	6b06                	ld	s6,64(sp)
    8000626a:	7be2                	ld	s7,56(sp)
    8000626c:	7c42                	ld	s8,48(sp)
    8000626e:	7ca2                	ld	s9,40(sp)
    80006270:	7d02                	ld	s10,32(sp)
    80006272:	6de2                	ld	s11,24(sp)
    80006274:	6109                	addi	sp,sp,128
    80006276:	8082                	ret

0000000080006278 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006278:	1101                	addi	sp,sp,-32
    8000627a:	ec06                	sd	ra,24(sp)
    8000627c:	e822                	sd	s0,16(sp)
    8000627e:	e426                	sd	s1,8(sp)
    80006280:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006282:	0001c497          	auipc	s1,0x1c
    80006286:	cfe48493          	addi	s1,s1,-770 # 80021f80 <disk>
    8000628a:	0001c517          	auipc	a0,0x1c
    8000628e:	e1e50513          	addi	a0,a0,-482 # 800220a8 <disk+0x128>
    80006292:	ffffb097          	auipc	ra,0xffffb
    80006296:	98e080e7          	jalr	-1650(ra) # 80000c20 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000629a:	10001737          	lui	a4,0x10001
    8000629e:	533c                	lw	a5,96(a4)
    800062a0:	8b8d                	andi	a5,a5,3
    800062a2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062a4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062a8:	689c                	ld	a5,16(s1)
    800062aa:	0204d703          	lhu	a4,32(s1)
    800062ae:	0027d783          	lhu	a5,2(a5)
    800062b2:	04f70863          	beq	a4,a5,80006302 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062b6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062ba:	6898                	ld	a4,16(s1)
    800062bc:	0204d783          	lhu	a5,32(s1)
    800062c0:	8b9d                	andi	a5,a5,7
    800062c2:	078e                	slli	a5,a5,0x3
    800062c4:	97ba                	add	a5,a5,a4
    800062c6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062c8:	00278713          	addi	a4,a5,2
    800062cc:	0712                	slli	a4,a4,0x4
    800062ce:	9726                	add	a4,a4,s1
    800062d0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062d4:	e721                	bnez	a4,8000631c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062d6:	0789                	addi	a5,a5,2
    800062d8:	0792                	slli	a5,a5,0x4
    800062da:	97a6                	add	a5,a5,s1
    800062dc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062de:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062e2:	ffffc097          	auipc	ra,0xffffc
    800062e6:	e2c080e7          	jalr	-468(ra) # 8000210e <wakeup>

    disk.used_idx += 1;
    800062ea:	0204d783          	lhu	a5,32(s1)
    800062ee:	2785                	addiw	a5,a5,1
    800062f0:	17c2                	slli	a5,a5,0x30
    800062f2:	93c1                	srli	a5,a5,0x30
    800062f4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062f8:	6898                	ld	a4,16(s1)
    800062fa:	00275703          	lhu	a4,2(a4)
    800062fe:	faf71ce3          	bne	a4,a5,800062b6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006302:	0001c517          	auipc	a0,0x1c
    80006306:	da650513          	addi	a0,a0,-602 # 800220a8 <disk+0x128>
    8000630a:	ffffb097          	auipc	ra,0xffffb
    8000630e:	9ca080e7          	jalr	-1590(ra) # 80000cd4 <release>
}
    80006312:	60e2                	ld	ra,24(sp)
    80006314:	6442                	ld	s0,16(sp)
    80006316:	64a2                	ld	s1,8(sp)
    80006318:	6105                	addi	sp,sp,32
    8000631a:	8082                	ret
      panic("virtio_disk_intr status");
    8000631c:	00002517          	auipc	a0,0x2
    80006320:	68450513          	addi	a0,a0,1668 # 800089a0 <syscall_names+0x3d0>
    80006324:	ffffa097          	auipc	ra,0xffffa
    80006328:	21a080e7          	jalr	538(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
