module i2s_tx #(
    parameter DAT_WDTH = 24,       // Width must be < SCK_RATE/WS_RATE
    parameter WS_RATE  = 48000,    // 48     kHz, sampling rate
    parameter SCK_RATE = 3072000,  // 307.2  kHz, 64x sampling
    parameter CLK_RATE = 12288000  // 122.88 MHz, 256x sampling
)(
    input wire                 clk,
    
    /* I2S interface wires */
    output reg                 sck = 0,
    output reg                 ws  = 0,
    output reg                 sd,

    /* Data to be serialised */
    input  wire [DAT_WDTH-1:0]  left_chan,
    input  wire [DAT_WDTH-1:0]  right_chan,
    input  wire                 valid,
    output wire                 ready
);
  
    /* Buffer and strobe signals*/
    localparam PAD_WDTH = SCK_RATE/WS_RATE/2-DAT_WDTH;
    reg [DAT_WDTH-1:0]  right_buff;
    reg [DAT_WDTH-1:0]  left_buff;
    wire                strobe;

    /* Counter for SCK */
    localparam SCK_COUNTER_VALUE = CLK_RATE/SCK_RATE/2-1;
    localparam SCK_COUNTER_WIDTH = $clog2(SCK_COUNTER_VALUE+1); // is the +1 needed?
    reg [SCK_COUNTER_WIDTH-1:0] sck_counter = 0;

    /* Counter for WS */
    localparam WS_COUNTER_VALUE = SCK_RATE/WS_RATE/2-1;
    localparam WS_COUNTER_WIDTH = $clog2(WS_COUNTER_VALUE+1);
    reg [WS_COUNTER_WIDTH-1:0] ws_counter = 0;

    /* Drive SCK clock */
    always@(posedge clk) begin
        if (sck_counter == 0) begin
            sck_counter <= SCK_COUNTER_VALUE;
            sck         <= ~sck;
        end else begin
            sck_counter <= sck_counter-1;
            sck         <= sck;
        end
    end
    assign strobe = sck_counter==0 && sck;

    /* Drive WS clock */
    always@(posedge clk) begin
        if (strobe) begin
            if (ws_counter == 0) begin
                ws_counter <= WS_COUNTER_VALUE;
                ws         <= ~ws;
            end else begin
                ws_counter <= ws_counter-1;
                ws         <= ws;
            end
        end
    end
    assign ready = ws_counter==0 && ws && strobe;

    /* Drive SD data */
    always@(posedge clk) begin

        // Load word in buffer
        if (ready && valid) begin
            left_buff  <= left_chan;
            right_buff <= right_chan;
        end

        // Mux bits onto SD line
        if (strobe) begin
            if (ws_counter < PAD_WDTH) begin
                sd <= 0;
            end else begin
                sd <= ws ? right_buff[ws_counter-PAD_WDTH] : left_buff[ws_counter-PAD_WDTH];
            end
        end

    end

endmodule


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


module i2s_slave_rx #(
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

