// RISC-V Processor Top Module
// Single-cycle implementation of RV32I instruction set with M-extension support
// SystemVerilog implementation with parameterized XLEN and extensions

module riscv_processor #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0
)(
    input  logic        clk,
    input  logic        reset,

    // Debug outputs
    output logic [XLEN-1:0] pc_debug,
    output logic [XLEN-1:0] instruction_debug,
    output logic [XLEN-1:0] alu_result_debug,
    output logic [XLEN-1:0] reg_debug_data1,
    output logic [XLEN-1:0] reg_debug_data2,
    output logic [XLEN-1:0] mem_debug_data,
    output logic [4:0]      reg_debug_addr1,
    output logic [4:0]      reg_debug_addr2,
    output logic [XLEN-1:0] immediate_debug,
    output logic            reg_write_debug,
    output logic            mem_read_debug,
    output logic            mem_write_debug,
    output logic            branch_taken_debug
);

    import riscv_pkg::*;

    // Internal signals
    logic [XLEN-1:0] pc_current, pc_next, pc_plus_4;
    logic [XLEN-1:0] instruction;
    logic [XLEN-1:0] immediate;
    logic [XLEN-1:0] read_data1, read_data2;
    logic [XLEN-1:0] alu_operand1, alu_operand2, alu_result;
    logic [XLEN-1:0] mem_read_data;
    logic [XLEN-1:0] reg_write_data;
    logic            alu_zero;
    logic            branch_taken;

    // Control signals
    logic            reg_write, mem_read, mem_write, branch, jump;
    logic            alu_src1;
    logic [1:0]      alu_src, reg_write_src;
    logic [3:0]      alu_op;

    // Instruction fields
    logic [6:0] opcode;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;

    assign opcode    = instruction[6:0];
    assign rd        = instruction[11:7];
    assign funct3    = instruction[14:12];
    assign rs1       = instruction[19:15];
    assign rs2       = instruction[24:20];
    assign funct7    = instruction[31:25];

    // Debug outputs
    assign pc_debug             = pc_current;
    assign instruction_debug    = instruction;
    assign alu_result_debug     = alu_result;
    assign reg_debug_data1      = read_data1;
    assign reg_debug_data2      = read_data2;
    assign mem_debug_data       = mem_read_data;
    assign reg_debug_addr1      = rs1;
    assign reg_debug_addr2      = rs2;
    assign immediate_debug      = immediate;
    assign reg_write_debug      = reg_write;
    assign mem_read_debug       = mem_read;
    assign mem_write_debug      = mem_write;
    assign branch_taken_debug   = branch_taken;

    // =====================================================================
    // Program Counter
    // =====================================================================
    program_counter #(
        .XLEN (XLEN)
    ) pc_inst (
        .clk        (clk),
        .reset      (reset),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    // PC + 4 calculation
    assign pc_plus_4 = pc_current + 32'd4;

    // =====================================================================
    // Branch Condition Evaluation
    // =====================================================================
    logic beq_cond, bne_cond, blt_cond, bge_cond, bltu_cond, bgeu_cond;

    assign beq_cond  = (funct3 == FUNCT3_BEQ)  & alu_zero;
    assign bne_cond  = (funct3 == FUNCT3_BNE)  & ~alu_zero;
    assign blt_cond  = (funct3 == FUNCT3_BLT)  & alu_result[0];
    assign bge_cond  = (funct3 == FUNCT3_BGE)  & ~alu_result[0];
    assign bltu_cond = (funct3 == FUNCT3_BLTU) & alu_result[0];
    assign bgeu_cond = (funct3 == FUNCT3_BGEU) & ~alu_result[0];

    assign branch_taken = branch & (beq_cond | bne_cond | blt_cond | bge_cond | bltu_cond | bgeu_cond);

    // =====================================================================
    // Jump Target Calculation
    // JAL:  target = PC + immediate
    // JALR: target = (rs1 + imm) & ~1 (clear LSB per RISC-V spec)
    // =====================================================================
    logic [XLEN-1:0] jump_target;

    assign jump_target = (opcode == OPCODE_JAL) ? (pc_current + immediate) :
                         {alu_result[XLEN-1:1], 1'b0};

    assign pc_next = jump           ? jump_target :
                     branch_taken   ? (pc_current + immediate) :
                                      pc_plus_4;

    // =====================================================================
    // Instruction Memory
    // =====================================================================
    instruction_memory #(
        .ADDR_WIDTH (IMEM_ADDR_WIDTH)
    ) imem_inst (
        .address    (pc_current),
        .instruction(instruction)
    );

    // =====================================================================
    // Immediate Generator
    // =====================================================================
    immediate_generator #(
        .XLEN (XLEN)
    ) imm_gen_inst (
        .instruction (instruction),
        .immediate   (immediate)
    );

    // =====================================================================
    // Register File
    // =====================================================================
    register_file #(
        .XLEN (XLEN)
    ) regfile_inst (
        .clk         (clk),
        .reset       (reset),
        .reg_write   (reg_write),
        .read_reg1   (rs1),
        .read_reg2   (rs2),
        .write_reg   (rd),
        .write_data  (reg_write_data),
        .read_data1  (read_data1),
        .read_data2  (read_data2)
    );

    // =====================================================================
    // Control Unit
    // =====================================================================
    control_unit #(
        .ENABLE_M (ENABLE_M),
        .ENABLE_C (ENABLE_C)
    ) control_inst (
        .opcode         (opcode),
        .funct3         (funct3),
        .funct7         (funct7),
        .reg_write      (reg_write),
        .mem_read       (mem_read),
        .mem_write      (mem_write),
        .branch         (branch),
        .jump           (jump),
        .alu_src1       (alu_src1),
        .alu_src        (alu_src),
        .alu_op         (alu_op),
        .reg_write_src  (reg_write_src)
    );

    // =====================================================================
    // ALU Operand Selection
    // alu_src1: 0 = register, 1 = PC (for AUIPC)
    // alu_src:  00 = register, 01 = immediate, 10 = PC, 11 = zero
    // =====================================================================
    assign alu_operand1 = alu_src1 ? pc_current : read_data1;

    always_comb begin
        unique case (alu_src)
            ALU_SRC_REG:   alu_operand2 = read_data2;
            ALU_SRC_IMM:   alu_operand2 = immediate;
            ALU_SRC_PC:    alu_operand2 = pc_current;
            default:       alu_operand2 = '0;
        endcase
    end

    // =====================================================================
    // ALU
    // =====================================================================
    alu #(
        .XLEN     (XLEN),
        .ENABLE_M (ENABLE_M)
    ) alu_inst (
        .operand_a    (alu_operand1),
        .operand_b    (alu_operand2),
        .alu_control  (alu_op),
        .result       (alu_result),
        .zero         (alu_zero)
    );

    // =====================================================================
    // Data Memory
    // =====================================================================
    data_memory #(
        .ADDR_WIDTH (DMEM_ADDR_WIDTH),
        .XLEN       (XLEN)
    ) dmem_inst (
        .clk        (clk),
        .reset      (reset),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .address    (alu_result),
        .write_data (read_data2),
        .funct3     (funct3),
        .read_data  (mem_read_data)
    );

    // =====================================================================
    // Register Write Data Selection
    // reg_write_src: 00=ALU, 01=MEM, 10=PC+4, 11=IMM
    // =====================================================================
    always_comb begin
        unique case (reg_write_src)
            WRITE_SRC_ALU:       reg_write_data = alu_result;
            WRITE_SRC_MEM:       reg_write_data = mem_read_data;
            WRITE_SRC_PC_PLUS_4: reg_write_data = pc_plus_4;
            WRITE_SRC_IMM:       reg_write_data = immediate;
            default:             reg_write_data = '0;
        endcase
    end

    // =====================================================================
    // Inline Assertions (SVA)
    // =====================================================================
    // synthesis translate_off

    // PC should be word-aligned
    assert property (@(posedge clk) disable iff (reset) (pc_current[1:0] == 2'b00))
        else $error("PC not word-aligned: PC = %08h", pc_current);

    // Register x0 should always read as zero
    assert property (@(posedge clk) disable iff (reset) (rs1 == 5'b0) |-> (read_data1 == '0))
        else $error("Register x0 not zero on read port 1: %08h", read_data1);

    assert property (@(posedge clk) disable iff (reset) (rs2 == 5'b0) |-> (read_data2 == '0))
        else $error("Register x0 not zero on read port 2: %08h", read_data2);

    // Register write should only occur for instructions that write registers
    assert property (@(posedge clk) disable iff (reset) reg_write |-> writes_register(opcode))
        else $error("Invalid register write for opcode %07b", opcode);

    // Memory read should only occur for load instructions
    assert property (@(posedge clk) disable iff (reset) mem_read |-> (opcode == OPCODE_LOAD))
        else $error("Invalid memory read for opcode %07b", opcode);

    // Memory write should only occur for store instructions
    assert property (@(posedge clk) disable iff (reset) mem_write |-> (opcode == OPCODE_STORE))
        else $error("Invalid memory write for opcode %07b", opcode);

    // Branch taken should only occur for branch/jump instructions
    assert property (@(posedge clk) disable iff (reset) branch_taken |-> is_control_flow(opcode))
        else $error("Invalid branch taken for opcode %07b", opcode);

    // Valid opcode check
    assert property (@(posedge clk) disable iff (reset) is_valid_base_opcode(opcode) || (instruction == '0))
        else $error("Invalid opcode: %07b", opcode);

    // ADD instruction ALU result check
    assert property (@(posedge clk) disable iff (reset)
        (opcode == OPCODE_R_TYPE && funct3 == FUNCT3_ADD_SUB && funct7 == FUNCT7_BASE) |->
        (alu_result == (read_data1 + read_data2)))
        else $error("ADD mismatch: %08h + %08h != %08h", read_data1, read_data2, alu_result);

    // SUB instruction ALU result check
    assert property (@(posedge clk) disable iff (reset)
        (opcode == OPCODE_R_TYPE && funct3 == FUNCT3_ADD_SUB && funct7 == FUNCT7_SUB_SRA) |->
        (alu_result == (read_data1 - read_data2)))
        else $error("SUB mismatch: %08h - %08h != %08h", read_data1, read_data2, alu_result);

    // ADDI instruction ALU result check
    assert property (@(posedge clk) disable iff (reset)
        (opcode == OPCODE_I_TYPE && funct3 == FUNCT3_ADD_SUB) |->
        (alu_result == (read_data1 + immediate)))
        else $error("ADDI mismatch: %08h + %08h != %08h", read_data1, immediate, alu_result);

    // No unknown values in critical signals
    assert property (@(posedge clk) disable iff (reset) !$isunknown(pc_current))
        else $error("PC contains unknown values: %08h", pc_current);

    assert property (@(posedge clk) disable iff (reset) !$isunknown(instruction))
        else $error("Instruction contains unknown values: %08h", instruction);

    // Reset behavior
    assert property (@(posedge clk) reset |=> (pc_current == '0))
        else $error("PC not reset to zero: PC = %08h", pc_current);

    // Coverage properties
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_R_TYPE);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LOAD);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_STORE);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_BRANCH);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_JAL);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_JALR);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LUI);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_AUIPC);
    cover property (@(posedge clk) disable iff (reset) branch_taken);
    cover property (@(posedge clk) disable iff (reset) !branch_taken && opcode == OPCODE_BRANCH);
    cover property (@(posedge clk) disable iff (reset) reg_write && rd != 5'b0);
    cover property (@(posedge clk) disable iff (reset) reg_write && rd == 5'd31);
    cover property (@(posedge clk) disable iff (reset) mem_read);
    cover property (@(posedge clk) disable iff (reset) mem_write);

    // synthesis translate_on

endmodule