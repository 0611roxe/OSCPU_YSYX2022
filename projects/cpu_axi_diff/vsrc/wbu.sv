`include "config.sv"
module wbu (
    input         [`CPU_WIDTH-1:0]      i_exu_res   ,
    input         [`CPU_WIDTH-1:0]      i_lsu_res   ,
    input                               i_ldflag    ,
    output logic  [`CPU_WIDTH-1:0]      o_rd        ,
    input			                	csr_to_rf   ,
	input			[`CPU_WIDTH-1:0]	csr_data    ,
    output	[7:0]						serial_ch	
);
  
    assign o_rd = csr_to_rf ? csr_data : (i_ldflag ? i_lsu_res : i_exu_res);
    assign serial_ch = o_rd[7:0];

endmodule
