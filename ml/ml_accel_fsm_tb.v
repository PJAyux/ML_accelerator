`timescale 1ns / 1ps

module tb_ml_accel_fsm;

    reg clk, reset;
    reg start, data_ready, done, ack;
    wire busy, compute_en, idle;

    // Instantiate the DUT
    ml_accel_fsm dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .data_ready(data_ready),
        .done(done),
        .ack(ack),
        .busy(busy),
        .compute_en(compute_en),
        .idle(idle)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test stimulus
    initial begin
        $dumpfile("ml_accel_fsm.vcd");
        $dumpvars(0, tb_ml_accel_fsm);

        // Initialize signals
        reset = 1; start = 0; data_ready = 0; done = 0; ack = 0;
        #10 reset = 0;

        // Trigger start
        #10 start = 1;
        #10 start = 0;

        // Simulate data ready
        #20 data_ready = 1;
        #10 data_ready = 0;

        // Simulate done
        #30 done = 1;
        #10 done = 0;

        // Acknowledge
        #20 ack = 1;
        #10 ack = 0;

        #50 $finish;
    end

endmodule