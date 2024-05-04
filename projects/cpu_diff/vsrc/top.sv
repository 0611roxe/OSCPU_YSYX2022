`include "config.sv"
module top(
	input                 i_clk   ,
	input                 i_rst_n
);

	logic if_valid,if_ready;
	logic id_valid,id_ready;
	logic exe_valid,exe_ready;
	logic mem_valid,mem_ready;
	logic wb_valid,wb_ready;
	assign if_valid = 1'b1;
	assign wb_ready = 1'b1;

	logic rst_n_sync;
  	stl_rst u_stl_rst(
		.i_clk        		(clock     	),
		.i_rst_n      		(reset    	),
		.o_rst_n_sync 		(rst_n_sync )
  	);
  
  	logic [`CPU_WIDTH-1:0]  pc;
  	logic pc_wen, ifid_stall, ifid_bubble, idex_bubble, idu_ldstbp, exu_ldstbp;

  	logic [`CPU_WIDTH-1:0]  s_idu_diffpc,s_exu_diffpc,s_lsu_diffpc,s_wbu_diffpc;
	
  	logic [`CPU_WIDTH-1:0]  ifu_pc,ifu_pc_r;
  	logic [`INS_WIDTH-1:0]  ifu_ins,ifu_ins_r;

	assign ifu_pc = pc;

	ifu u_ifu(
		.i_clk	 			(clock		),
		.i_rst_n 			(rst_n_sync	),
		.i_pc    			(ifu_pc    	),
		.o_ins   			(ifu_ins   	)
	);

	pipe_if_id u_pipe_if_id(
		.i_clk        		(clock       ),
		.i_rst_n      		(rst_n_sync  ),
		.i_stall        	(ifid_stall    ),
		.i_bubble     		(ifid_bubble ),
		.i_ifu_ins    		(ifu_ins     ),
		.i_ifu_pc     		(ifu_pc      ),
		.if_valid_i   		(if_valid    ),
		.id_ready_i   		(id_ready    ),
		.if_ready_o   		(if_ready    ),
		.id_valid_o   		(id_valid    ),
		.o_idu_ins    		(ifu_ins_r   ),
		.o_idu_pc     		(ifu_pc_r    ),
		.s_idu_diffpc 		(s_idu_diffpc)
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
		.i_ins       		(ifu_ins_r   ),
		.o_rs1id     		(idu_rs1id   ),
		.o_rs2id     		(idu_rs2id   ),
		.o_rdid      		(idu_rdid    ),
		.o_rdwen     		(idu_rdwen   ),
		.o_imm       		(idu_imm     ),
		.o_src_sel   		(idu_src_sel ),
		.o_exopt     		(idu_exopt   ),
		.o_lsu_func3 		(idu_lsfunc3 ),
		.o_lsu_lden  		(idu_lden    ),
		.o_lsu_sten  		(idu_sten    ),
		.o_jal       		(idu_jal     ),
		.o_jalr      		(idu_jalr    ),
		.o_brch      		(idu_brch    ),
		.o_bfun3     		(idu_bfun3   )
	);

	assign idu_pc = ifu_pc_r;
	logic [`INS_WIDTH-1:0] idu_ins_r;
	pipe_id_ex u_pipe_id_ex(
		.i_clk         		(clock        ),
		.i_rst_n       		(rst_n_sync   ),
		.i_bubble      		(idex_bubble  ),
		.i_idu_imm     		(idu_imm      ),
		.i_idu_rs1     		(idu_rs1      ),
		.i_idu_rs2     		(idu_rs2      ),
		.i_idu_rdid    		(idu_rdid     ),
		.i_idu_rdwen   		(idu_rdwen    ),
		.i_idu_src_sel 		(idu_src_sel  ),
		.i_idu_exopt   		(idu_exopt    ),
		.i_idu_func3   		(idu_lsfunc3  ),
		.i_idu_lden    		(idu_lden     ),
		.i_idu_sten    		(idu_sten     ),
		.i_idu_ldstbp  		(idu_ldstbp   ),
		.i_idu_pc      		(idu_pc       ),
		.s_idu_diffpc  		(s_idu_diffpc ),
		.s_idu_diffins 		(ifu_ins_r	  ),
		.id_valid_i    		(id_valid     ),
		.exe_ready_i   		(alu_id_ready ),
		.id_ready_o    		(id_ready     ),
		.exe_valid_o   		(id_alu_valid ),
		.o_exu_imm     		(idu_imm_r    ),
		.o_exu_rs1     		(idu_rs1_r    ),
		.o_exu_rs2     		(idu_rs2_r    ),
		.o_exu_rdid    		(idu_rdid_r   ),
		.o_exu_rdwen   		(idu_rdwen_r  ),
		.o_exu_src_sel 		(idu_src_sel_r),
		.o_exu_exopt   		(idu_exopt_r  ),
		.o_exu_func3   		(idu_lsfunc3_r),
		.o_exu_lden    		(idu_lden_r   ),
		.o_exu_sten    		(idu_sten_r   ),
		.o_exu_ldstbp  		(exu_ldstbp   ),
		.o_exu_pc      		(idu_pc_r     ),
		.s_exu_diffpc  		(s_exu_diffpc ),
		.s_exu_diffins 		(idu_ins_r 	  )
	);

	logic [`CPU_WIDTH-1:0]      exu_exres,exu_exres_r;
	logic [`CPU_WIDTH-1:0]      exu_rs2,exu_rs2_bp,exu_rs2_r;
	logic [`REG_ADDRW-1:0]      exu_rdid,exu_rdid_r;
	logic                       exu_rdwen,exu_rdwen_r;
	logic [2:0]                 exu_lsfunc3,exu_lsfunc3_r;
	logic                       exu_lden,exu_lden_r;
	logic                       exu_sten,exu_sten_r;
	logic [`INS_WIDTH-1:0]	  exu_ins_r;
	logic   id_alu_valid, alu_id_ready, alu_mem_valid, mem_alu_ready;
	
	exu u_exu(
		.i_clk				(clock),
		.i_rst_n			(rst_n_sync),
		.i_pc      			(idu_pc_r      ),
		.i_rs1     			(idu_rs1_r     ),
		.i_rs2     			(idu_rs2_r     ),
		.i_imm     			(idu_imm_r     ),
		.i_src_sel 			(idu_src_sel_r ),
		.i_exopt   			(idu_exopt_r   ),
		.id_alu_valid       (id_alu_valid),
		.mem_alu_ready      (mem_alu_ready),
		.alu_id_ready       (alu_id_ready),
		.alu_mem_valid      (alu_mem_valid),
		.o_exu_res 			(exu_exres     )
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
		.i_exu_exres  		(exu_exres    	),
		.i_exu_rs2    		(exu_rs2_bp   	),
		.i_exu_rdid   		(exu_rdid     	),
		.i_exu_rdwen  		(exu_rdwen    	),
		.i_exu_func3  		(exu_lsfunc3  	),
		.i_exu_lden   		(exu_lden     	),
		.i_exu_sten   		(exu_sten     	),
		.s_exu_diffpc 		(s_exu_diffpc 	),
		.s_exu_diffins		(idu_ins_r		),
		.exe_valid_i  		(alu_mem_valid	),
		.mem_ready_i  		(mem_ready    	),
		.exe_ready_o  		(mem_alu_ready	),
		.mem_valid_o  		(mem_valid    	),
		.o_lsu_exres  		(exu_exres_r  	),
		.o_lsu_rs2    		(exu_rs2_r    	),
		.o_lsu_rdid   		(exu_rdid_r   	),
		.o_lsu_rdwen  		(exu_rdwen_r  	),
		.o_lsu_func3  		(exu_lsfunc3_r	),
		.o_lsu_lden   		(exu_lden_r   	),
		.o_lsu_sten   		(exu_sten_r   	),
		.s_lsu_diffpc 		(s_lsu_diffpc 	),
		.s_mem_diffins		(exu_ins_r 		)
	);

	logic [`CPU_WIDTH-1:0]      lsu_exres,lsu_exres_r;
	logic [`CPU_WIDTH-1:0]      lsu_lsres,lsu_lsres_r;
	logic                       lsu_lden, lsu_lden_r;
	logic [`REG_ADDRW-1:0]      lsu_rdid, lsu_rdid_r;
	logic                       lsu_rdwen,lsu_rdwen_r;
	logic [`INS_WIDTH-1:0]	  mem_ins_r;

	lsu u_lsu(
		.i_clk     			(clock         	),
		.i_lsfunc3 			(exu_lsfunc3_r 	),
		.i_lden    			(exu_lden_r    	),
		.i_sten    			(exu_sten_r    	),
		.i_addr    			(exu_exres_r   	),
		.i_regst   			(exu_rs2_r     	),
		.o_regld   			(lsu_lsres     	)
	);

	assign lsu_exres = exu_exres_r;
	assign lsu_lden  = exu_lden_r;
	assign lsu_rdid  = exu_rdid_r;
	assign lsu_rdwen = exu_rdwen_r;

	pipe_ls_wb u_pipe_ls_wb(
		.i_clk        		(clock        	),
		.i_rst_n      		(rst_n_sync   	),
		.i_lsu_exres  		(lsu_exres    	),
		.i_lsu_lsres  		(lsu_lsres    	),
		.i_lsu_rdid   		(lsu_rdid     	),
		.i_lsu_rdwen  		(lsu_rdwen    	),
		.i_lsu_lden   		(lsu_lden     	),
		.s_lsu_diffpc 		(s_lsu_diffpc 	),
		.s_mem_diffins		(exu_ins_r		),
		.mem_valid_i  		(mem_valid  	),
		.wb_ready_i   		(wb_ready   	),
		.mem_ready_o  		(mem_ready  	),
		.wb_valid_o   		(wb_valid   	),
		.o_wbu_exres  		(lsu_exres_r  	),
		.o_wbu_lsres  		(lsu_lsres_r  	),
		.o_wbu_rdid   		(lsu_rdid_r   	),
		.o_wbu_rdwen  		(lsu_rdwen_r  	),
		.o_wbu_lden   		(lsu_lden_r   	),
		.s_wbu_diffpc 		(s_wbu_diffpc  	),
		.s_wbu_diffins		(mem_ins_r		)
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
		.o_rd      			(wbu_rd      	)
	);

	bypass u_bypass(
		.i_clk         		(clock         	),
		.i_idu_rs1id   		(idu_rs1id     	),
		.i_idu_rs2id   		(idu_rs2id     	),
		.i_idu_sten    		(idu_sten      	),
		.i_exu_lden    		(exu_lden      	),
		.i_exu_rdwen   		(exu_rdwen     	),
		.i_exu_rdid    		(exu_rdid      	),
		.i_exu_exres   		(exu_exres     	),
		.i_lsu_lden    		(lsu_lden      	),
		.i_lsu_rdwen   		(lsu_rdwen     	),
		.i_lsu_rdid    		(lsu_rdid      	),
		.i_lsu_lsres   		(lsu_lsres     	),
		.i_lsu_exres   		(lsu_exres     	),   
		.i_wbu_rdwen   		(wbu_rdwen     	),
		.i_wbu_rdid    		(wbu_rdid      	),
		.i_wbu_rd      		(wbu_rd        	),
		.o_idu_rs1     		(idu_rs1       	),
		.o_idu_rs2     		(idu_rs2       	),
		.o_pc_wen      		(pc_wen        	),
		.o_ifid_stall    	(ifid_stall     ),
		.o_idex_bubble 		(idex_bubble   	),
		.i_exu_rs2     		(exu_rs2       	),
		.o_idu_ldstbp  		(idu_ldstbp    	),
		.i_exu_ldstbp  		(exu_ldstbp    	),
		.o_exu_rs2     		(exu_rs2_bp    	),
		.o_regs 	   		(regs		  	)
	);

	bru u_bru(
		.i_clk        		(clock       	),
		.i_rst_n      		(rst_n_sync  	),
		.i_pcwen      		(pc_wen      	),
		.i_jal        		(idu_jal     	),
		.i_jalr       		(idu_jalr    	),
		.i_brch       		(idu_brch    	),
		.i_bfun3      		(idu_bfun3   	),
		.i_rs1        		(idu_rs1     	),
		.i_rs2        		(idu_rs2     	),
		.i_imm        		(idu_imm     	),
		.i_prepc      		(idu_pc      	),
		.o_pc         		(pc          	),
		.o_ifid_bubble		(ifid_bubble 	)
	);

endmodule