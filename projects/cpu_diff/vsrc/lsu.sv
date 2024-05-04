`include "config.sv"
module lsu (
	input                               i_clk   ,
	input         [2:0]                 i_lsfunc3,
	input                               i_lden  ,
	input                               i_sten  ,
	input         [`CPU_WIDTH-1:0]      i_addr  ,   // mem i_addr. from exu result.
	input         [`CPU_WIDTH-1:0]      i_regst ,   // for st.
	output  logic [`CPU_WIDTH-1:0]      o_regld     // for ld.
);

	logic ren;
	logic [63:0] wmask;
	logic [`CPU_WIDTH-1:0] raddr,rdata,waddr,wdata;
	logic [2:0] shift;

	assign shift = i_addr[2:0];
	always @(*) begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
		if(i_lden)  begin
			case (i_lsfunc3)
				`FUNC3_LB_SB: begin
					case (shift)
						3'b000	: o_regld = {{56{rdata[7]}},rdata[7:0]};
						3'b001	: o_regld = {{56{rdata[15]}},rdata[15:8]};
						3'b010	: o_regld = {{56{rdata[23]}},rdata[23:16]};
						3'b011	: o_regld = {{56{rdata[31]}},rdata[31:24]};
						3'b100	: o_regld = {{56{rdata[39]}},rdata[39:32]};
						3'b101	: o_regld = {{56{rdata[47]}},rdata[47:40]};
						3'b110	: o_regld = {{56{rdata[55]}},rdata[55:48]};
						3'b111	: o_regld = {{56{rdata[63]}},rdata[63:56]};
						default	: o_regld = 64'h0;
					endcase	
				end 
				`FUNC3_LH_SH: begin
					case (shift)
						3'b000	: o_regld = {{48{rdata[15]}},rdata[15:0]};
						3'b010	: o_regld = {{48{rdata[31]}},rdata[31:16]};
						3'b100	: o_regld = {{48{rdata[47]}},rdata[47:32]};
						3'b110	: o_regld = {{48{rdata[63]}},rdata[63:48]};
						default : o_regld = 64'h0;
					endcase
				end
				`FUNC3_LW_SW: begin
					case (shift) 
						3'b000	: o_regld = {{32{rdata[31]}},rdata[31:0]};
						3'b100	: o_regld = {{32{rdata[63]}},rdata[63:32]};
						default : o_regld = 64'h0;
					endcase	
				end
				`FUNC3_LD_SD: begin
					o_regld = rdata;
				end
				default: o_regld = 64'h0;
				`FUNC3_LBU: begin
					case (shift)
						3'b000	: 	o_regld = {56'h0,rdata[7:0]};
						3'b001	:	o_regld = {56'h0,rdata[15:8]};
						3'b010	:	o_regld = {56'h0,rdata[23:16]};
						3'b011	:	o_regld = {56'h0,rdata[31:24]};
						3'b100	:	o_regld = {56'h0,rdata[39:32]};
						3'b101	:	o_regld = {56'h0,rdata[47:40]};
						3'b110	:	o_regld = {56'h0,rdata[55:48]};
						3'b111	:	o_regld = {56'h0,rdata[63:56]};
						default	:	o_regld = 64'h0;
					endcase
				end
				`FUNC3_LHU: begin
					case (shift)
						3'b000	: 	o_regld = {48'h0,rdata[15:0]};
						3'b010	: 	o_regld = {48'h0,rdata[31:16]};
						3'b100	: 	o_regld = {48'h0,rdata[47:32]};
						3'b110	: 	o_regld = {48'h0,rdata[63:48]};
						default : 	o_regld = 64'h0;
					endcase
				end
				`FUNC3_LWU: begin
					case (shift)
						3'b000	: 	o_regld = {32'h0,rdata[31:0]};
						3'b100	: 	o_regld = {32'h0,rdata[63:32]};
						default : 	o_regld = 64'h0;
					endcase
				end
			endcase	
		end	
	end	

	always @(*) begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
		if(i_sten)  begin
			case (i_lsfunc3)
				`FUNC3_LB_SB: begin
					wdata = {8{i_regst[7:0]}};
					case (shift)
						3'b000	: 	wmask = {56'h0,8'hff};
						3'b001	: 	wmask = {48'h0,8'hff,8'h0};
						3'b010	: 	wmask = {40'h0,8'hff,16'h0};
						3'b011	: 	wmask = {32'h0,8'hff,24'h0};
						3'b100	: 	wmask = {24'h0,8'hff,32'h0};
						3'b101	: 	wmask = {16'h0,8'hff,40'h0};
						3'b110	: 	wmask = {8'h0,8'hff,48'h0};
						3'b111	: 	wmask = {8'hff,56'h0};
						default	: 	wmask = 64'h0;
					endcase	
				end 
				`FUNC3_LH_SH: begin
					wdata = {4{i_regst[15:0]}};
					case (shift)
						3'b000	:	wmask = {48'h0,16'hffff};
						3'b010	: 	wmask = {32'h0,16'hffff,16'h0};
						3'b100	: 	wmask = {16'h0,16'hffff,32'h0};
						3'b110	: 	wmask = {16'hffff,48'h0};
						default : 	wmask = 64'h0;
					endcase
				end
				`FUNC3_LW_SW: begin
					wdata = {2{i_regst[31:0]}};
					case (shift) 
						3'b000	: 	wmask = {32'h0,32'hffff_ffff};
						3'b100	: 	wmask = {32'hffff_ffff,32'h0};
						default : 	wmask = 64'h0;
					endcase	
				end
				`FUNC3_LD_SD: begin
					wdata = i_regst;
					wmask = 64'hffff_ffff_ffff_ffff;
				end
				default: wmask = 64'h0;
			endcase	
		end	
	end	


	assign raddr = i_addr;
	assign waddr = i_addr;

	RAMHelper Memory(
		.clk              (i_clk),
		.en               (i_lden || i_sten),
		.rIdx             ((raddr-`PC_START) >> 3),
		.rdata            (rdata),
		.wIdx             ((waddr-`PC_START) >> 3),
		.wdata            (wdata),
		.wmask            (wmask),
		.wen              (i_sten)
	);

endmodule
