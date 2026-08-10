// RISC-V Processor Common Package
// Shared types, parameters, and constants for the RISC-V processor
// SystemVerilog package for use across all modules

package riscv_pkg;

    // =====================================================================
    // Architecture Parameters
    // =====================================================================
    parameter int XLEN = 32;                    // Base ISA width (32 or 64)
    parameter int REG_ADDR_WIDTH = 5;           // Register address width (5 bits = 32 registers)
    parameter int NUM_REGS = 32;                // Number of architectural registers

    // Extension enable parameters
    parameter bit ENABLE_M = 1'b1;              // M-extension (multiply/divide)
    parameter bit ENABLE_C = 1'b0;              // C-extension (compressed instructions)
    parameter bit ENABLE_F = 1'b0;              // F-extension (single-precision float)
    parameter bit ENABLE_D = 1'b0;              // D-extension (double-precision float)

    // Memory parameters
    parameter int IMEM_ADDR_WIDTH = 8;          // Instruction memory address width
    parameter int DMEM_ADDR_WIDTH = 8;          // Data memory address width

    // =====================================================================
    // RISC-V Base ISA Opcodes (RV32I)
    // =====================================================================
    typedef enum logic [6:0] {
        OPCODE_R_TYPE    = 7'b0110011,  // Register-register operations
        OPCODE_I_TYPE    = 7'b0010011,  // Immediate ALU operations
        OPCODE_LOAD      = 7'b0000011,  // Load instructions
        OPCODE_STORE     = 7'b0100011,  // Store instructions
        OPCODE_BRANCH    = 7'b1100011,  // Conditional branches
        OPCODE_JAL       = 7'b1101111,  // Jump and link
        OPCODE_JALR      = 7'b1100111,  // Jump and link register
        OPCODE_LUI       = 7'b0110111,  // Load upper immediate
        OPCODE_AUIPC     = 7'b0010111,  // Add upper immediate to PC
        OPCODE_SYSTEM    = 7'b1110011,  // System instructions (ECALL, EBREAK, CSR)
        OPCODE_FENCE     = 7'b0001111   // Fence instructions
    } opcode_e;

    // =====================================================================
    // Funct3 Values (per instruction type to avoid duplicate enum values)
    // =====================================================================
    typedef enum logic [2:0] {
        // R-type / I-type ALU
        FUNCT3_ADD_SUB   = 3'b000,
        FUNCT3_SLL       = 3'b001,
        FUNCT3_SLT       = 3'b010,
        FUNCT3_SLTU      = 3'b011,
        FUNCT3_XOR       = 3'b100,
        FUNCT3_SRL_SRA   = 3'b101,
        FUNCT3_OR        = 3'b110,
        FUNCT3_AND       = 3'b111
    } funct3_alu_e;

    typedef enum logic [2:0] {
        // Load instructions
        FUNCT3_LB        = 3'b000,
        FUNCT3_LH        = 3'b001,
        FUNCT3_LW        = 3'b010,
        FUNCT3_LBU       = 3'b100,
        FUNCT3_LHU       = 3'b101
    } funct3_load_e;

    typedef enum logic [2:0] {
        // Store instructions
        FUNCT3_SB        = 3'b000,
        FUNCT3_SH        = 3'b001,
        FUNCT3_SW        = 3'b010
    } funct3_store_e;

    typedef enum logic [2:0] {
        // Branch instructions
        FUNCT3_BEQ       = 3'b000,
        FUNCT3_BNE       = 3'b001,
        FUNCT3_BLT       = 3'b100,
        FUNCT3_BGE       = 3'b101,
        FUNCT3_BLTU      = 3'b110,
        FUNCT3_BGEU      = 3'b111
    } funct3_branch_e;

    typedef enum logic [2:0] {
        // JALR
        FUNCT3_JALR      = 3'b000
    } funct3_jalr_e;

    typedef enum logic [2:0] {
        // System instructions
        FUNCT3_ECALL     = 3'b000,
        FUNCT3_CSRRW     = 3'b001,
        FUNCT3_CSRRS     = 3'b010,
        FUNCT3_CSRRC     = 3'b011,
        FUNCT3_CSRRWI    = 3'b101,
        FUNCT3_CSRRSI    = 3'b110,
        FUNCT3_CSRRCI    = 3'b111
    } funct3_system_e;

    // =====================================================================
    // Funct7 Values (for R-type)
    // =====================================================================
    typedef enum logic [6:0] {
        FUNCT7_BASE      = 7'b0000000,
        FUNCT7_SUB_SRA   = 7'b0100000,
        FUNCT7_MULDIV    = 7'b0000001   // M-extension
    } funct7_e;

    // =====================================================================
    // ALU Operations
    // =====================================================================
    typedef enum logic [3:0] {
        ALU_ADD   = 4'b0000,
        ALU_SUB   = 4'b1000,
        ALU_AND   = 4'b0111,
        ALU_OR    = 4'b0110,
        ALU_XOR   = 4'b0100,
        ALU_SLL   = 4'b0001,
        ALU_SRL   = 4'b0101,
        ALU_SRA   = 4'b1101,
        ALU_SLT   = 4'b0010,
        ALU_SLTU  = 4'b0011,
        ALU_MUL   = 4'b1110,    // M-extension
        ALU_MULH  = 4'b1111,    // M-extension
        ALU_DIV   = 4'b1010,    // M-extension
        ALU_REM   = 4'b1011     // M-extension
    } alu_op_e;

    // =====================================================================
    // Register Write Source Selection
    // =====================================================================
    typedef enum logic [1:0] {
        WRITE_SRC_ALU       = 2'b00,  // ALU result
        WRITE_SRC_MEM       = 2'b01,  // Memory load data
        WRITE_SRC_PC_PLUS_4 = 2'b10,  // PC + 4 (for JAL/JALR)
        WRITE_SRC_IMM       = 2'b11   // Immediate (for LUI)
    } write_src_e;

    // =====================================================================
    // ALU Operand Source Selection
    // =====================================================================
    typedef enum logic [1:0] {
        ALU_SRC_REG   = 2'b00,  // Register operand
        ALU_SRC_IMM   = 2'b01,  // Immediate operand
        ALU_SRC_PC    = 2'b10,  // PC operand
        ALU_SRC_ZERO  = 2'b11   // Zero operand
    } alu_src_e;

    // =====================================================================
    // Instruction Format Types
    // =====================================================================
    typedef enum logic [2:0] {
        INST_R_TYPE = 3'd0,
        INST_I_TYPE = 3'd1,
        INST_S_TYPE = 3'd2,
        INST_B_TYPE = 3'd3,
        INST_U_TYPE = 3'd4,
        INST_J_TYPE = 3'd5
    } inst_type_e;

    // =====================================================================
    // Pipeline Control Signals (for future multi-cycle/pipelined versions)
    // =====================================================================
    typedef struct packed {
        logic         stall;
        logic         flush;
        logic         bubble;
    } pipeline_ctrl_s;

    // =====================================================================
    // Processor Status/Control Register (for debug/VIO)
    // =====================================================================
    typedef struct packed {
        logic [15:0]  reserved;
        logic [6:0]   current_opcode;
        logic         branch_taken;
        logic         mem_write;
        logic         mem_read;
        logic         reg_write;
        logic         jump_op;
        logic         branch_op;
        logic         processor_active;
        logic         error_flag;
    } proc_status_s;

    // =====================================================================
    // Utility Functions
    // =====================================================================

    // Check if opcode is valid RV32I base instruction
    function automatic logic is_valid_base_opcode(input logic [6:0] opcode);
        return (opcode == OPCODE_R_TYPE  ||
                opcode == OPCODE_I_TYPE  ||
                opcode == OPCODE_LOAD    ||
                opcode == OPCODE_STORE   ||
                opcode == OPCODE_BRANCH  ||
                opcode == OPCODE_JAL     ||
                opcode == OPCODE_JALR    ||
                opcode == OPCODE_LUI     ||
                opcode == OPCODE_AUIPC   ||
                opcode == OPCODE_SYSTEM  ||
                opcode == OPCODE_FENCE);
    endfunction

    // Check if instruction writes to register file
    function automatic logic writes_register(input logic [6:0] opcode);
        return (opcode == OPCODE_R_TYPE  ||
                opcode == OPCODE_I_TYPE  ||
                opcode == OPCODE_LOAD    ||
                opcode == OPCODE_JAL     ||
                opcode == OPCODE_JALR    ||
                opcode == OPCODE_LUI     ||
                opcode == OPCODE_AUIPC);
    endfunction

    // Check if instruction reads from memory
    function automatic logic reads_memory(input logic [6:0] opcode);
        return (opcode == OPCODE_LOAD);
    endfunction

    // Check if instruction writes to memory
    function automatic logic writes_memory(input logic [6:0] opcode);
        return (opcode == OPCODE_STORE);
    endfunction

    // Check if instruction is a control flow instruction
    function automatic logic is_control_flow(input logic [6:0] opcode);
        return (opcode == OPCODE_BRANCH ||
                opcode == OPCODE_JAL     ||
                opcode == OPCODE_JALR);
    endfunction

endpackage