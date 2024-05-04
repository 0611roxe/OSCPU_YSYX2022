`include "config.sv"
module pipe_id_ex (
	input                         	i_clk         ,
	input                         	i_rst_n       ,
	input                         	i_bubble      ,
	input							flush		  ,

	input   [`CPU_WIDTH-1:0]      	i_idu_imm     ,
	input   [`CPU_WIDTH-1:0]      	i_idu_rs1     ,
	input   [`CPU_WIDTH-1:0]      	i_idu_rs2     ,
	input   [`REG_ADDRW-1:0]      	i_idu_rdid    ,
	input                         	i_idu_rdwen   ,
	input   [`EXU_SEL_WIDTH-1:0]  	i_idu_src_sel ,
	input   [`EXU_OPT_WIDTH-1:0]  	i_idu_exopt   ,
	input   [2:0]                 	i_idu_func3   ,
	input                         	i_idu_lden    ,
	input                         	i_idu_sten    ,
	input                         	i_idu_ldstbp  ,
	input   [`CPU_WIDTH-1:0]      	i_idu_pc      ,
	input	[11:0]					id_csr		  ,
	input	[`CPU_WIDTH-1:0]		id_csr_wdata  ,
	input	[2:0]					id_csr_choose ,
	input	[`CPU_WIDTH-1:0]		id_except_code,
	input							id_except_en  ,
	input							id_mret		  ,
	input							id_mtime_int  ,
	input   [`INS_WIDTH-1:0]      	s_idu_diffins ,

	input                           id_valid_i	  ,
	input                           exe_ready_i	  ,
	output  logic                   id_ready_o	  ,
	output  logic                   exe_valid_o	  ,

	output  [`CPU_WIDTH-1:0]     	o_exu_imm     ,
	output  [`CPU_WIDTH-1:0]     	o_exu_rs1     ,
	output  [`CPU_WIDTH-1:0]     	o_exu_rs2     ,
	output  [`REG_ADDRW-1:0]     	o_exu_rdid    ,
	output                       	o_exu_rdwen   ,
	output  [`EXU_SEL_WIDTH-1:0] 	o_exu_src_sel ,
	output  [`EXU_OPT_WIDTH-1:0] 	o_exu_exopt   ,
	output  [2:0]                	o_exu_func3   ,
	output                       	o_exu_lden    ,
	output                       	o_exu_sten    ,
	output                       	o_exu_ldstbp  ,
	output  [`CPU_WIDTH-1:0]     	o_exu_pc      , 
	output	[11:0]					ex_csr		  ,
	output	[`CPU_WIDTH-1:0]		ex_csr_wdata  ,
	output	[2:0]					ex_csr_choose ,
	output	[`CPU_WIDTH-1:0]		ex_except_code,
	output							ex_except_en  ,
	output							ex_mret		  ,
	output							ex_mtime_int  ,
	output  [`INS_WIDTH-1:0]     	s_exu_diffins
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
	logic	[11:0]				 t_id_csr		 ;
	logic	[`CPU_WIDTH-1:0]	 t_id_csr_wdata  ;
	logic	[2:0]				 t_id_csr_choose ;
	logic	[`CPU_WIDTH-1:0]	 t_id_except_code;
	logic						 t_id_except_en  ;
	logic						 t_id_mret		 ;
	logic						 t_id_mtime_int  ;
	logic  [`INS_WIDTH-1:0]      t_idu_diffins ;

	assign t_idu_imm     = flush ? 'b0 : (i_bubble ? `CPU_WIDTH'b0 : i_idu_imm    ) ;
	assign t_idu_rs1     = flush ? 'b0 : (i_bubble ? `CPU_WIDTH'b0 : i_idu_rs1    ) ;
	assign t_idu_rs2     = flush ? 'b0 : (i_bubble ? `CPU_WIDTH'b0 : i_idu_rs2    ) ;
	assign t_idu_rdid    = flush ? 'b0 : (i_bubble ? `REG_ADDRW'b0 : i_idu_rdid   ) ;
	assign t_idu_rdwen   = flush ? 'b0 : (i_bubble ?  1'b0         : i_idu_rdwen  ) ;
	assign t_idu_src_sel = flush ? 'b0 : (i_bubble ? `EXU_SEL_IMM  : i_idu_src_sel) ;
	assign t_idu_exopt   = flush ? 'b0 : (i_bubble ? `EXU_ADD      : i_idu_exopt  ) ;
	assign t_idu_func3   = flush ? 'b0 : i_idu_func3 ;
	assign t_idu_lden    = flush ? 'b0 : (i_bubble ?  1'b0         : i_idu_lden   ) ;
	assign t_idu_sten    = flush ? 'b0 : (i_bubble ?  1'b0         : i_idu_sten   ) ;
	assign t_idu_ldstbp  = flush ? 'b0 : (i_bubble ?  1'b0         : i_idu_ldstbp ) ;
	assign t_idu_pc      = flush ? 'b0 : i_idu_pc ;
	assign t_idu_diffins = flush ? 'b0 : (i_bubble ? `INS_WIDTH'b0 : s_idu_diffins);
	assign t_id_csr 	 = flush ? 'b0 : id_csr;	
	assign t_id_csr_choose = flush ? 'b0 : id_csr_choose;
	assign t_id_csr_wdata = flush ? 'b0 : id_csr_wdata;
	assign t_id_except_code = flush ? 'b0 : id_except_code;
	assign t_id_except_en = flush ? 'b0 : id_except_en;
	assign t_id_mret = flush ? 'b0 : id_mret;
	assign t_id_mtime_int = flush ? 'b0 : id_mtime_int;

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
		.WIDTH      (7*`CPU_WIDTH+`REG_ADDRW+25+`EXU_SEL_WIDTH+`EXU_OPT_WIDTH+`INS_WIDTH),
		.RESET_VAL  (0       )
	) if_id_reg(
		.i_clk      (i_clk   ),
		.i_rst_n    (i_rst_n ),
		.i_wen      (id_valid_i && id_ready_o || flush),
		.i_din      ({t_idu_imm, t_idu_rs1, t_idu_rs2, t_idu_rdid, t_idu_rdwen, t_idu_src_sel, t_idu_exopt, t_idu_func3, t_idu_lden, t_idu_sten, t_idu_ldstbp, t_idu_pc, t_id_csr		 ,t_id_csr_wdata  ,t_id_csr_choose ,t_id_except_code,t_id_except_en  ,t_id_mret		 ,t_id_mtime_int  ,t_idu_diffins} ),
		.o_dout     ({o_exu_imm, o_exu_rs1, o_exu_rs2, o_exu_rdid, o_exu_rdwen, o_exu_src_sel, o_exu_exopt, o_exu_func3, o_exu_lden, o_exu_sten, o_exu_ldstbp, o_exu_pc, ex_csr		  ,ex_csr_wdata  ,ex_csr_choose ,ex_except_code,ex_except_en  ,ex_mret		  ,ex_mtime_int  ,s_exu_diffins} )
	);

endmodule
