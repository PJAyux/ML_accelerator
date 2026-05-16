`timescale 1ns/1ps

module execute_top_tb;

    //----------------------------------------------------
    // Clock and Reset
    //----------------------------------------------------

    reg clk;
    reg bigclk;
    reg rst;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 10ns clock
    end

    initial begin
        bigclk = 1;
        forever #40 bigclk = ~bigclk; // slower pipeline clock
    end

    //----------------------------------------------------
    // DUT Inputs
    //----------------------------------------------------

    reg rd_wr_bar;

    reg signed [7:0] reg_a;
    reg signed [7:0] reg_b;

    reg signed [7:0] matrix_a [0:3][0:3];
    reg signed [7:0] matrix_b [0:3][0:3];

    reg [3:0] opcode;

    reg [3:0] addr_a;
    reg [3:0] addr_b;

    //----------------------------------------------------
    // DUT Outputs
    //----------------------------------------------------

    wire [3:0] addr_a_next;
    wire [3:0] addr_b_next;
    wire rd_wr_bar_next;

    wire signed [31:0] cout;

    //----------------------------------------------------
    // DUT Instantiation
    //----------------------------------------------------

    execute_top dut (

        .clk(clk),
        .bigclk(bigclk),
        .rst(rst),
        .rd_wr_bar(rd_wr_bar),

        .reg_a(reg_a),
        .reg_b(reg_b),

        .matrix_a(matrix_a),
        .matrix_b(matrix_b),

        .opcode(opcode),

        .addr_a(addr_a),
        .addr_b(addr_b),

        .addr_a_next(addr_a_next),
        .addr_b_next(addr_b_next),
        .rd_wr_bar_next(rd_wr_bar_next),

        .cout(cout)
    );

    //----------------------------------------------------
    // Test Procedure
    //----------------------------------------------------

    integer i, j;

    initial begin

        $dumpfile("waveform.vcd");
        $dumpvars(0, execute_top_tb);

        //------------------------------------------------
        // Initialize
        //------------------------------------------------

        rst = 1;
        rd_wr_bar = 0;

        reg_a = 0;
        reg_b = 0;

        opcode = 0;

        addr_a = 4'd0;
        addr_b = 4'd0;

        //------------------------------------------------
        // Initialize matrices
        //------------------------------------------------

        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin

                matrix_a[i][j] = i + j + 1;
                matrix_b[i][j] = (i * 4) + j;

            end
        end

        #200;
        rst = 0;

        //------------------------------------------------
        // Test ReLU
        //------------------------------------------------

        reg_a = -8;
        opcode = 4'b0100;

        #100;

        $display("ReLU Output = %d", cout);

        //------------------------------------------------
        // Test MAC
        //------------------------------------------------

        reg_a = 5;
        reg_b = 3;

        opcode = 4'b0011;

        #100;

        $display("MAC Output = %d", cout);

        //------------------------------------------------
        // Test Popcount
        //------------------------------------------------

        reg_a = 8'b10101101;

        opcode = 4'b0101;

        #100;

        $display("Popcount Output = %d", cout);

        //------------------------------------------------
        // Test Dot Product
        //------------------------------------------------

        opcode = 4'b0010;

        #100;

        $display("Dot Product Output = %d", cout);

        //------------------------------------------------
        // Test Sigmoid
        //------------------------------------------------

        reg_a = 10;
        reg_b = 2;

        opcode = 4'b0111;

        #100;

        $display("Sigmoid Output = %d", cout);

        //------------------------------------------------
        // Test Tanh
        //------------------------------------------------

        opcode = 4'b1000;

        #100;

        $display("Tanh Output = %d", cout);

        //------------------------------------------------
        // Test Max Finder
        //------------------------------------------------

        opcode = 4'b1001;

        #100;

        $display("Max Value Output = %d", cout);
    
        //--------------------------------------------------------
        // matrix_mul
        //--------------------------------------------------------

        opcode=4'b1010;
        #200

        $display("col 1=%d",cout);
        //--------------------------------------------------------
        // systolic
        //--------------------------------------------------------

        opcode=4'b1011;
        #200

        $display("sys 1=%d",cout);


        //------------------------------------------------
        // Finish
        //------------------------------------------------

        #100;
        $finish;

    end



    //----------------------------------------------------
    // Monitor
    //----------------------------------------------------

    initial begin

        $display(
            "TIME=%0t | OPCODE=%b | reg_a=%d | reg_b=%d | cout=%d",
            $time,
            opcode,
            reg_a,
            reg_b,
            cout
        );

    end

endmodule