
module matrix_mult_4x4 (
    input clk,
    input rst,
    input valid,
    input signed [7:0] A[0:3][0:3], // A: 4x4
    input signed [7:0] B[0:3][0:3], // B: 4x4
    output reg signed [31:0] C[0:3][0:3], // C: 4x4
    output reg done
);

    // Stage 1: Transpose B to B_T
    reg signed [7:0] B_T_reg[0:3][0:3];
    reg signed [7:0] A_reg[0:3][0:3];


    reg stage1_done;
    integer i, j;

    // Stage 2 pipeline control
    wire [31:0] dot_results[0:3][0:3];
    reg stage2_valid;

    //  precompute  for previous data 4x4 dot products
    generate
        genvar m, n;
        for (m = 0; m < 4; m = m + 1) begin : row
            for (n = 0; n < 4; n = n + 1) begin : col
            wire signed [7:0] a_wire [0:3];
            wire signed [7:0] b_wire [0:3];

            assign a_wire[0] = A_reg[m][0];
            assign a_wire[1] = A_reg[m][1];
            assign a_wire[2] = A_reg[m][2];
            assign a_wire[3] = A_reg[m][3];

            assign b_wire[0] = B_T_reg[n][0];
            assign b_wire[1] = B_T_reg[n][1];
            assign b_wire[2] = B_T_reg[n][2];
            assign b_wire[3] = B_T_reg[n][3];
                dot_product_4 dp (
                    .rst(rst),
                    .valid_dot(stage2_valid),
                    .A(a_wire),
                    .B(b_wire),
                    .result(dot_results[m][n])
                );
                
            end
        end
    endgenerate

reg[31:0] cr1,cr2,cr3,cr4;
        

    reg[2:0] state,nextstate;

    always@(*)begin
        case(state)
            3'b000:begin
                if(valid) nextstate=3'b001;
                else nextstate=3'b000;
            end
            3'b001:begin
                nextstate=3'b010;
            end
            3'b010:begin
                nextstate=3'b011;
            end
            3'b011:begin
                nextstate=3'b100;
            end
            3'b100:begin
                nextstate=3'b100;
            end
            default:begin
                stage1_done  = 0;
                stage2_valid = 0;
                done         = 0;
                nextstate =3'b000;
            end
        endcase
    end

    always @(posedge clk) begin
        
        if (rst || !valid) begin
            state<=0;
            stage1_done<=0;
            stage2_valid<=0;
            done<=0;
            cr1<=0;
            cr2<=0;
            cr3<=0;
            cr4<=0;
        end   
        else begin
            state<=nextstate;
            if(state==3'b000)begin
                stage1_done<=0;
                stage2_valid<=0;
                done<=0;
            end
            else if(state==3'b001)begin
                for (i = 0; i < 4; i = i + 1) begin
                    for (j = 0; j < 4; j = j + 1) begin
                        A_reg[i][j] <= A[i][j];
                        B_T_reg[j][i] <= B[i][j]; // Transpose
                    end
                end
                stage1_done<=1;
                stage2_valid<=0;
                done<=0;
            end
            else if(state==3'b010)begin
                stage1_done<=0;
                stage2_valid<=1;
                done<=0;
            end
            else if(state==3'b011)begin
                for (i = 0; i < 4; i = i + 1)
                    for (j = 0; j < 4; j = j + 1)
                        C[i][j] <= dot_results[i][j];
                stage1_done<=0;
                stage2_valid<=0;
                done<=0;
            end
            else if(state==3'b100)begin
                cr1<=C[0][0];
                cr2<=C[0][1];
                stage1_done<=0;
                stage2_valid<=0;
                done<=1;
            end
            else begin
                stage1_done<=0;
                stage2_valid<=0;
                done<=0;
            end
            
            end
        end


endmodule







// module matrix_mult_4x4 (
//     input clk,
//     input rst,
//     input valid,
//     input signed [7:0] A[0:3][0:3], // A: 4x4
//     input signed [7:0] B[0:3][0:3], // B: 4x4
//     output signed [31:0] C[0:3][0:3] // C: 4x4
// );
//     genvar m, n, k;

//     // Transpose B for easy column access
//     wire signed [7:0] B_T[0:3][0:3];


//     generate
//         for (m = 0; m < 4; m = m + 1)
//             for (n = 0; n < 4; n = n + 1)
//                 assign B_T[n][m] = B[m][n];
//     endgenerate

//     // Generate 4x4 dot product units
//     generate
//         for (m = 0; m < 4; m = m + 1) begin : ROWS
//             for (n = 0; n < 4; n = n + 1) begin : COLS
//                 dot_product_4 dp (
//                     .clk(clk),
//                     .rst(rst),
//                     .valid(valid),
//                     .A(A[m]),
//                     .B(B_T[n]),
//                     .result(C[m][n])
//                 );
//             end
//         end
//     endgenerate

// endmodule


/*
// Sequential logic for pipeline stages
    always @(posedge clk) begin
        if (rst) begin
            stage1_done <= 0;
            stage2_valid <= 0;
            done <= 0;

            /// 3 stage pipeline for accuracy
        end else begin
            if (valid) begin
                // Stage 1: Latch A and B_T
                for (i = 0; i < 4; i = i + 1) begin
                    for (j = 0; j < 4; j = j + 1) begin
                        A_reg[i][j] <= A[i][j];
                        B_T_reg[j][i] <= B[i][j]; // Transpose
                    end
                end
                stage1_done <= 1;
            end else if (stage1_done) begin
                // Stage 2: Perform multiplication
                stage2_valid <= 1;
                stage1_done <= 0;
            end else if (stage2_valid) begin
                // Latch result
                for (i = 0; i < 4; i = i + 1)
                    for (j = 0; j < 4; j = j + 1)
                        C[i][j] <= dot_results[i][j];

                done <= 1;
                stage2_valid <= 0;
            end else begin
                done <= 0;
            end
        end
    end
    */