`include "config.sv"
module ifu (
	input                          	i_clk  ,
	input                          	i_rst_n,
	input        [`CPU_WIDTH-1:0]  	i_pc   ,
	output logic [`INS_WIDTH-1:0]  	o_ins   
);

	// Access memory
	reg [63:0] rdata;
	RAMHelper RAMHelper(
		.clk              (i_clk),
		.en               (1),
		.rIdx             ((i_pc - `PC_START) >> 3),
		.rdata            (rdata),
		.wIdx             (0),
		.wdata            (0),
		.wmask            (0),
		.wen              (0)
	);

	assign o_ins = i_pc[2] ? rdata[63 : 32] : rdata[31 : 0];

endmodule
