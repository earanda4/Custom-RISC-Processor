// FloatAdder.sv - floating point unit

module FloatAdder (
    input  logic Clk,
    input  logic Reset,
    input  logic Start,           // Pulse to initiate a new addition
    input  logic [7:0] A_MSB_in,  // MSB of 16-bit float A (Sign, Exp_bits[4:0], Mant_bit[9])
    input  logic [7:0] A_LSB_in,  // LSB of 16-bit float A (Mant_bits[8:0])
    input  logic [7:0] B_MSB_in,  // MSB of 16-bit float B
    input  logic [7:0] B_LSB_in,  // LSB of 16-bit float B
    output logic [7:0] Result_MSB_out, // MSB of 16-bit float Result
    output logic [7:0] Result_LSB_out, // LSB of 16-bit float Result
    output logic Done             // High when operation is complete
);

    // These registers would hold intermediate values across pipeline stages/cycles.
    logic        sign_A, sign_B;
    logic [4:0]  exp_A, exp_B;       // 5-bit exponent
    logic [9:0]  mant_A, mant_B;     // 10-bit mantissa 

    logic        sign_result;
    logic [4:0]  exp_result;
    logic [10:0] mant_sum;           // Mantissa sum might need extra bit for overflow
    logic [9:0]  mant_result;        // Final 10-bit mantissa

    // These will now be registered outputs of the stage
    logic [4:0]  exp_diff_reg;           // Difference between exponents 
    logic        exp_A_greater_reg;      // Flag: exponent A > exponent B 

    // --- Control State Machine 
    typedef enum logic [2:0] {
        IDLE,
        PARSE_INPUTS,
        COMPARE_EXPONENTS,
        ALIGN_MANTISSAS,
        ADD_MANTISSAS,
        NORMALIZE_ROUND,
        FORMAT_OUTPUT,
        DONE_STATE
    } FSM_STATE_T;

    FSM_STATE_T current_state, next_state;
    always_ff @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            current_state  <= IDLE;
            Done           <= 1'b0;
            Result_MSB_out <= 8'b0; // Clear outputs on reset
            Result_LSB_out <= 8'b0; // Clear outputs on reset
            // Clear internal state registers on reset
            sign_A <= 1'b0; sign_B <= 1'b0;
            exp_A  <= 5'b0; exp_B  <= 5'b0;
            mant_A <= 10'b0; mant_B <= 10'b0;
            sign_result <= 1'b0;
            exp_result  <= 5'b0;
            mant_sum    <= 11'b0;
            mant_result <= 10'b0;
            exp_diff_reg    <= 5'b0; 
            exp_A_greater_reg <= 1'b0; 
        end else begin
            current_state <= next_state;
//done
            if (next_state == DONE_STATE) Done <= 1'b1;
            else if (current_state == DONE_STATE && next_state == IDLE) Done <= 1'b0;
            else Done <= 1'b0;
         // Default to not Done unless explicitly set

            if (current_state == FORMAT_OUTPUT) begin
                Result_MSB_out <= {sign_result, exp_result, mant_result[9:8]};
                Result_LSB_out <= mant_result[7:0];
            end else begin
                Result_MSB_out <= 8'b0;
                Result_LSB_out <= 8'b0;
            end

            if (current_state == PARSE_INPUTS) begin
                sign_A <= A_MSB_in[7];
                exp_A  <= A_MSB_in[6:2];
                mant_A <= {A_MSB_in[1:0], A_LSB_in[7:0]};
                sign_B <= B_MSB_in[7];
                exp_B  <= B_MSB_in[6:2];
                mant_B <= {B_MSB_in[1:0], B_LSB_in[7:0]};
            end

            if (current_state == COMPARE_EXPONENTS) begin
                exp_A_greater_reg <= (exp_A > exp_B);
                exp_diff_reg      <= exp_A_greater_reg ? (exp_A - exp_B) : (exp_B - exp_A);
            end
            
        end
    end

    always_comb begin
        next_state = current_state; // Default to staying in current state
        case (current_state)
            IDLE: begin
                if (Start) next_state = PARSE_INPUTS;
            end
            PARSE_INPUTS:      next_state = COMPARE_EXPONENTS;
            COMPARE_EXPONENTS: next_state = ALIGN_MANTISSAS;
            ALIGN_MANTISSAS:   next_state = ADD_MANTISSAS;
            ADD_MANTISSAS:     next_state = NORMALIZE_ROUND;
            NORMALIZE_ROUND:   next_state = FORMAT_OUTPUT;
            FORMAT_OUTPUT:     next_state = DONE_STATE;
            DONE_STATE: begin
                if (!Start) next_state = IDLE; 
            end
        endcase
    end


endmodule
