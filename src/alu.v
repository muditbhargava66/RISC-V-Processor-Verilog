module alu (
    input [3:0] alu_op,
    input [31:0] operand1,
    input [31:0] operand2,
    output reg [31:0] alu_result
);

    always @(*) begin
        case (alu_op)
            4'b0000: alu_result = operand1 + operand2;                    // ADD
            4'b1000: alu_result = operand1 - operand2;                    // SUB
            4'b0001: alu_result = operand1 << operand2[4:0];              // SLL
            4'b0010: alu_result = ($signed(operand1) < $signed(operand2)) ? 32'd1 : 32'd0; // SLT
            4'b0011: alu_result = (operand1 < operand2) ? 32'd1 : 32'd0;  // SLTU
            4'b0100: alu_result = operand1 ^ operand2;                    // XOR
            4'b0101: alu_result = operand1 >> operand2[4:0];              // SRL
            4'b1101: alu_result = $signed(operand1) >>> operand2[4:0];    // SRA
            4'b0110: alu_result = operand1 | operand2;                    // OR
            4'b0111: alu_result = operand1 & operand2;                    // AND
            default: alu_result = 32'h00000000;
        endcase
    end

endmodule