`include "config.sv"
module atributer(
	input  					clock,
	input  					reset,

	//handshake
	input					if_rw_valid_i, 	//if->atributer
	output					if_rw_ready_o,	//atributer->if 

	input					mem_rw_valid_i,	//mem->atributer
	output					mem_rw_ready_o,	//atributer->mem

	//from if stage
	input	[63:0]			if_rw_addr_i,
	input	[1:0] 			if_rw_size_i,

	//from mem stage
	input	[63:0]			mem_rw_addr_i,
	input	[1:0] 			mem_rw_size_i,
	input	[63:0]			mem_data_write_i,
	input					sig_store,
	output	wire			axi_sig_mem,
	output					axi_sig_write,

	output	logic [63:0]	if_data_read,
	output	logic [63:0]	mem_data_read,

	//axi to master
	output	wire [`AXI_ID_WIDTH-1:0]		axi_rw_id,
	output	wire [1:0]		axi_rw_size,
	output	wire  [63:0]	axi_rw_addr,
	output	wire [63:0]	axi_wt_data,
	
	input	[`AXI_ID_WIDTH-1:0]			axi_ret_id,
	input	[63:0]						axi_ret_rd_data,
	//AXI handshake
	output					axi_rw_valid,		//atributer->master
	input					axi_rw_ready		//master->atribute
);

	assign if_rw_ready_o = (axi_sig_mem) ? 'b0 : (axi_ret_id == 4'h1) ? axi_rw_ready : 'b0;
	assign mem_rw_ready_o = (axi_sig_mem) ? ((axi_ret_id == 4'h2) ? axi_rw_ready : 'b0) : 'b0;
	wire axi_handshake = axi_rw_valid & axi_rw_ready;

	assign 	axi_sig_mem = (mem_rw_valid_i) ? mem_rw_valid_i : 'b0;
	
	assign 	axi_sig_write = (axi_sig_mem) ? sig_store : 'b0; 
	assign 	axi_rw_valid = axi_sig_mem ? mem_rw_valid_i : if_rw_valid_i;
	assign 	axi_rw_addr = axi_sig_mem ? mem_rw_addr_i : if_rw_addr_i;
	assign 	axi_rw_id 	= axi_sig_mem ? 2'b10 : 2'b01;
	assign	axi_rw_size = axi_sig_mem ? mem_rw_size_i : if_rw_size_i;
	assign	axi_wt_data = mem_data_write_i;

	assign 	if_data_read = ((axi_rw_id == axi_ret_id) & (axi_ret_id == 2'b01)) ? axi_ret_rd_data : 'b0;
	assign 	mem_data_read = ((axi_rw_id == axi_ret_id) & (axi_ret_id == 2'b10)) ? axi_ret_rd_data : 'b0;

endmodule