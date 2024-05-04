`include "config.sv"
module pipe_if_id (
	input                     	i_clk       ,
	input                     	i_rst_n     ,
	input                     	i_bubble    ,
	input						flush		,

	input   [`INS_WIDTH-1:0]  	i_ifu_ins   ,
	input   [`CPU_WIDTH-1:0]  	i_ifu_pc    ,
	input						pc_stall	,

	input                       if_valid_i ,
	input                       id_ready_i ,
	output  logic               if_ready_o ,
	output  logic               id_valid_o ,

	output  [`INS_WIDTH-1:0]  	o_idu_ins   ,
	output  [`CPU_WIDTH-1:0]  	o_idu_pc    
);

	wire [`CPU_WIDTH-1:0] t_ifu_pc;     // t means temp;
	wire [`INS_WIDTH-1:0] t_ifu_ins; 

	assign t_ifu_pc     = flush ? 'b0 : i_ifu_pc;
	assign t_ifu_ins    = flush ? 'b0 : (i_bubble ? `INS_WIDTH'h0 : i_ifu_ins);      // 0x13 == ADDI x0,x0,0 == nop.

	assign  if_ready_o = (~id_valid_o || id_ready_i) & ~pc_stall ;
	always @(posedge i_clk) begin
		if(i_rst_n) begin
			id_valid_o <= 1'b0;
		end 
		else if (if_ready_o) begin
			id_valid_o <= if_valid_i;
		end
	end

	stl_reg #(
	.WIDTH      (`CPU_WIDTH+`INS_WIDTH),
	.RESET_VAL  (0                    )
	) if_id_reg(
	.i_clk      (i_clk                ),
	.i_rst_n    (i_rst_n              ),
	.i_wen      (if_ready_o & if_valid_i || flush),
	.i_din      ({t_ifu_ins,t_ifu_pc}),
	.o_dout     ({o_idu_ins,o_idu_pc})
	);
	
endmodule
