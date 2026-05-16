//dot_product_bnn = popcount(XNOR(input, weight))
module bnn_compute #(
    parameter WIDTH = 8,
    parameter ACC_WIDTH=32
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [ACC_WIDTH-1:0] out
);
    integer i;

    wire[WIDTH-1:0] x_nor;
    assign x_nor=(~(a^b));


    reg [ACC_WIDTH-1:0] count;

    
    always @(*) begin
        count = 0;
        for (i = 0; i < WIDTH; i = i + 1)
            count = count + x_nor[i];
    end
    assign out = count;
endmodule

