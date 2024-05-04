`include "config.sv"
module pipe_ex_ls (
	input                         i_clk         ,
	input                         i_rst_n       ,

	input   [`CPU_WIDTH-1:0]      i_exu_exres   ,
	input   [`CPU_WIDTH-1:0]      i_exu_rs2     ,
	input   [`REG_ADDRW-1:0]      i_exu_rdid    ,
	input                         i_exu_rdwen   ,
	input   [2:0]                 i_exu_func3   ,
	input                         i_exu_lden    ,
	input                         i_exu_sten    ,
	input   [`CPU_WIDTH-1:0]      s_exu_diffpc  ,
	input   [`INS_WIDTH-1:0]      s_exu_diffins ,

	input                       exe_valid_i,
	input                       mem_ready_i,
	output  logic               exe_ready_o,
	output  logic               mem_valid_o,

	output  [`CPU_WIDTH-1:0]      o_lsu_exres   ,
	output  [`CPU_WIDTH-1:0]      o_lsu_rs2     ,
	output  [`REG_ADDRW-1:0]      o_lsu_rdid    ,
	output                        o_lsu_rdwen   ,
	output  [2:0]                 o_lsu_func3   ,
	output                        o_lsu_lden    ,
	output                        o_lsu_sten    ,
	output  [`CPU_WIDTH-1:0]      s_lsu_diffpc  ,
	output  [`INS_WIDTH-1:0]      s_mem_diffins 
);

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
		.WIDTH      (3*`CPU_WIDTH+`REG_ADDRW+6+`INS_WIDTH),
		.RESET_VAL  (0       )
	) if_id_reg(
		.i_clk      (i_clk   ),
		.i_rst_n    (i_rst_n ),
		.i_wen      (exe_valid_i && exe_ready_o),
		.i_din      ({i_exu_exres, i_exu_rs2, i_exu_rdid, i_exu_rdwen, i_exu_func3, i_exu_lden, i_exu_sten, s_exu_diffpc, s_exu_diffins} ),
		.o_dout     ({o_lsu_exres, o_lsu_rs2, o_lsu_rdid, o_lsu_rdwen, o_lsu_func3, o_lsu_lden, o_lsu_sten, s_lsu_diffpc, s_mem_diffins} )
	);

endmodule
