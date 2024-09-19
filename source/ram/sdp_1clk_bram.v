module sdp_1clk_bram #(
    parameter ADDR_WIDTH=8,
    parameter DATA_WIDTH=12
)(
    input  wire                  clk,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output reg  [DATA_WIDTH-1:0] rd_data
);
    localparam RAM_DEPTH = 2**ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] ram [RAM_DEPTH-1:0];

    always@(posedge clk) begin
        rd_data <= ram[rd_addr];
        if (wr_en) ram[wr_addr] <= wr_data;
    end

endmodule