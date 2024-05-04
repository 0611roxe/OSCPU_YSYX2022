`include "config.sv"
module pipe_ls_wb (
	input                         i_clk         ,
	input                         i_rst_n       ,

	input   [`CPU_WIDTH-1:0]      i_lsu_exres   ,
	input   [`CPU_WIDTH-1:0]      i_lsu_lsres   ,
	input   [`REG_ADDRW-1:0]      i_lsu_rdid    ,
	input                         i_lsu_rdwen   ,
	input                         i_lsu_lden    ,
	input   [`CPU_WIDTH-1:0]      s_lsu_diffpc  ,
	input   [`INS_WIDTH-1:0]      s_mem_diffins ,

	input                           mem_valid_i,
	input                           wb_ready_i,
	output  logic                   mem_ready_o,
	output  logic                   wb_valid_o,

	output  [`CPU_WIDTH-1:0]      o_wbu_exres   ,
	output  [`CPU_WIDTH-1:0]      o_wbu_lsres   ,
	output  [`REG_ADDRW-1:0]      o_wbu_rdid    ,
	output                        o_wbu_rdwen   ,
	output                        o_wbu_lden    ,
	output  [`CPU_WIDTH-1:0]      s_wbu_diffpc  ,
	output  [`INS_WIDTH-1:0]      s_wbu_diffins  
);


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
		.WIDTH      (3*`CPU_WIDTH+`REG_ADDRW+2+`INS_WIDTH),
		.RESET_VAL  (0       )
	) if_id_reg(
		.i_clk      (i_clk   ),
		.i_rst_n    (i_rst_n ),
		.i_wen      (mem_valid_i && mem_ready_o),
		.i_din      ({i_lsu_exres, i_lsu_lsres, i_lsu_rdid, i_lsu_rdwen, i_lsu_lden, s_lsu_diffpc, s_mem_diffins} ),
		.o_dout     ({o_wbu_exres, o_wbu_lsres, o_wbu_rdid, o_wbu_rdwen, o_wbu_lden, s_wbu_diffpc, s_wbu_diffins} )
	);

endmodule
