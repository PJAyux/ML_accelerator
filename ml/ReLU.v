module relu (
    input  signed [7:0] in,
    output signed [31:0] out
);
    assign out = (in > 0) ? in : 0;
endmodule
