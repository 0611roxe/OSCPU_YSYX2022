`include "config.sv"
module ifu (
	input                          	i_clk  	,
	input                          	i_rst_n	,
	input							flush	,
	input							keep	,
	input         [`CPU_WIDTH-1:0]  i_pc   	,
	output	logic [`CPU_WIDTH-1:0]	o_pc	,
	output 	logic [`INS_WIDTH-1:0]  o_ins  	,

	output							axi_if_valid,
	input							axi_if_ready,
	input							id_if_ready,
	output							if_id_valid,

	input  [`CPU_WIDTH-1:0] 		if_data_read,
	input  [1:0] 					if_resp	,
  	output [1:0] 					if_size	,
	input							pc_stall
);
	
	wire handshake_done = axi_if_valid & axi_if_ready;
	assign if_id_valid = handshake_done;

	always @( posedge i_clk ) begin
	  	if (i_rst_n) begin
			o_pc <= `PC_START;
	  	end
		else if	(flush) begin
			o_pc <= 'b0;
		end 
		else if ( handshake_done & ~pc_stall) begin
			o_pc <= i_pc;
	 	end
		else begin
			o_pc <= o_pc;
		end
	end

	assign o_ins = keep ? 'b0 : if_data_read[31:0];
	assign axi_if_valid = !pc_stall;
	assign if_size = `SIZE_W;

endmodule
