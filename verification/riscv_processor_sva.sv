// RISC-V Processor SystemVerilog Assertions (SVA)
// Formal verification properties for critical processor behavior

`timescale 1ns / 1ps

module riscv_processor_sva (
    input wire clk,
    input wire reset,
    input wire [31:0] pc_debug,
    input wire [31:0] instruction_debug,
    input wire [31:0] alu_result_debug,
    input wire [31:0] reg_debug_data1,
    input wire [31:0] reg_debug_data2,
    input wire [4:0] reg_debug_addr1,
    input wire [4:0] reg_debug_addr2,
    input wire [31:0] immediate_debug,
    input wire reg_write_debug,
    input wire mem_read_debug,
    input wire mem_write_debug,
    input wire branch_taken_debug
);

    // Extract instruction fields
    wire [6:0] opcode = instruction_debug[6:0];
    wire [4:0] rd = instruction_debug[11:7];
    wire [2:0] funct3 = instruction_debug[14:12];
    wire [4:0] rs1 = instruction_debug[19:15];
    wire [4:0] rs2 = instruction_debug[24:20];
    wire [6:0] funct7 = instruction_debug[31:25];

    // RISC-V opcodes
    localparam [6:0] OPCODE_R_TYPE  = 7'b0110011;
    localparam [6:0] OPCODE_I_TYPE  = 7'b0010011;
    localparam [6:0] OPCODE_LOAD    = 7'b0000011;
    localparam [6:0] OPCODE_STORE   = 7'b0100011;
    localparam [6:0] OPCODE_BRANCH  = 7'b1100011;
    localparam [6:0] OPCODE_JAL     = 7'b1101111;
    localparam [6:0] OPCODE_JALR    = 7'b1100111;
    localparam [6:0] OPCODE_LUI     = 7'b0110111;
    localparam [6:0] OPCODE_AUIPC   = 7'b0010111;

    // Basic System Properties
    
    // Property 1: PC should be word-aligned
    property pc_word_aligned;
        @(posedge clk) disable iff (reset)
        (pc_debug[1:0] == 2'b00);
    endproperty
    
    assert property (pc_word_aligned)
        else $error("PC not word-aligned: PC = %08h", pc_debug);

    // Property 2: PC should advance by 4 for non-branch/jump instructions
    property pc_sequential_advance;
        @(posedge clk) disable iff (reset)
        (!branch_taken_debug && opcode != OPCODE_JAL && opcode != OPCODE_JALR) |=>
        (pc_debug == $past(pc_debug, 1, 1'b1, @(posedge clk)) + 4);
    endproperty
    
    assert property (pc_sequential_advance)
        else $error("PC did not advance sequentially: prev_PC = %08h, curr_PC = %08h", 
                    $past(pc_debug, 1, 1'b1, @(posedge clk)), pc_debug);

    // Property 3: Register x0 should always read as zero
    property reg_x0_always_zero;
        @(posedge clk) disable iff (reset)
        (reg_debug_addr1 == 5'b00000) |-> (reg_debug_data1 == 32'h00000000);
    endproperty
    
    assert property (reg_x0_always_zero)
        else $error("Register x0 not zero: x0 = %08h", reg_debug_data1);

    property reg_x0_always_zero_2;
        @(posedge clk) disable iff (reset)
        (reg_debug_addr2 == 5'b00000) |-> (reg_debug_data2 == 32'h00000000);
    endproperty
    
    assert property (reg_x0_always_zero_2)
        else $error("Register x0 not zero: x0 = %08h", reg_debug_data2);

    // Property 4: Register write should only occur for instructions that write registers
    property reg_write_valid_instructions;
        @(posedge clk) disable iff (reset)
        reg_write_debug |-> (opcode == OPCODE_R_TYPE || opcode == OPCODE_I_TYPE || 
                            opcode == OPCODE_LOAD || opcode == OPCODE_JAL || 
                            opcode == OPCODE_JALR || opcode == OPCODE_LUI || 
                            opcode == OPCODE_AUIPC);
    endproperty
    
    assert property (reg_write_valid_instructions)
        else $error("Invalid register write for opcode %07b", opcode);

    // Property 5: Memory read should only occur for load instructions
    property mem_read_valid_instructions;
        @(posedge clk) disable iff (reset)
        mem_read_debug |-> (opcode == OPCODE_LOAD);
    endproperty
    
    assert property (mem_read_valid_instructions)
        else $error("Invalid memory read for opcode %07b", opcode);

    // Property 6: Memory write should only occur for store instructions
    property mem_write_valid_instructions;
        @(posedge clk) disable iff (reset)
        mem_write_debug |-> (opcode == OPCODE_STORE);
    endproperty
    
    assert property (mem_write_valid_instructions)
        else $error("Invalid memory write for opcode %07b", opcode);

    // Property 7: Branch taken should only occur for branch/jump instructions
    property branch_taken_valid_instructions;
        @(posedge clk) disable iff (reset)
        branch_taken_debug |-> (opcode == OPCODE_BRANCH || opcode == OPCODE_JAL || 
                                opcode == OPCODE_JALR);
    endproperty
    
    assert property (branch_taken_valid_instructions)
        else $error("Invalid branch taken for opcode %07b", opcode);

    // Property 8: Valid opcode check
    property valid_opcode;
        @(posedge clk) disable iff (reset)
        (opcode == OPCODE_R_TYPE || opcode == OPCODE_I_TYPE || opcode == OPCODE_LOAD ||
         opcode == OPCODE_STORE || opcode == OPCODE_BRANCH || opcode == OPCODE_JAL ||
         opcode == OPCODE_JALR || opcode == OPCODE_LUI || opcode == OPCODE_AUIPC);
    endproperty
    
    assert property (valid_opcode)
        else $error("Invalid opcode: %07b", opcode);

    // Property 9: R-type instruction format validation
    property r_type_format_valid;
        @(posedge clk) disable iff (reset)
        (opcode == OPCODE_R_TYPE) |-> 
        ((funct7 == 7'b0000000 || funct7 == 7'b0100000) && 
         (funct3 >= 3'b000 && funct3 <= 3'b111));
    endproperty
    
    assert property (r_type_format_valid)
        else $error("Invalid R-type format: funct7=%07b, funct3=%03b", funct7, funct3);

    // Property 10: I-type immediate generation
    property i_type_immediate_valid;
        @(posedge clk) disable iff (reset)
        (opcode == OPCODE_I_TYPE || opcode == OPCODE_LOAD || opcode == OPCODE_JALR) |->
        (immediate_debug == {{20{instruction_debug[31]}}, instruction_debug[31:20]});
    endproperty
    
    assert property (i_type_immediate_valid)
        else $error("Invalid I-type immediate: expected=%08h, actual=%08h", 
                    {{20{instruction_debug[31]}}, instruction_debug[31:20]}, immediate_debug);

    // Property 11: ALU operation consistency for ADD instruction
    property add_instruction_alu_result;
        @(posedge clk) disable iff (reset)
        (opcode == OPCODE_R_TYPE && funct3 == 3'b000 && funct7 == 7'b0000000) |->
        (alu_result_debug == (reg_debug_data1 + reg_debug_data2));
    endproperty
    
    assert property (add_instruction_alu_result)
        else $error("ADD instruction ALU mismatch: %08h + %08h != %08h", 
                    reg_debug_data1, reg_debug_data2, alu_result_debug);

    // Property 12: ALU operation consistency for SUB instruction
    property sub_instruction_alu_result;
        @(posedge clk) disable iff (reset)
        (opcode == OPCODE_R_TYPE && funct3 == 3'b000 && funct7 == 7'b0100000) |->
        (alu_result_debug == (reg_debug_data1 - reg_debug_data2));
    endproperty
    
    assert property (sub_instruction_alu_result)
        else $error("SUB instruction ALU mismatch: %08h - %08h != %08h", 
                    reg_debug_data1, reg_debug_data2, alu_result_debug);

    // Property 13: ADDI instruction ALU result
    property addi_instruction_alu_result;
        @(posedge clk) disable iff (reset)
        (opcode == OPCODE_I_TYPE && funct3 == 3'b000) |->
        (alu_result_debug == (reg_debug_data1 + immediate_debug));
    endproperty
    
    assert property (addi_instruction_alu_result)
        else $error("ADDI instruction ALU mismatch: %08h + %08h != %08h", 
                    reg_debug_data1, immediate_debug, alu_result_debug);

    // Property 14: System stability - no X or Z values in critical signals
    property no_unknown_pc;
        @(posedge clk) disable iff (reset)
        !$isunknown(pc_debug);
    endproperty
    
    assert property (no_unknown_pc)
        else $error("PC contains unknown values: %08h", pc_debug);

    property no_unknown_instruction;
        @(posedge clk) disable iff (reset)
        !$isunknown(instruction_debug);
    endproperty
    
    assert property (no_unknown_instruction)
        else $error("Instruction contains unknown values: %08h", instruction_debug);

    // Property 15: Reset behavior
    property reset_behavior;
        @(posedge clk)
        reset |=> (pc_debug == 32'h00000000);
    endproperty
    
    assert property (reset_behavior)
        else $error("PC not reset to zero: PC = %08h", pc_debug);

    // Coverage Properties
    
    // Cover all instruction types
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_R_TYPE);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LOAD);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_STORE);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_BRANCH);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_JAL);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_JALR);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LUI);
    cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_AUIPC);

    // Cover branch taken and not taken
    cover property (@(posedge clk) disable iff (reset) branch_taken_debug);
    cover property (@(posedge clk) disable iff (reset) !branch_taken_debug && opcode == OPCODE_BRANCH);

    // Cover register writes to different registers
    cover property (@(posedge clk) disable iff (reset) reg_write_debug && rd != 5'b00000);
    cover property (@(posedge clk) disable iff (reset) reg_write_debug && rd == 5'b11111); // x31

    // Cover memory operations
    cover property (@(posedge clk) disable iff (reset) mem_read_debug);
    cover property (@(posedge clk) disable iff (reset) mem_write_debug);

endmodule