`include "config.sv"
module idu(
	input        [`INS_WIDTH-1:0]    	i_ins      	,
	input		 [`CPU_WIDTH-1:0]		rf_rs1		,
	output logic [`REG_ADDRW-1:0]    	o_rs1id    	, 
	output logic [`REG_ADDRW-1:0]    	o_rs2id    	, 
	output logic [`REG_ADDRW-1:0]    	o_rdid     	, 
	output logic                     	o_rdwen    	, 
	output logic [`CPU_WIDTH-1:0]    	o_imm      	, 
	output logic [`EXU_SEL_WIDTH-1:0]	o_src_sel  	, 
	output logic [`EXU_OPT_WIDTH-1:0]	o_exopt    	, 
	output logic [2:0]               	o_lsu_func3	, 
	output logic                     	o_lsu_lden 	, 
	output logic                     	o_lsu_sten 	,   
	output logic                     	o_jal      	, 
	output logic                     	o_jalr     	, 
	output logic                     	o_brch     	, 
	output logic [2:0]               	o_bfun3    	,
	output wire							except_en	,
	output wire	 [`CPU_WIDTH-1:0]		except_code	,
	output wire	 [11:0]					csr			,
	output wire							ins_mret	,
	output logic [`CPU_WIDTH-1:0]		csr_wdata	,
	output wire  [2:0]					csr_choose	
);

	wire [6:0] func7  = i_ins[31:25];
	wire [4:0] rs2id  = i_ins[24:20];
	wire [4:0] rs1id  = i_ins[19:15];
	wire [2:0] func3  = i_ins[14:12];
	wire [4:0] rdid   = i_ins[11: 7];
	wire [6:0] opcode = i_ins[ 6: 0];
	assign csr = i_ins[31:20];

	always@(*)begin
		o_imm   = `CPU_WIDTH'b0;
		o_rs1id = `REG_ADDRW'b0;
		o_rs2id = `REG_ADDRW'b0;
		o_rdid  = `REG_ADDRW'b0;
		o_rdwen = 1'b0;
		case(opcode) 
			`TYPE_R:        begin o_rs2id = rs2id;  o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = `CPU_WIDTH'b0;                                              end
			`TYPE_R_W:      begin o_rs2id = rs2id;  o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = `CPU_WIDTH'b0;                                              end
			`TYPE_S:        begin o_rs2id = rs2id;  o_rs1id = rs1id;                                  o_imm = {{52{i_ins[31]}},i_ins[31:25],i_ins[11:7]};                 end
			`TYPE_B:        begin o_rs2id = rs2id;  o_rs1id = rs1id;                                  o_imm = {{52{i_ins[31]}},i_ins[7],i_ins[30:25],i_ins[11:8],1'b0};   end
			`TYPE_I:        begin                   o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
			`TYPE_I_W:      begin                   o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
			`TYPE_I_LOAD:   begin                   o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
			`TYPE_I_JALR:   begin                   o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
			`TYPE_CSR:   	begin                   o_rs1id = rs1id;  o_rdid = rdid;                  o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
			`TYPE_U_LUI:    begin                   o_rs1id = 0  ;    o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{32{i_ins[31]}},i_ins[31:12],12'b0};                       end //LUI: rdid = x0 + imm;
			`TYPE_U_AUIPC:  begin                                     o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{32{i_ins[31]}},i_ins[31:12],12'b0};                       end
			`TYPE_J:        begin                                     o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{44{i_ins[31]}},i_ins[19:12],i_ins[20],i_ins[30:21],1'b0}; end
			default: ;
		endcase
		if(o_rdid  == `REG_ADDRW'b0) o_rdwen = 1'b0; 
	end

	always @(*) begin
		o_exopt     = `EXU_ADD;
		o_src_sel = `EXU_SEL_IMM;
		case (opcode)
			`TYPE_S:        begin o_exopt = `EXU_ADD;  o_src_sel = `EXU_SEL_IMM; end 
			`TYPE_CSR:
				begin
					case (func3)
						`FUNC3_CSRRW:		begin o_src_sel = `EXU_SEL_REG; o_exopt = `EXU_CSRRW;	end
						`FUNC3_CSRRS:		begin o_src_sel = `EXU_SEL_REG; o_exopt = `EXU_OR; 		end
						`FUNC3_CSRRC:		begin o_src_sel = `EXU_SEL_REG; o_exopt = `EXU_AND; 	end
						`FUNC3_CSRRWI:		begin o_src_sel = `EXU_SEL_IMM; o_exopt = `EXU_CSRRW;	end
						`FUNC3_CSRRSI:		begin o_src_sel = `EXU_SEL_IMM; o_exopt = `EXU_OR; 		end
						`FUNC3_CSRRCI:		begin o_src_sel = `EXU_SEL_IMM; o_exopt = `EXU_AND; 	end
						default :;
					endcase
			    end 
			`TYPE_I_LOAD:   begin o_exopt = `EXU_ADD;  o_src_sel = `EXU_SEL_IMM; end 
			`TYPE_I_JALR:   begin o_exopt = `EXU_ADD;  o_src_sel = `EXU_SEL_PC4; end
			`TYPE_J:        begin o_exopt = `EXU_ADD;  o_src_sel = `EXU_SEL_PC4; end 
			`TYPE_U_LUI:    begin o_exopt = `EXU_ADD;  o_src_sel = `EXU_SEL_IMM; end 
			`TYPE_U_AUIPC:  begin o_exopt = `EXU_ADD;  o_src_sel = `EXU_SEL_PCI; end 
			`TYPE_B:        begin                                                end 
			`TYPE_I:
				begin
					o_src_sel = `EXU_SEL_IMM;
					case (func3)
						`FUNC3_ADD_SUB_MUL:   o_exopt = `EXU_ADD; 
						`FUNC3_SLL_MULH:      o_exopt = `EXU_SLL;
						`FUNC3_SRL_SRA_DIVU:  case (func7[6:1]) 6'b000000: o_exopt = `EXU_SRL; 6'b010000:o_exopt = `EXU_SRA; default:; endcase
						`FUNC3_XOR_DIV:       o_exopt = `EXU_XOR;
						`FUNC3_OR_REM:        o_exopt = `EXU_OR ;
						`FUNC3_AND_REMU:      o_exopt = `EXU_AND;
						`FUNC3_SLT_MULHSU:    o_exopt = `EXU_SLT;
						`FUNC3_SLTU_MULHU:    o_exopt = `EXU_SLTU;
						default:;
					endcase
				end
			`TYPE_I_W:
				begin
					o_src_sel = `EXU_SEL_IMM;
					case (func3)
						`FUNC3_ADD_SUB_MUL:   o_exopt = `EXU_ADDW;
						`FUNC3_SLL_MULH:      o_exopt = `EXU_SLLW;
						`FUNC3_SRL_SRA_DIVU:  case (func7) 7'b0000000:o_exopt = `EXU_SRLW; 7'b0100000: o_exopt = `EXU_SRAW;  default:; endcase
						default:;
					endcase
				end
			`TYPE_R:
				begin
					o_src_sel = `EXU_SEL_REG;
					case (func3)
						`FUNC3_ADD_SUB_MUL:  case (func7) 7'b0000000:o_exopt = `EXU_ADD ; 7'b0000001: o_exopt = `EXU_MUL   ; 7'b0100000: o_exopt = `EXU_SUB; default:; endcase
						`FUNC3_SRL_SRA_DIVU: case (func7) 7'b0000000:o_exopt = `EXU_SRL ; 7'b0000001: o_exopt = `EXU_DIVU  ; 7'b0100000: o_exopt = `EXU_SRA; default:; endcase
						`FUNC3_SLL_MULH:     case (func7) 7'b0000000:o_exopt = `EXU_SLL ; 7'b0000001: o_exopt = `EXU_MULH  ; default:; endcase
						`FUNC3_XOR_DIV:      case (func7) 7'b0000000:o_exopt = `EXU_XOR ; 7'b0000001: o_exopt = `EXU_DIV   ; default:; endcase
						`FUNC3_OR_REM:       case (func7) 7'b0000000:o_exopt = `EXU_OR  ; 7'b0000001: o_exopt = `EXU_REM   ; default:; endcase
						`FUNC3_AND_REMU:     case (func7) 7'b0000000:o_exopt = `EXU_AND ; 7'b0000001: o_exopt = `EXU_REMU  ; default:; endcase
						`FUNC3_SLT_MULHSU:   case (func7) 7'b0000000:o_exopt = `EXU_SLT ; 7'b0000001: o_exopt = `EXU_MULHSU; default:; endcase
						`FUNC3_SLTU_MULHU:   case (func7) 7'b0000000:o_exopt = `EXU_SLTU; 7'b0000001: o_exopt = `EXU_MULHU ; default:; endcase
						default:;
					endcase
				end
			`TYPE_R_W:
				begin
					o_src_sel = `EXU_SEL_REG;
					case (func3)
						`FUNC3_ADD_SUB_MUL:   case (func7) 7'b0000000:o_exopt = `EXU_ADDW; 7'b0100000: o_exopt = `EXU_SUBW; 7'b0000001: o_exopt = `EXU_MULW ; default:; endcase
						`FUNC3_SRL_SRA_DIVU:  case (func7) 7'b0000000:o_exopt = `EXU_SRLW; 7'b0100000: o_exopt = `EXU_SRAW; 7'b0000001: o_exopt = `EXU_DIVUW; default:; endcase
						`FUNC3_XOR_DIV:       o_exopt  = `EXU_DIVW;
						`FUNC3_OR_REM:        o_exopt  = `EXU_REMW;
						`FUNC3_AND_REMU:      o_exopt  = `EXU_REMUW;
						`FUNC3_SLL_MULH:      o_exopt  = `EXU_SLLW;
						default:;
					endcase
				end
			default:; 
		endcase
	end

	wire is_ecall = (opcode == `TYPE_CSR) && (csr == `ECALL_IMM);
	wire is_mret = (opcode == `TYPE_CSR) && (csr == `MRET_IMM);
	wire id_ebreak = (opcode == `TYPE_CSR) && (csr == `EBREAK_IMM);

	assign except_en = is_ecall;
	assign except_code = is_ecall ? {1'b0,63'd11} : 64'b0;
	assign ins_mret = is_mret;

	wire csrr_i = (opcode == `TYPE_CSR) && (func3 == `FUNC3_CSRRWI || func3 == `FUNC3_CSRRSI || func3 == `FUNC3_CSRRCI);
	assign csr_wdata = csrr_i ? {59'b0,o_rs1id} : rf_rs1;

	wire csrrw = (opcode == `TYPE_CSR) && (func3 ==`FUNC3_CSRRW);
	wire csrrwi = (opcode == `TYPE_CSR) && (func3 ==`FUNC3_CSRRWI);
	wire csrrs = (opcode == `TYPE_CSR) && (func3 ==`FUNC3_CSRRS);
	wire csrrsi = (opcode == `TYPE_CSR) && (func3 ==`FUNC3_CSRRSI);
	wire csrrc = (opcode == `TYPE_CSR) && (func3 ==`FUNC3_CSRRC);
	wire csrrci = (opcode == `TYPE_CSR) && (func3 ==`FUNC3_CSRRCI);
	assign csr_choose = {(csrrw | csrrwi), (csrrs | csrrsi), (csrrc | csrrci)};

	assign o_lsu_func3 = func3;
	assign o_lsu_lden = (opcode == `TYPE_I_LOAD) ? 1'b1 : 1'b0;
	assign o_lsu_sten = (opcode == `TYPE_S)      ? 1'b1 : 1'b0;

	assign o_jal  = (opcode == `TYPE_J)? 1:0;
	assign o_jalr = (opcode == `TYPE_I_JALR)? 1:0;
	assign o_brch = (opcode == `TYPE_B)? 1:0;
	assign o_bfun3 = func3;

endmodule
