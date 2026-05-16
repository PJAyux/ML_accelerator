// model in the end
// a pipeline has to build with the fetch+decode module then execture_top and writeback module
// in the top module it is set as always @(posedge bigclk) wire assign fetch+decode_out = execute_top_input similarly for write_back

module execute_top (
    input clk,
    input bigclk,
    // bigclk generated after 8 clk pulses
    input rst,
    input rd_wr_bar,

    input signed [7:0] reg_a,
    input signed [7:0] reg_b,

    input signed [7:0] matrix_a [0:3][0:3],
    input signed [7:0] matrix_b [0:3][0:3],

    input [3:0] opcode,

    input [3:0] addr_a,
    input [3:0] addr_b,

    output [3:0] addr_a_next,
    output [3:0] addr_b_next,
    output rd_wr_bar_next,

    output reg signed [31:0] cout
);

    //----------------------------------------------------
    // Pipeline forwarding signals
    //----------------------------------------------------

    assign addr_a_next    = addr_a;
    assign addr_b_next    = addr_b;
    assign rd_wr_bar_next = rd_wr_bar;

    //----------------------------------------------------
    // Internal wires
    //----------------------------------------------------

    wire signed [31:0] relu_out;
    wire signed [31:0] mac_out;
    wire signed [31:0] popcount_out;
    wire signed [31:0] bnn_out;
    wire signed [31:0] clip_out;
    wire signed [31:0] dot_prod_out;
    wire signed [31:0] scaling_out;
    wire signed [31:0] sigmoid_out;
    wire signed [31:0] tanh_out;

    reg [2:0] max_index;
    reg signed[31:0] max_value;

    //----------------------------------------------------
    // Temporary vectors for dot product
    //----------------------------------------------------

    wire signed [7:0] vecA [0:3];
    wire signed [7:0] vecB [0:3];

    assign vecA[0] = matrix_a[0][0];
    assign vecA[1] = matrix_a[0][1];
    assign vecA[2] = matrix_a[0][2];
    assign vecA[3] = matrix_a[0][3];

    assign vecB[0] = matrix_b[0][0];
    assign vecB[1] = matrix_b[0][1];
    assign vecB[2] = matrix_b[0][2];
    assign vecB[3] = matrix_b[0][3];


    
    wire valid_dot;
    wire valid_mac;
    assign valid_dot=1'b1;
    assign valid_mac=1'b1;

    // can send this valid_dot and valid_mac from the processor into pipeline 

    wire [31:0]mult_result;

    //----------------------------------------------------
    // ReLU
    //----------------------------------------------------

    relu relu_u (
        .in(reg_a),
        .out(relu_out)
    );

    //----------------------------------------------------
    // MAC
    //----------------------------------------------------

    int8_mac mac_u (
        .rst(rst),
        .valid_mac(valid_mac),
        .A(reg_a),
        .B(reg_b),
        .result(mac_out),
        .mult_result(mult_result)
    );

    //----------------------------------------------------
    // Popcount
    //----------------------------------------------------

    popcount8 pop_u (
        .in(reg_a),
        .out(popcount_out)
    );

    //----------------------------------------------------
    // BNN
    //----------------------------------------------------

    bnn_compute bnn_u (
        .a(reg_a),
        .b(reg_b),
        .out(bnn_out)
    );

    //----------------------------------------------------
    // Clip
    //----------------------------------------------------

    clip clip_u (
        .in(reg_a),
        .min_val(-32),
        .max_val(32),
        .out(clip_out)
    );

    //----------------------------------------------------
    // Dot Product
    //----------------------------------------------------

    dot_product_4 dot_u (
        .rst(rst),
        .valid_dot(valid_dot),
        .A(vecA),
        .B(vecB),
        .result(dot_prod_out)
    );

    //----------------------------------------------------
    // Scaling
    //----------------------------------------------------

    scaling scale_u (
        .in(reg_a),
        .scale_factor(16'd2),
        .shift_amount(5'd1),
        .out(scaling_out)
    );

    //----------------------------------------------------
    // Sigmoid Approximation
    //----------------------------------------------------

    sigmoid_approx sig_u (
        .in(reg_a),
        .out(sigmoid_out)
    );

    //----------------------------------------------------
    // Tanh Approximation
    //----------------------------------------------------

    tanh_approx tanh_u (
        .in(reg_a),
        .out(tanh_out)
    );

    //----------------------------------------------------
    // Max
    //----------------------------------------------------

    argmax max_u(
        .in(vecA),
        .max_index(max_index),
        .max_value(max_value)
    );

    wire signed [31:0] matrix_c_out[3:0][3:0];
    reg valid_mat;
    wire valid_mat_wire;
    assign valid_mat_wire = valid_mat;
    reg done_mat;


     matrix_mult_4x4 mat(
    .clk(clk),
    .rst(rst),
    .valid(valid_mat_wire),
    .A(matrix_a), // A: 4x4
    .B(matrix_b), // B: 4x4
    .C(matrix_c_out), // C: 4x4
    .done(done_mat)
    );

    wire [31:0]systolic_c_out[3:0][3:0];
    assign check1=systolic_c_out[0][0];
    assign check2=systolic_c_out[0][1];
    assign check3=systolic_c_out[0][2];
    assign check4=systolic_c_out[0][3];

    reg en_sys;
    wire en_sys_wire;
    assign en_sys_wire=en_sys;
    wire done_sys;

    my_systolic_array sys(
        .clk(clk),
        .rst(rst),
        .a_in(matrix_a),
        .b_in(matrix_b),
        .c_out(systolic_c_out),
        .en(en_sys_wire),
        .done(done_sys)
    );

    //----------------------------------------------------
    // Execute Stage
    // Controlled using bigclk
    //----------------------------------------------------
    integer m,n;

    always @(posedge bigclk or posedge rst) begin

        if (rst) begin
            cout <= 32'd0;
            valid_mat<=0;
            en_sys<=0;
        end

        else begin

     case(opcode)
                4'b0000: cout <= bnn_out;
                4'b0001: cout <= clip_out;
                4'b0010: cout <= dot_prod_out;
                4'b0011: cout <= mac_out;
                4'b0100: cout <= relu_out;
                4'b0101: cout <= popcount_out;
                4'b0110: cout <= scaling_out;
                4'b0111: cout <= sigmoid_out;
                4'b1000: cout <= tanh_out;
                4'b1001: cout <= max_value;
                4'b1010:begin
                     if(done_mat)begin
                        cout <=matrix_c_out[0][0];
                        valid_mat<=0;
                     end
                     else valid_mat<=1;
                end
                4'b1011: begin
                    if(!done_sys)en_sys<=1;
                    else begin
                        cout<=systolic_c_out[0][0];
                        en_sys<=0;
                    end
                end
                default: cout <= 32'd0;
            endcase
        end
    end
endmodule

/*
module execute_top (
    input clk,
    input bigclk,
    // bigclk = 8 clk pulses in top module counter==8 bigclk= ~bigclk
    input rst,
    input rd_wr_bar,


    input signed [7:0] matrix_a [0:3][0:3],
    input signed [7:0] matrix_b [0:3][0:3],

    input [3:0] opcode,

    input [3:0] addr_a,
    input [3:0] addr_b,

    output [3:0] addr_a_next,
    output [3:0] addr_b_next,
    output rd_wr_bar_next,

    output reg signed [31:0] couts
);

    wire signed [7:0] reg_a;
    wire signed [7:0] reg_b;

    assign reg_a = matrix_a[0][0];
    assign reg_b = matrix_b[0][0];

    

    // for next layer pipeline writeback
    assign addr_a_next=addr_a;
    assign addr_b_next=addr_b;
    assign rd_wr_bar_next=rd_wr_bar;




    wire signed [31:0] bnn_out;
    wire signed [31:0] clip_out;
    wire signed [31:0] dot_prod_out;
    wire signed [31:0] mac_out;
    wire signed [31:0] max_out;
    wire [31:0] popcount_out;
    wire signed [31:0] relu_out;
    wire signed [31:0] scaling_out;
    wire signed [31:0] sigmoid_out;
    wire signed [31:0] systolic_array_out;
    wire signed [31:0] tanh_out;


    ReLU relu_u(
        .in(reg_a),
        .out(relu_out)
    );

    mac mac_u(
        .clk(clk),
        .rst(rst),
        .a(reg_a),
        .b(reg_b),
        .out(mac_out)
    );

    popcount pop_u(
        .in(reg_a),
        .out(pop_out)
    );

    bnn bnn_u(
        .a(reg_a),
        .b(reg_b),
        .out(bnn_out)
    );

    ///similarly

    /// here clk needs to be passed to systolic array for 8 counts

    always @(posedge bigclk or posedge rst) begin

        if (rst) begin
            cout <= 32'd0;
        end

        else begin

                case(opcode)

                    // bnn
                    4'b0000:
                        cout <= bnn_out;

                    // clipout
                    4'b0001:
                        cout <= clip_out;

                    // dot_prod
                    4'b0010:
                        cout <= dot_prod_out;

                    // mac
                    4'b0011:
                        cout <= mac_out;

                        ///similarly
                endcase
        end
    end

    
endmodule
*/
