`timescale 1ns / 1ps
// Arithmetic Logic Unit (ALU)
// Combinational RV32I operations plus the RV32M multiply ops.
// RV32M divide/remainder (DIV/DIVU/REM/REMU) are NOT computed here: they are
// handled by the multi-cycle sequential divider (see divider.sv) and the core
// muxes that result into the register write-back path. The divide ALU codes
// therefore produce zero here and are never used for write-back.
// SystemVerilog implementation with parameterized XLEN (RV32 only).

module alu #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1
)(
    input  logic [XLEN-1:0] operand_a,
    input  logic [XLEN-1:0] operand_b,
    input  logic [4:0]      alu_control,
    output logic [XLEN-1:0] result,
    output logic            zero
);

    import riscv_pkg::*;

    logic [XLEN:0]     addsub_result;
    logic [2*XLEN-1:0] mul_result;

    always_comb begin
        result        = '0;
        addsub_result = '0;
        mul_result    = '0;

        case (alu_control)
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

            // M-extension multiply (synthesized only when ENABLE_M=1)
            ALU_MUL: begin
                if (ENABLE_M) begin
                    mul_result = operand_a * operand_b;   // low bits identical signed/unsigned
                    result = mul_result[XLEN-1:0];
                end
            end
            ALU_MULH: begin
                if (ENABLE_M) begin
                    mul_result = $signed(operand_a) * $signed(operand_b);
                    result = mul_result[2*XLEN-1:XLEN];
                end
            end
            ALU_MULHSU: begin
                if (ENABLE_M) begin
                    // signed a x unsigned b: zero-extend b so it is non-negative
                    mul_result = $signed(operand_a) * $signed({1'b0, operand_b});
                    result = mul_result[2*XLEN-1:XLEN];
                end
            end
            ALU_MULHU: begin
                if (ENABLE_M) begin
                    mul_result = operand_a * operand_b;
                    result = mul_result[2*XLEN-1:XLEN];
                end
            end

            // Divide/remainder are computed by the sequential divider, not here.
            // These codes intentionally yield zero; the core selects div_result.
            ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU: result = '0;

            default: result = '0;
        endcase
    end

    // Zero flag generation
    assign zero = (result == '0);

    // Optional simulation-only diagnostic for unknown control (enable with
    // +define+RISCV_DEBUG). Kept quiet by default to avoid log spam.
    // synthesis translate_off
`ifdef RISCV_DEBUG
    always_comb begin
        if (alu_control != ALU_ADD && alu_control != ALU_SUB &&
            alu_control != ALU_AND && alu_control != ALU_OR &&
            alu_control != ALU_XOR && alu_control != ALU_SLL &&
            alu_control != ALU_SRL && alu_control != ALU_SRA &&
            alu_control != ALU_SLT && alu_control != ALU_SLTU &&
            (!ENABLE_M || (alu_control != ALU_MUL && alu_control != ALU_MULH &&
                           alu_control != ALU_MULHSU && alu_control != ALU_MULHU &&
                           alu_control != ALU_DIV && alu_control != ALU_DIVU &&
                           alu_control != ALU_REM && alu_control != ALU_REMU))) begin
            $warning("ALU: Unknown alu_control value: %05b", alu_control);
        end
    end
`endif
    // synthesis translate_on

endmodule
