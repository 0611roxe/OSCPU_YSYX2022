`include "config.sv"
module alu(
    input                               clk     ,
    input                               rst_n   ,
    input [`CPU_WIDTH-1:0]              src1    ,
    input [`CPU_WIDTH-1:0]              src2    ,
    input [`EXU_OPT_WIDTH-1:0]          exopt   ,

    input                               alu_valid_in    ,
    input                               alu_ready_in    ,
    output                              alu_valid_out   ,
    output                              alu_ready_out   ,

    output logic  [`CPU_WIDTH-1:0]      o_exe_res
);

    logic [`CPU_WIDTH-1:0] divisor, dividend;
    logic div_signed, divw;
    logic [`CPU_WIDTH-1:0] quotient, remainder;

    assign alu_valid_out = alu_valid_in;
    assign alu_ready_out = alu_ready_in;

    `ifdef DIVIDER
    logic div_hand;
    assign div_hand = (exopt == `EXE_DIV) | (exopt == `EXE_DIVW) | (exopt == `EXE_DIVUW) | (exopt == `EXE_DIVU) | (exopt == `EXE_REM) | (exopt == `EXE_REMU) | (exopt == `EXE_REMW) | (exopt == `EXE_REMUW);

    assign alu_valid_out = div_hand ? div_out_valid : 'b1;
    assign alu_ready_out = div_hand ? div_out_ready : 'b1;

    logic div_out_valid, div_out_ready, div_in_valid, div_in_ready;
    assign div_in_valid = div_hand ? alu_valid_in : 1'b0;
    assign div_in_ready = div_hand ? alu_ready_in : 1'b0;

    divider divider (
        .clk                (clk        ),
        .rst_n              (rst_n      ),
        .dividend           (dividend   ), 
        .divisor            (divisor    ),
        .div_valid          (div_in_valid),
        .i_div_ready        (div_in_ready),
        .div_signed         (div_signed ),
        .divw               (divw       ),
        .out_valid          (div_out_valid),
        .out_ready          (div_out_ready),
        .quotient           (quotient   ),
        .remainder          (remainder  )
    );
    `endif 
 
    always @(*) begin
        dividend = 'b0;
        divisor = 'b0;
        div_signed = 1'b1;
        quotient = 'b0;
        remainder = 'b0;
        divw = 'b0;
        case (exopt)
            `EXU_ADD:   o_exe_res = src1 + src2;
            `EXU_SUB:   o_exe_res = src1 - src2;
            `EXU_ADDW:  begin o_exe_res[31:0] = src1[31:0] + src2[31:0]; o_exe_res = {{32{o_exe_res[31]}}, o_exe_res[31:0]};end
            `EXU_SUBW:  begin o_exe_res[31:0] = src1[31:0] - src2[31:0]; o_exe_res = {{32{o_exe_res[31]}}, o_exe_res[31:0]};end
            `EXU_AND:   o_exe_res = src1 & src2;
            `EXU_OR:    o_exe_res = src1 | src2;
            `EXU_XOR:   o_exe_res = src1 ^ src2;
            `EXU_SLL:   o_exe_res = src1 << src2[5:0];
            `EXU_SRL:   o_exe_res = src1 >> src2[5:0];
            `EXU_SRA:   o_exe_res = {{{64{src1[63]}},src1} >> src2[5:0]}[63:0];
            `EXU_SLLW:  begin o_exe_res[31:0] = src1[31:0] << src2[4:0];               o_exe_res = {{32{o_exe_res[31]}},o_exe_res[31:0]}; end
            `EXU_SRLW:  begin o_exe_res[31:0] = src1[31:0] >> src2[4:0];               o_exe_res = {{32{o_exe_res[31]}},o_exe_res[31:0]}; end
            `EXU_SRAW:  begin o_exe_res = {{32{src1[31]}}, src1[31:0]} >> src2[4:0]; o_exe_res = {{32{o_exe_res[31]}},o_exe_res[31:0]}; end
            `EXU_MUL:   o_exe_res = src1 * src2;
            `EXU_MULH:  o_exe_res = src1 * src2 >> 64;
            `EXU_MULHSU:o_exe_res = {{1'b0, src1} * src2 >> 64}[63:0];
            `EXU_MULHU: o_exe_res = {{1'b0, src1} * {1'b0, src2} >> 64}[63:0]; 
            `EXU_DIV:   o_exe_res = src1 / src2;
            `EXU_DIVU:  o_exe_res = {{1'b0, src1} / {1'b0, src2}}[63:0];
            `EXU_REM:   o_exe_res = src1 % src2;
            `EXU_REMU:  o_exe_res = {{1'b0, src1} % {1'b0, src2}}[63:0];
            `EXU_MULW:  begin o_exe_res[31:0] = {src1[31:0] * src2[31:0]}[31:0];             o_exe_res = {{32{o_exe_res[31]}}, o_exe_res[31:0]}; end
            //`EXE_DIVW:  begin end
            `EXU_DIVW:  begin 
                `ifdef DIVIDER
                    divw = 1'b1; 
                    div_signed = 1'b1; 
                    dividend = {{32{src1[31]}},src1[31:0]}; 
                    divisor = {{32{src2[31]}},src2[31:0]}; 
                    o_exe_res[31:0] = quotient[31:0] ; 
                    o_exe_res = {{32{o_exe_res[31]}}, o_exe_res[31:0]}; 
                    $display("DIVW src1:%d src2:%d dividend:%d divisor:%d quotient:%d exeres:%d",src1,src2,dividend,divisor,quotient,o_exe_res);
                `endif
                o_exe_res[31:0] = {src1[31:0] / src2[31:0]};                   
                o_exe_res = {{32{o_exe_res[31]}}, o_exe_res[31:0]}; 
            end
            `EXU_DIVUW: begin o_exe_res[31:0] = {{1'b0,src1[31:0]}/{1'b0,src2[31:0]}}[31:0]; o_exe_res = {{32{o_exe_res[31]}}, o_exe_res[31:0]}; end
            `EXU_REMW:  begin o_exe_res[31:0] = {src1[31:0] % src2[31:0]};                   o_exe_res = {{32{o_exe_res[31]}}, o_exe_res[31:0]}; end
            `EXU_REMUW: begin o_exe_res[31:0] = {{1'b0,src1[31:0]}%{1'b0,src2[31:0]}}[31:0]; o_exe_res = {{32{o_exe_res[31]}}, o_exe_res[31:0]}; end
            `EXU_SLT:   begin o_exe_res = {63'b0 , {src1 - src2}[63] };                                                                          end
            `EXU_SLTU:  begin o_exe_res = {63'b0 , {{1'b0,src1} - {1'b0,src2}}[64] };                                                            end
            default:    o_exe_res = `CPU_WIDTH'b0;
        endcase
    end

endmodule