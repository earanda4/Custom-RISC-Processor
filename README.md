# Custom-RISC-Processor
The custom processor is designed as a 9-bit ISA and supports essential core arithmetic, memory, and control operations. Using load/store architecture, data manipulation occurs on values within registers with instructions for moving data between registers and memory.t
Machine Type: 9-bit ISA, Load/Store Architecture.
Instruction Length: All instructions are a fixed 9 bits in length.
Number of Registers: It features 8 general-purpose registers (R0-R7), each capable of storing 8 bits of data. This 8-bit data path is a fundamental characteristic influencing all operations.
Instruction Formats and Bit Breakdowns: The ISA defines several instruction types, each with a specific 9-bit breakdown:
TYPE
FORMAT
CORRESPONDING INSTRUCTIONS
I


1 bit Type, 3 bits Opcode , 3 bits Rd, 2 bits Immediate
MOV, ADD, SUB, LSL, LSR, RSB, CMP


R


1 bit Type, 3 bits Opcode, 2 bits Rd , 2 bits Rn, 1 bit Rm 
ORR, LSR
U
1 bit Type , 3 bits Opcode , 3 bits Rd , 2 bits Unused 


SXT, CLZ, HALT 
M
1 bit Type, 3 bits Opcode , 3 bits Rd , 2 bits Offset 
LDRB, LDR, STR, STRB 
C
1 bit Type , 3 bits Opcode , 5 bits Address/Offset 


BEQ, B, BGE
X
1 bit Type, 3 bits Opcode , 5 bits Address/Offset 
BX 




Branching Logic:
PC-relative branches (BEQ, BGE, B): The target address is calculated by adding a signed 5-bit offset (from the instruction) to the current Program Counter (PC). This allows jumps within a limited range.
Indirect branch (BX): The target address is loaded directly from a specified register (Rm). Used to jump to dynamically calculated addresses.
Operations:




NAME
TYPE


BIT BREAKDOWN



EXAMPLE
NOTES


MOV, move immediate to register
I
1 bit Type (1), 3 bits Opcode (000), 3 bits Rd (XXX), 2 bits Immediate (XX)
MOV R0, #2 ⇔ 1_000_000_10 (R0 = 2)
Rd is the destination register (R0-R7). Immediate values are 0-3.


ADDI, add immediate to register
I
1 bit Type (1), 3 bits Opcode (001), 3 bits Rd (XXX), 2 bits Immediate (XX)
ADD R0, R1, #3 ⇔ 1_001_000_11 (R0 = R1 + 3)
Rd is destination, Rn (R1 in example) is implied to be Rd or a fixed register for this simple format. The actual operation is Rd = Rd + Imm. Immediate values are 0-3.


SUBI, subtract immediate from register
I
1 bit Type (1), 3 bits Opcode (010), 3 bits Rd (XXX), 2 bits Immediate (XX)
SUB R0, R1, #1 ⇔ 1_010_000_01 (R0 = R1 - 1)
Rd is destination. Rd = Rd - Imm. Immediate values are 0-3.


RSBI, reverse subtract immediate
I
1 bit Type (1), 3 bits Opcode (011), 3 bits Rd (XXX), 2 bits Immediate (XX)
RSB R0, R1, #0 ⇔ 1_011_000_00 (R0 = 0 - R1)
Rd is destination. Rd = Imm - Rd. Immediate values are 0-3.


ANDI, logical AND with immediate
I
1 bit Type (1), 3 bits Opcode (100), 3 bits Rd (XXX), 2 bits Immediate (XX)
AND R0, R1, #3 ⇔ 1_100_000_11 (R0 = R1 & 3)
Rd is destination. Rd = Rd & Imm. Immediate values are 0-3.


LSLI,  logical shift left by immediate
I
1 bit Type (1), 3 bits Opcode (101), 3 bits Rd (XXX), 2 bits Immediate (XX)
LSL R0, R1, #2 ⇔ 1_101_000_10 (R0 = R1 << 2)
Rd is destination. Rd = Rd \<\< Imm. Shift amount is the immediate (0-3).


LSRI, logical shift right by immediate
I
1 bit Type (1), 3 bits Opcode (110), 3 bits Rd (XXX), 2 bits Immediate (XX)
LSR R0, R1, #1 ⇔ 1_110_000_01 (R0 = R1 >> 1)
Rd is destination. Rd = Rd \>\> Imm. Shift amount is the immediate (0-3).


CMPI, compare with immediate
I
1 bit Type (1), 3 bits Opcode (111), 3 bits Rn (XXX), 2 bits Immediate (XX)
CMP R0, #0 ⇔ 1_111_000_00 (Compares R0 with 0, sets flags)
Rn is the register operand (R0-R7). No destination register.


ORR, logical OR
R
1 bit Type (0), 3 bits Opcode (000), 2 bits Rd (XX), 2 bits Rn (XX), 1 bit Rm (X)
ORR R2, R0, R1 ⇔ 0_000_10_00_1 (R2 = R0 | R1)
Rd is destination (R0-R3). Rn is first operand (R0-R3). Rm is second operand (R0-R1). This fits a 9-bit scheme.


LSR, logical shift right by register
R
1 bit Type (0), 3 bits Opcode (001), 2 bits Rd (XX), 2 bits Rn (XX), 1 bit Rm (X)
LSR R2, R0, R1 ⇔ 0_001_10_00_1 (R2 = R0 >> R1)
Rm contains the shift amount. Same register encoding limitations.


CMP, compare registers
R
1 bit Type (0), 3 bits Opcode (010), 2 bits Unused (00), 2 bits Rn (XX), 1 bit Rm (X)
CMP R0, R1 ⇔ 0_010_00_00_1 (Compares R0 and R1, sets flags)
No destination, so 2 bits for Rd are unused. Rn and Rm are operands.


SXT, sign extend
U
1 bit Type (1), 3 bits Opcode (001), 3 bits Rd (000), 2 bits Unused (00)
SXT R0 ⇔ 1_001_000_00 (R0 = sign-extended R0)
Rd is both source and destination (R0-R7). The 2 unused bits are 00.


CLZ,  count leading zeros
U
1 bit Type (1), 3 bits Opcode (010), 3 bits Rd (000), 2 bits Unused (00)
CLZ R0 ⇔ 1_010_000_00 (R0 = count of leading zeros in R0)
Rd is both source and destination (R0-R7). The 2 unused bits are 00.


HALT, raises done flag
U
1 bit Type (1), 3 bits Opcode (111), 3 bits Rd (000), 2 bits Unused (00)
HALT ⇒ 1_111_000_00 
Rd is both source and destination (R0-R7). 2 unused bits are 00.


LDRB,  load byte from memory
M
1 bit Type (0), 3 bits Opcode (000), 3 bits Rd (XXX), 2 bits Offset (XX)
LDRB R0, 0(R4) ⇔ 0_000_000_00 (R0 = memory[R4 + 0])
Rd is destination (R0-R7). Offset is 2 bits (0-3). Rn (base register, e.g., R4 for memory array) is implied or specified by opcode variant.


STRB, store byte to memory
M
1 bit Type (0), 3 bits Opcode (001), 3 bits Rs (XXX), 2 bits Offset (XX)
STRB R0, 2(R4) ⇔ 0_001_000_10 (memory[R4 + 2] = R0)
Rs is source (R0-R7). Offset is 2 bits (0-3). Rn (base register, e.g., R4) is implied.


LDR, load word from memory
M
1 bit Type (0), 3 bits Opcode (010), 3 bits Rd (XXX), 2 bits Offset (XX)
LDR R0, 0(R4) ⇔ 0_010_000_00 (R0 = memory[R4 + 0])
Rd is destination (R0-R7). Offset is 2 bits (0-3). Rn (base register, e.g., R4 or SP) is implied.


STR, store word to memory
M
1 bit Type (0), 3 bits Opcode (011), 3 bits Rs (XXX), 2 bits Offset (XX)
STR R0, 0(R4) ⇔ 0_011_000_00 (memory[R4 + 0] = R0)
Rs is source (R0-R7). Offset is 2 bits (0-3). Rn (base register, e.g., R4 or SP) is implied.


BEQ,  branch if equal
C
1 bit Type (1), 3 bits Opcode (000), 5 bits Address/Offset (XXXXX)
BEQ label ⇔ 1_000_00000 (Branch to relative address 0)
The 5-bit field (0-31) specifies a signed relative offset, allowing 32 different targets (e.g., -16 to +15 instructions).


BGE,  branch if greater or equal
C
1 bit Type (1), 3 bits Opcode (001), 5 bits Address/Offset (XXXXX)
BGE label ⇔ 1_001_00000 (Branch to relative address 0)
The 5-bit field specifies the branch target offset.


B, unconditional branch
C
1 bit Type (1), 3 bits Opcode (010), 5 bits Address/Offset (XXXXX)
B label ⇔ 1_010_00000 (Branch to relative address 0)
The 5-bit field specifies the branch target offset.


BX,  branch and exchange
X
1 bit Type (1), 3 bits Opcode (011), 3 bits Rm (XXX), 2 bits Unused (00)
BX R0 ⇔ 1_011_000_00 (Branch to address in R0)
Rm is source register (R0-R7) containing the target address. The 2 unused bits are 00.




Memory:
Instruction Memory: 12-bit address space (allowing up to 4096 instructions).
Data Memory: 8-bit address space with 8-bit data width.
ALU: An 8-bit ALU that can perform arithmetic, logical, and shift operations. It generates these 4 standard flags: ZeroFlag (result is 0), NegativeFlag (MSB of result is 1), CarryFlag, and OverflowFlag.
