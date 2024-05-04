`include "config.sv"
module bypass (
	input                          	i_clk       ,
	input							csr_to_rf	,
	input							flush		,

	input         [`REG_ADDRW-1:0] 	i_idu_rs1id ,
	input         [`REG_ADDRW-1:0] 	i_idu_rs2id ,
	input                          	i_idu_sten  ,

	input                          	i_exu_lden  ,
	input                          	i_exu_rdwen ,
	input         [`REG_ADDRW-1:0] 	i_exu_rdid  ,
	input         [`CPU_WIDTH-1:0] 	i_exu_exres ,
	input							ex_valid	,

	input                          	i_lsu_lden  ,
	input                          	i_lsu_rdwen ,
	input         [`REG_ADDRW-1:0] 	i_lsu_rdid  ,
	input         [`CPU_WIDTH-1:0] 	i_lsu_exres ,
	input         [`CPU_WIDTH-1:0] 	i_lsu_lsres ,
	input							mem_valid	,

	input                          	i_wbu_rdwen ,
	input         [`REG_ADDRW-1:0] 	i_wbu_rdid  ,
	input         [`CPU_WIDTH-1:0] 	i_wbu_rd    ,
	input 							wb_valid	,
	input							wb_ready	,

	output logic  [`CPU_WIDTH-1:0] 	o_idu_rs1   ,
	output logic  [`CPU_WIDTH-1:0] 	o_idu_rs2   ,

	output logic                    o_ifid_stall,
	output reg                     	o_idex_bubble,

	input         [`CPU_WIDTH-1:0] 	i_exu_rs2   , 
	output                         	o_idu_ldstbp,  
	input                          	i_exu_ldstbp,  
	output  wire  [`CPU_WIDTH-1:0] 	o_exu_rs2   ,  

	output logic [`REG_BUS]        	o_regs [0:31],
	output logic [`CPU_WIDTH-1:0] 	regfile_rs1
);
	
	logic [`CPU_WIDTH-1:0] regfile_rs2;
	wire wb_hs =wb_valid & wb_ready;
	wire rf_wen = (i_wbu_rdwen || csr_to_rf) & wb_hs & !flush;

	regfile u_regfile(
		.i_clk    (i_clk        ),
		.i_wen    (rf_wen		),
		.i_waddr  (i_wbu_rdid   ),
		.i_wdata  (i_wbu_rd     ),
		.i_raddr1 (i_idu_rs1id  ),
		.i_raddr2 (i_idu_rs2id  ),
		.o_rdata1 (regfile_rs1  ),
		.o_rdata2 (regfile_rs2  ),
		.o_regs   (o_regs       )
	);

	wire ex_rs1en =  ex_valid && !i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_idu_rs1id);
	wire mem_rs1en = mem_valid && i_lsu_rdwen && (i_lsu_rdid == i_idu_rs1id);
	wire wb_rs1en = wb_valid && i_wbu_rdwen && (i_wbu_rdid == i_idu_rs1id);

	always @(*) begin 
		if(ex_rs1en)begin
			o_idu_rs1 = i_exu_exres;
		end else if(mem_rs1en)begin
			o_idu_rs1 = i_lsu_lden ? i_lsu_lsres : i_lsu_exres;
		end else if(wb_rs1en)begin
			o_idu_rs1 = i_wbu_rd;
		end else begin
			o_idu_rs1 = regfile_rs1;
		end
	end

	wire ex_rs2en = ex_valid && !i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_idu_rs2id);
	wire mem_rs2en = mem_valid && i_lsu_rdwen && (i_lsu_rdid == i_idu_rs2id);
	wire wb_rs2en = wb_valid && i_wbu_rdwen && (i_wbu_rdid == i_idu_rs2id);

	always @(*) begin 
		if(ex_rs2en)begin
			o_idu_rs2 = i_exu_exres;
		end else if(mem_rs2en)begin
			o_idu_rs2 = i_lsu_lden ? i_lsu_lsres : i_lsu_exres;
		end else if(wb_rs2en)begin
			o_idu_rs2 = i_wbu_rd;
		end else begin
			o_idu_rs2 = regfile_rs2;
		end
	end

	assign o_idex_bubble =  i_exu_lden && i_exu_rdwen && ( i_exu_rdid == i_idu_rs1id || i_exu_rdid == i_idu_rs2id ) && !o_idu_ldstbp && ex_valid;
	assign o_ifid_stall  =  o_idex_bubble;

	assign o_idu_ldstbp  =  i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_idu_rs2id) &i_idu_sten;  //load + store, do not need bubble!
	assign o_exu_rs2 = i_exu_ldstbp ? o_idu_rs2 : i_exu_rs2;

endmodule
