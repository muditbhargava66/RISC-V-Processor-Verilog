module immediate_generator (
    input [31:0] instruction,
    input [2:0] inst_type,
    output reg [31:0] immediate
);

    // Instruction type encoding
    localparam [2:0] I_TYPE = 3'b000;
    localparam [2:0] S_TYPE = 3'b001;
    localparam [2:0] B_TYPE = 3'b010;
    localparam [2:0] U_TYPE = 3'b011;
    localparam [2:0] J_TYPE = 3'b100;

    always @(*) begin
        case (inst_type)
            I_TYPE: begin
                // I-type: imm[11:0] = inst[31:20]
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            
            S_TYPE: begin
                // S-type: imm[11:0] = {inst[31:25], inst[11:7]}
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            
            B_TYPE: begin
                // B-type: imm[12:1] = {inst[31], inst[7], inst[30:25], inst[11:8]}
                immediate = {{19{instruction[31]}}, instruction[31], instruction[7], 
                           instruction[30:25], instruction[11:8], 1'b0};
            end
            
            U_TYPE: begin
                // U-type: imm[31:12] = inst[31:12], imm[11:0] = 0
                immediate = {instruction[31:12], 12'b0};
            end
            
            J_TYPE: begin
                // J-type: imm[20:1] = {inst[31], inst[19:12], inst[20], inst[30:21]}
                immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
                           instruction[20], instruction[30:21], 1'b0};
            end
            
            default: begin
                immediate = 32'h00000000;
            end
        endcase
    end

endmodule