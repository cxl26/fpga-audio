module i2s_slave_tx #(
    parameter DAT_WDTH = 24,
    parameter SYS_WDTH = 32
)(
    /* I2S interface wires */
    input  wire                 sck, 
    input  wire                 ws,
    output reg                  sd,
    /* Data to be serialised */
    input  wire [DAT_WDTH-1:0]  left_chan,
    input  wire [DAT_WDTH-1:0]  right_chan
);

    localparam COUNTER_VALUE = 2*SYS_WDTH-1;
    localparam COUNTER_WIDTH = $clog2(COUNTER_VALUE+1);
    localparam PAD_WDTH      = SYS_WDTH-DAT_WDTH;
  
    wire ready;
  	reg  valid = 1;

    reg                               ws_reg;
    reg [COUNTER_WIDTH-1:0]           counter = 0;
    reg [COUNTER_VALUE  :0]           buffer  = 0;

    always@(negedge sck) begin
        ws_reg  <= ws;
        sd      <= buffer[counter];
        counter <= (ready)          ? COUNTER_VALUE                                                : counter - 1;
        buffer  <= (ready && valid) ? {left_chan,  {PAD_WDTH{1'b0}}, right_chan, {PAD_WDTH{1'b0}}} : buffer;
    end
  
    assign ready = ({ws_reg, ws} == 2'b10);

endmodule