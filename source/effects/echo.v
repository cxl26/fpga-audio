module echo #(
    parameter DATA_WDTH = 24,
    parameter ADDR_WDTH = 5,
    parameter CNTR_WDTH = 4
) (
    input  wire                           clk,
    input  wire                           48khz_strobe,
    input  wire signed [DATA_WDTH-1:0]    sine_in,
    input  reg  signed [DATA_WDTH-1:0]    sine_out
);

    reg signed [DATA_WDTH-1:0] sine_delayed_value;
    reg                        sine_delayed_valid;

    wire almost_full;

    sync_fifo #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) sync_fifo_u1 (
        .clk   (clk),
        .wr_en      (!full       && 48khz_strobe),
        .rd_en      (almost_full && 48khz_strobe),
        .wr_data    (sine_in),
        .rd_data    (sine_delayed),
        .empty      (empty),
        .full       (full),
        .almost_full(almost_full)
    );

    always@(posedge clk) begin
        sine_delayed_valid <= almost_full && 48khz_strobe;
    end

    always@(*) begin
        if (sine_delayed_valid) begin
            sine_out = sine_in>>>1 + sine_delayed_value>>>1;
        end else begin
            sine_out = sine_in>>>1;
        end
    end

endmodule