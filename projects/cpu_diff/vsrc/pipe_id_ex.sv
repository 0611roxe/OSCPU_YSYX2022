`include "config.sv"
module pipe_id_ex (
	input                         i_clk         ,
	input                         i_rst_n       ,
	input                         i_bubble      ,

	input   [`CPU_WIDTH-1:0]      i_idu_imm     ,
	input   [`CPU_WIDTH-1:0]      i_idu_rs1     ,
	input   [`CPU_WIDTH-1:0]      i_idu_rs2     ,
	input   [`REG_ADDRW-1:0]      i_idu_rdid    ,
	input                         i_idu_rdwen   ,
	input   [`EXU_SEL_WIDTH-1:0]  i_idu_src_sel ,
	input   [`EXU_OPT_WIDTH-1:0]  i_idu_exopt   ,
	input   [2:0]                 i_idu_func3   ,
	input                         i_idu_lden    ,
	input                         i_idu_sten    ,
	input                         i_idu_ldstbp  ,
	input   [`CPU_WIDTH-1:0]      i_idu_pc      ,
	input   [`CPU_WIDTH-1:0]      s_idu_diffpc  ,
	input   [`INS_WIDTH-1:0]      s_idu_diffins   ,

	input                           id_valid_i,
	input                           exe_ready_i,
	output  logic                   id_ready_o,
	output  logic                   exe_valid_o,

	output  [`CPU_WIDTH-1:0]      o_exu_imm     ,
	output  [`CPU_WIDTH-1:0]      o_exu_rs1     ,
	output  [`CPU_WIDTH-1:0]      o_exu_rs2     ,
	output  [`REG_ADDRW-1:0]      o_exu_rdid    ,
	output                        o_exu_rdwen   ,
	output  [`EXU_SEL_WIDTH-1:0]  o_exu_src_sel ,
	output  [`EXU_OPT_WIDTH-1:0]  o_exu_exopt   ,
	output  [2:0]                 o_exu_func3   ,
	output                        o_exu_lden    ,
	output                        o_exu_sten    ,
	output                        o_exu_ldstbp  ,
	output  [`CPU_WIDTH-1:0]      o_exu_pc      , 
	output  [`CPU_WIDTH-1:0]      s_exu_diffpc  ,
	output  [`INS_WIDTH-1:0]      s_exu_diffins
);

	logic  [`CPU_WIDTH-1:0]      t_idu_imm     ;
	logic  [`CPU_WIDTH-1:0]      t_idu_rs1     ;
	logic  [`CPU_WIDTH-1:0]      t_idu_rs2     ;
	logic  [`REG_ADDRW-1:0]      t_idu_rdid    ;
	logic                        t_idu_rdwen   ;
	logic  [`EXU_SEL_WIDTH-1:0]  t_idu_src_sel ;
	logic  [`EXU_OPT_WIDTH-1:0]  t_idu_exopt   ;
	logic  [2:0]                 t_idu_func3   ;
	logic                        t_idu_lden    ;
	logic                        t_idu_sten    ;
	logic                        t_idu_ldstbp  ;
	logic  [`CPU_WIDTH-1:0]      t_idu_pc      ;
	logic  [`CPU_WIDTH-1:0]      t_idu_diffpc  ;
	logic  [`INS_WIDTH-1:0]      t_idu_diffins ;

	assign t_idu_imm     = i_bubble ? `CPU_WIDTH'b0 : i_idu_imm     ;
	assign t_idu_rs1     = i_bubble ? `CPU_WIDTH'b0 : i_idu_rs1     ;
	assign t_idu_rs2     = i_bubble ? `CPU_WIDTH'b0 : i_idu_rs2     ;
	assign t_idu_rdid    = i_bubble ? `REG_ADDRW'b0 : i_idu_rdid    ;
	assign t_idu_rdwen   = i_bubble ?  1'b0         : i_idu_rdwen   ;
	assign t_idu_src_sel = i_bubble ? `EXU_SEL_IMM  : i_idu_src_sel ;
	assign t_idu_exopt   = i_bubble ? `EXU_ADD      : i_idu_exopt   ;
	assign t_idu_func3   = i_idu_func3 ;
	assign t_idu_lden    = i_bubble ?  1'b0         : i_idu_lden    ;
	assign t_idu_sten    = i_bubble ?  1'b0         : i_idu_sten    ;
	assign t_idu_ldstbp  = i_bubble ?  1'b0         : i_idu_ldstbp  ;
	assign t_idu_pc      = i_idu_pc ;
	assign t_idu_diffpc  = i_bubble ? `CPU_WIDTH'b1 : s_idu_diffpc  ;
	assign t_idu_diffins = s_idu_diffins;


	assign id_ready_o = ~exe_valid_o || exe_ready_i;
	always @(posedge i_clk) begin
		if(i_rst_n) begin
			exe_valid_o <= 1'b0;
		end 
		else if (id_ready_o) begin
			exe_valid_o <= id_valid_i;
		end    
	end

	stl_reg #(
		.WIDTH      (5*`CPU_WIDTH+`REG_ADDRW+7+`EXU_SEL_WIDTH+`EXU_OPT_WIDTH+`INS_WIDTH),
		.RESET_VAL  (0       )
	) if_id_reg(
		.i_clk      (i_clk   ),
		.i_rst_n    (i_rst_n ),
		.i_wen      (id_valid_i && id_ready_o),
		.i_din      ({t_idu_imm, t_idu_rs1, t_idu_rs2, t_idu_rdid, t_idu_rdwen, t_idu_src_sel, t_idu_exopt, t_idu_func3, t_idu_lden, t_idu_sten, t_idu_ldstbp, t_idu_pc, t_idu_diffpc, t_idu_diffins} ),
		.o_dout     ({o_exu_imm, o_exu_rs1, o_exu_rs2, o_exu_rdid, o_exu_rdwen, o_exu_src_sel, o_exu_exopt, o_exu_func3, o_exu_lden, o_exu_sten, o_exu_ldstbp, o_exu_pc, s_exu_diffpc, s_exu_diffins} )
	);

endmodule
