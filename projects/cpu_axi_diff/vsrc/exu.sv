`include "config.sv"
module exu (
	input                   			i_clk		,
	input                   			i_rst_n		,
	input		 [`CPU_WIDTH-1:0]		i_ins		,
	input        [`CPU_WIDTH-1:0]      	i_pc      	,
	input        [`CPU_WIDTH-1:0]      	i_rs1     	,
	input        [`CPU_WIDTH-1:0]      	i_rs2     	,
	input        [`CPU_WIDTH-1:0]      	i_imm     	,
	input        [`EXU_SEL_WIDTH-1:0]  	i_src_sel 	,
	input        [`EXU_OPT_WIDTH-1:0]  	i_exopt   	,
	input                               id_alu_valid, 
	input                               mem_alu_ready,
	output                              alu_id_ready, 
	output                              alu_mem_valid,
	output 	logic  	[`CPU_WIDTH-1:0]    o_exu_res	,
	input			[2:0]				csr_choose	,
	input			[`CPU_WIDTH-1:0]	csr_data	,
	input			[`CPU_WIDTH-1:0]	csr_wdata	,
	output 	logic	[`CPU_WIDTH-1:0]	csr_data_res,
	output								csr_wen		,
	output	logic 						csr_to_rf	,
	output								serial_valid
);

	always @(posedge i_clk) begin
		serial_valid <= (i_ins == 'h7b);
	end	

	logic [63:0] csrrci = csr_data & ~csr_wdata;
	assign csr_data_res = 	csr_choose == 3'b100 ? csr_wdata : 
							(csr_choose == 3'b010 ? csr_data | csr_wdata:
							(csr_choose == 3'b001 ? {csr_data[63:5], csrrci[4:0]} : 64'b0)); 
	assign csr_wen = |csr_choose;
	assign csr_to_rf = csr_choose[1] || csr_choose[0];

	logic [`CPU_WIDTH-1:0] src1,src2;

	stl_mux_default #(1<<`EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src1 (src1, i_src_sel, `CPU_WIDTH'b0, {
		`EXU_SEL_REG, i_rs1,
		`EXU_SEL_IMM, i_rs1,
		`EXU_SEL_PC4, i_pc,
		`EXU_SEL_PCI, i_pc
	});

	stl_mux_default #(1<<`EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src2 (src2, i_src_sel, `CPU_WIDTH'b0, {
		`EXU_SEL_REG, i_rs2,
		`EXU_SEL_IMM, i_imm,
		`EXU_SEL_PC4, `CPU_WIDTH'h4,
		`EXU_SEL_PCI, i_imm
});

	alu alu(
		.clk                (i_clk    ),
		.rst_n              (i_rst_n  ),
		.src1               (src1   ),
		.src2               (src2   ),
		.exopt              (i_exopt  ),
		.alu_valid_in       (id_alu_valid),
		.alu_ready_in       (mem_alu_ready),
		.alu_valid_out      (alu_mem_valid),
		.alu_ready_out      (alu_id_ready),
		.o_exe_res          (o_exu_res)
	);

endmodule
