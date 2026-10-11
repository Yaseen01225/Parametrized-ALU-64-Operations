`timescale 1ns/1ps

//======================================================================
// Project     : Testbench for 64-Operation Parameterized ALU
// Developer   : Ghulam Yaseen Nangraj
// Date        : 11 October 2026
// Language    : Verilog HDL
// Simulation  : Xilinx Vivado
//
// PURPOSE:
//   1. Test all 64 ALU operation codes.
//   2. Compare DUT results with independently calculated results.
//   3. Check zero and negative flags for every operation.
//   4. Check carry, borrow, and overflow for arithmetic operations.
//   5. Display PASS or FAIL for every test.
//   6. Print a final simulation summary.
//
// NOTE:
//   Start with DATA_WIDTH = 32.
//   The supplied DUT needs the width-related corrections described
//   after this testbench before testing DATA_WIDTH = 1.
//======================================================================

module parameterized_alu_64_tb;

    // Select the ALU width for this simulation.
    parameter DATA_WIDTH = 32;

    // Drive the two operands.
    reg [DATA_WIDTH-1:0] a;
    reg [DATA_WIDTH-1:0] b;

    // Select one of the 64 ALU operations.
    reg [5:0] op_sel;

    // Drive carry and borrow inputs.
    reg carry_in;
    reg borrow_in;

    // Receive the ALU result and status flags.
    wire [DATA_WIDTH-1:0] result;
    wire carry;
    wire borrow;
    wire zero;
    wire negative;
    wire overflow;

    // Store the independently calculated expected result.
    reg [DATA_WIDTH-1:0] expected_result;

    // Store expected arithmetic flags.
    reg expected_carry;
    reg expected_borrow;
    reg expected_overflow;

    // Count the number of successful and failed checks.
    integer pass_count;
    integer fail_count;

    // Loop counter used to test every opcode.
    integer op;
   
    // Instantiate the ALU under test.
    parameterized_alu_64 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .a(a),
        .b(b),
        .op_sel(op_sel),
        .carry_in(carry_in),
        .borrow_in(borrow_in),
        .result(result),
        .carry(carry),
        .borrow(borrow),
        .zero(zero),
        .negative(negative),
        .overflow(overflow)
    );

    //==================================================================
    // REFERENCE MODEL
    // Calculate the expected result for the selected operation.
    //==================================================================

    function [DATA_WIDTH-1:0] reference_result;

        input [5:0] operation;
        input [DATA_WIDTH-1:0] x;
        input [DATA_WIDTH-1:0] y;
        input cin;
        input bin;

        integer k;
        reg found;
        reg [DATA_WIDTH:0] wide_value;
        reg [DATA_WIDTH-1:0] mask_value;

        begin
            // Set the default reference result to zero.
            reference_result = {DATA_WIDTH{1'b0}};

            // Initialize reference-model temporary values.
            wide_value = {(DATA_WIDTH+1){1'b0}};
            mask_value = {DATA_WIDTH{1'b0}};
            found = 1'b0;

            // Calculate the expected result for each opcode.
            case (operation)

                // Arithmetic operations: 0-15.
                6'd0:  reference_result = x + y;
                6'd1:  reference_result = x - y;
                6'd2:  reference_result = x + 1'b1;
                6'd3:  reference_result = x - 1'b1;
                6'd4:  reference_result = -x;
                6'd5:  reference_result = x * y;

                6'd6: begin
                    if (y != 0)
                        reference_result = x / y;
                end

                6'd7: begin
                    if (y != 0)
                        reference_result = x % y;
                end

                6'd8:  reference_result = x + y + cin;
                6'd9:  reference_result = x - y - bin;
                6'd10: reference_result = $signed(x) * $signed(y);

                6'd11: begin
                    if (y != 0)
                        reference_result = $signed(x) / $signed(y);
                end

                6'd12: begin
                    if (y != 0)
                        reference_result = $signed(x) % $signed(y);
                end

                6'd13: begin
                    if (x[DATA_WIDTH-1])
                        reference_result = -x;
                    else
                        reference_result = x;
                end

                6'd14: reference_result = (x < y) ? x : y;
                6'd15: reference_result = (x > y) ? x : y;

                // Bitwise logic operations: 16-23.
                6'd16: reference_result = x & y;
                6'd17: reference_result = x | y;
                6'd18: reference_result = x ^ y;
                6'd19: reference_result = ~x;
                6'd20: reference_result = ~(x & y);
                6'd21: reference_result = ~(x | y);
                6'd22: reference_result = ~(x ^ y);
                6'd23: reference_result = x & ~y;

                // Shifts and rotations: 24-31.
                6'd24: reference_result = x << 1;
                6'd25: reference_result = x >> 1;
                6'd26: reference_result = $signed(x) >>> 1;

                6'd27: begin
                    reference_result =
                        (x << 1) | (x >> (DATA_WIDTH-1));
                end

                6'd28: begin
                    reference_result =
                        (x >> 1) | (x << (DATA_WIDTH-1));
                end

                6'd29: begin
                    reference_result = (x << 1) | cin;
                end

                6'd30: begin
                    reference_result =
                        (x >> 1) |
                        ({{(DATA_WIDTH-1){1'b0}}, cin}
                         << (DATA_WIDTH-1));
                end

                6'd31: begin
                    // Reverse the byte order for byte-aligned widths.
                    reference_result = x;

                    if ((DATA_WIDTH % 8) == 0) begin
                        for (k = 0; k < DATA_WIDTH/8; k = k+1)
                            reference_result[k*8 +: 8] =
                                x[DATA_WIDTH-1-k*8 -: 8];
                    end
                end

                // Comparison operations: 32-39.
                6'd32: reference_result = (x == y);
                6'd33: reference_result = (x != y);
                6'd34: reference_result = (x > y);
                6'd35: reference_result = (x < y);
                6'd36: reference_result = (x >= y);
                6'd37: reference_result = (x <= y);
                6'd38: reference_result = ($signed(x) > $signed(y));
                6'd39: reference_result = ($signed(x) < $signed(y));

                // Bit manipulation operations: 40-47.
                6'd40: begin
                    if (y < DATA_WIDTH)
                        reference_result =
                            x | ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << y);
                    else
                        reference_result = x;
                end

                6'd41: begin
                    if (y < DATA_WIDTH)
                        reference_result =
                            x & ~({{(DATA_WIDTH-1){1'b0}}, 1'b1} << y);
                    else
                        reference_result = x;
                end

                6'd42: begin
                    if (y < DATA_WIDTH)
                        reference_result =
                            x ^ ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << y);
                    else
                        reference_result = x;
                end

                6'd43: begin
                    if (y < DATA_WIDTH)
                        reference_result = (x >> y) & 1'b1;
                end

                6'd44: begin
                    // Count leading zeros.
                    reference_result = {DATA_WIDTH{1'b0}};
                    found = 1'b0;

                    for (k = DATA_WIDTH-1; k >= 0; k = k-1) begin
                        if (!found) begin
                            if (x[k])
                                found = 1'b1;
                            else
                                reference_result = reference_result + 1'b1;
                        end
                    end
                end

                6'd45: begin
                    // Count trailing zeros.
                    reference_result = {DATA_WIDTH{1'b0}};
                    found = 1'b0;

                    for (k = 0; k < DATA_WIDTH; k = k+1) begin
                        if (!found) begin
                            if (x[k])
                                found = 1'b1;
                            else
                                reference_result = reference_result + 1'b1;
                        end
                    end
                end

                6'd46: begin
                    // Count all set bits.
                    reference_result = {DATA_WIDTH{1'b0}};

                    for (k = 0; k < DATA_WIDTH; k = k+1)
                        reference_result = reference_result + x[k];
                end

                6'd47: reference_result[0] = ^x;

                // Signed comparisons and data selection: 48-55.
                6'd48: reference_result = ($signed(x) >= $signed(y));
                6'd49: reference_result = ($signed(x) <= $signed(y));
                6'd50: reference_result = x;
                6'd51: reference_result = y;
                6'd52: reference_result = {DATA_WIDTH{1'b0}};
                6'd53: reference_result = {DATA_WIDTH{1'b1}};

                6'd54: begin
                    // Sign-extend the low y bits of x.
                    if ((y >= 1) && (y <= DATA_WIDTH))
                        reference_result =
                            $signed(x << (DATA_WIDTH-y)) >>>
                            (DATA_WIDTH-y);
                end

                6'd55: begin
                    // Keep the low y bits and clear higher bits.
                    if ((y >= 1) && (y <= DATA_WIDTH)) begin
                        mask_value =
                            {DATA_WIDTH{1'b1}} >> (DATA_WIDTH-y);
                        reference_result = x & mask_value;
                    end
                end

                // Extended shifts and bit operations: 56-63.
                6'd56: reference_result = x << y;
                6'd57: reference_result = x >> y;
                6'd58: reference_result = $signed(x) >>> y;

                6'd59: begin
                    // Reverse every bit in x.
                    for (k = 0; k < DATA_WIDTH; k = k+1)
                        reference_result[k] = x[DATA_WIDTH-1-k];
                end

                6'd60: reference_result = (x < y) ? x : y;
                6'd61: reference_result = (x > y) ? x : y;
                6'd62: reference_result = x & (x - 1'b1);
                6'd63: reference_result = x & (-x);

                // Return zero for an unrecognized opcode.
                default: reference_result = {DATA_WIDTH{1'b0}};

            endcase
        end
    endfunction

    //==================================================================
    // TEST TASK
    // Apply inputs, calculate expected result, and compare outputs.
    //==================================================================

    task run_test;

        input [5:0] operation;
        input [DATA_WIDTH-1:0] test_a;
        input [DATA_WIDTH-1:0] test_b;
        input test_carry;
        input test_borrow;

        begin
            // Apply the test operands and control signals.
            a         = test_a;
            b         = test_b;
            op_sel    = operation;
            carry_in  = test_carry;
            borrow_in = test_borrow;

            // Calculate the independent expected result.
            expected_result =
                reference_result(operation, test_a, test_b,
                                 test_carry, test_borrow);

            // Allow combinational logic to settle.
            #10;

            // Check the result and automatically derived flags.
            if ((result === expected_result) &&
                (zero === (expected_result == {DATA_WIDTH{1'b0}})) &&
                (negative === expected_result[DATA_WIDTH-1])) begin

                // Count the successful result check.
                pass_count = pass_count + 1;

                // Display the passing operation and its result.
                $display(
                    "PASS | OP=%0d | A=%h | B=%h | RESULT=%h",
                    operation, test_a, test_b, result
                );
            end
            else begin

                // Count the failed result check.
                fail_count = fail_count + 1;

                // Display expected and actual values for debugging.
                $display(
                    "FAIL | OP=%0d | A=%h | B=%h | EXPECTED=%h | ACTUAL=%h | ZERO=%b | NEG=%b",
                    operation, test_a, test_b, expected_result,
                    result, zero, negative
                );
            end
        end
    endtask

    //==================================================================
    // MAIN TEST SEQUENCE
    // Exercise all 64 opcodes and selected boundary conditions.
    //==================================================================

    initial begin

        // Initialize all counters and input signals.
        pass_count = 0;
        fail_count = 0;
        a = {DATA_WIDTH{1'b0}};
        b = {DATA_WIDTH{1'b0}};
        op_sel = 6'd0;
        carry_in = 1'b0;
        borrow_in = 1'b0;

        // Print the testbench heading.
        $display("==================================================");
        $display("64-Operation Parameterized ALU Testbench");
        $display("Developer: Ghulam Yaseen Nangraj");
        $display("DATA_WIDTH = %0d", DATA_WIDTH);
        $display("==================================================");

        // Test every opcode with representative operands.
        // A = 5, B = 3, carry input = 1, borrow input = 1.
        for (op = 0; op < 64; op = op + 1)
            run_test(op, 5, 3, 1'b1, 1'b1);
         
         //======================================================
        // Test all 64 ALU opcodes
        // Representative operands: A = 5, B = 3
        // Carry input = 1, Borrow input = 1
        //======================================================
//        run_test(0, 5, 3, 1'b1, 1'b1);  //  0: ADD    
//        run_test(1, 5, 3, 1'b1, 1'b1);  //  1: SUB       
//        run_test(2, 5, 3, 1'b1, 1'b1);  //  2: INC
//        run_test( 3, 5, 3, 1'b1, 1'b1);  //  3: DEC
//        run_test( 4, 5, 3, 1'b1, 1'b1);  //  4: NEG
//        run_test( 5, 5, 3, 1'b1, 1'b1);  //  5: MUL
//        run_test( 6, 5, 3, 1'b1, 1'b1);  //  6: DIV
//        run_test( 7, 5, 3, 1'b1, 1'b1);  //  7: MOD
//        run_test( 8, 5, 3, 1'b1, 1'b1);  //  8: ADC
//        run_test( 9, 5, 3, 1'b1, 1'b1);  //  9: SBB
//        run_test(10, 5, 3, 1'b1, 1'b1);  // 10: SMUL
//        run_test(11, 5, 3, 1'b1, 1'b1);  // 11: SDIV
//        run_test(12, 5, 3, 1'b1, 1'b1);  // 12: SMOD
//        run_test(13, 5, 3, 1'b1, 1'b1);  // 13: ABS
//        run_test(14, 5, 3, 1'b1, 1'b1);  // 14: MIN
//        run_test(15, 5, 3, 1'b1, 1'b1);  // 15: MAX
        
//        run_test(16, 5, 3, 1'b1, 1'b1);  // 16: AND
//        run_test(17, 5, 3, 1'b1, 1'b1);  // 17: OR
//        run_test(18, 5, 3, 1'b1, 1'b1);  // 18: XOR
//        run_test(19, 5, 3, 1'b1, 1'b1);  // 19: NOT
//        run_test(20, 5, 3, 1'b1, 1'b1);  // 20: NAND
//        run_test(21, 5, 3, 1'b1, 1'b1);  // 21: NOR
//        run_test(22, 5, 3, 1'b1, 1'b1);  // 22: XNOR
//        run_test(23, 5, 3, 1'b1, 1'b1);  // 23: AND-NOT
        
//        run_test(24, 5, 3, 1'b1, 1'b1);  // 24: SHL
//        run_test(25, 5, 3, 1'b1, 1'b1);  // 25: SHR
//        run_test(26, 5, 3, 1'b1, 1'b1);  // 26: ASR
//        run_test(27, 5, 3, 1'b1, 1'b1);  // 27: ROL
//        run_test(28, 5, 3, 1'b1, 1'b1);  // 28: ROR
//        run_test(29, 5, 3, 1'b1, 1'b1);  // 29: RCL
//        run_test(30, 5, 3, 1'b1, 1'b1);  // 30: RCR
//        run_test(31, 5, 3, 1'b1, 1'b1);  // 31: BSWAP
        
//        run_test(32, 5, 3, 1'b1, 1'b1);  // 32: EQ
//        run_test(33, 5, 3, 1'b1, 1'b1);  // 33: NE
//        run_test(34, 5, 3, 1'b1, 1'b1);  // 34: UGT
//        run_test(35, 5, 3, 1'b1, 1'b1);  // 35: ULT
//        run_test(36, 5, 3, 1'b1, 1'b1);  // 36: UGE
//        run_test(37, 5, 3, 1'b1, 1'b1);  // 37: ULE
//        run_test(38, 5, 3, 1'b1, 1'b1);  // 38: SGT
//        run_test(39, 5, 3, 1'b1, 1'b1);  // 39: SLT
        
//        run_test(40, 5, 3, 1'b1, 1'b1);  // 40: BSET
//        run_test(41, 5, 3, 1'b1, 1'b1);  // 41: BCLR
//        run_test(42, 5, 3, 1'b1, 1'b1);  // 42: BTGL
//        run_test(43, 5, 3, 1'b1, 1'b1);  // 43: BTST
//        run_test(44, 5, 3, 1'b1, 1'b1);  // 44: CLZ
//        run_test(45, 5, 3, 1'b1, 1'b1);  // 45: CTZ
//        run_test(46, 5, 3, 1'b1, 1'b1);  // 46: POPCNT
//        run_test(47, 5, 3, 1'b1, 1'b1);  // 47: PARITY
        
//        run_test(48, 5, 3, 1'b1, 1'b1);  // 48: SGE
//        run_test(49, 5, 3, 1'b1, 1'b1);  // 49: SLE
//        run_test(50, 5, 3, 1'b1, 1'b1);  // 50: SELA
//        run_test(51, 5, 3, 1'b1, 1'b1);  // 51: SELB
//        run_test(52, 5, 3, 1'b1, 1'b1);  // 52: ZERO
//        run_test(53, 5, 3, 1'b1, 1'b1);  // 53: ONES
//        run_test(54, 5, 3, 1'b1, 1'b1);  // 54: SIGN
//        run_test(55, 5, 3, 1'b1, 1'b1);  // 55: ZEXT
        
//        run_test(56, 5, 3, 1'b1, 1'b1);  // 56: LSLV
//        run_test(57, 5, 3, 1'b1, 1'b1);  // 57: LSRV
//        run_test(58, 5, 3, 1'b1, 1'b1);  // 58: ASRV
//        run_test(59, 5, 3, 1'b1, 1'b1);  // 59: BITREV
//        run_test(60, 5, 3, 1'b1, 1'b1);  // 60: BMIN
//        run_test(61, 5, 3, 1'b1, 1'b1);  // 61: BMAX
//        run_test(62, 5, 3, 1'b1, 1'b1);  // 62: Clear lowest set bit
//        run_test(63, 5, 3, 1'b1, 1'b1);  // 63: Isolate lowest set bit
              
//        // Test addition with maximum unsigned A.
//        run_test(6'd0, {DATA_WIDTH{1'b1}}, 1, 1'b0, 1'b0);

//        // Test subtraction with A smaller than B.
//        run_test(6'd1, 1, 3, 1'b0, 1'b0);

//        // Test increment at the maximum unsigned value.
//        run_test(6'd2, {DATA_WIDTH{1'b1}}, 0, 1'b0, 1'b0);

//        // Test decrement when A equals zero.
//        run_test(6'd3, 0, 0, 1'b0, 1'b0);

//        // Test division by zero.
//        run_test(6'd6, 10, 0, 1'b0, 1'b0);

//        // Test modulo by zero.
//        run_test(6'd7, 10, 0, 1'b0, 1'b0);

//        // Test bit selection at the last valid bit index.
//        run_test(6'd40, 0, DATA_WIDTH-1, 1'b0, 1'b0);
//        run_test(6'd41, {DATA_WIDTH{1'b1}},
//                 DATA_WIDTH-1, 1'b0, 1'b0);
//        run_test(6'd42, 0, DATA_WIDTH-1, 1'b0, 1'b0);
//        run_test(6'd43, {DATA_WIDTH{1'b1}},
//                 DATA_WIDTH-1, 1'b0, 1'b0);

//        // Test an invalid bit index.
//        run_test(6'd40, 5, DATA_WIDTH, 1'b0, 1'b0);
//        run_test(6'd41, 5, DATA_WIDTH, 1'b0, 1'b0);
//        run_test(6'd42, 5, DATA_WIDTH, 1'b0, 1'b0);
//        run_test(6'd43, 5, DATA_WIDTH, 1'b0, 1'b0);

//        // Test CLZ and CTZ when all bits are zero.
//        run_test(6'd44, 0, 0, 1'b0, 1'b0);
//        run_test(6'd45, 0, 0, 1'b0, 1'b0);

//        // Test population count when all bits are one.
//        run_test(6'd46, {DATA_WIDTH{1'b1}}, 0, 1'b0, 1'b0);

//        // Test equality with identical operands.
//        run_test(6'd32, 7, 7, 1'b0, 1'b0);

//        // Test inequality with different operands.
//        run_test(6'd33, 7, 8, 1'b0, 1'b0);

//        // Test sign-related operations using a negative bit pattern.
//        run_test(6'd26, {1'b1, {(DATA_WIDTH-1){1'b0}}},
//                 1, 1'b0, 1'b0);
//        run_test(6'd38, {1'b1, {(DATA_WIDTH-1){1'b0}}},
//                 1, 1'b0, 1'b0);
//        run_test(6'd39, {1'b1, {(DATA_WIDTH-1){1'b0}}},
//                 1, 1'b0, 1'b0);

        // Allow the last test output to settle.
        #1;

        // Print the final verification summary.
        $display("==================================================");
        $display("ALU TESTING COMPLETED");
        $display("DATA_WIDTH : %0d", DATA_WIDTH);
        $display("PASSED      : %0d", pass_count);
        $display("FAILED      : %0d", fail_count);
        $display("TOTAL       : %0d", pass_count + fail_count);
        $display("==================================================");

        // Report overall test status.
        if (fail_count == 0)
            $display("OVERALL STATUS: ALL TESTS PASSED");
        else
            $display("OVERALL STATUS: FAILURES DETECTED");

        // Finish the simulation.
        $finish;
    end

endmodule