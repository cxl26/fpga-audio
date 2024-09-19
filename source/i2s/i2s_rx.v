module i2s_rx #(
    parameter DAT_WDTH = 24,       // Width must be < SCK_RATE/WS_RATE
    parameter WS_RATE  = 48000,    // 48     kHz, sampling rate
    parameter SCK_RATE = 3072000,  // 307.2  kHz, 64x sampling
    parameter CLK_RATE = 12288000  // 122.88 MHz, 256x sampling
)(
    input wire                 clk,
    
    /* I2S interface wires */
    output reg                 sck = 0,
    output reg                 ws  = 0,
    input  wire                sd,

    /* Internal interface */
    output wire [DAT_WDTH-1:0]  left_chan,
    output wire [DAT_WDTH-1:0]  right_chan,
    output wire                 dump
);
  
    /* Buffer and strobe signals*/
    localparam PAD_WDTH = SCK_RATE/WS_RATE/2-DAT_WDTH;
    reg [DAT_WDTH-1:0]  right_buff;
    reg [DAT_WDTH-1:0]  left_buff;
    wire                strobe;
    reg 				ws_reg;

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
    assign posedge_strobe = sck_counter==0 && !sck;
    assign negedge_strobe = sck_counter==0 &&  sck;

    /* Drive WS clock */
    always@(posedge clk) begin
        if (negedge_strobe) begin
            if (ws_counter == 0) begin
                ws_counter <= WS_COUNTER_VALUE;
                ws         <= ~ws;
            end else begin
                ws_counter <= ws_counter-1;
                ws         <= ws;
            end
            ws_reg <= ws;
        end
    end
  
    assign dump = ws_counter==WS_COUNTER_VALUE && ws && posedge_strobe;

    /* Process SD data */
    always@(posedge clk) begin
        // Shift bits in from SD line
        if (posedge_strobe && ws_counter > PAD_WDTH-2 && ws_counter < WS_COUNTER_VALUE) begin
        	if (ws_reg) begin
                right_buff <= {right_buff, sd};
            end else begin
            	left_buff  <= {left_buff,  sd};
            end
        end
    end

    assign left_chan  = left_buff;
    assign right_chan = right_buff;

endmodule