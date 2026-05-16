module clip (
    input  signed [7:0] in,
    input  signed [31:0] min_val,
    input  signed [31:0] max_val,
    output signed [31:0] out
);
    assign out = (in > max_val) ? max_val :
                 (in < min_val) ? min_val :
                 in;
endmodule


/*
module clip (
    input  signed [31:0] in,
    input  signed [31:0] min_val,
    input  signed [31:0] max_val,
    output signed [31:0] out
);
    assign out = (in > max_val) ? max_val :
                 (in < min_val) ? min_val :
                 in;
endmodule
*/