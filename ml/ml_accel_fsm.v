module ml_accel_fsm (
    input clk,
    input reset,
    input start,
    input data_ready,  // for fifo conncetivity or UART connectivity
    input done,
    input ack,
    output reg busy,
    output reg compute_en,   // enable for the processor
    output reg idle
);

    parameter IDLE = 2'b00,
              WAIT = 2'b01,
              BUSY = 2'b10,
              DONE = 2'b11;

    reg [1:0] current_state, next_state;
    //fifo of depth 4 to hold values of 2x2 matrix
    reg[3:0]fifo;
    reg[1:0] index;

    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    
    always @(*) begin
        // default
        next_state   = current_state;
        busy         = 0;
        compute_en   = 0;
        idle         = 0;

        case (current_state)
            IDLE: begin
                idle = 1;
                if (start)
                    next_state = WAIT;
            end

            WAIT: begin
                if (data_ready)
                    next_state = BUSY;
                    fifo[index]=data_ready;
                    index=index+1;
            end

            BUSY: begin
                busy= 1;
                compute_en = 1;
                if (done)
                    next_state = DONE;
            end

            DONE: begin
                if (ack)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule