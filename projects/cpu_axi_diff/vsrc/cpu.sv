`include "config.sv"

module cpu(
	input                               clock		,
	input                               reset		,
	
	output                              axi_valid	,
	input                               axi_ready	,
	input  	[63:0]                      axi_data_read,
	output 	[63:0]                      axi_addr	,
	output 	[1:0]                       axi_size	,
	input  	[1:0]                       axi_resp	,
	output	logic						axi_sig_mem	,
	output	wire						axi_sig_write,
	input	[`AXI_ID_WIDTH-1:0]			axi_ret_id	,
	output	logic [63:0]				axi_data_write,
	output	logic [7:0]					wmask		,
	output	wire						serial_valid,
	output	logic [7:0]					serial_ch	
);

	logic axi_if_valid, axi_if_ready, axi_mem_valid, axi_mem_ready;
	logic [`AXI_ID_WIDTH-1:0] axi_id;
	logic [`CPU_WIDTH-1:0] axi_mem_addr,	axi_mem_wdata;
	logic [1:0] axi_if_size, axi_mem_size;
	logic [1:0] axi_if_resp, axi_mem_resp;
	logic [`CPU_WIDTH-1:0]	if_data_read, mem_data_read;
 
	atributer arb (
		.clock				(clock		),
		.reset				(reset		),

		.if_rw_valid_i		(axi_if_valid),
		.if_rw_ready_o		(axi_if_ready),

		.mem_rw_valid_i		(axi_mem_valid),
		.mem_rw_ready_o		(axi_mem_ready),

		.if_rw_addr_i		(ifu_pc_o	),
		.if_rw_size_i		(axi_if_size),

		.mem_rw_addr_i		(exu_exres_r),
		.mem_rw_size_i		(axi_mem_size),
		.mem_data_write_i	(axi_mem_wdata),
		.sig_store			(exu_sten_r	),
		.axi_sig_mem		(axi_sig_mem),
		.axi_sig_write		(axi_sig_write),

		.if_data_read	    (if_data_read),
		.mem_data_read		(mem_data_read),

		.axi_rw_id			(axi_id		),
		.axi_rw_size		(axi_size	),
		.axi_rw_addr		(axi_addr	),
		.axi_wt_data		(axi_data_write),

		.axi_ret_id			(axi_ret_id	),
		.axi_ret_rd_data	(axi_data_read),

		.axi_rw_valid		(axi_valid	),		
		.axi_rw_ready		(axi_ready	)
	);

	wire [`REG_BUS] regs[0 : 31];

	logic if_valid, if_ready, id_ready;
	wire  id_valid;
	logic ex_valid, ex_ready, id_ex_valid_o, ex_id_ready_i; 
	logic mem_valid, mem_ready, ex_mem_valid_o, mem_ex_ready_i;
	logic wb_valid,wb_ready;
	assign wb_ready = axi_if_ready;

	logic rst_n_sync;
	stl_rst u_stl_rst(
		.i_clk        		(clock     	),
		.i_rst_n      		(reset    	),
		.o_rst_n_sync 		(rst_n_sync )
	);
	
	logic [`CPU_WIDTH-1:0]  pc;
	logic ifid_stall, ifid_bubble, idex_bubble, idu_ldstbp, exu_ldstbp;
	
	logic [`CPU_WIDTH-1:0]  ifu_pc_i, ifu_pc_o, ifu_pc_r;
	logic [`INS_WIDTH-1:0]  ifu_ins,ifu_ins_r;

	ifu u_ifu(
		.i_clk	 			(clock			),
		.i_rst_n 			(rst_n_sync		),
		.flush				(flush			),
		.keep				(keep			),
		.i_pc    			(pc    			),
		.o_pc				(ifu_pc_o		),
		.o_ins   			(ifu_ins   		),
		.axi_if_valid    	(axi_if_valid	),
		.axi_if_ready    	(axi_if_ready	),
		.id_if_ready		(if_ready		),
		.if_id_valid		(if_valid		),
		.if_data_read		(if_data_read	),
		.if_size     		(axi_if_size	),
		.if_resp     		(axi_if_resp	),
		.pc_stall			(ifid_stall		)
	);

	pipe_if_id u_pipe_if_id(
		.i_clk        		(clock       	),
		.i_rst_n      		(rst_n_sync  	),
		.flush				(flush			),
		.i_bubble     		(ifid_bubble 	),
		.i_ifu_ins    		(ifu_ins     	),
		.i_ifu_pc     		(ifu_pc_o 	 	),
		.if_valid_i   		(if_valid		),
		.id_ready_i   		(id_ready		),
		.if_ready_o   		(if_ready 		),
		.id_valid_o   		(id_valid 		),
		.pc_stall			(ifid_stall		),
		.o_idu_ins    		(ifu_ins_r   	),
		.o_idu_pc     		(ifu_pc_r    	)
	);

	logic [`REG_ADDRW-1:0]      idu_rs1id,idu_rs2id;
	logic [`REG_ADDRW-1:0]      idu_rdid,idu_rdid_r;
	logic                       idu_rdwen,idu_rdwen_r;
	logic [`CPU_WIDTH-1:0]      idu_imm,idu_imm_r;
	logic [`CPU_WIDTH-1:0]      idu_rs1,idu_rs1_r;
	logic [`CPU_WIDTH-1:0]      idu_rs2,idu_rs2_r;
	logic [`EXU_SEL_WIDTH-1:0]  idu_src_sel,idu_src_sel_r;
	logic [`EXU_OPT_WIDTH-1:0]  idu_exopt,idu_exopt_r;
	logic [2:0]                 idu_lsfunc3,idu_lsfunc3_r;
	logic                       idu_lden,idu_lden_r;
	logic                       idu_sten,idu_sten_r;
	logic [`CPU_WIDTH-1:0]      idu_pc,idu_pc_r;

	logic                       idu_jal,idu_jalr,idu_brch;
	logic [2:0]                 idu_bfun3;

	idu u_idu(
		.i_ins       		(ifu_ins_r   	),
		.rf_rs1				(regfile_rs1	),
		.o_rs1id     		(idu_rs1id   	),
		.o_rs2id     		(idu_rs2id   	),
		.o_rdid      		(idu_rdid    	),
		.o_rdwen     		(idu_rdwen   	),
		.o_imm       		(idu_imm     	),
		.o_src_sel   		(idu_src_sel 	),
		.o_exopt     		(idu_exopt   	),
		.o_lsu_func3 		(idu_lsfunc3 	),
		.o_lsu_lden  		(idu_lden    	),
		.o_lsu_sten  		(idu_sten    	),
		.o_jal       		(idu_jal     	),
		.o_jalr      		(idu_jalr    	),
		.o_brch      		(idu_brch    	),
		.o_bfun3     		(idu_bfun3   	),
		.except_en			(id_except_en	),
		.except_code		(id_except_code	),	
		.csr				(id_csr			),	
		.ins_mret			(id_mret		),
		.csr_wdata			(id_csr_wdata	),
		.csr_choose			(id_csr_choose	)
	);

	assign idu_pc = ifu_pc_r;
	logic [`INS_WIDTH-1:0] idu_ins_r;
	pipe_id_ex u_pipe_id_ex(
		.i_clk         		(clock        	),
		.i_rst_n       		(rst_n_sync   	),
		.i_bubble      		(idex_bubble  	),
		.flush				(flush			),
		.i_idu_imm     		(idu_imm      	),
		.i_idu_rs1     		(idu_rs1      	),
		.i_idu_rs2     		(idu_rs2      	),
		.i_idu_rdid    		(idu_rdid     	),
		.i_idu_rdwen   		(idu_rdwen    	),
		.i_idu_src_sel 		(idu_src_sel  	),
		.i_idu_exopt   		(idu_exopt    	),
		.i_idu_func3   		(idu_lsfunc3  	),
		.i_idu_lden    		(idu_lden     	),
		.i_idu_sten    		(idu_sten     	),
		.i_idu_ldstbp  		(idu_ldstbp   	),
		.i_idu_pc      		(idu_pc       	),
		.id_csr		  		(id_csr			),
		.id_csr_wdata  		(id_csr_wdata	),
		.id_csr_choose 		(id_csr_choose	),
		.id_except_code		(id_except_code	),
		.id_except_en  		(id_except_en  	),
		.id_mret			(id_mret		),  
		.id_mtime_int  		(clint_mtime_int),
		.s_idu_diffins 		(ifu_ins_r	  	),

		.id_valid_i    		(id_valid		),
		.exe_ready_i   		(ex_id_ready_i 	),
		.id_ready_o    		(id_ready	 	),
		.exe_valid_o   		(id_ex_valid_o 	),

		.o_exu_imm     		(idu_imm_r    	),
		.o_exu_rs1     		(idu_rs1_r    	),
		.o_exu_rs2     		(idu_rs2_r    	),
		.o_exu_rdid    		(idu_rdid_r   	),
		.o_exu_rdwen   		(idu_rdwen_r  	),
		.o_exu_src_sel 		(idu_src_sel_r	),
		.o_exu_exopt   		(idu_exopt_r  	),
		.o_exu_func3   		(idu_lsfunc3_r	),
		.o_exu_lden    		(idu_lden_r   	),
		.o_exu_sten    		(idu_sten_r   	),
		.o_exu_ldstbp  		(exu_ldstbp   	),
		.o_exu_pc      		(idu_pc_r     	),
		.ex_csr		  		(ex_csr		  	),
		.ex_csr_wdata  		(ex_csr_wdata  	),
		.ex_csr_choose 		(ex_csr_choose 	),
		.ex_except_code		(ex_except_code	),
		.ex_except_en  		(ex_except_en  	),
		.ex_mret			(ex_mret		), 
		.ex_mtime_int  		(ex_mtime_int  	),
		.s_exu_diffins 		(idu_ins_r 	  	)
	);

	logic [`CPU_WIDTH-1:0]      exu_exres,exu_exres_r;
	logic [`CPU_WIDTH-1:0]      exu_rs2,exu_rs2_r;
	wire [`CPU_WIDTH-1:0] 		exu_rs2_bp;
	logic [`REG_ADDRW-1:0]      exu_rdid,exu_rdid_r;
	logic                       exu_rdwen,exu_rdwen_r;
	logic [2:0]                 exu_lsfunc3,exu_lsfunc3_r;
	logic                       exu_lden,exu_lden_r;
	logic                       exu_sten,exu_sten_r;
	logic [`INS_WIDTH-1:0]	  	exu_ins_r;
	logic [`CPU_WIDTH-1:0]		exu_pc_r;
	
	exu u_exu(
		.i_clk				(clock			),
		.i_rst_n			(rst_n_sync		),
		.i_ins				(idu_ins_r		),
		.i_pc      			(idu_pc_r      	),
		.i_rs1     			(idu_rs1_r     	),
		.i_rs2     			(idu_rs2_r     	),
		.i_imm     			(idu_imm_r     	),
		.i_src_sel 			(idu_src_sel_r 	),
		.i_exopt   			(idu_exopt_r   	),

		.id_alu_valid       (id_ex_valid_o	),
		.mem_alu_ready      (ex_ready		),
		.alu_id_ready       (ex_id_ready_i	),
		.alu_mem_valid      (ex_valid		),

		.o_exu_res 			(exu_exres     	),
		.csr_choose			(ex_csr_choose	),
		.csr_wdata			(id_csr_wdata	),
		.csr_data			(csr_data		),
		.csr_data_res		(ex_csr_data_res),
		.csr_wen			(ex_csr_wen		),
		.serial_valid		(serial_valid	),
		.csr_to_rf			(ex_csr_to_rf	)
	);

	assign exu_rs2 = idu_rs2_r;
	assign exu_rdid = idu_rdid_r;
	assign exu_rdwen = idu_rdwen_r;
	assign exu_lsfunc3 = idu_lsfunc3_r;
	assign exu_lden = idu_lden_r;
	assign exu_sten = idu_sten_r;

	pipe_ex_ls u_pipe_ex_ls(
		.i_clk        		(clock        	),
		.i_rst_n      		(rst_n_sync   	),
		.flush				(flush			),
		.i_exu_exres  		(exu_exres    	),
		.i_exu_rs2    		(exu_rs2_bp   	),
		.i_exu_rdid   		(exu_rdid     	),
		.i_exu_rdwen  		(exu_rdwen    	),
		.i_exu_func3  		(exu_lsfunc3  	),
		.i_exu_lden   		(exu_lden     	),
		.i_exu_sten   		(exu_sten     	),
		.s_exu_diffins		(idu_ins_r		),
		.i_exu_pc			(idu_pc_r		),
		.exu_csr		 	(ex_csr			),
		.exu_csr_wen		(ex_csr_wen		),
		.exu_csr_data_res	(ex_csr_data_res),
		.exu_except_code	(ex_except_code	),
		.exu_except_en		(ex_except_en	),
		.exu_mret			(ex_mret		),
		.exu_mtime_int		(ex_mtime_int	),
		.exu_csr_to_rf		(ex_csr_to_rf	),
		.exu_csr_data		(csr_data		),

		.exe_valid_i  		(ex_valid		),
		.mem_ready_i  		(mem_ex_ready_i	),
		.exe_ready_o  		(ex_ready		),
		.mem_valid_o  		(ex_mem_valid_o	),

		.o_lsu_exres  		(exu_exres_r  	),
		.o_lsu_rs2    		(exu_rs2_r    	),
		.o_lsu_rdid   		(exu_rdid_r   	),
		.o_lsu_rdwen  		(exu_rdwen_r  	),
		.o_lsu_func3  		(exu_lsfunc3_r	),
		.o_lsu_lden   		(exu_lden_r   	),
		.o_lsu_sten   		(exu_sten_r   	),
		.s_mem_diffins		(exu_ins_r 		),
		.o_mem_pc			(exu_pc_r		),
		.mem_csr			(mem_csr		),
		.mem_csr_wen		(mem_csr_wen	),
		.mem_csr_data_res	(mem_csr_data_res),
		.mem_except_code	(mem_except_code),
		.mem_except_en		(mem_except_en	),
		.mem_mret			(mem_mret		),
		.mem_mtime_int		(mem_mtime_int	),
		.mem_csr_to_rf		(mem_csr_to_rf	),
		.mem_csr_data		(mem_csr_data	)
	);

	logic [`CPU_WIDTH-1:0]      lsu_exres,lsu_exres_r;
	logic [`CPU_WIDTH-1:0]      lsu_lsres,lsu_lsres_r;
	logic                       lsu_lden, lsu_lden_r;
	logic                       lsu_sten, lsu_sten_r;
	logic [`REG_ADDRW-1:0]      lsu_rdid, lsu_rdid_r;
	logic                       lsu_rdwen,lsu_rdwen_r;
	logic [`INS_WIDTH-1:0]	 	mem_ins_r;

	lsu u_lsu(
		.i_clk				(clock			),
		.i_rst_n			(reset			),
		.i_lsfunc3			(exu_lsfunc3_r	),
		.i_lden				(exu_lden_r		),
		.i_sten				(exu_sten_r		),
		.ex_mem_valid		(ex_mem_valid_o	),
		.mem_ex_ready		(mem_ex_ready_i	),
		.axi_mem_valid		(axi_mem_valid	),
		.axi_mem_ready		(axi_mem_ready	),
		.mem_wb_valid		(mem_valid		),
		.wb_mem_ready		(mem_ready		),
		.mem_resp			(axi_mem_resp	),
		.i_addr				(exu_exres_r	),
		.i_wt_data			(exu_rs2_r		),
		.mem_rdata			(mem_data_read	),
		.mem_addr			(axi_mem_addr	),
		.mem_size			(axi_mem_size	),
		.mem_wdata			(axi_mem_wdata	),
		.o_ld_data			(lsu_lsres		),
		.wmask				(wmask			),
		.mtime_data			(mtime_data		),
		.mtimecmp_data		(mtimecmp_data	),
		.mtime_en			(mtime_en		),
		.mtimecmp_en		(mtimecmp_en	),
		.time_wdata			(time_wdata		)
	);

	assign lsu_exres = exu_exres_r;
	assign lsu_lden  = exu_lden_r;
	assign lsu_sten	 = exu_sten_r;
	assign lsu_rdid  = exu_rdid_r;
	assign lsu_rdwen = exu_rdwen_r;
	logic 	[`CPU_WIDTH-1:0] mem_pc_r;
	pipe_ls_wb u_pipe_ls_wb(
		.i_clk        		(clock        	),
		.i_rst_n      		(rst_n_sync   	),
		.flush				(flush			),
		.i_lsu_exres  		(lsu_exres    	),
		.i_lsu_lsres  		(lsu_lsres    	),
		.i_lsu_rdid   		(lsu_rdid     	),
		.i_lsu_rdwen  		(lsu_rdwen    	),
		.i_lsu_lden   		(lsu_lden     	),
		.i_lsu_sten			(lsu_sten		),
		.s_mem_diffins		(exu_ins_r		),
		.i_mem_pc			(exu_pc_r		),
		.mem_csr			(mem_csr		),
		.mem_csr_wen	 	(mem_csr_wen	 ),
		.mem_csr_data_res	(mem_csr_data_res),
		.mem_except_code	(mem_except_code),
		.mem_except_en		(mem_except_en	),
		.mem_mret	 		(mem_mret	 	),
		.mem_mtime_int		(mem_mtime_int	),
		.mem_csr_to_rf		(mem_csr_to_rf	),
		.mem_csr_data 		(mem_csr_data 	),
		.mem_valid_i  		(mem_valid		),
		.wb_ready_i   		(wb_ready   	),
		.mem_ready_o  		(mem_ready		),
		.wb_valid_o   		(wb_valid   	),
		.o_wbu_exres  		(lsu_exres_r  	),
		.o_wbu_lsres  		(lsu_lsres_r  	),
		.o_wbu_rdid   		(lsu_rdid_r   	),
		.o_wbu_rdwen  		(lsu_rdwen_r  	),
		.o_wbu_lden   		(lsu_lden_r   	),
		.o_wbu_sten			(lsu_sten_r		),
		.s_wbu_diffins		(mem_ins_r		),
		.o_wb_pc			(mem_pc_r		),
		.wb_csr				(wb_csr			),		 	
		.wb_csr_wen	 		(wb_csr_wen	 	),
		.wb_csr_data_res	(wb_csr_data_res),
		.wb_except_code		(wb_except_code	),
		.wb_except_en 		(wb_except_en 	),
		.wb_mret 	 		(wb_mret 	 	),
		.wb_csr_to_rf 		(wb_csr_to_rf 	),
		.wb_mtime_int 		(wb_mtime_int 	),
		.wb_csr_data		(wb_csr_data	)
	);

	logic [`CPU_WIDTH-1:0]      wbu_rd;
	logic [`REG_ADDRW-1:0]      wbu_rdid;
	logic                       wbu_rdwen;

	assign wbu_rdid  = lsu_rdid_r ;
	assign wbu_rdwen = lsu_rdwen_r;
	wbu u_wbu(
		.i_exu_res 			(lsu_exres_r 	),
		.i_lsu_res 			(lsu_lsres_r 	),
		.i_ldflag  			(lsu_lden_r  	),
		.o_rd      			(wbu_rd      	),
		.csr_to_rf   		(wb_csr_to_rf	),
		.csr_data    		(wb_csr_data	),
		.serial_ch			(serial_ch		)
	);

	bypass u_bypass(
		.i_clk         		(clock         	),
		.csr_to_rf			(wb_csr_to_rf	),
		.flush				(flush			),
		.i_idu_rs1id   		(idu_rs1id     	),
		.i_idu_rs2id   		(idu_rs2id     	),
		.i_idu_sten    		(idu_sten      	),
		.i_exu_lden    		(exu_lden      	),
		.i_exu_rdwen   		(exu_rdwen     	),
		.i_exu_rdid    		(exu_rdid      	),
		.i_exu_exres   		(exu_exres     	),
		.ex_valid			(ex_valid		),
		.i_lsu_lden    		(lsu_lden      	),
		.i_lsu_rdwen   		(lsu_rdwen     	),
		.i_lsu_rdid    		(lsu_rdid      	),
		.i_lsu_lsres   		(lsu_lsres     	),
		.i_lsu_exres   		(lsu_exres     	), 
		.mem_valid			(mem_valid		),  
		.i_wbu_rdwen   		(wbu_rdwen     	),
		.i_wbu_rdid    		(wbu_rdid      	),
		.i_wbu_rd      		(wbu_rd        	),
		.wb_valid			(wb_valid		),
		.wb_ready			(wb_ready		),
		.o_idu_rs1     		(idu_rs1       	),
		.o_idu_rs2     		(idu_rs2       	),
		.o_ifid_stall    	(ifid_stall     ),
		.o_idex_bubble 		(idex_bubble   	),
		.i_exu_rs2     		(exu_rs2       	),
		.o_idu_ldstbp  		(idu_ldstbp    	),
		.i_exu_ldstbp  		(exu_ldstbp    	),
		.o_exu_rs2     		(exu_rs2_bp    	),
		.o_regs 	   		(regs		  	),
		.regfile_rs1		(regfile_rs1	)
	);
	logic [63:0] regfile_rs1;
	bru u_bru(
		.i_clk        		(clock       	),
		.i_rst_n      		(rst_n_sync  	),
		.flush				(flush			),
		.keep				(keep			),
		.ecall				(ecall			),
		.time_int			(time_int		),
		.mret				(id_mret		),
		.mtvec_pc			(mtvec_pc		),
		.epc				(epc			),
		.i_jal        		(idu_jal     	),
		.i_jalr       		(idu_jalr    	),
		.i_brch       		(idu_brch    	),
		.i_bfun3      		(idu_bfun3   	),
		.i_rs1        		(idu_rs1     	),
		.i_rs2        		(idu_rs2     	),
		.i_rs1id			(idu_rs1id		),
		.i_rdid 			(idu_rdid		),
		.i_rf1				(regfile_rs1	),
		.i_imm        		(idu_imm     	),
		.i_prepc      		(ifu_pc_r	    ),
		.br_fetch_valid		(id_valid		),
		.br_fetch_ready		(id_ready		),
		.pc_stall			(ifid_stall		),
		.o_pc         		(pc          	),
		.jump_stall			(jump_stall		),
		.o_ifid_bubble		(ifid_bubble 	)
	);

	//exception	
	wire id_except_en, id_mret;
	wire ex_except_en, ex_mret, ex_mtime_int, ex_csr_wen, ex_csr_to_rf;
	wire mem_except_en, mem_mret, mem_mtime_int, mem_csr_wen, mem_csr_to_rf;
	wire wb_except_en, wb_mret, wb_mtime_int, wb_csr_wen, wb_csr_to_rf;

	logic [`CPU_WIDTH-1:0] id_except_code, ex_except_code, mem_except_code, wb_except_code;
	logic [`CPU_WIDTH-1:0] id_csr_wdata, ex_csr_wdata;
	wire  [2:0] 	id_csr_choose, ex_csr_choose;
	wire  [11:0] 	id_csr, ex_csr, mem_csr, wb_csr;
	logic [`CPU_WIDTH-1:0] mem_csr_data, wb_csr_data;
	logic [`CPU_WIDTH-1:0] ex_csr_data_res, mem_csr_data_res, wb_csr_data_res;
	logic [`CPU_WIDTH-1:0] csr_data;

	//csr
	wire [`CPU_WIDTH-1:0] epc, mtvec_pc;
	logic keep;
	wire time_int;
	logic [63:0] mstatus;
	logic [63:0] mie;
	logic [63:0] mtvec;
	logic [63:0] mepc;
	logic [63:0] mcause;
	logic [63:0] mip;
	logic [63:0] mscratch;
	logic [63:0] sstatus;
	wire flush;
	wire ecall;

	csr u_csr(
		.clk				(clock			),
		.reset				(rst_n_sync		),
		.csr_wdata			(wb_csr_data_res),
		.csr_r				(ex_csr			),
		.csr_w				(wb_csr			),
		.csr_wen			(wb_csr_wen		),
		.except_en			(wb_except_en	),
		.csr_exaddr			(idu_pc_r		),
		.csr_wbaddr			(mem_pc_r		),
		.except_code		(wb_except_code	),
		.mret				(wb_mret		),
		.mtime_int			(wb_mtime_int	),
		.wb_valid			(wb_valid		),
		.wb_ready			(wb_ready		),
		.wb_ins				(mem_ins_r		),
		.flush				(flush			),
		.csr_data			(csr_data		),
		.mtvec_pc			(mtvec_pc		),
		.epc				(epc			),
		.time_int			(time_int		),
		.ecall				(ecall			),
		.keep				(keep			),
		.mstatus			(mstatus		),
		.sstatus			(sstatus		),
		.mie				(mie			),
		.mtvec				(mtvec			),
		.mepc				(mepc			),
		.mcause				(mcause			),
		.mip				(mip			),
		.mscratch			(mscratch		),
		.mstatus_diff		(mstatus_diff	),
		.sstatus_diff		(sstatus_diff	),
		.mie_diff			(mie_diff		),	
		.mtvec_diff			(mtvec_diff		),
		.mepc_diff			(mepc_diff		),
		.mcause_diff		(mcause_diff	),	
		.mip_diff			(mip_diff		),
		.mscratch_diff		(mscratch_diff	)
	);

	//clint
	wire [63:0] time_wdata;
	wire mtimecmp_en, mtime_en;
	wire clint_mtime_int;
	wire [63:0] mtime_data;
	wire [63:0] mtimecmp_data;

	clint u_clint(
    	.clk        		(clock			),
    	.reset      		(rst_n_sync		),
    	.wdata      		(time_wdata		),
    	.mtimecmp_en		(mtimecmp_en	),
    	.mtime_en   		(mtime_en		),
    	.mtime_int  		(clint_mtime_int),
    	.mtime_data 		(mtime_data		),
    	.mtimecmp_data		(mtimecmp_data	)
	);

// Difftest
	reg cmt_wen;
	reg [7:0] cmt_wdest;
	reg [`REG_BUS] cmt_wdata;
	reg [`REG_BUS] cmt_pc;
	reg [31:0] cmt_inst;
	reg cmt_valid;
	reg trap;
	reg [7:0] trap_code;
	reg [63:0] cycleCnt;
	reg [63:0] instrCnt;
	reg [`REG_BUS] regs_diff [0 : 31];
	reg [`CPU_WIDTH-1:0] mstatus_diff;
	reg [`CPU_WIDTH-1:0] mie_diff	;
	reg [`CPU_WIDTH-1:0] mtvec_diff	;
	reg [`CPU_WIDTH-1:0] mepc_diff	;
	reg [`CPU_WIDTH-1:0] mcause_diff;
	reg [`CPU_WIDTH-1:0] mip_diff	;
	reg [`CPU_WIDTH-1:0] mscratch_diff;
	reg [`CPU_WIDTH-1:0] sstatus_diff;

	reg [`INS_WIDTH-1:0] old_ins;
	reg [`CPU_WIDTH-1:0] old_pc;

	always @(posedge clock) begin
		if(axi_ready & axi_valid) begin
			old_ins <= mem_ins_r;
			old_pc <= mem_pc_r;
		end
	end	
	
	wire wb_hs = (wb_valid & wb_ready);
	wire iszero = (mem_ins_r == 'b0) | (mem_pc_r == 'b0);
	wire delay = (old_ins != mem_ins_r) | (old_pc != mem_pc_r);
	wire inst_valid = (wb_hs & delay & ~iszero | flush) & (intrNO != 32'd7);
	wire serial_skip = mem_ins_r[6:0] == 7'h7b;
	wire clint_skip = (lsu_lden_r || lsu_sten_r) & (lsu_exres_r == 'h2004000 || lsu_exres_r == 'h200bff8);

always @(negedge clock) begin
	if(reset) begin
		{cmt_wen, cmt_wdest, cmt_wdata, cmt_pc, cmt_inst, cmt_valid, trap, trap_code, cycleCnt, instrCnt} <= 0;
	end
	else if (~trap) begin
		cmt_wen <= wbu_rdwen;
		cmt_wdest <= {3'd0, wbu_rdid};
		cmt_wdata <= wbu_rd;
		cmt_pc <= mem_pc_r;
		cmt_inst <= mem_ins_r;
		cmt_valid <= inst_valid;

		regs_diff <= regs;

		trap <= mem_ins_r[6:0] == 7'h6b;
		trap_code <= regs[10][7:0];
		cycleCnt <= cycleCnt + 1;
		instrCnt <= instrCnt + inst_valid;
	end
end

DifftestInstrCommit DifftestInstrCommit(
	.clock              (clock),
	.coreid             (0),
	.index              (0),
	.valid              (cmt_valid),
	.pc                 (cmt_pc),
	.instr              (cmt_inst),
	//.special          (0),
	.skip               (serial_skip || clint_skip),
	.isRVC              (0),
	.scFailed           (0),
	.wen                (cmt_wen),
	.wdest              (cmt_wdest),
	.wdata              (cmt_wdata)
);

	wire [31:0] intrNO = (wb_ready & time_int) ? 32'd7 : 'b0;
DifftestArchEvent DifftestArchEvent(
	.clock				(clock),	// 时钟
	.coreid				(0),		// cpu id，单核时固定为0
	.intrNO				(intrNO),	// 中断号，非0时产生中断。产生中断的时钟周期中，DifftestInstrCommit提交的valid需为0
	.cause				(0),		// 异常号，ecall时不需要考虑
	.exceptionPC		(cmt_pc),	// 产生异常时的PC
	.exceptionInst		(cmt_inst)	// 产生异常时的指令
);

DifftestArchIntRegState DifftestArchIntRegState (
	.clock              (clock),
	.coreid             (0),
	.gpr_0              (regs_diff[0]),
	.gpr_1              (regs_diff[1]),
	.gpr_2              (regs_diff[2]),
	.gpr_3              (regs_diff[3]),
	.gpr_4              (regs_diff[4]),
	.gpr_5              (regs_diff[5]),
	.gpr_6              (regs_diff[6]),
	.gpr_7              (regs_diff[7]),
	.gpr_8              (regs_diff[8]),
	.gpr_9              (regs_diff[9]),
	.gpr_10             (regs_diff[10]),
	.gpr_11             (regs_diff[11]),
	.gpr_12             (regs_diff[12]),
	.gpr_13             (regs_diff[13]),
	.gpr_14             (regs_diff[14]),
	.gpr_15             (regs_diff[15]),
	.gpr_16             (regs_diff[16]),
	.gpr_17             (regs_diff[17]),
	.gpr_18             (regs_diff[18]),
	.gpr_19             (regs_diff[19]),
	.gpr_20             (regs_diff[20]),
	.gpr_21             (regs_diff[21]),
	.gpr_22             (regs_diff[22]),
	.gpr_23             (regs_diff[23]),
	.gpr_24             (regs_diff[24]),
	.gpr_25             (regs_diff[25]),
	.gpr_26             (regs_diff[26]),
	.gpr_27             (regs_diff[27]),
	.gpr_28             (regs_diff[28]),
	.gpr_29             (regs_diff[29]),
	.gpr_30             (regs_diff[30]),
	.gpr_31             (regs_diff[31])
);

DifftestTrapEvent DifftestTrapEvent(
	.clock              (clock),
	.coreid             (0),
	.valid              (trap),
	.code               (trap_code),
	.pc                 (cmt_pc),
	.cycleCnt           (cycleCnt),
	.instrCnt           (instrCnt)
);

DifftestCSRState DifftestCSRState(
	.clock              (clock),
	.coreid             (0),
	.priviledgeMode     (`RISCV_PRIV_MODE_M),
	.mstatus            (mstatus_diff),
	.sstatus            (sstatus_diff),
	.mepc               (mepc_diff),
	.sepc               (0),
	.mtval              (0),
	.stval              (0),
	.mtvec              (mtvec_diff),
	.stvec              (0),
	.mcause             (mcause_diff),
	.scause             (0),
	.satp               (0),
	.mip                (mip_diff),
	.mie                (mie_diff),
	.mscratch           (mscratch_diff),
	.sscratch           (0),
	.mideleg            (0),
	.medeleg            (0)
);

DifftestArchFpRegState DifftestArchFpRegState(
	.clock              (clock),
	.coreid             (0),
	.fpr_0              (0),
	.fpr_1              (0),
	.fpr_2              (0),
	.fpr_3              (0),
	.fpr_4              (0),
	.fpr_5              (0),
	.fpr_6              (0),
	.fpr_7              (0),
	.fpr_8              (0),
	.fpr_9              (0),
	.fpr_10             (0),
	.fpr_11             (0),
	.fpr_12             (0),
	.fpr_13             (0),
	.fpr_14             (0),
	.fpr_15             (0),
	.fpr_16             (0),
	.fpr_17             (0),
	.fpr_18             (0),
	.fpr_19             (0),
	.fpr_20             (0),
	.fpr_21             (0),
	.fpr_22             (0),
	.fpr_23             (0),
	.fpr_24             (0),
	.fpr_25             (0),
	.fpr_26             (0),
	.fpr_27             (0),
	.fpr_28             (0),
	.fpr_29             (0),
	.fpr_30             (0),
	.fpr_31             (0)
);

endmodule