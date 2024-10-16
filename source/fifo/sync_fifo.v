module sync_fifo #(
    parameter ADDR_WIDTH = 3,
    parameter DATA_WIDTH = 24
)(
    input  wire clk,
    input  wire wr_en,
    input  wire rd_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire  empty,
    output wire  full,
    output wire  almost_full
);

    reg                   rd_wrap = 0;
    reg                   wr_wrap = 0;
    reg  [ADDR_WIDTH-1:0] rd_ptr  = 0;
    reg  [ADDR_WIDTH-1:0] wr_ptr  = 0;

    assign empty = (rd_wrap == wr_wrap) && (rd_ptr == wr_ptr); // wraps equal, ptrs equal
    assign full  = (rd_wrap != wr_wrap) && (rd_ptr == wr_ptr); // wraps not equal, ptrs equal

    assign almost_full = (rd_wrap != wr_wrap) && (rd_ptr == wr_ptr-1);

    always@(posedge clk) begin
        {rd_wrap, rd_ptr} <= {rd_wrap, rd_ptr} + (rd_en && !empty);
        {wr_wrap, wr_ptr} <= {wr_wrap, wr_ptr} + (wr_en && !full);
    end

    sdp_1clk_bram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) sdp_1clk_bram_u1 (
        .clk    (clk),
        .rd_addr(rd_ptr),
        .wr_addr(wr_ptr),
        .wr_en  (wr_en && !full),
        .wr_data(wr_data),
        .rd_data(rd_data)
    );

endmodule