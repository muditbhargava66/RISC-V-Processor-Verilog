module branch_unit (
    input [2:0] funct3,
    input [31:0] operand1,
    input [31:0] operand2,
    input branch,
    input jump,
    output reg branch_taken
);

    always @(*) begin
        branch_taken = 0;
        
        if (jump) begin
            branch_taken = 1;
        end else if (branch) begin
            case (funct3)
                3'b000: branch_taken = (operand1 == operand2);                    // BEQ
                3'b001: branch_taken = (operand1 != operand2);                    // BNE
                3'b100: branch_taken = ($signed(operand1) < $signed(operand2));   // BLT
                3'b101: branch_taken = ($signed(operand1) >= $signed(operand2));  // BGE
                3'b110: branch_taken = (operand1 < operand2);                     // BLTU
                3'b111: branch_taken = (operand1 >= operand2);                    // BGEU
                default: branch_taken = 0;
            endcase
        end
    end

endmodule