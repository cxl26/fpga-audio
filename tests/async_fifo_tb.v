module async_fifo_tb;

    parameter ADDR_WIDTH = 3;
    parameter DATA_WIDTH = 12;

    logic fastclk;
    logic slowclk;

    wire wr_full;
    wire rd_empty;

    reg  [DATA_WIDTH-1:0] wr_data = 0;
    wire [DATA_WIDTH-1:0] rd_data;

    async_fifo #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) async_fifo_u1 (
        .rd_clk   (slowclk),
        .wr_clk   (fastclk),
        .wr_en    (!wr_full),
        .rd_en    (!rd_empty),
        .wr_data  (wr_data),
        .rd_data  (rd_data),
        .rd_empty (rd_empty),
        .wr_full  (wr_full)
    );
        
    always@(posedge fastclk) begin
        if (!wr_full) begin
        wr_data <= wr_data + 1;
        end
    end
        

    initial begin
        $dumpvars;
        fastclk = 0;
        slowclk = 0;
        #40000
        $finish;
    end
        
    always #5  fastclk = ~fastclk;
    always #23 slowclk = ~slowclk;

endmodule