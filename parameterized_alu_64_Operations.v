`timescale 1ns/1ps

//======================================================================
// Project     : 64-Operation Parameterized Arithmetic Logic Unit
// Developer   : Ghulam Yaseen Nangraj
// Date        : 11 October 2026
// Language    : Verilog HDL
// Tool        : Xilinx Vivado
//
// PURPOSE:
//   Perform 64 selectable arithmetic, logic, shift, comparison,
//   and bit-manipulation operations.
//
// DATA WIDTH:
//   DATA_WIDTH can be configured from 1 to 32 bits.
//
// SELECTOR:
//   op_sel is 6 bits wide and selects operation codes 0 through 63.
//
// INPUTS:
//   a          : First operand
//   b          : Second operand or shift/bit index
//   op_sel     : Operation selector
//   carry_in   : Carry input for ADC and rotate-through-carry
//   borrow_in  : Borrow input for SBB
//
// OUTPUTS:
//   result     : Selected operation result
//   carry      : Carry output for supported arithmetic operations
//   borrow     : Borrow output for supported subtraction operations
//   zero       : 1 when result is zero
//   negative   : Copy of the result's most significant bit
//   overflow   : Signed arithmetic overflow for supported operations
//
// IMPORTANT:
//   This is combinational logic. No clock or reset is required.
//   Arithmetic operands are unsigned unless explicitly cast signed.
//======================================================================

module parameterized_alu_64 #(
    parameter DATA_WIDTH = 32
)(
    input  wire [DATA_WIDTH-1:0] a,          // First operand
    input  wire [DATA_WIDTH-1:0] b,          // Second operand
    input  wire [5:0]            op_sel,     // Select one of 64 operations
    input  wire                  carry_in,   // Carry input
    input  wire                  borrow_in,  // Borrow input

    output reg  [DATA_WIDTH-1:0] result,     // Operation result
    output reg                   carry,      // Carry flag
    output reg                   borrow,     // Borrow flag
    output reg                   zero,       // Zero-result flag
    output reg                   negative,   // Most significant result bit
    output reg                   overflow    // Signed overflow flag
);

    // Extra bit preserves the unsigned carry during addition.
    reg [DATA_WIDTH:0] temp;

    // Loop index used by synthesizable bit-manipulation operations.
    integer i;

    // Indicates whether a set bit has been found by CLZ or CTZ.
    reg found;

    // Temporary value used for extended arithmetic calculations.
    reg [DATA_WIDTH:0] extended_b;

    // Recalculate the outputs whenever any input changes.
    always @(*) begin

        // Initialize the result to zero.
        result = {DATA_WIDTH{1'b0}};

        // Initialize all status flags.
        carry    = 1'b0;
        borrow   = 1'b0;
        zero     = 1'b0;
        negative = 1'b0;
        overflow = 1'b0;

        // Clear temporary arithmetic values.
        temp       = {(DATA_WIDTH+1){1'b0}};
        extended_b = {(DATA_WIDTH+1){1'b0}};

        // Clear the bit-search indicator.
        found = 1'b0;

        // Decode the selected operation.
        case (op_sel)

            //==========================================================
            // GROUP 1: ARITHMETIC OPERATIONS (0-15)
            //==========================================================

            6'd0: begin
                // ADD: Calculate unsigned A + B.
                temp   = {1'b0, a} + {1'b0, b};
                result = temp[DATA_WIDTH-1:0];
                carry  = temp[DATA_WIDTH];

                // Detect signed addition overflow.
                overflow =
                    (~(a[DATA_WIDTH-1] ^ b[DATA_WIDTH-1])) &
                     (result[DATA_WIDTH-1] ^ a[DATA_WIDTH-1]);
            end

            6'd1: begin
                // SUB: Calculate unsigned A - B.
                result = a - b;

                // Borrow occurs when unsigned A is less than B.
                borrow = (a < b);

                // Detect signed subtraction overflow.
                overflow =
                    (a[DATA_WIDTH-1] ^ b[DATA_WIDTH-1]) &
                    (result[DATA_WIDTH-1] ^ a[DATA_WIDTH-1]);
            end

            6'd2: begin
                // INC: Increment A by one.
                temp   = {1'b0, a} + {{DATA_WIDTH{1'b0}}, 1'b1};
                result = temp[DATA_WIDTH-1:0];
                carry  = temp[DATA_WIDTH];
            end

            6'd3: begin
                // DEC: Decrement A by one.
                result = a - {{(DATA_WIDTH-1){1'b0}}, 1'b1};

                // Unsigned underflow occurs when A is zero.
                borrow = (a == {DATA_WIDTH{1'b0}});
            end

            6'd4: begin
                // NEG: Calculate two's-complement negation of A.
                result = ~a + {{(DATA_WIDTH-1){1'b0}}, 1'b1};
            end

            6'd5: begin
                // MUL: Multiply unsigned A and B.
                // Keep only the lower DATA_WIDTH result bits.
                result = a * b;
            end

            6'd6: begin
                // DIV: Divide unsigned A by B.
                // Return zero if the divisor is zero.
                if (b != {DATA_WIDTH{1'b0}})
                    result = a / b;
                else
                    result = {DATA_WIDTH{1'b0}};
            end

            6'd7: begin
                // MOD: Calculate unsigned A modulo B.
                // Return zero if the divisor is zero.
                if (b != {DATA_WIDTH{1'b0}})
                    result = a % b;
                else
                    result = {DATA_WIDTH{1'b0}};
            end

            6'd8: begin
                // ADC: Add A, B, and the carry input.
                temp = {1'b0, a} + {1'b0, b} + carry_in;
                result = temp[DATA_WIDTH-1:0];
                carry  = temp[DATA_WIDTH];

                // Detect signed addition overflow, including carry-in.
                overflow =
                    (~(a[DATA_WIDTH-1] ^ b[DATA_WIDTH-1])) &
                     (result[DATA_WIDTH-1] ^ a[DATA_WIDTH-1]);
            end

            6'd9: begin
                // SBB: Subtract B and the borrow input from A.
                extended_b = {1'b0, b} + borrow_in;
                temp = {1'b0, a} - extended_b;
                result = temp[DATA_WIDTH-1:0];

                // Detect unsigned borrow for A - B - borrow_in.
                borrow = ({1'b0, a} < extended_b);

                // Detect signed subtraction overflow.
                overflow =
                    (a[DATA_WIDTH-1] ^ b[DATA_WIDTH-1]) &
                    (result[DATA_WIDTH-1] ^ a[DATA_WIDTH-1]);
            end

            6'd10: begin
                // SMUL: Signed multiplication.
                // Return the lower DATA_WIDTH product bits.
                result = $signed(a) * $signed(b);
            end

            6'd11: begin
                // SDIV: Signed division.
                // Return zero if the divisor is zero.
                if (b != {DATA_WIDTH{1'b0}})
                    result = $signed(a) / $signed(b);
                else
                    result = {DATA_WIDTH{1'b0}};
            end

            6'd12: begin
                // SMOD: Signed remainder.
                // Return zero if the divisor is zero.
                if (b != {DATA_WIDTH{1'b0}})
                    result = $signed(a) % $signed(b);
                else
                    result = {DATA_WIDTH{1'b0}};
            end

            6'd13: begin
                // ABS: Calculate the absolute value of signed A.
                // The minimum negative value wraps in DATA_WIDTH bits.
                if (a[DATA_WIDTH-1])
                    result = ~a + {{(DATA_WIDTH-1){1'b0}}, 1'b1};
                else
                    result = a;
            end

            6'd14: begin
                // MIN: Return the smaller unsigned operand.
                result = (a < b) ? a : b;
            end

            6'd15: begin
                // MAX: Return the larger unsigned operand.
                result = (a > b) ? a : b;
            end

            //==========================================================
            // GROUP 2: BITWISE LOGIC OPERATIONS (16-23)
            //==========================================================

            6'd16: begin
                // AND: Set each output bit when both input bits are one.
                result = a & b;
            end

            6'd17: begin
                // OR: Set each output bit when either input bit is one.
                result = a | b;
            end

            6'd18: begin
                // XOR: Set each output bit when the input bits differ.
                result = a ^ b;
            end

            6'd19: begin
                // NOT: Invert every bit of A.
                result = ~a;
            end

            6'd20: begin
                // NAND: Invert the bitwise AND result.
                result = ~(a & b);
            end

            6'd21: begin
                // NOR: Invert the bitwise OR result.
                result = ~(a | b);
            end

            6'd22: begin
                // XNOR: Invert the bitwise XOR result.
                result = ~(a ^ b);
            end

            6'd23: begin
                // AND-NOT: Set bits where A is one and B is zero.
                result = a & ~b;
            end

            //==========================================================
            // GROUP 3: SHIFT AND ROTATION OPERATIONS (24-31)
            //==========================================================

            6'd24: begin
                // SHL: Shift A left by one position.
                // A zero enters the least significant bit.
                result = a << 1;
                carry  = a[DATA_WIDTH-1];
            end

            6'd25: begin
                // SHR: Shift A right by one position.
                // A zero enters the most significant bit.
                result = a >> 1;
                carry  = a[0];
            end

            6'd26: begin
                // ASR: Arithmetic right shift by one position.
                // Replicate the sign bit at the most significant end.
                result = $signed(a) >>> 1;
                carry  = a[0];
            end

            6'd27: begin
                // ROL: Rotate A left by one position.
                // The former MSB re-enters at the LSB.
                result = (a << 1) | (a >> (DATA_WIDTH-1));
                carry  = a[DATA_WIDTH-1];
            end

            6'd28: begin
                // ROR: Rotate A right by one position.
                // The former LSB re-enters at the MSB.
                result = (a >> 1) |
                         (a << (DATA_WIDTH-1));
                carry = a[0];
            end

            6'd29: begin
                // RCL: Rotate A left through the carry input.
                // The old MSB becomes carry; carry_in enters the LSB.
                result = (a << 1) | carry_in;
                carry  = a[DATA_WIDTH-1];
            end

            6'd30: begin
                // RCR: Rotate A right through the carry input.
                // The old LSB becomes carry; carry_in enters the MSB.
                result = (a >> 1) |
                         (carry_in << (DATA_WIDTH-1));
                carry = a[0];
            end

            6'd31: begin
                // BSWAP: Reverse the order of bytes in A.
                // Perform byte swapping only for widths divisible by 8.
                // For other widths, pass A through unchanged.
                result = a;

                if ((DATA_WIDTH % 8) == 0) begin
                    for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
                        // Copy each byte to its reversed byte position.
                        result[i*8 +: 8] =
                            a[DATA_WIDTH-1-i*8 -: 8];
                    end
                end
            end

            //==========================================================
            // GROUP 4: COMPARISON OPERATIONS (32-39)
            //==========================================================

            6'd32: begin
                // EQ: Return one when A equals B.
                result = (a == b);
            end

            6'd33: begin
                // NE: Return one when A differs from B.
                result = (a != b);
            end

            6'd34: begin
                // UGT: Return one when unsigned A is greater than B.
                result = (a > b);
            end

            6'd35: begin
                // ULT: Return one when unsigned A is less than B.
                result = (a < b);
            end

            6'd36: begin
                // UGE: Return one when unsigned A is at least B.
                result = (a >= b);
            end

            6'd37: begin
                // ULE: Return one when unsigned A is at most B.
                result = (a <= b);
            end

            6'd38: begin
                // SGT: Return one when signed A is greater than B.
                result = ($signed(a) > $signed(b));
            end

            6'd39: begin
                // SLT: Return one when signed A is less than B.
                result = ($signed(a) < $signed(b));
            end

            //==========================================================
            // GROUP 5: BIT MANIPULATION OPERATIONS (40-47)
            //==========================================================

            6'd40: begin
                // BSET: Set the bit selected by B.
                // B is treated as an unsigned bit index.
                if (b < DATA_WIDTH)
                    result = a |
                        ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << b);
                else
                    result = a;
            end

            6'd41: begin
                // BCLR: Clear the bit selected by B.
                if (b < DATA_WIDTH)
                    result = a &
                        ~( {{(DATA_WIDTH-1){1'b0}}, 1'b1} << b);
                else
                    result = a;
            end

            6'd42: begin
                // BTGL: Toggle the bit selected by B.
                if (b < DATA_WIDTH)
                    result = a ^
                        ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << b);
                else
                    result = a;
            end

            6'd43: begin
                // BTST: Return one if the selected bit of A is one.
                if (b < DATA_WIDTH)
                    result = (a >> b) & 1'b1;
                else
                    result = {DATA_WIDTH{1'b0}};
            end

            6'd44: begin
                // CLZ: Count leading zeros in A.
                // An all-zero input returns DATA_WIDTH.
                found  = 1'b0;
                result = {DATA_WIDTH{1'b0}};

                // Search from the MSB towards the LSB.
                for (i = DATA_WIDTH-1; i >= 0; i = i-1) begin
                    if (!found) begin
                        if (a[i])
                            found = 1'b1;
                        else
                            result = result + 1'b1;
                    end
                end
            end

            6'd45: begin
                // CTZ: Count trailing zeros in A.
                // An all-zero input returns DATA_WIDTH.
                found  = 1'b0;
                result = {DATA_WIDTH{1'b0}};

                // Search from the LSB towards the MSB.
                for (i = 0; i < DATA_WIDTH; i = i+1) begin
                    if (!found) begin
                        if (a[i])
                            found = 1'b1;
                        else
                            result = result + 1'b1;
                    end
                end
            end

            6'd46: begin
                // POPCNT: Count the number of one bits in A.
                result = {DATA_WIDTH{1'b0}};

                // Add one for every set bit.
                for (i = 0; i < DATA_WIDTH; i = i+1)
                    result = result + a[i];
            end

            6'd47: begin
                // PARITY: Put the XOR reduction of A in result bit zero.
                // All other result bits remain zero.
                result[0] = ^a;
            end

            //==========================================================
            // GROUP 6: SIGNED COMPARISON AND DATA SELECTION (48-55)
            //==========================================================

            6'd48: begin
                // SGE: Return one when signed A is >= signed B.
                result = ($signed(a) >= $signed(b));
            end

            6'd49: begin
                // SLE: Return one when signed A is <= signed B.
                result = ($signed(a) <= $signed(b));
            end

            6'd50: begin
                // SELA: Pass operand A directly to the output.
                result = a;
            end

            6'd51: begin
                // SELB: Pass operand B directly to the output.
                result = b;
            end

            6'd52: begin
                // ZERO: Force the result to zero.
                result = {DATA_WIDTH{1'b0}};
            end

            6'd53: begin
                // ONES: Set every result bit to one.
                result = {DATA_WIDTH{1'b1}};
            end

            6'd54: begin
                // SIGN: Sign-extend the low B bits of A.
                // Valid field widths are 1 through DATA_WIDTH.
                // B is interpreted as the field width.
                if ((b >= 1) && (b <= DATA_WIDTH))
                    result =
                        $signed(a << (DATA_WIDTH-b)) >>> (DATA_WIDTH-b);
                else
                    result = {DATA_WIDTH{1'b0}};
            end

            6'd55: begin
                // ZEXT: Keep the low B bits of A and clear higher bits.
                // Valid field widths are 1 through DATA_WIDTH.
                if ((b >= 1) && (b <= DATA_WIDTH))
                    result = a &
                        ({DATA_WIDTH{1'b1}} >> (DATA_WIDTH-b));
                else
                    result = {DATA_WIDTH{1'b0}};
            end

            //==========================================================
            // GROUP 7: VARIABLE SHIFTS AND ADVANCED BIT OPERATIONS
            // OPCODES 56-63
            //==========================================================

            6'd56: begin
                // LSLV: Shift A left by the amount specified by B.
                result = a << b;
            end

            6'd57: begin
                // LSRV: Shift A right by the amount specified by B.
                result = a >> b;
            end

            6'd58: begin
                // ASRV: Arithmetic right shift by the amount in B.
                result = $signed(a) >>> b;
            end

            6'd59: begin
                // BITREV: Reverse the order of all DATA_WIDTH bits.
                for (i = 0; i < DATA_WIDTH; i = i+1)
                    result[i] = a[DATA_WIDTH-1-i];
            end

            6'd60: begin
                // BMIN: Return the smaller unsigned operand.
                // This is an alias of MIN.
                result = (a < b) ? a : b;
            end

            6'd61: begin
                // BMAX: Return the larger unsigned operand.
                // This is an alias of MAX.
                result = (a > b) ? a : b;
            end

            6'd62: begin
                // CLEAR_LOWEST_SET: Clear the lowest set bit in A.
                // A & (A-1) clears the least significant one bit.
                result = a & (a - 1'b1);
            end

            6'd63: begin
                // ISOLATE_LOWEST_SET: Keep only the lowest set bit.
                // A & (-A) isolates the least significant one bit.
                result = a & (~a + 1'b1);
            end

            //==========================================================
            // DEFAULT: Handle any unrecognized or unknown selector.
            //==========================================================

            default: begin
                // Return zero and clear status flags.
                result   = {DATA_WIDTH{1'b0}};
                carry    = 1'b0;
                borrow   = 1'b0;
                overflow = 1'b0;
            end

        endcase

        // Set the zero flag when the final result equals zero.
        zero = (result == {DATA_WIDTH{1'b0}});

        // Set negative to the MSB of the result.
        // This is a sign indicator when the result is interpreted signed.
        negative = result[DATA_WIDTH-1];

    end

endmodule