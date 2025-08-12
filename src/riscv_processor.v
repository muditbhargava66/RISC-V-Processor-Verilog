// RISC-V Processor Top Module
// Single-cycle implementation of RV32I instruction set
// Production-ready for Vivado synthesis

module riscv_processor (
    input wire clk,
    input wire reset,
    output wire [31:0] pc_debug,
    output wire [31:0] instruction_debug,
    output wire [31:0] alu_result_debug
);

    // Internal signals
    wire [31:0] pc_current, pc_next, pc_plus_4;
    wire [31:0] instruction;
    wire [31:0] immediate;
    wire [31:0] read_data1, read_data2;
    wire [31:0] alu_operand1, alu_operand2, alu_result;
    wire [31:0] mem_read_data;
    wire [31:0] reg_write_data;
    wire branch_taken;
    
    // Control signals
    wire reg_write, mem_read, mem_write, branch, jump;
    wire [1:0] alu_src, reg_write_src;
    wire [3:0] alu_op;
    
    // Instruction fields
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];
    
    // Debug outputs
    assign pc_debug = pc_current;
    assign instruction_debug = instruction;
    assign alu_result_debug = alu_result;
    
    // Program Counter
    program_counter pc_inst (
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc_current(pc_current)
    );
    
    // PC + 4 calculation
    assign pc_plus_4 = pc_current + 32'd4;
    
    // PC next calculation
    assign pc_next = branch_taken ? 
                     (jump && (opcode == 7'b1100111)) ? alu_result :  // JALR: rs1 + immediate
                     (jump && (opcode == 7'b1101111)) ? (pc_current + immediate) : // JAL: PC + immediate
                     (pc_current + immediate) :  // Branch: PC + immediate
                     pc_plus_4;
    
    // Instruction Memory
    instruction_memory imem_inst (
        .address(pc_current),
        .instruction(instruction)
    );
    
    // Immediate Generator
    immediate_generator imm_gen_inst (
        .instruction(instruction),
        .immediate(immediate)
    );
    
    // Register File
    register_file regfile_inst (
        .clk(clk),
        .reset(reset),
        .reg_write(reg_write),
        .read_reg1(rs1),
        .read_reg2(rs2),
        .write_reg(rd),
        .write_data(reg_write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );
    
    // Control Unit
    control_unit control_inst (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .reg_write_src(reg_write_src)
    );
    
    // ALU operand selection
    assign alu_operand1 = read_data1;
    assign alu_operand2 = (alu_src == 2'b00) ? read_data2 :     // Register
                         (alu_src == 2'b01) ? immediate :       // Immediate
                         (alu_src == 2'b10) ? pc_current :      // PC
                         32'h00000000;                          // Default
    
    // ALU
    alu alu_inst (
        .operand_a(alu_operand1),
        .operand_b(alu_operand2),
        .alu_control(alu_op),
        .result(alu_result),
        .zero() // Not used in single-cycle implementation
    );
    
    // Data Memory
    data_memory dmem_inst (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(alu_result),
        .write_data(read_data2),
        .funct3(funct3),
        .read_data(mem_read_data)
    );
    
    // Register write data selection
    assign reg_write_data = (reg_write_src == 2'b00) ? alu_result :     // ALU result
                           (reg_write_src == 2'b01) ? mem_read_data :   // Memory data
                           (reg_write_src == 2'b10) ? pc_plus_4 :       // PC+4
                           32'h00000000;                                // Default
    
    // Branch Unit
    branch_unit branch_inst (
        .funct3(funct3),
        .operand1(read_data1),
        .operand2(read_data2),
        .branch(branch),
        .jump(jump),
        .branch_taken(branch_taken)
    );

endmodule