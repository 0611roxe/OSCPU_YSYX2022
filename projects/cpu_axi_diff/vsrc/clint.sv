`include "config.sv"
module clint(
    input               clk         ,
    input               reset       ,
    input   [63:0]      wdata       ,
    input               mtimecmp_en ,
    input               mtime_en    ,
    output              mtime_int   ,
    output  [63:0]      mtime_data  ,
    output  [63:0]      mtimecmp_data
);

    reg [63:0] mtime;
    reg [63:0] mtimecmp;

    always @(posedge clk) begin
        if(reset) begin
            mtime <= 64'b0;
        end else begin
            if(mtime_en) begin
                mtime <= wdata;
            end else begin
                mtime <= mtime + 64'd1;
            end 
        end 
    end 

    always @(posedge clk) begin
        if(reset) begin
            mtimecmp <= 64'b0;
        end else if(mtimecmp_en) begin
            mtimecmp <= wdata;
        end 
    end 

    assign mtime_int = (mtime >= mtimecmp);
    assign mtime_data = mtime;
    assign mtimecmp_data = mtimecmp;
    
endmodule