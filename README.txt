# Arty A7-100T 4-bit 64-operation ALU

## Files
- `parameterized_alu_64.v` — combinational 64-op ALU, default width 4.
- `arty_a7_alu64_top.v` — board-level I/O wrapper.
- `arty_a7_alu64.xdc` — pin constraints for Arty A7-100T, `xc7a100tcsg324-1`.

## Physical input mapping
- `SW[3:0]`: operand A.
- `BTN[3:0]`: operand B. Buttons are momentary, so use the buttons while observing results.
- `JA[5:0]`: six-bit opcode, 0–63.
- `JA[6]`: carry input.
- `JA[7]`: borrow input.
- `LED[3:0]`: four-bit result.
- RGB LED 0: blue=carry, green=borrow, red=zero.
- RGB LED 1: green=negative, blue=overflow.

The 8 JA signals require external logic switches or jumper wires to drive valid 0/3.3 V logic levels. Do not connect voltages above 3.3 V to FPGA I/O. If you do not have external switches for JA, use simulation to select all 64 opcodes; the onboard four slide switches alone cannot select a six-bit opcode while also setting both operands.

## Vivado setup
1. Create an RTL project and select `xc7a100tcsg324-1` (or the exact Arty A7-100T board part).
2. Add both `.v` files as design sources.
3. Add `arty_a7_alu64.xdc` as a constraints file.
4. Set `arty_a7_alu64_top` as the top module.
5. Run Synthesis, Implementation, then Generate Bitstream.

64-Operation ALU — Concise Introduction with Examples
A 64-operation Arithmetic Logic Unit (ALU) performs arithmetic, logical, shifting, comparison, and bit-manipulation operations. The 6-bit opcode (op_sel) selects one of the 64 operations. The examples below use 4-bit operands unless otherwise stated.
Assume A = 0101 (5), B = 0011 (3), and carry_in = 1, borrow_in = 1 where applicable.

1. Arithmetic Operations (0–15)
Opcode	Operation	Concise explanation and example
0		ADD			Adds A and B: 5 + 3 = 8 → 1000.
1		SUB			Subtracts B from A: 5 − 3 = 2 → 0010.
2		INC			Increments A by one: 5 + 1 = 6 → 0110.
3		DEC			Decrements A by one: 5 − 1 = 4 → 0100.
4		NEG			Produces the two’s-complement negative of A: −5 → 1011 (4-bit representation).
5		MUL			Multiplies A and B; keeps the lower 4 bits: 5 × 3 = 15 → 1111.
6		DIV			Performs unsigned integer division: 5 ÷ 3 = 1 → 0001.
7		MOD			Returns the unsigned division remainder: 5 % 3 = 2 → 0010.
8		ADC			Adds A, B, and carry-in: 5 + 3 + 1 = 9; lower 4 bits → 1001.
9		SBB			Subtracts B and borrow-in from A: 5 − 3 − 1 = 1 → 0001.
10		SMUL		Multiplies signed operands: 5 × 3 = 15 → 1111 (lower 4 bits).
11		SDIV		Performs signed integer division: −5 ÷ 3 = −1 → 1111 (using signed A = 1011).
12		SMOD		Returns the signed remainder: −5 % 3 = −2 → 1110 (using signed A = 1011).
13		ABS			Returns the absolute value: ABS(−5) = 5 → 0101 (using signed A = 1011).
14		MIN			Selects the smaller operand: MIN(5, 3) = 3 → 0011.
15		MAX			Selects the larger operand: MAX(5, 3) = 5 → 0101.

Note: Signed examples interpret 4-bit values using two’s-complement notation. Division or modulo by zero returns zero in the described ALU.

2. Logical Operations (16–23)

Opcode	Operation	Concise explanation and example
16		AND			Outputs 1 only when both corresponding bits are 1: 0101 & 0011 = 0001.
17		OR			Outputs 1 when either corresponding bit is 1: 0101 \| 0011 = 0111.
18		XOR			Outputs 1 when corresponding bits differ: 0101 ^ 0011 = 0110.
19		NOT			Inverts every bit of A: ~0101 = 1010 (4 bits).
20		NAND		Inverts the AND result: ~(0101 & 0011) = 1110.
21		NOR			Inverts the OR result: ~(0101 \| 0011) = 1000.
22		XNOR		Outputs 1 when corresponding bits match: ~(0101 ^ 0011) = 1001.
23		AND-NOT		ANDs A with the inverted B: 0101 & ~0011 = 0100.

3. Shifting, Rotation and Byte Swap (24–31)
For these examples, use A = 1011 and assume a shift or rotation amount of one bit.

Opcode	Operation	Concise explanation and example
24		SHL			Shifts bits left, inserting 0 at the right: 1011 → 0110 (the leftmost bit is 
                    discarded).
25		SHR			Shifts bits right, inserting 0 at the left: 1011 → 0101.
26		ASR			Arithmetic right shift; copies the sign bit into the leftmost position: 1011 → 1101.
27		ROL			Rotates bits left; the outgoing MSB returns at the right: 1011 → 0111.
28		ROR			Rotates bits right; the outgoing LSB returns at the left: 1011 → 1101.
29		RCL			Rotates left through carry; the old carry enters the LSB and the old MSB becomes
                    carry. For carry-in 0: 1011 → 0110.
30		RCR			Rotates right through carry; the old carry enters the MSB and the old LSB becomes 
                    carry. For carry-in 0: 1011 → 0101.
31	BSWAP			Reverses the order of bytes; for a 32-bit value, 12 34 56 78 → 78 56 34 12. For a 
                    4-bit ALU, this operation returns zero if the code only supports widths divisible by 8.

4. Comparison Operations (32–39)
Comparison operations return 0001 when the condition is true and 0000 when false, according to the ALU implementation.

Opcode	Operation	Concise explanation and example
32		EQ			Tests equality: 5 == 3 → 0000.
33		NE			Tests inequality: 5 != 3 → 0001.
34		UGT			Tests whether A is greater than B as unsigned numbers: 5 > 3 → 0001.
35		ULT			Tests whether A is less than B as unsigned numbers: 5 < 3 → 0000.
36		UGE			Tests whether A is greater than or equal to B unsigned: 5 >= 3 → 0001.
37		ULE			Tests whether A is less than or equal to B unsigned: 5 <= 3 → 0000.
38		SGT			Tests whether signed A is greater than signed B: 5 > 3 → 0001.
39		SLT			Tests whether signed A is less than signed B: 5 < 3 → 0000.

5. Bit Manipulation and Counting (40–47)
Assume A = 0101 and bit positions are numbered from 0 at the rightmost bit.

Opcode	Operation	Concise explanation and example
40		BSET		Sets the selected bit to 1: set bit 1 of 0101 → 0111.
41		BCLR		Clears the selected bit to 0: clear bit 0 of 0101 → 0100.
42		BTGL		Toggles the selected bit: toggle bit 0 of 0101 → 0100.
43		BTST		Tests the selected bit and returns its value: test bit 2 of 0101 → 0001.
44		CLZ			Counts leading zeros: 0011 has 2 leading zeros.
45		CTZ			Counts trailing zeros: 0100 has 2 trailing zeros.
46		POPCNT		Counts the number of 1s: 0101 contains 2 ones.
47		PARITY		Returns the parity of the bits; 0101 has two ones, so its even-parity result is 0.

Note: The exact bit position for BSET, BCLR, BTGL and BTST depends on how the ALU code uses operand B to select the bit.

6. Signed Comparisons and Data Formatting (48–55)

Opcode	Operation	Concise explanation and example
48		SGE			Tests signed greater-than-or-equal: 5 >= 3 → 0001.
49		SLE			Tests signed less-than-or-equal: 5 <= 3 → 0000.
50		SELA		Selects operand A: result = 0101.
51		SELB		Selects operand B: result = 0011.
52		ZERO		Forces the result to all zeros: 0000.
53		ONES		Forces the result to all ones: 1111 for a 4-bit ALU.
54		SIGN		Sign-extends a selected portion of A; for example, extending 101 as a 3-bit signed 
                    value gives 1101 (−3).
55		ZEXT		Zero-extends a smaller value by adding zeros on the left; for example, 3-bit 101 
                    becomes 4-bit 0101.

7. Variable Shifts and Advanced Bit Operations (56–63)

Opcode	Operation	Concise explanation and example
56		LSLV		Shifts A left by the amount specified by B: 0101 << 1 = 1010.
57		LSRV		Shifts A right logically by the amount specified by B: 1010 >> 1 = 0101.
58		ASRV		Shifts A right arithmetically by B, preserving the sign bit: signed 1100 >> 1 = 1110.
59		BITREV		Reverses the order of all bits: 0101 → 1010.
60		BMIN		Alias for MIN in this ALU: selects the smaller operand, MIN(5, 3) = 3.
61		BMAX		Alias for MAX in this ALU: selects the larger operand, MAX(5, 3) = 5.
62		Clear lowest set bit	Clears the rightmost 1: 1100 → 1000.
63		Isolate lowest set bit	Keeps only the rightmost 1: 1100 → 0100.

Important notes
- Opcode width: Six bits select all 64 operations, from 000000 to 111111.
- 4-bit result width: Arithmetic results are truncated to four bits unless a separate status flag 
  captures carry or overflow.
- Signed vs. unsigned: UGT/ULT treat operands as unsigned; SGT/SLT interpret the most significant bit as 
  the two’s-complement sign bit.
- Implementation-specific behavior: Some operation names have conventional meanings, but details such as 
  the bit index source, carry/borrow flag behavior, and unsupported BSWAP widths must match the actual Verilog implementation.

## Notes
- `result` is only `DATA_WIDTH` bits. Multiplication returns the low four bits at width 4.
- Division/modulo by zero return zero.
- BSWAP passes the operand through for widths below one byte.
- BMIN and BMAX are aliases of unsigned MIN and MAX.
- This is a combinational demo and does not need a clock constraint.
