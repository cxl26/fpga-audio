module top (
    input        sys_clk, 
    output wire  out_mclk,
    output wire  out_ws,
    output wire  out_sck,
    output wire  out_sd,
    output reg  led1,
    output reg  led2,
    output reg  led3,
    output reg  led4,
    output reg  led5,
    input      rx_pin,
    output     tx_pin, 
);

    localparam ASCII_0 = 8'd48;
    localparam ASCII_1 = 8'd49;
    localparam ASCII_2 = 8'd50;
    localparam ASCII_3 = 8'd51;
    localparam ASCII_4 = 8'd52;

    /* UART wires */
    wire [7:0] data_byte;
    wire       tx_ready;
    wire       rx_valid;
    wire       clk;

    wire [23:0] sine_value;
    wire        query_sine;
    assign out_mclk = clk;

    dds #(
        .DATA_WDTH = 24,
        .ADDR_WDTH = 12,
        .CNTR_WDTH = 2
    ) dds_u1 (
        .clk,
        .change_note(rx_valid && tx_ready),
        .query_sine (query_sine),
        .note       (data_byte[6:0]),
        .sine       (sine_value)
    );
    
    i2s_tx #(
        .DAT_WDTH (24),       // Width must be < SCK_RATE/WS_RATE
        .WS_RATE  (48000),    // 48     kHz, sampling rate
        .SCK_RATE (3072000),  // 307.2  kHz, 64x sampling
        .CLK_RATE (12288000)  // 122.88 MHz, 256x sampling
    ) i2s_tx_u1 (
        .clk(clk)
        /* I2S interface wires */
        .sck (out_sck),
        .ws  (out_ws),
        .sd  (out_sd),
        /* Data to be serialised */
        .left_chan  (sine_value),
        .right_chan (sine_value),
        .valid      (),
        .ready      (sine_strobe)
    );

    pll pll_u1 (
        .clock_in  (sys_clk),
        .clock_out (clk),
        .locked    ()
    );

    uart_rx_deserialise #(
        .CLK_RATE(24576000)
    ) uart_rx_deserialise_u1 (
        .clk     (clk),
        .rx_bits (rx_pin),
        .receive (tx_ready),
        .valid   (rx_valid),
        .rx_byte (data_byte)
    );
  
    uart_tx_serialise #(
  	    .CLK_RATE(24576000)
    ) uart_tx_serialise_u2 (
        .clk     (clk),
        .tx_byte (data_byte),
        .send    (rx_valid),
        .ready   (tx_ready),
        .tx_bits (tx_pin)
    );

    /* Light LEDs according to serial input */
    always @ (posedge clk) begin
        led5 <= 1'b1;
        if (rx_valid) begin
            case(data_byte)
                ASCII_0: {led1,led2,led3,led4} <= 4'b0000;
                ASCII_1: {led1,led2,led3,led4} <= 4'b1000;
                ASCII_2: {led1,led2,led3,led4} <= 4'b0100;
                ASCII_3: {led1,led2,led3,led4} <= 4'b0010;
                ASCII_4: {led1,led2,led3,led4} <= 4'b0001;
                default: {led1,led2,led3,led4} <= 4'b1111;
            endcase
        end
    end

endmodule