`include "config.sv"
module bypass (
	input                            i_clk         ,

	input         [`REG_ADDRW-1:0]   i_idu_rs1id   ,
	input         [`REG_ADDRW-1:0]   i_idu_rs2id   ,
	input                            i_idu_sten    ,

	input                            i_exu_lden    ,
	input                            i_exu_rdwen   ,
	input         [`REG_ADDRW-1:0]   i_exu_rdid    ,
	input         [`CPU_WIDTH-1:0]   i_exu_exres   ,

	input                            i_lsu_lden    ,
	input                            i_lsu_rdwen   ,
	input         [`REG_ADDRW-1:0]   i_lsu_rdid    ,
	input         [`CPU_WIDTH-1:0]   i_lsu_exres   ,
	input         [`CPU_WIDTH-1:0]   i_lsu_lsres   ,

	input                            i_wbu_rdwen   ,
	input         [`REG_ADDRW-1:0]   i_wbu_rdid    ,
	input         [`CPU_WIDTH-1:0]   i_wbu_rd      ,

	output logic  [`CPU_WIDTH-1:0]   o_idu_rs1     ,
	output logic  [`CPU_WIDTH-1:0]   o_idu_rs2     ,

	output                           o_pc_wen      ,
	output                           o_ifid_stall  ,
	output                           o_idex_bubble ,

	input         [`CPU_WIDTH-1:0]   i_exu_rs2     ,  
	output                           o_idu_ldstbp  ,  
	input                            i_exu_ldstbp  ,  
	output        [`CPU_WIDTH-1:0]   o_exu_rs2     ,  

	// 3. for sim:
	output logic [`REG_BUS]          o_regs [0:31]
);
	
	logic [`CPU_WIDTH-1:0] regfile_rs1,regfile_rs2;

	regfile u_regfile(
		.i_clk    (i_clk        ),
		.i_wen    (i_wbu_rdwen  ),
		.i_waddr  (i_wbu_rdid   ),
		.i_wdata  (i_wbu_rd     ),
		.i_raddr1 (i_idu_rs1id  ),
		.i_raddr2 (i_idu_rs2id  ),
		.o_rdata1 (regfile_rs1  ),
		.o_rdata2 (regfile_rs2  ),
		.o_regs   (o_regs       )
	);

	always @(*) begin 
		if(!i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_idu_rs1id))begin
			o_idu_rs1 = i_exu_exres;
		end else if(i_lsu_rdwen && (i_lsu_rdid == i_idu_rs1id))begin
			o_idu_rs1 = i_lsu_lden ? i_lsu_lsres : i_lsu_exres;
		end else if(i_wbu_rdwen && (i_wbu_rdid == i_idu_rs1id))begin
			o_idu_rs1 = i_wbu_rd;
		end else begin
			o_idu_rs1 = regfile_rs1;
		end
	end

	always @(*) begin 
		if(!i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_idu_rs2id))begin
			o_idu_rs2 = i_exu_exres;
		end else if(i_lsu_rdwen && (i_lsu_rdid == i_idu_rs2id))begin
			o_idu_rs2 = i_lsu_lden ? i_lsu_lsres : i_lsu_exres;
		end else if(i_wbu_rdwen && (i_wbu_rdid == i_idu_rs2id))begin
			o_idu_rs2 = i_wbu_rd;
		end else begin
			o_idu_rs2 = regfile_rs2;
		end
	end

	assign o_idex_bubble =  i_exu_lden && i_exu_rdwen && ( i_exu_rdid == i_idu_rs1id || i_exu_rdid == i_idu_rs2id ) && !o_idu_ldstbp;
	assign o_pc_wen      = 	~o_idex_bubble;
	assign o_ifid_stall    =  o_idex_bubble;

	assign o_idu_ldstbp  =  i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_idu_rs2id) && i_idu_sten;  //load + store, do not need bubble!
	assign o_exu_rs2 = i_exu_ldstbp ? i_lsu_lsres : i_exu_rs2;

endmodule
