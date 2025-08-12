// Immediate Generator Module
// Extracts and sign-extends immediates for all instruction types

module immediate_generator (
    input wire [31:0] instruction,
    output reg [31:0] immediate
);

    wire [6:0] opcode = instruction[6:0];
    
    always @(*) begin
        case (opcode)
            // I-type instructions
            7'b0010011, 7'b0000011, 7'b1100111: begin
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            
            // S-type instructions
            7'b0100011: begin
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            
            // B-type instructions
            7'b1100011: begin
                immediate = {{19{instruction[31]}}, instruction[31], instruction[7], 
                           instruction[30:25], instruction[11:8], 1'b0};
            end
            
            // U-type instructions
            7'b0110111, 7'b0010111: begin
                immediate = {instruction[31:12], 12'b0};
            end
            
            // J-type instructions
            7'b1101111: begin
                immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
                           instruction[20], instruction[30:21], 1'b0};
            end
            
            default: begin
                immediate = 32'h00000000;
            end
        endcase
    end

endmodule