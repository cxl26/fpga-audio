module i2s_rx_slave #(
    parameter DAT_WDTH = 24,
    parameter SYS_WDTH = 32
)(
    /* I2S interface */
    input wire       sck,
    input wire       ws,
    input wire       sd,
    /* Internal inteface */
    output wire [DAT_WDTH-1:0]  left_chan,
    output wire [DAT_WDTH-1:0]  right_chan
);

    wire valid;

    reg [1:0]                ws_reg;
    reg [2*SYS_WDTH-1:0]     sd_reg;

    always@(posedge sck) begin
        ws_reg  <= {ws_reg, ws};
        sd_reg  <= {sd_reg, sd};
    end
  
    assign left_chan  = sd_reg[2*SYS_WDTH-1 -: DAT_WDTH];
    assign right_chan = sd_reg[  SYS_WDTH-1 -: DAT_WDTH];
    assign valid = (ws_reg == 2'b10);

endmodule