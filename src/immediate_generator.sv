`timescale 1ns / 1ps
// Immediate Generator Module
// Extracts and sign-extends immediates for all RV32I instruction types
// SystemVerilog implementation with parameterized XLEN (RV32 only)

module immediate_generator #(
    parameter int XLEN = 32
)(
    input  logic [31:0] instruction,
    output logic [XLEN-1:0] immediate
);

    import riscv_pkg::*;

    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    always_comb begin
        immediate = '0;
        case (opcode)
            // I-type instructions (ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, LB, LH, LW, LBU, LHU, JALR)
            OPCODE_I_TYPE,
            OPCODE_LOAD,
            OPCODE_JALR: begin
                immediate = {{(XLEN-12){instruction[31]}}, instruction[31:20]};
            end

            // S-type instructions (SB, SH, SW)
            OPCODE_STORE: begin
                immediate = {{(XLEN-12){instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            // B-type instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            OPCODE_BRANCH: begin
                immediate = {{(XLEN-13){instruction[31]}}, instruction[31], instruction[7],
                            instruction[30:25], instruction[11:8], 1'b0};
            end

            // U-type instructions (LUI, AUIPC): upper 20 bits placed at [31:12],
            // low 12 bits zero. The 32-bit result is sign-extended to XLEN (a
            // no-op for RV32) so the field placement is correct regardless of width.
            OPCODE_LUI,
            OPCODE_AUIPC: begin
                immediate = {{(XLEN-32){instruction[31]}}, instruction[31:12], 12'b0};
            end

            // J-type instructions (JAL)
            OPCODE_JAL: begin
                immediate = {{(XLEN-21){instruction[31]}}, instruction[31], instruction[19:12],
                            instruction[20], instruction[30:21], 1'b0};
            end

            default: begin
                immediate = '0;
            end
        endcase
    end

    // Optional simulation-only diagnostic (enable with +define+RISCV_DEBUG).
    // synthesis translate_off
`ifdef RISCV_DEBUG
    always_comb begin
        if (!is_valid_base_opcode(opcode) && opcode != 7'b0000000) begin
            $warning("IMM_GEN: Unknown opcode: %07b", opcode);
        end
    end
`endif
    // synthesis translate_on

endmodule
