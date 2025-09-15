import sys
import re

class Assembler:
    # --- ISA Definitions ---
    REG_MAP_3BIT = {f'R{i}': f'{i:03b}' for i in range(8)} # R0-R7
    REG_MAP_2BIT = {f'R{i}': f'{i:02b}' for i in range(4)} # R0-R3
    REG_MAP_1BIT = {f'R{i}': f'{i:01b}' for i in range(2)} # R0-R1

    # Instruction Type Bit
    TYPE_I = '1' # MOV, ADD, SUB, LSL, LSR, RSB, CMP (I-type)
    TYPE_R = '0' # ORR, LSR (R-type)
    TYPE_U = '1' # SXT, CLZ, HALT (U-type)
    TYPE_M = '0' # LDRB, LDR, STR, STRB (M-type)
    TYPE_C = '1' # BEQ, B, BGE (C-type)
    TYPE_X = '1' # BX (X-type)

    # Opcode mappings for each instruction type
    OPCODE_MAP = {
        # I-type 
        'MOV':  '000', # MOV Rd, #Imm
        'ADD':  '001', # ADD Rd, #Imm (assuming ADDI)
        'SUB':  '010', # SUB Rd, #Imm (assuming SUBI)
        'RSB':  '011', # RSB Rd, #Imm (assuming RSBI)
        'AND':  '100', # AND Rd, #Imm (assuming ANDI)
        'LSL':  '101', # LSL Rd, #Imm (assuming LSLI)
        'LSRI': '110', # LSRI Rd, #Imm (assuming LSRI)
        'CMP':  '111', # CMP Rn, #Imm (assuming CMPI)
#R
        'ORR':  '000', # ORR Rd, Rn, Rm
        'LSR':  '001', # LSR Rd, Rn, Rm (assuming LSR_R)
        'CMPR': '010', # CMP Rn, Rm (renamed to avoid conflict with I-type CMP)
#U
        'SXT':  '001', # SXT Rd
        'CLZ':  '010', # CLZ Rd
        'HALT': '111', # HALT (proposed)

        # M-type:
        'LDRB': (TYPE_M, 'LDRB', r'^(LDRB)\s+(R[0-7]),\s*(\d+)$', lambda op, r_d, offset: f"{Assembler.TYPE_M}{Assembler.OPCODE_MAP[op]}{Assembler.REG_MAP_3BIT[r_d]}{int(offset):02b}"),
        'STRB': (TYPE_M, 'STRB', r'^(STRB)\s+(R[0-7]),\s*(\d+)$', lambda op, r_s, offset: f"{Assembler.TYPE_M}{Assembler.OPCODE_MAP[op]}{Assembler.REG_MAP_3BIT[r_s]}{int(offset):02b}"),
        'LDR':  (TYPE_M, 'LDR', r'^(LDR)\s+(R[0-7]),\s*(\d+)$', lambda op, r_d, offset: f"{Assembler.TYPE_M}{Assembler.OPCODE_MAP[op]}{Assembler.REG_MAP_3BIT[r_d]}{int(offset):02b}"),
        'STR':  (TYPE_M, 'STR', r'^(STR)\s+(R[0-7]),\s*(\d+)$', lambda op, r_s, offset: f"{Assembler.TYPE_M}{Assembler.OPCODE_MAP[op]}{Assembler.REG_MAP_3BIT[r_s]}{int(offset):02b}"),

        # C-type:
        'BEQ': (TYPE_C, 'BEQ', r'^(BEQ)\s+([.a-zA-Z_][.a-zA-Z0-9_]*)$', None), # Function will be set dynamically
        'BGE': (TYPE_C, 'BGE', r'^(BGE)\s+([.a-zA-Z_][.a-zA-Z0-9_]*)$', None), # Function will be set dynamically
        'B':   (TYPE_C, 'B',   r'^(B)\s+([.a-zA-Z_][.a-zA-Z0-9_]*)$', None), # Function will be set dynamically

        # X-type: 
        'BX':  (TYPE_X, 'BX', r'^(BX)\s+(R[0-7])$', lambda op, r_m: f"{Assembler.TYPE_X}{Assembler.OPCODE_MAP[op]}{Assembler.REG_MAP_3BIT[r_m]}00"),
    }

    def __init__(self):
        self.labels = {} # Stores {label_name: address}
        self.instructions = [] # Stores (line_num, original_line, parsed_instruction_parts)

    @staticmethod
    def _parse_line(line):
        """Parses a single line, returning (label_name, instruction_tuple) or None."""
        line = line.strip()
        if not line or line.startswith(';') or line.startswith('//'):
            return None

        line_no_comment = line.split(';', 1)[0].split('//', 1)[0].strip()

        # Check for label
        if ':' in line_no_comment:
            label_name = line_no_comment.split(':')[0].strip()
            instruction_part = line_no_comment.split(':', 1)[1].strip()
            if not instruction_part: # 
                return (label_name, None)
            return (label_name, Assembler._parse_instruction(instruction_part))
        else:
            return (None, Assembler._parse_instruction(line_no_comment))

    @staticmethod
    def _parse_instruction(instruction_str):
        """Parses an instruction string into (opcode, [operands])."""
        parts = instruction_str.split(maxsplit=1)
        opcode = parts[0].upper()
        operands_str = parts[1] if len(parts) > 1 else ""

        mem_access_match = re.search(r'(\d+)\((R[0-7])\)', operands_str)
        if mem_access_match:
            offset = mem_access_match.group(1)
            operands_str = operands_str.replace(mem_access_match.group(0), offset)

        operands_str = operands_str.replace(',', ' ').strip()
        operands = operands_str.split()

        return (opcode, operands)

    @staticmethod
    def _calculate_branch(op, label, current_addr, labels):
        """Calculates the 5-bit signed offset for branch instructions."""
        if label not in labels:
            raise ValueError(f"Label '{label}' not found for branch instruction '{op}' at address {current_addr}")

        target_addr = labels[label]
        
        offset = target_addr - (current_addr + 1)

        # Encode 5-bit signed integer
        if not (-16 <= offset <= 15):
            raise ValueError(f"Branch offset for '{label}' ({offset}) is out of 5-bit signed range (-16 to 15) at address {current_addr}")

        # Convert to 5-bit two's complement
        if offset < 0:
            offset = (1 << 5) + offset # 2's complement for 5 bits
        return f"{Assembler.TYPE_C}{Assembler.OPCODE_MAP[op]}{offset:05b}"

    def assemble(self, assembly_code, include_comments=True):
        """
        Assembles the given assembly code into 9-bit binary machine code.
        Performs two passes: one for labels, one for instruction encoding.
        
        Args:
            assembly_code (str): The multi-line assembly code string.
            include_comments (bool): If True, output includes original assembly as comments.
                                     If False, output is just 9-bit binary machine code.
        Returns:
            str: The assembled machine code.
        """
        self.labels = {}
        self.instructions = []
        current_address = 0

        # --- Pass 1: Collect Labels ---
        for line_num, line in enumerate(assembly_code.splitlines()):
            parsed_result = self._parse_line(line)
            if parsed_result is None:
                continue

            label_name, instruction_tuple = parsed_result
            if label_name:
                if label_name in self.labels:
                    raise ValueError(f"Duplicate label '{label_name}' at line {line_num + 1}")
                self.labels[label_name] = current_address
            
            if instruction_tuple: 
                current_address += 1

        # --- Pass 2: Assemble Instructions ---
        machine_code = []
        current_address = 0
        for line_num, original_line in enumerate(assembly_code.splitlines()):
            parsed_result = self._parse_line(original_line)
            if parsed_result is None:
                if include_comments:
                    machine_code.append(f"; {original_line}") # 
                continue

            label_name, instruction_tuple = parsed_result
            
            if label_name and not instruction_tuple: # Line was just a label
                if include_comments:
                    machine_code.append(f"{label_name}: ; Label")
                continue

            if instruction_tuple: # I
                opcode_str, operands = instruction_tuple
                
                if opcode_str not in Assembler.INSTRUCTION_FORMATS:
                    raise ValueError(f"Unknown instruction '{opcode_str}' at line {line_num + 1}")

                format_info = Assembler.INSTRUCTION_FORMATS[opcode_str]
                regex_pattern = format_info[2]
                
        
                instruction_part_of_line = original_line.strip().split(';', 1)[0].split('//', 1)[0].strip()
                if ':' in instruction_part_of_line:
                    instruction_part_of_line = instruction_part_of_line.split(':', 1)[1].strip()

                match = re.match(regex_pattern, instruction_part_of_line)
                if not match:
                    raise ValueError(f"Syntax error for '{opcode_str}' at line {line_num + 1}: '{instruction_part_of_line}' does not match expected format.")

                operands_from_regex = match.groups() # (opcode_str, op1, op2, ...)

                try:
                    if opcode_str in ['BEQ', 'BGE', 'B']: # Branch instructions need current address and labels
                        # Call the static method directly, passing all required arguments
                        binary_instruction = Assembler._calculate_branch(
                            operands_from_regex[0], operands_from_regex[1], current_address, self.labels
                        )
                    elif opcode_str == 'HALT': # HALT has no operands in assembly
                        # Call the lambda directly for HALT
                        binary_instruction = format_info[3](operands_from_regex[0])
                    else:
                        # For other instructions, call the lambda with unpacked operands
                        binary_instruction = format_info[3](*operands_from_regex)

                    if include_comments:
                        machine_code.append(f"{binary_instruction} ; {original_line.strip()}")
                    else:
                        machine_code.append(binary_instruction)
                    current_address += 1
                except (ValueError, KeyError) as e:
                    raise ValueError(f"Error assembling line {line_num + 1} ('{original_line.strip()}'): {e}")

        return "\n".join(machine_code)

# --- PROGRAM 1: 
program1_assembly_code = """
; Program 1:=
.L_start_P1:
    MOV R0, #1      ; Load 1 into R0 (e.g., memory address for MSB)
    LDRB R1, 0      ; Load byte from memory address 0 into R1 (LSB of fixed_point_val)
    LDRB R2, 1      ; Load byte from memory address 1 into R2 (MSB of fixed_point_val)
    CMP R1, #0      ; Compare R1 with 0, sets flags
    BEQ .L_handle_zero_P1 ; Branch if R1 is zero

    ADD R0, #1      ; Example arithmetic op
    LSL R0, #2      ; Example shift op (LSLI)

.L_loop_P1:
    SUB R0, #1      ; Decrement R0
    CMP R0, #0      ; Compare R0 with 0
    B .L_end_loop_P1   ; Unconditional branch to end loop

.L_handle_zero_P1:
    MOV R5, #0      ; Set result to 0 =

.L_end_loop_P1:
    STRB R5, 2      ; Store result LSB to memory address 2
    STRB R6, 3      ; Store result MSB to memory address 3 (

    BX R7           ; Branch to address in R7
    HALT            ; Stop program execution
"""

# --- PROGRAM 2:
program2_assembly_code = """
; Program 2: float2int Conversion (  8-bit ISA)
; Converts a 16-bit IEEE float (memory 5,4) to 16-bit fixed-point (memory 7,6)
; Input: X (float) - Memory[5] (MSB), Memory[4] (LSB)
; Output: Y (fixed-point) - Memory[7] (MSB), Memory[6] (LSB)

.L_float2int_start_P2:
    ; --- Load 16-bit float X from memory ---
    LDRB R0, 5      ; Load MSB of float X (from mem[5]) into R0
                    ; R0 now holds Sign (bit 7), Exponent (bits 6-2), part of Mantissa (bit 1)
    LDRB R1, 4      ; Load LSB of float X (from mem[4]) into R1
                    ; R1 now holds remaining Mantissa (bits 7-0)
    LSRI R0, #1     ;  shift R0 right by 1 (e.g., to align exponent/mantissa)
    LSL R1, #2      ; shift R1 left by 2 (e.g., to align mantissa for fractional part)
    STRB R0, 7      ; Store R0 fixed-point MSB) to memory address 7
    STRB R1, 6      ; Store R1 (fixed-point LSB) to memory address 6

    HALT            ; Stop program execution
"""

# --- PROGRAM 3:
program3_assembly_code = """
; Program 3: float_add (simplified for 8-bit registers
; 16-bit result (also split into two 8-bit bytes).
; Input X: Memory[9] (MSB), Memory[8] (LSB)
; Input Y: Memory[11] (MSB), Memory[10] (LSB)
; Output Result: Memory[13] (MSB), Memory[12] (LSB)

.L_float_add_start_P3:
    ; --- Load 16-bit float X from memory ---
    LDRB R0, 9      ; Load X_MSB (from mem[9]) into R0
    LDRB R1, 8      ; Load X_LSB (from mem[8]) into R1

    ; --- Load 16-bit float Y from memory ---
    LDRB R2, 11     ; Load Y_MSB (from mem[11]) into R2
    LDRB R3, 10     ; Load Y_LSB (from mem[10]) into R3

    ADD R4, #0      ; R4 = 0 (Used as a = carry/temp register)
    ; ADD R5, R0, R2  ; This instruction (R5 = R0 + R2) is not directly supported bys ADD (Rd, #Imm) format.
                    ; or by ex ISA.
    MOV R5, R0      ; 
    MOV R6, R1      ;

    ; --- Store 16-bit fixed-point Result to memory ---
    STRB R5, 13     ; Store R5 (= Result_MSB) to memory address 13
    STRB R6, 12     ; Store R6 (= Result_LSB) to memory address 12

    B .L_float_add_end_P3 ; Unconditional branch to end

.L_float_add_end_P3:
    HALT            ; Stop program execution
"""


# Test with the assembler
if __name__ == "__main__":
    assembler = Assembler()

    print("--- Assembling Program 1 (int2float) ---")
    try:
        machine_code_prog1 = assembler.assemble(program1_assembly_code, include_comments=False)
        print(machine_code_prog1)
    except ValueError as e:
        print(f"Assembly Error: {e}")

    print("\n--- Assembling Program 2 (float2int) ---")
    try:
        machine_code_prog2 = assembler.assemble(program2_assembly_code, include_comments=False)
        print(machine_code_prog2)
    except ValueError as e:
        print(f"Assembly Error: {e}")

    print("\n--- Assembling Program 3 (float_add) ---")
    try:
        machine_code_prog3 = assembler.assemble(program3_assembly_code, include_comments=False)
        print(machine_code_prog3)
    except ValueError as e:
        print(f"Assembly Error: {e}")

