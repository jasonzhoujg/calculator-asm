;这个程序是用来实现计算器的一般功能，包括多位计算以及优先级判断
;整体的处理思想还是按照将此程序分为了三个阶段
;包括输入（以等号为标志一次性读入，然后将符号和数字分开存储在两个数组里）
;乘除法串处理阶段（一是优先进行乘除法，二是对原式进行加减零改造，不改变原来的长度，这是本算法亮点之一）
;加法减法处理阶段（先将第一个数字以及加法后面的数字相加，再把减法后面的数字相加，最后比较大小后相减）

DATA_SEG SEGMENT
	NUMBERS DB 16 DUP(?);数字数组
	SYMBOLS DB 16 DUP(?);符号数组
	N DB 0H;总符号数
	I DB 0H;指针
	X DB 0H;运算中间量
	Y DB 0H;运算中间量
	NE DB 0H;结果正负存储
	LAST DB 0H;中间量
DATA_SEG ENDS 

STACK_SEG SEGMENT STACK
	DB 10 DUP(?)
STACK_SEG ENDS

CODE_SEG SEGMENT
	ASSUME DS:DATA_SEG,SS:STACK_SEG,CS:CODE_SEG
START:MOV AX,DATA_SEG
	MOV DS,AX
	MOV CL,0H
STA1: MOV AH,01H;阶段一 循环读入 以=判断终止条件，分别存储
	INT 21H
	CMP AL,'+'
	JZ SYM
	CMP AL,'-'
	JZ SYM
	CMP AL,'*'
	JZ SYM
	CMP AL,'/'
	JZ SYM
	CMP AL,'='
	JZ STA2
	SUB AL,30H
	LEA BX,NUMBERS
	ADD BL,CL
	MOV [BX],AL
	JMP STA1
SYM: LEA BX,SYMBOLS
	ADD BL,CL
	MOV [BX],AL
	INC CL
	JMP STA1
	
STA2:	MOV DL,0H;阶段二
	MOV N,CL
	LEA BX,SYMBOLS
	MOV CH,0H;决定把乘除改为加还是减号
NEXT:	CMP DL,N
	JZ T
	JMP NEX
T:	JMP STA3
NEX:	MOV AL,DS:[BX];先读取符号数组的符号，进行判断，结束标志是读完所有的符号
	CMP AL,'+'
	JZ LAB1
	CMP AL,'-'
	JZ LAB2
	CMP AL,'*'
	JZ CHENG
	CMP AL,'/'
	JZ CHU
CHENG:TEST CH,1H;乘法执行操作，这里读取符号数组和数字数组实际上是有一个对应关系的，一个符号对应着是前面的数字，所以只是用到了一个指针
	JNZ CHENG1;当上一个非乘除号为加号，则把现在的乘号改成加号；反之，负号同样
	MOV AL,'+'
	JMP CHENG2
CHENG1:MOV AL,'-'
CHENG2:MOV [BX],AL
	MOV AX,0H
	PUSH BX
	LEA BX,NUMBERS
	ADD BL,DL	
	MOV CL,[BX]
	MOV X,CL
	MOV CL,0H
	MOV [BX],CL
	INC BX
	MOV AL,[BX]
	MUL X
	MOV [BX],AL
	POP BX
	JMP LAB3
CHU: TEST CH,1H;除法执行操作；同×号
	JNZ CHU1
	MOV AL,'+'
	JMP CHU2
CHU1:MOV AL,'-'
CHU2:MOV [BX],AL
	PUSH BX
	LEA BX,NUMBERS
	ADD BL,DL	
	MOV CL,[BX]
	MOV X,CL
	MOV CL,0H
	MOV [BX],CL
	INC BX
	MOV AX,0H
	MOV AL,[BX]
	MOV CL,AL
	MOV AL,X
	DIV CL
	MOV [BX],AL
	POP BX
	JMP LAB3

LAB1:	MOV CH,0H;加减无处理，只是往下继续读
	JMP LAB3
LAB2: MOV CH,1H
LAB3:	MOV DL,I
	INC DL
	MOV I,DL
	INC BX
	JMP NEXT
	
STA3: LEA BX, NUMBERS;阶段三
	MOV AL,[BX]
	MOV X,AL
	MOV CX,0H
	MOV CL,N
	MOV DL,0H
LOO:	LEA BX,SYMBOLS;这个循环的作用是把加号后面的数字以及第一个数字加起来，存入X,把减号后的数字加起来，存进Y
	ADD BL,DL
	INC DL
	MOV AL,[BX]
	LEA BX,NUMBERS
	ADD BL,DL
	CMP AL,'+'
	JNZ JIAN
	MOV AL,[BX]
	ADD AL,X
	MOV X,AL
	LOOP LOO
	JMP NEXT2	
JIAN: MOV AL,[BX]
	ADD AL,Y
	MOV Y,AL
	LOOP LOO
	
NEXT2: MOV AL,X;判断X\Y大小，做正数结果的减法，把正负信息存入BL中
	MOV BL,Y
	CMP AL,BL
	JB NEGF 
	SUB AL,BL
	MOV BL,0H
	JMP OUTPUT
NEGF: MOV CL,1H
	MOV NE,CL
	SUB BL,AL
	MOV AL,BL
	MOV BL,1H
OUTPUT:ADD AX,0H

CODE_SEG ENDS
END START