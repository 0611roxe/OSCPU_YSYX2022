`include "config.sv"
module regfile (
	input                         i_clk   ,
	input                         i_wen   ,
	input        [`REG_ADDRW-1:0] i_waddr ,
	input        [`CPU_WIDTH-1:0] i_wdata ,
	input        [`REG_ADDRW-1:0] i_raddr1,
	input        [`REG_ADDRW-1:0] i_raddr2,
	output logic [`CPU_WIDTH-1:0] o_rdata1,
	output logic [`CPU_WIDTH-1:0] o_rdata2,
	output logic [`REG_BUS] o_regs [0:31] 
);

	logic [`CPU_WIDTH-1:0] rf [`REG_COUNT-1:0];

	assign rf[0] = `CPU_WIDTH'b0; 

	generate                   
		for(genvar i=1; i<`REG_COUNT; i=i+1 )begin: regfile
			always @(posedge i_clk) begin
				if (i_wen && i_waddr == i) begin
					rf[i] <= i_wdata;
				end
			end
		end
	endgenerate

	assign o_rdata1 = rf[i_raddr1];
	assign o_rdata2 = rf[i_raddr2];

	genvar j;
	generate
		for (j = 0; j < 32; j = j + 1) begin
			assign o_regs[j] = (i_wen & i_waddr == j & j != 0) ? i_wdata : rf[j];
		end
	endgenerate

endmodule
