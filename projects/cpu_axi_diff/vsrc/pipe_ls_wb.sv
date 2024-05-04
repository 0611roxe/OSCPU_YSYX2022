`include "config.sv"
module pipe_ls_wb (
	input                         	i_clk        ,
	input                         	i_rst_n      ,
	input							flush		 ,

	input   [`CPU_WIDTH-1:0]      	i_lsu_exres  ,
	input   [`CPU_WIDTH-1:0]      	i_lsu_lsres  ,
	input   [`REG_ADDRW-1:0]      	i_lsu_rdid   ,
	input                         	i_lsu_rdwen  ,
	input                         	i_lsu_lden   ,
	input							i_lsu_sten	 ,
	input   [`INS_WIDTH-1:0]      	s_mem_diffins,
	input	[`CPU_WIDTH-1:0]		i_mem_pc	 ,
	input	[11:0]					mem_csr		 ,
	input							mem_csr_wen	 ,
	input	[`CPU_WIDTH-1:0]		mem_csr_data_res,
	input	[`CPU_WIDTH-1:0]		mem_except_code,
	input							mem_except_en,
	input							mem_mret	 ,
	input							mem_mtime_int,
	input							mem_csr_to_rf,
	input	[`CPU_WIDTH-1:0]		mem_csr_data ,

	input                           mem_valid_i	 ,
	input                           wb_ready_i	 ,
	output  logic                   mem_ready_o	 ,
	output  logic                   wb_valid_o	 ,

	output  [`CPU_WIDTH-1:0]      	o_wbu_exres  	,
	output  [`CPU_WIDTH-1:0]      	o_wbu_lsres  	,
	output  [`REG_ADDRW-1:0]      	o_wbu_rdid   	,
	output                        	o_wbu_rdwen  	,
	output                        	o_wbu_lden   	,
	output							o_wbu_sten		,
	output  [`INS_WIDTH-1:0]      	s_wbu_diffins	,
	output	[`CPU_WIDTH-1:0]		o_wb_pc		 	,
	output	[11:0]					wb_csr		 	,
	output							wb_csr_wen	 	,
	output	[`CPU_WIDTH-1:0]		wb_csr_data_res	,
	output	[`CPU_WIDTH-1:0]		wb_except_code	,
	output							wb_except_en 	,
	output							wb_mret 	 	,
	output	logic 					wb_csr_to_rf 	,
	output							wb_mtime_int 	,
	output	[`CPU_WIDTH-1:0]		wb_csr_data
);

	logic [`CPU_WIDTH-1:0] 		t_lsu_exres  		;
	logic [`CPU_WIDTH-1:0] 		t_lsu_lsres  		;
	logic [`REG_ADDRW-1:0] 		t_lsu_rdid   		;
	logic                  		t_lsu_rdwen  		;
	logic                  		t_lsu_lden   		;
	logic 				 		t_lsu_sten	 		;
	logic [`INS_WIDTH-1:0] 		t_mem_diffins		;
	logic [`CPU_WIDTH-1:0] 		t_mem_pc	 		;
	logic [11:0]			 	t_mem_csr			;	
	logic 				 		t_mem_csr_wen		;	
	logic [`CPU_WIDTH-1:0] 		t_mem_csr_data_res	;
	logic [`CPU_WIDTH-1:0] 		t_mem_except_code	;
	logic 				 		t_mem_except_en		;
	logic 				 		t_mem_mret	 		;
	logic 				 		t_mem_mtime_int		;
	logic 				 		t_mem_csr_to_rf		;
	logic [`CPU_WIDTH-1:0] 		t_mem_csr_data 		;

	assign t_lsu_exres   		= flush ? 'b0 : i_lsu_exres   	;
	assign t_lsu_lsres   		= flush ? 'b0 : i_lsu_lsres   	;
	assign t_lsu_rdid    		= flush ? 'b0 : i_lsu_rdid    	;
	assign t_lsu_rdwen   		= flush ? 'b0 : i_lsu_rdwen   	;
	assign t_lsu_lden    		= flush ? 'b0 : i_lsu_lden    	;
	assign t_lsu_sten	 		= flush ? 'b0 : i_lsu_sten	 	;
	assign t_mem_diffins 		= flush ? 'b0 : s_mem_diffins 	;
	assign t_mem_pc	 	 		= flush ? 'b0 : i_mem_pc	 	;
	assign t_mem_csr	 		= flush ? 'b0 : mem_csr	 		;
	assign t_mem_csr_wen 		= flush ? 'b0 : mem_csr_wen 	;
	assign t_mem_csr_data_res	= flush ? 'b0 : mem_csr_data_res;
	assign t_mem_except_code 	= flush ? 'b0 : mem_except_code ;
	assign t_mem_except_en  	= flush ? 'b0 : mem_except_en 	;
	assign t_mem_mret	  		= flush ? 'b0 : mem_mret	  	;
	assign t_mem_mtime_int 		= flush ? 'b0 : mem_mtime_int 	;
	assign t_mem_csr_to_rf 		= flush ? 'b0 : mem_csr_to_rf 	;
	assign t_mem_csr_data  		= flush ? 'b0 : mem_csr_data  	;

	assign mem_ready_o = ~wb_valid_o || wb_ready_i;
	always @(posedge i_clk) begin
		if(i_rst_n) begin
			wb_valid_o <= 1'b0;
		end 
		else if (mem_ready_o) begin
			wb_valid_o <= mem_valid_i;
		end 
	end

	stl_reg #(
		.WIDTH      (6*`CPU_WIDTH+`REG_ADDRW+20+`INS_WIDTH),
		.RESET_VAL  (0       )
	) if_id_reg(
		.i_clk      (i_clk   ),
		.i_rst_n    (i_rst_n ),
		.i_wen      (mem_valid_i && mem_ready_o || flush),
		.i_din      ({t_lsu_exres  		,t_lsu_lsres  		,t_lsu_rdid   		,t_lsu_rdwen  		,t_lsu_lden   		,t_lsu_sten	 		,t_mem_diffins		,t_mem_pc	 		,t_mem_csr			,t_mem_csr_wen		,t_mem_csr_data_res		,t_mem_except_code	,t_mem_except_en	,t_mem_mret	 		,t_mem_mtime_int		,t_mem_csr_to_rf		,t_mem_csr_data} ),
		.o_dout     ({o_wbu_exres  		,o_wbu_lsres  		,o_wbu_rdid   		,o_wbu_rdwen  		,o_wbu_lden   		,o_wbu_sten		 	,s_wbu_diffins		,o_wb_pc		 	,wb_csr		 		,wb_csr_wen	 		,wb_csr_data_res		,wb_except_code		,wb_except_en 		,wb_mret 	 		,wb_mtime_int			,wb_csr_to_rf 		 	,wb_csr_data} )
	);

endmodule
