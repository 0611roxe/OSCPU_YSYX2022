`include "config.sv"
module lsu (
	input                               i_clk   	,
	input								i_rst_n 	,
	input         [2:0]                 i_lsfunc3	,
	input                               i_lden  	,
	input                               i_sten  	,	

	input								ex_mem_valid,
	output								mem_ex_ready,
	output								axi_mem_valid,
	input								axi_mem_ready,
	input								wb_mem_ready,
	output								mem_wb_valid,

	input         [`CPU_WIDTH-1:0]      i_addr  	,	
	input         [`CPU_WIDTH-1:0]      i_wt_data	,
	input		  [`CPU_WIDTH-1:0]		mem_rdata	,
	input	[1:0]						mem_resp	,
	output	logic [`CPU_WIDTH-1:0]		mem_addr	,
	output	logic [1:0]					mem_size	,
	output  logic [`CPU_WIDTH-1:0]		mem_wdata	,
	output  logic [`CPU_WIDTH-1:0]      o_ld_data	,
	output	logic [7:0]					wmask		,

	input	[`CPU_WIDTH-1:0]			mtime_data	,
	input	[`CPU_WIDTH-1:0]			mtimecmp_data,
	output								mtime_en	,
	output								mtimecmp_en	,
	output	[`CPU_WIDTH-1:0]			time_wdata		
);

	assign time_wdata = i_wt_data;
	assign mtime_en = (i_sten && i_addr == 64'h00000000_0200bff8) ? 1'b1 : 1'b0;
	assign mtimecmp_en = (i_sten && i_addr == 64'h00000000_02004000) ? 1'b1 : 1'b0;

	wire [63:0] mem_choose_data;
	assign mem_choose_data = (i_addr == 64'h00000000_0200bff8) ? mtime_data : (i_addr == 64'h00000000_02004000) ? mtimecmp_data : mem_rdata; 

	wire visit_axi = i_lden | i_sten;
	wire axi_handshake = axi_mem_valid & axi_mem_ready;
	assign mem_wb_valid = visit_axi ? axi_handshake : ex_mem_valid;
	assign axi_mem_valid = ex_mem_valid & visit_axi;
	assign mem_ex_ready = mem_wb_valid & wb_mem_ready;

	assign mem_addr  = i_addr;
	assign mem_size  = 	(i_lsfunc3 == `FUNC3_LB_SB) ? `SIZE_B :
						(i_lsfunc3 == `FUNC3_LH_SH) ? `SIZE_H :
						(i_lsfunc3 == `FUNC3_LW_SW) ? `SIZE_W :
						(i_lsfunc3 == `FUNC3_LD_SD) ? `SIZE_D : 
						(i_lsfunc3 == `FUNC3_LWU  ) ? `SIZE_W :
						(i_lsfunc3 == `FUNC3_LHU  ) ? `SIZE_H :
						(i_lsfunc3 == `FUNC3_LBU  ) ? `SIZE_B : 2'b0;

	always @(*) begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
		if(i_lden)  begin
			case (i_lsfunc3)
				`FUNC3_LB_SB: begin
					o_ld_data = {{56{mem_choose_data[7]}},mem_choose_data[7:0]};
				end 
				`FUNC3_LH_SH: begin
					o_ld_data = {{48{mem_choose_data[15]}},mem_choose_data[15:0]};
				end
				`FUNC3_LW_SW: begin 
					o_ld_data = {{32{mem_choose_data[31]}},mem_choose_data[31:0]};
				end
				`FUNC3_LD_SD: begin
					o_ld_data = mem_choose_data;
				end
				`FUNC3_LBU: begin
					o_ld_data = {56'h0,mem_choose_data[7:0]};
				end
				`FUNC3_LHU: begin
					o_ld_data = {48'h0,mem_choose_data[15:0]};
				end
				`FUNC3_LWU: begin
					o_ld_data = {32'h0,mem_choose_data[31:0]};
				end
				default : begin
					o_ld_data = 'b0;
				end	
			endcase	
		end	else begin
			o_ld_data = 'b0;
		end
	end	

	wire [2:0] shift = i_addr[2:0];

	always @(*) begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
		if(i_sten)  begin
			case (i_lsfunc3)
				`FUNC3_LB_SB: begin
					case (shift)
						3'b000 	:	begin mem_wdata = {56'h0,i_wt_data[7:0]};		wmask = 8'b0000_0001;	end
						3'b001	: 	begin mem_wdata = {48'h0,i_wt_data[7:0],8'h0};	wmask = 8'b0000_0010;	end
						3'b010	: 	begin mem_wdata = {40'h0,i_wt_data[7:0],16'h0};	wmask = 8'b0000_0100;	end
						3'b011	: 	begin mem_wdata = {32'h0,i_wt_data[7:0],24'h0};	wmask = 8'b0000_1000;	end
						3'b100	: 	begin mem_wdata = {24'h0,i_wt_data[7:0],32'h0};	wmask = 8'b0001_0000;	end
						3'b101	: 	begin mem_wdata = {16'h0,i_wt_data[7:0],40'h0};	wmask = 8'b0010_0000;	end
						3'b110	: 	begin mem_wdata = {8'h0,i_wt_data[7:0],48'h0};	wmask = 8'b0100_0000;	end
						3'b111	: 	begin mem_wdata = {i_wt_data[7:0],56'h0};		wmask = 8'b1000_0000;	end
						default	: 	begin mem_wdata = 64'h0;						wmask = 8'b0;			end
					endcase	
				end 
				`FUNC3_LH_SH: begin
					case (shift)
						3'b000	:	begin mem_wdata = {48'h0,i_wt_data[15:0]};		 wmask = 8'b0000_0011;	end
						3'b010	: 	begin mem_wdata = {32'h0,i_wt_data[15:0],16'h0}; wmask = 8'b0000_1100;	end	
						3'b100	: 	begin mem_wdata = {16'h0,i_wt_data[15:0],32'h0}; wmask = 8'b0011_0000;	end	
						3'b110	: 	begin mem_wdata = {i_wt_data[15:0],48'h0};		 wmask = 8'b1100_0000;	end
						default : 	begin mem_wdata = 64'h0;						 wmask = 8'b0;			end
					endcase
				end
				`FUNC3_LW_SW: begin
					case (shift) 
						3'b000 	:	begin mem_wdata = {32'h0,i_wt_data[31:0]};		wmask = 8'b0000_1111;	end
						3'b100	: 	begin mem_wdata = {i_wt_data[31:0],32'h0};		wmask = 8'b1111_0000;	end
						default : 	begin mem_wdata = 64'h0;		  				wmask = 8'b0;			end
					endcase	
				end
				`FUNC3_LD_SD: begin
					mem_wdata = i_wt_data;
					wmask = 8'b1111_1111;
				end
				default: begin
					mem_wdata = 64'h0;
					wmask = 8'b0;
				end
			endcase	
		end	
	end	

endmodule
