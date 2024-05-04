`include "config.sv"
module csr (
	input           				clk			,
	input           				reset		,
	input [`CPU_WIDTH-1:0]			csr_wdata	,
	input [11:0]					csr_r		,
	input [11:0]					csr_w		,
	input 							csr_wen		,
	input							except_en	,
	input [`CPU_WIDTH-1:0]			csr_exaddr	,
	input [`CPU_WIDTH-1:0]			csr_wbaddr	,
	input [`CPU_WIDTH-1:0]			except_code	,
	input							mret		,
	input							mtime_int	,
	input							wb_valid	,
	input							wb_ready	,
	input [`CPU_WIDTH-1:0]			wb_ins		,
	
	output	logic					flush		,
	output	logic [`CPU_WIDTH-1:0] 	csr_data	,
	output	[`CPU_WIDTH-1:0]		mtvec_pc	,
	output	[`CPU_WIDTH-1:0]		epc			,
	output							time_int	,
	output							ecall		,
	output	logic					keep		,
	output 	reg [`CPU_WIDTH-1:0] 	mstatus		,
	output 	reg [`CPU_WIDTH-1:0] 	sstatus		,
	output 	reg [`CPU_WIDTH-1:0] 	mie			,
	output 	reg [`CPU_WIDTH-1:0] 	mtvec		,
	output 	reg [`CPU_WIDTH-1:0] 	mepc		,
	output 	reg [`CPU_WIDTH-1:0] 	mcause		,
	output 	reg [`CPU_WIDTH-1:0] 	mip			,
	output 	reg [`CPU_WIDTH-1:0] 	mscratch	,
	output	reg [`CPU_WIDTH-1:0] 	mstatus_diff,
	output	reg [`CPU_WIDTH-1:0] 	sstatus_diff,
	output	reg [`CPU_WIDTH-1:0] 	mie_diff	,	
	output	reg [`CPU_WIDTH-1:0] 	mtvec_diff	,	
	output	reg [`CPU_WIDTH-1:0] 	mepc_diff	,	
	output	reg [`CPU_WIDTH-1:0] 	mcause_diff	,	
	output	reg [`CPU_WIDTH-1:0] 	mip_diff	,	
	output	reg [`CPU_WIDTH-1:0] 	mscratch_diff
);

	assign ecall = wb_ready && except_en;
	wire interrupt_en = wb_ready && (mie[7] == 1'b1) & (wb_ins != 'b0);
	assign time_int = mtime_int & mstatus[3] & mie[7] & (wb_ins != 'b0);

	always @(*) begin
		if(ecall) begin
			flush = 1'b1;
		end else if(interrupt_en && time_int) begin
			flush = 1'b1;
		end else if(mret) begin
			flush = 1'b1;
		end	else begin
			flush= 1'b0;
		end	
	end	

	always @(posedge clk) begin
		if(flush) begin
			keep <= 1'b1;
		end	else if (keep == 1'b1 && wb_ready) begin
			keep <= 1'b0;
		end  
	end		

	always @(posedge clk) begin
		if(reset) begin
			mstatus <= {51'b0,2'b11,3'b0,1'b0,3'b0,1'b1,3'b0};
		end	else if(mstatus[3] == 1'b1 && (except_en || mtime_int && interrupt_en)) begin
			mstatus <= {mstatus[63:13],2'b11,3'b0,mstatus[3],3'b0,1'b0,3'b0};
		end else if(csr_wen && csr_w == 12'h300 && !time_int && wb_ready) begin
			mstatus <= {csr_wdata[16:15] == 2'b11 || csr_wdata[14:13] == 2'b11,csr_wdata[62:0]};
		end	else if(mret) begin
			mstatus <= {mstatus[63:13],2'b00,3'b0,1'b1,3'b0,mstatus[7],3'b0};
		end	
	end

	always @(*) begin
		if(reset) begin
			sstatus = 'b0;
		end	else if(mstatus_diff[63] == 1'b1) begin
			sstatus = {mstatus_diff[63],46'b0,mstatus_diff[16:13],13'b0};
		end	else if(mstatus_diff[63] == 1'b0) begin
			sstatus = 'b0;
		end	else begin
			sstatus = 'b0;
		end	
	end	

	always @(posedge clk) begin
		if(reset) begin
			mtvec <= 64'd0;
		end else if(csr_wen && csr_w== 12'h305) begin
			mtvec <= csr_wdata;
		end
	end	

	always @(posedge clk) begin
		if(reset) begin
			mepc <= 64'b0;
		end	else if(mtime_int && mstatus[3] == 1'b1 && interrupt_en) begin
			mepc <= {csr_wbaddr[63:2],2'b0};
		end	else if(except_en) begin
			mepc <= {csr_exaddr[63:2],2'b0};
		end	else if(csr_wen && csr_w == 12'h341) begin
			mepc <= csr_wdata;
		end	
	end	

	always @(posedge clk) begin
		if(reset) begin
			mcause <= 64'b0;
		end	else if(mtime_int && mstatus[3] == 1'b1 && interrupt_en) begin
			mcause <= {1'b1,63'd7};
		end else if(except_en) begin
			mcause <= except_code;
		end	else if(csr_wen && csr_w == 12'h342) begin
			mcause <= csr_wdata;
		end	
	end	

	always @(posedge clk) begin
		if(reset) begin
			mie <= 64'b0;
		end	else if(csr_wen && csr_w == 12'h304 && wb_ready) begin
			mie <= csr_wdata;
		end	
	end	

	always @(posedge clk) begin
		if(reset) begin
			mip <= 64'b0;
		end else if(csr_wen && csr_w == 12'h344) begin
			mip <= csr_wdata;
		end	else begin
			mip[11] <= 1'b0;
		end	
	end	

	always @(posedge clk) begin
		if(reset) begin
			mscratch <= 64'b0;
		end else if(csr_wen && csr_w == 12'h340) begin
			mscratch <= csr_wdata;
		end
	end	

	always @(*) begin
		case (csr_r)
			12'h300	: csr_data = mstatus;
			12'h304	: csr_data = mie;
			12'h305 : csr_data = mtvec;
			12'h341 : csr_data = mepc;
			12'h342 : csr_data = mcause;
			12'h344 : csr_data = mip;
			default : csr_data = 64'b0;
		endcase	
	end	

	wire mstatus_en = csr_wen && csr_w == 12'h300 && !time_int && wb_ready;
	wire int_change = mstatus[3] == 1'b1 && (except_en || mtime_int && interrupt_en);
	assign mip_diff = (csr_wen && csr_w == 12'h344) ? csr_wdata : mip;
	assign mie_diff = (csr_wen && csr_w == 12'h304) ? csr_wdata : mie;
	assign mscratch_diff = (csr_wen && csr_w == 12'h340) ? csr_wdata : mscratch;
	assign mcause_diff = except_en ? except_code : ((csr_wen && csr_w == 12'h342) ? csr_wdata : ((mtime_int && mstatus[3] == 1'b1 && interrupt_en) ? {1'b1,63'd7} : mcause));
	assign mepc_diff = except_en ? {csr_exaddr[63:2],2'b0} : ((csr_wen && csr_w == 12'h341) ? csr_wdata : ((mtime_int && mstatus[3] == 1'b1 && interrupt_en) ? {csr_wbaddr[63:2],2'b0} : mepc));
	assign mtvec_diff = (csr_wen && csr_w == 12'h305) ? csr_wdata : mtvec;
	assign mstatus_diff = 	(mstatus_en) ? {csr_wdata[16:15] == 2'b11 || csr_wdata[14:13] == 2'b11,csr_wdata[62:0]} : 
							(int_change) ? {mstatus[63:13],2'b11,3'b0,mstatus[3],3'b0,1'b0,3'b0} : 
							(mret ? {mstatus[63:13],2'b00,3'b0,1'b1,3'b0,mstatus[7],3'b0} : mstatus);
	assign sstatus_diff = (mstatus_diff[63] == 1'b1) ? {mstatus_diff[63],46'b0,mstatus_diff[16:13],13'b0} : sstatus;

	assign mtvec_pc = mtvec[1:0] == 2'b00 ? {mtvec[63:2],2'b00} : (mcause[63] == 1'b0 ? ({mtvec[63:2],2'b00} + mcause[62:0] >> 2) : (mcause[63] == 1'b1 ? {mtvec[63:2],2'b00} : 64'b0)) ;
	assign epc = mepc;

endmodule