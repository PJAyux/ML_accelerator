//pe=processing element

module pe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input clk,
    input rst,
    input [3:0]c,

    input  [DATA_WIDTH-1:0] a_in,
    input  [DATA_WIDTH-1:0] b_in,
    input  [ACC_WIDTH-1:0] accumulator,

    output reg [DATA_WIDTH-1:0] a_out,
    output reg [DATA_WIDTH-1:0] b_out,

    output reg [ACC_WIDTH-1:0] acc_out
);
always @(posedge clk) begin

    if(rst) begin
        a_out   <= 0;
        b_out   <= 0;
        acc_out <= 0;
    end

    else begin
        
        if(c==3'b111)begin
            a_out <= 0;
            b_out <= 0;

        // MAC
        acc_out <= 0;
        end
        else begin
            
        // forward data
        a_out <= a_in;
        b_out <= b_in;

        // MAC
        acc_out <= accumulator + (a_in * b_in);
        end

    end
end
endmodule
/*
    reg [DATA_WIDTH-1:0] a_reg, b_reg;
    reg [ACC_WIDTH-1:0] acc_reg;

    always @(posedge clk) begin

        if (rst) begin

            a_reg   <= 0;
            b_reg   <= 0;
            acc_reg <= 0;

        end

        else begin

            // Latch inputs
            a_reg <= a_in;
            b_reg <= b_in;

            // MAC operation
            acc_reg <= accumulator + (a_reg * b_reg);

        end
    end

    always @(posedge clk) begin

        if (rst) begin

            a_out   <= 0;
            b_out   <= 0;
            acc_out <= 0;

        end

        else begin

            // systolic forwarding
            a_out  <= a_reg;
            b_out  <= b_reg;

            acc_out <= acc_reg;

        end
    end

endmodule
*/

