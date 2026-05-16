module scaling #(
    parameter DATA_WIDTH = 32,
    parameter SCALE_WIDTH = 16
)(
    input  signed [7:0] in,            // Input value
    input  signed [SCALE_WIDTH-1:0] scale_factor, // Multiplier
    input  [4:0] shift_amount,                    // Right shift (0–31)
    output signed [DATA_WIDTH-1:0] out            // Scaled output
);
    wire signed [DATA_WIDTH+SCALE_WIDTH-1:0] product;
    assign product = in * scale_factor;

    assign out = product >>> shift_amount;
endmodule


/*
out = (50 × 256) >> 8 = 12800 >> 8 = 50
*/