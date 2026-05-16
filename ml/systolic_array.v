
module my_systolic_array #(
    parameter N = 8,
    parameter M=4,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input clk,
    input rst,
    input en,

    input  [DATA_WIDTH-1:0] a_in [0:M-1][0:M-1], // row inputs
    input  [DATA_WIDTH-1:0] b_in [0:M-1][0:M-1], // column inputs

    output [ACC_WIDTH-1:0] c_out [0:M-1][0:M-1],
    output done
);


    reg[DATA_WIDTH-1:0] a_pad[0:N-1][0:N-1];
    reg[DATA_WIDTH-1:0] b_pad[0:N-1][0:N-1];


//check debug
wire[31:0] a_in_check,a_check,a_pad_check,acc_next_check,accumulator_check,b_check;
assign b_check=b_wire[0][0];
assign a_in_check=a_in[0][3];
assign a_pad_check=a_pad[0][6];
assign accumulator_check= accumulator[1][1];
assign acc_next_check=acc_next[1][1];
assign a_check=a_wire[0][0];
    integer i, j;

    reg[ACC_WIDTH-1:0] accumulator[0:N-1][0:N-1];
    
    wire [ACC_WIDTH-1:0] acc_next [0:N-1][0:N-1];

    // reg can update wire as assign and wire can update reg in always block
/*genvar row, col;
generate
    for (row = 0; row < N; row = row + 1) begin : row_gen
        for (col = 0; col < N; col = col + 1) begin : col_gen
            assign acc_prev[row][col] = accumulator[row][col];
        end
    end
endgenerate*/

reg[3:0] c;
reg done;
    /// initialize accumulator for partial sum
    //en logic to switch on the systolic array
    //counter for updating the pad matrix other wires are updated form clk of PE
    // last cycle is extra just to refresh
always @(posedge clk) begin
    if(rst || !en) begin
        for(i=0;i<N;i=i+1)
            for(j=0;j<N;j=j+1)
                accumulator[i][j] <= 0;
        c<=3'd7;
        done<=0;
    end
    else begin
        if(c==3'd6)begin
            done<=1;
            c<=c+1;
        end
        else begin
            if(c==3'd7)c<=3'd0;
            else c<=c+1;
        end
    end
end

always@(*)begin
    for(i=0;i<N;i=i+1)
        for(j=0;j<N;j=j+1)
           accumulator[i][j] <= acc_next[i][j]; 
end

always@(posedge clk)begin
    //updated done to prev clock and set initial cond to c=7;
    if(c==3'd7)begin
    for(i=0;i<N;i=i+1) begin
        for(j=0;j<N;j=j+1) begin

            if(i >= M) begin
                a_pad[i][j] <= 0;
            end
            else if((i+j-M) < 0 ||
                    (i+j-(M-1)) > M) begin
                a_pad[i][j] <= 0;
            end
            else begin
                 a_pad[i][j] <= a_in[i][i+j-M];
            end
        end
        end
    end
    else begin
        for(i=0;i<N;i=i+1) begin
        for(j=1;j<N;j=j+1) begin
            a_pad[i][j]<=a_pad[i][j-1];
        end
        end
    end
end
always@(posedge clk)begin
    //padding updated logic
    if(c==3'd7)begin
    for(i=0;i<N;i=i+1) begin
        for(j=0;j<N;j=j+1) begin

            if(j >= M) begin
                b_pad[i][j] <= 0;
            end
            else if((i+j-(M)) < 0 ||
                    (i+j-(M-1)) > M) begin
                b_pad[i][j] <= 0;
            end
            else begin
                 b_pad[i][j] <= b_in[i+j-(M)][j];
            end
            end
        end
    end
    else begin
        for(i=1;i<N;i=i+1) begin
        for(j=0;j<N;j=j+1) begin
            b_pad[i][j]<=b_pad[i-1][j];
        end
        end
    end
end

   /* /// a padding
    always@(*)begin
    for(i=0;i<N;i=i+1) begin
        for(j=0;j<N;j=j+1) begin

            if(i >= M) begin
                a_pad[i][j] = 0;
            end
            else if((i+j-M) < 0 ||
                    (i+j-(M-1)) > M) begin
                a_pad[i][j] = 0;
            end
            else begin
                 a_pad[i][j] = a_in[i][i+j-M];
            end

        end
    end
end

///// b padding for timing sync
    always@(*)begin
    for(i=0;i<N;i=i+1) begin
        for(j=0;j<N;j=j+1) begin

            if(j >= M) begin
                b_pad[i][j] = 0;
            end
            else if((i+j-(M)) < 0 ||
                    (i+j-(M-1)) > M) begin
                b_pad[i][j] = 0;
            end
            else begin
                 b_pad[i][j] = b_in[i+j-(M)][j];
            end

        end
    end
end
*/


    // Internal wires for interconnections
    wire [DATA_WIDTH-1:0] a_wire [0:N-1][0:N-1];
    wire [DATA_WIDTH-1:0] b_wire [0:N-1][0:N-1];

    genvar ii,jj;
 /* // checking debugging
   pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst(rst),
 
                    .a_in(a_pad[0][7]),
                    .b_in(b_pad[7][0]),
                    .accumulator(accumulator[0][0]),

                    .a_out(a_wire[0][0]),
                    .b_out(b_wire[0][0]),
                    .acc_out(acc_next[0][0])
                );

*/
    // dot product layer a_pad layer b_pad then sum with layer c_out
    generate
    for (ii = 0; ii < N; ii = ii + 1) begin: row
        for (jj = 0; jj < N; jj = jj + 1) begin: col

            if (jj == 0 && ii == 0) begin

                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .c(c),
 
                    .a_in(a_pad[ii][N-1-jj]),
                    .b_in(b_pad[N-ii-1][jj]),
                    .accumulator(accumulator[ii][jj]),

                    .a_out(a_wire[ii][jj]),
                    .b_out(b_wire[ii][jj]),
                    .acc_out(acc_next[ii][jj])
                );

            end

            else if (jj == 0) begin

                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .c(c),

                    .a_in(a_pad[ii][N-1-jj]),
                    .b_in(b_wire[ii-1][jj]),
                    .accumulator(accumulator[ii][jj]),

                    .a_out(a_wire[ii][jj]),
                    .b_out(b_wire[ii][jj]),
                    .acc_out(acc_next[ii][jj])
                );

            end

            else if (ii == 0) begin

                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .c(c),
                    

                    .a_in(a_wire[ii][jj-1]),
                    .b_in(b_pad[N-ii-1][jj]),
                    .accumulator(accumulator[ii][jj]),

                    .a_out(a_wire[ii][jj]),
                    .b_out(b_wire[ii][jj]),
                    .acc_out(acc_next[ii][jj])
                );

            end

            else begin

                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst(rst),

                    .a_in(a_wire[ii][jj-1]),
                    .b_in(b_wire[ii-1][jj]),
                    .accumulator(accumulator[ii][jj]),
                    .c(c),


                    .a_out(a_wire[ii][jj]),
                    .b_out(b_wire[ii][jj]),
                    .acc_out(acc_next[ii][jj])
                );

            end
        end
    end
endgenerate


    genvar u,v;
    generate
        for(u=0; u<M; u=u+1)begin
            for(v=0;v<M;v=v+1)begin
                assign c_out[u][v]=accumulator[u][v];
            end
        end
        endgenerate



endmodule



/*module systolic_array #(
    parameter N = 8,
    parameter M=4,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input clk,
    input rst,

    input  [DATA_WIDTH-1:0] a_in [0:M-1][0:M-1], // row inputs
    input  [DATA_WIDTH-1:0] b_in [0:M-1][0:M-1], // column inputs

    output [ACC_WIDTH-1:0] c_out [0:N-1][0:N-1]
);


    // Internal wires for interconnections
    wire [DATA_WIDTH-1:0] a_wire [0:N-1][0:N-1];
    wire [DATA_WIDTH-1:0] b_wire [0:N-1][0:N-1];



    generate
        for (i = 0; i < N; i = i + 1) begin: row
            for (j = 0; j < N; j = j + 1) begin: col

                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst(rst),

                    // Input connections
                    .a_in( (j == 0) ? a_in[i] : a_wire[i][j-1] ),
                    .b_in( (i == 0) ? b_in[j] : b_wire[i-1][j] ),

                    // Output connections
                    .a_out( a_wire[i][j] ),
                    .b_out( b_wire[i][j] ),

                    .acc_out( c_out[i][j] )
                );

            end
        end
    endgenerate

endmodule
*/