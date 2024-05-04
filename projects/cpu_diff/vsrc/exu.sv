`include "config.sv"
module exu (
	input                   			i_clk,
	input                   			i_rst_n,
	input         [`CPU_WIDTH-1:0]      i_pc      ,
	input         [`CPU_WIDTH-1:0]      i_rs1     ,
	input         [`CPU_WIDTH-1:0]      i_rs2     ,
	input         [`CPU_WIDTH-1:0]      i_imm     ,
	input         [`EXU_SEL_WIDTH-1:0]  i_src_sel ,
	input         [`EXU_OPT_WIDTH-1:0]  i_exopt   ,
	input                               id_alu_valid, //id->ex valid
	input                               mem_alu_ready, //ex->id ready
	output                              alu_id_ready, //id
	output                              alu_mem_valid,
	output logic  [`CPU_WIDTH-1:0]      o_exu_res
);

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
