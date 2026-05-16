module int8_mac (
    input rst,          // Active-high asynchronous reset
    input valid_mac,        // When high, performs MAC operation
    input signed [7:0] A, // INT8 input A
    input signed [7:0] B, // INT8 input B
    output reg signed [31:0] result, // Accumulated output
    output signed [31:0] mult_result // multiplied output
);

    assign mult_result = A * B;

    always @(A,B,rst) begin
        if (rst)
            result <= 0;
        else if (valid_mac)
            result <= result + mult_result;
    end

endmodule
