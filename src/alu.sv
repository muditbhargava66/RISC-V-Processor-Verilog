// Arithmetic Logic Unit (ALU)
// Complete implementation for all RV32I operations with M-extension support
// SystemVerilog implementation with parameterized XLEN

module alu #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1
)(
    input  logic [XLEN-1:0] operand_a,
    input  logic [XLEN-1:0] operand_b,
    input  logic [3:0]      alu_control,
    output logic [XLEN-1:0] result,
    output logic            zero
);

    import riscv_pkg::*;

    // ALU operation codes (using package definitions)
    localparam logic [3:0] ALU_ADD   = 4'b0000;
    localparam logic [3:0] ALU_SUB   = 4'b1000;
    localparam logic [3:0] ALU_AND   = 4'b0111;
    localparam logic [3:0] ALU_OR    = 4'b0110;
    localparam logic [3:0] ALU_XOR   = 4'b0100;
    localparam logic [3:0] ALU_SLL   = 4'b0001;
    localparam logic [3:0] ALU_SRL   = 4'b0101;
    localparam logic [3:0] ALU_SRA   = 4'b1101;
    localparam logic [3:0] ALU_SLT   = 4'b0010;
    localparam logic [3:0] ALU_SLTU  = 4'b0011;

    // M-extension operations
    localparam logic [3:0] ALU_MUL   = 4'b1110;
    localparam logic [3:0] ALU_MULH  = 4'b1111;
    localparam logic [3:0] ALU_DIV   = 4'b1010;
    localparam logic [3:0] ALU_REM   = 4'b1011;

    logic [XLEN:0] addsub_result;
    logic [2*XLEN-1:0] mul_result;
    logic [XLEN-1:0] div_result;
    logic [XLEN-1:0] rem_result;

    always_comb begin
        result = '0;
        addsub_result = '0;
        mul_result = '0;
        div_result = '0;
        rem_result = '0;

        unique case (alu_control)
            ALU_ADD: begin
                addsub_result = operand_a + operand_b;
                result = addsub_result[XLEN-1:0];
            end
            ALU_SUB: begin
                addsub_result = operand_a - operand_b;
                result = addsub_result[XLEN-1:0];
            end
            ALU_AND: result = operand_a & operand_b;
            ALU_OR:  result = operand_a | operand_b;
            ALU_XOR: result = operand_a ^ operand_b;
            ALU_SLL: result = operand_a << operand_b[$clog2(XLEN)-1:0];
            ALU_SRL: result = operand_a >> operand_b[$clog2(XLEN)-1:0];
            ALU_SRA: result = $signed(operand_a) >>> operand_b[$clog2(XLEN)-1:0];
            ALU_SLT: result = ($signed(operand_a) < $signed(operand_b)) ? {{(XLEN-1){1'b0}}, 1'b1} : '0;
            ALU_SLTU: result = (operand_a < operand_b) ? {{(XLEN-1){1'b0}}, 1'b1} : '0;

            // M-extension operations (only synthesized if ENABLE_M=1)
            ALU_MUL: begin
                if (ENABLE_M) begin
                    mul_result = $signed(operand_a) * $signed(operand_b);
                    result = mul_result[XLEN-1:0];
                end
            end
            ALU_MULH: begin
                if (ENABLE_M) begin
                    mul_result = $signed(operand_a) * $signed(operand_b);
                    result = mul_result[2*XLEN-1:XLEN];
                end
            end
            ALU_DIV: begin
                if (ENABLE_M) begin
                    div_result = (operand_b != 0) ? $signed(operand_a) / $signed(operand_b) : -1;
                    result = div_result;
                end
            end
            ALU_REM: begin
                if (ENABLE_M) begin
                    rem_result = (operand_b != 0) ? $signed(operand_a) % $signed(operand_b) : operand_a;
                    result = rem_result;
                end
            end

            default: result = '0;
        endcase
    end

    // Zero flag generation
    assign zero = (result == '0);

    // Synthesis-time assertion for unknown control
    // synthesis translate_off
    always_comb begin
        if (alu_control != ALU_ADD && alu_control != ALU_SUB &&
            alu_control != ALU_AND && alu_control != ALU_OR &&
            alu_control != ALU_XOR && alu_control != ALU_SLL &&
            alu_control != ALU_SRL && alu_control != ALU_SRA &&
            alu_control != ALU_SLT && alu_control != ALU_SLTU &&
            (!ENABLE_M || (alu_control != ALU_MUL && alu_control != ALU_MULH &&
                           alu_control != ALU_DIV && alu_control != ALU_REM))) begin
            $warning("ALU: Unknown alu_control value: %04b", alu_control);
        end
    end
    // synthesis translate_on

endmodule