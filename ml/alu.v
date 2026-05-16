module alu (
    input[7:0] src1,
    input[7:0] src2,
    input[5:0] alu_control,
    input[3:0] shamt,//shift amount
    output reg[31:0] result
);
    always @(*) begin
        case (alu_control)
            6'b000001:result=src1+src2;
            6'b000010:result=src1-src2;
            6'b000011:result=src1<<src2;
            6'b000100:result=(src1 < src)?1:0;
            6'b000101:result=src |src;
            6'b000110:result=src ^ src;
            6'b000110:result=src<<src;
            6'b000111:result=(src1 > src)?1:0;
        endcase
    end
    
endmodule