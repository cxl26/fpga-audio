module sync_fifo_tb;

    parameter ADDR_WIDTH = 3;
    parameter DATA_WIDTH = 12;

    logic clk;

    wire full;
    wire empty;

    reg rd_en = 0;

    reg  [DATA_WIDTH-1:0] wr_data = 0;
    wire [DATA_WIDTH-1:0] rd_data;

    sync_fifo #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) sync_fifo_u1 (
        .clk        (clk),
        .wr_en      (!full),
        .rd_en      (rd_en),
        .wr_data    (wr_data),
        .rd_data    (rd_data),
        .empty      (empty),
        .full       (full),
        .almost_full()
    );
        
    always@(posedge clk) begin
        if (!full) begin
            wr_data <= wr_data + 1;
        end
    end

    initial begin
        $dumpvars;
        clk = 0;
        #40000
        $finish;
    end
        
    always #5  clk = ~clk;
    always #50  rd_en = ~rd_en;

endmodule