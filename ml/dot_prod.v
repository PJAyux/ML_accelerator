// using fsm we cannot do since the matrix_mul takes clk as input and for each row then so many sub clks will be used
// array of length 4 element wise multiplication
module dot_product_4 (
    input rst,
    input valid_dot,
    input signed [7:0] A[0:3],
    input signed [7:0] B[0:3],
    output signed [31:0] result
);

    wire signed [31:0] mac_out [0:3];
    reg signed [31:0] acc_res[0:3];

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : MACS
            int8_mac mac (
                .rst(rst),
                .valid_mac(valid_dot),
                .A(A[i]),
                .B(B[i]),
                .result(acc_res[i]),
                .mult_result(mac_out[i])
            );
        end
    endgenerate

    assign result = mac_out[0] + mac_out[1] + mac_out[2] + mac_out[3];

endmodule
