`include "config.sv"
module pipe_ex_ls (
	input                         	i_clk        	,
	input                         	i_rst_n      	,
	input							flush			,

	input   [`CPU_WIDTH-1:0]      	i_exu_exres  	,
	input   [`CPU_WIDTH-1:0]      	i_exu_rs2    	,
	input   [`REG_ADDRW-1:0]      	i_exu_rdid   	,
	input                         	i_exu_rdwen  	,
	input   [2:0]                 	i_exu_func3  	,
	input                         	i_exu_lden   	,
	input                         	i_exu_sten   	,
	input   [`INS_WIDTH-1:0]      	s_exu_diffins	,
	input	[`CPU_WIDTH-1:0]		i_exu_pc	 	,
	input	[11:0]					exu_csr		 	,
	input							exu_csr_wen		,
	input	[`CPU_WIDTH-1:0]		exu_csr_data_res,
	input	[`CPU_WIDTH-1:0]		exu_except_code	,
	input							exu_except_en	,
	input							exu_mret		,
	input							exu_mtime_int	,
	input							exu_csr_to_rf	,
	input	[`CPU_WIDTH-1:0]		exu_csr_data	,
	

	input                       	exe_valid_i,
	input                       	mem_ready_i,
	output  logic               	exe_ready_o,
	output  logic               	mem_valid_o,

	output  [`CPU_WIDTH-1:0]      	o_lsu_exres  	,
	output  [`CPU_WIDTH-1:0]      	o_lsu_rs2    	,
	output  [`REG_ADDRW-1:0]      	o_lsu_rdid   	,
	output                        	o_lsu_rdwen  	,
	output  [2:0]                 	o_lsu_func3  	,
	output                        	o_lsu_lden   	,
	output                        	o_lsu_sten   	,
	output  [`INS_WIDTH-1:0]      	s_mem_diffins	,
	output 	[`CPU_WIDTH-1:0]	  	o_mem_pc	 	,
	output	[11:0]					mem_csr			,
	output							mem_csr_wen		,
	output	[`CPU_WIDTH-1:0]		mem_csr_data_res,
	output	[`CPU_WIDTH-1:0]		mem_except_code	,
	output							mem_except_en	,
	output							mem_mret		,
	output							mem_mtime_int	,
	output							mem_csr_to_rf	,
	output	[`CPU_WIDTH-1:0]		mem_csr_data
);

	logic [`CPU_WIDTH-1:0]      t_exu_exres  	;
	logic [`CPU_WIDTH-1:0]      t_exu_rs2    	;
	logic [`REG_ADDRW-1:0]      t_exu_rdid   	;
	logic                       t_exu_rdwen  	;
	logic [2:0]                 t_exu_func3  	;
	logic                       t_exu_lden   	;
	logic                       t_exu_sten   	;
	logic [`INS_WIDTH-1:0]      t_exu_diffins	;
	logic [`CPU_WIDTH-1:0]		t_exu_pc	 	;
	logic [11:0]				t_exu_csr		 	;
	logic 						t_exu_csr_wen		;
	logic [`CPU_WIDTH-1:0]		t_exu_csr_data_res;
	logic [`CPU_WIDTH-1:0]		t_exu_except_code	;
	logic 						t_exu_except_en	;
	logic 						t_exu_mret		;
	logic 						t_exu_mtime_int	;
	logic 						t_exu_csr_to_rf	;
	logic [`CPU_WIDTH-1:0]		t_exu_csr_data	;

	assign t_exu_exres  	 =  flush ? 'b0 : i_exu_exres;
	assign t_exu_rs2    	 =  flush ? 'b0 : i_exu_rs2	;
	assign t_exu_rdid   	 =  flush ? 'b0 : i_exu_rdid;
	assign t_exu_rdwen  	 =  flush ? 'b0 : i_exu_rdwen;
	assign t_exu_func3  	 =  flush ? 'b0 : i_exu_func3; 
	assign t_exu_lden   	 =  flush ? 'b0 : i_exu_lden;
	assign t_exu_sten   	 =  flush ? 'b0 : i_exu_sten;  
	assign t_exu_diffins	 =  flush ? 'b0 : s_exu_diffins;
	assign t_exu_pc	 		 =	flush ? 'b0 : i_exu_pc	;
	assign t_exu_csr		 =  flush ? 'b0 : exu_csr		 ;
	assign t_exu_csr_wen	 =  flush ? 'b0 : exu_csr_wen	 ;
	assign t_exu_csr_data_res = flush ? 'b0 : exu_csr_data_res;
	assign t_exu_except_code =  flush ? 'b0 : exu_except_code ;
	assign t_exu_except_en	 =  flush ? 'b0 : exu_except_en	 ;
	assign t_exu_mret		 =  flush ? 'b0 : exu_mret		 ;
	assign t_exu_mtime_int	 =  flush ? 'b0 : exu_mtime_int	 ;
	assign t_exu_csr_to_rf	 =  flush ? 'b0 : exu_csr_to_rf	 ;
	assign t_exu_csr_data	 =  flush ? 'b0 : exu_csr_data	 ;

	assign exe_ready_o = ~mem_valid_o || mem_ready_i;
	always @(posedge i_clk) begin
		if(i_rst_n) begin
			mem_valid_o <= 1'b0;
		end 
		else if (exe_ready_o) begin
			mem_valid_o <= exe_valid_i;
		end 
	end

	stl_reg #(
		.WIDTH      (6*`CPU_WIDTH+`REG_ADDRW+23+`INS_WIDTH),
		.RESET_VAL  (0       )
	) if_id_reg(
		.i_clk      (i_clk   ),
		.i_rst_n    (i_rst_n ),
		.i_wen      (exe_valid_i && exe_ready_o || flush),
		.i_din      ({t_exu_exres  	 ,t_exu_rs2    	 ,t_exu_rdid   	 ,t_exu_rdwen  	 ,t_exu_func3  	 ,t_exu_lden   	 ,t_exu_sten   	 ,t_exu_diffins	 ,t_exu_pc	 	 ,t_exu_csr		 	,t_exu_csr_wen	 	,t_exu_csr_data_res	,t_exu_except_code 	,t_exu_except_en	,t_exu_mret		 ,t_exu_mtime_int	,t_exu_csr_to_rf	,t_exu_csr_data} ),
		.o_dout     ({o_lsu_exres  	 ,o_lsu_rs2    	 ,o_lsu_rdid   	 ,o_lsu_rdwen  	 ,o_lsu_func3  	 ,o_lsu_lden   	 ,o_lsu_sten   	 ,s_mem_diffins	 ,o_mem_pc	 	 ,mem_csr			,mem_csr_wen		,mem_csr_data_res 	,mem_except_code	,mem_except_en	 	,mem_mret		 ,mem_mtime_int	 	,mem_csr_to_rf	 	,mem_csr_data} )
	);

endmodule
