`include "config.sv"
module bru (
	input                         	i_clk  	,	
	input                         	i_rst_n	,
	input							flush	,
	input							keep	,
	input							ecall	,
	input							time_int,
	input							mret	,
	input		[`CPU_WIDTH-1:0]	mtvec_pc,
	input		[`CPU_WIDTH-1:0]	epc		,
	input                         	i_jal  	,
	input                         	i_jalr 	,
	input                         	i_brch 	,
	input       [2:0]            	i_bfun3	,	
	input       [`CPU_WIDTH-1:0] 	i_rs1  	,
	input       [`CPU_WIDTH-1:0] 	i_rs2  	,
	input		[`REG_ADDRW-1:0]	i_rs1id ,
	input		[`REG_ADDRW-1:0]	i_rdid  ,
	input		[`CPU_WIDTH-1:0] 	i_rf1	,
	input       [`CPU_WIDTH-1:0] 	i_imm  	,
	input       [`CPU_WIDTH-1:0] 	i_prepc	,
	input							br_fetch_valid,
	input							br_fetch_ready,
	input							pc_stall,
	output logic [`CPU_WIDTH-1:0] 	o_pc   	,
	output							jump_stall,
	output                        	o_ifid_bubble
);

	wire br_handshake = br_fetch_valid & br_fetch_ready;
	
	wire jalr_bp = i_jalr && (i_rs1id == i_rdid);
	logic [63:0]jalr_bp_tar_i = i_rf1 + i_imm;
	logic [63:0]jalr_bp_tar_o;
	stl_reg #(
		.WIDTH     (`CPU_WIDTH          ),
		.RESET_VAL (`PC_START)
	)u_jalr_reg(
		.i_clk   (i_clk   	),
		.i_rst_n (i_rst_n 	),
		.i_wen   (jalr_bp && br_handshake),
		.i_din   (jalr_bp_tar_i ),
		.o_dout  (jalr_bp_tar_o )
	);

	logic branch;
	logic supersub_resbit;
	logic [`CPU_WIDTH-1:0] sub_res;

	assign sub_res = i_rs1 - i_rs2;
	assign supersub_resbit = {{1'b0,i_rs1} - {1'b0,i_rs2}}[`CPU_WIDTH];

	stl_mux_default #(6,3,1) mux_branch (branch, i_bfun3, 0, {
		`FUNC3_BEQ ,   ~(|sub_res)           ,
		`FUNC3_BNE ,    (|sub_res)           ,
		`FUNC3_BLT ,    sub_res[`CPU_WIDTH-1],
		`FUNC3_BGE ,   ~sub_res[`CPU_WIDTH-1],
		`FUNC3_BLTU,    supersub_resbit       ,
		`FUNC3_BGEU,   ~supersub_resbit
	});

	wire jump = (i_brch ? branch : 1'b0) ||  i_jal || i_jalr;
	assign jump_stall = jump;
	assign o_ifid_bubble = jump;

	logic [`CPU_WIDTH-1:0] seq_pc, jump_pc, next_pc;

	assign seq_pc  = o_pc + 4;
	assign jump_pc = i_jalr ? (jalr_bp ? jalr_bp_tar_o : (i_rs1 + i_imm)) : (i_prepc + i_imm);
	assign next_pc = jump ? jump_pc : seq_pc ;

	reg delay;
	always @(posedge i_clk) begin
		if(jump) 
			delay <= br_handshake;
		else
			delay <= 1'b0;
	end	
 
	always @(posedge i_clk) begin
		if(i_rst_n) begin
			o_pc <= `PC_START;
		end	else if(flush && (ecall || time_int)) begin
			o_pc <= mtvec_pc;
		end	else if(flush && mret) begin
			o_pc <= epc;
		end else if(pc_wen) begin
			o_pc <= next_pc;
		end else begin
			o_pc <= o_pc;
		end
	end

	wire pc_wen = (br_handshake || jump || delay) & ~pc_stall && ~keep;

endmodule
