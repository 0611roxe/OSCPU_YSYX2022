`include "config.sv"
module stl_mux_default #(NR_KEY = 2, KEY_LEN = 1, DATA_LEN = 1) (
	output [DATA_LEN-1:0] out,
	input [KEY_LEN-1:0] key,
	input [DATA_LEN-1:0] default_out,
	input [NR_KEY*(KEY_LEN + DATA_LEN)-1:0] lut
);

	stl_mux_internal #(NR_KEY, KEY_LEN, DATA_LEN, 1) i0 (out, key, default_out, lut);
	
endmodule
