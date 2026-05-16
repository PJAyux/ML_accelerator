module sigmoid_approx (
    input  signed [7:0] in,
    output reg    [31:0]  out  // Q8.8 fixed point output (0–255 maps to 0.0–1.0)
);

    wire[31:0] in_extended;
    assign in_extended=in;

    always @(*) begin
        if (in <= -32)        // ~ -4.0
            out = 31'd0;
        else if (in >= 32)    // ~ +4.0
            out = 31'd255;
        else
            out = 31'd128 + (in_extended <<< 2); // 0.5 + x/8
    end
endmodule

/*
module sigmoid_approx (
    input  signed [7:0]  in,  // Q4.4 format (approx -8.0 to +7.9)
    output reg    [31:0] out  // Q24.8 output
);

    // Internal wires for absolute value to exploit symmetry
    wire [7:0] abs_in = (in[7]) ? -in : in;
    reg  [15:0] temp_out; // Intermediate 16-bit to prevent overflow before extension

    always @(*) begin
        if (abs_in >= 8'd80) begin          // |x| >= 5.0
            temp_out = 16'd255;
        end 
        else if (abs_in >= 8'd40) begin     // 2.5 <= |x| < 5.0
            // Shallow slope: y = 1/16 * |x| + 0.8125
            temp_out = 16'd208 + (abs_in >> 4);
        end 
        else if (abs_in >= 8'd16) begin     // 1.0 <= |x| < 2.5
            // Medium slope: y = 1/8 * |x| + 0.625
            temp_out = 16'd160 + (abs_in >> 3);
        end 
        else begin                          // 0 <= |x| < 1.0
            // Steep slope: y = 1/4 * |x| + 0.5
            temp_out = 16'd128 + (abs_in >> 2);
        end

        // Apply symmetry: if in was negative, result is (1.0 - temp_out)
        // Then zero-extend to 32 bits
        if (in[7]) 
            out = {16'b0, (8'd255 - temp_out[7:0])};
        else 
            out = {16'b0, temp_out[7:0]};
    end
endmodule
*/