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
    input  wire rx_pin,
    output wire tx_pin
);


    localparam NOTE_C4 = 8'd60;
    localparam NOTE_D4 = 8'd62;
    localparam NOTE_E4 = 8'd64;
    localparam NOTE_F4 = 8'd65;
    localparam NOTE_G4 = 8'd67;
    localparam NOTE_A4 = 8'd69;
    localparam NOTE_B4 = 8'd71;
    localparam NOTE_C5 = 8'd72;

    /* UART wires */
    wire [7:0] data_byte;
    wire       tx_ready;
    wire       rx_valid;
    wire       clk;

    wire signed [23:0] mixed_sine_value;

    wire signed [23:0] sine_value_1;
    wire signed [23:0] sine_value_2;

    wire [6:0] note_value_1;
    wire [6:0] note_value_2;

    wire [6:0] velocity_value_1;
    wire [6:0] velocity_value_2;

    wire        query_sine;

    assign out_mclk = clk;
    assign mixed_sine_value = (sine_value_1>>>1)+(sine_value_2>>>1);

    dds #(
        .DATA_WDTH(24),
        .ADDR_WDTH(12),
        .CNTR_WDTH(4)
    ) dds_u1 (
        .clk        (clk),
        .query_sine (query_sine),
        .note       (note_value_1),
        .sine       (sine_value_1)
    );

    dds #(
        .DATA_WDTH(24),
        .ADDR_WDTH(12),
        .CNTR_WDTH(4)
    ) dds_u2 (
        .clk        (clk),
        .query_sine (query_sine),
        .note       (note_value_2),
        .sine       (sine_value_2)
    );

    midi_fsm #(
        .NUM_DDS(2),
        .MY_MIDI_CH_ADDR(0)
    ) midi_fsm_u1 (
        .clk(clk),
        .new_byte_valid     (rx_valid && tx_ready),
        .new_byte_value     (data_byte),
        .note_values        ({note_value_2, note_value_1}),
        .velocity_values    ({velocity_value_2, velocity_value_1})
    );

    i2s_tx #(
        .DAT_WDTH (24),       // Width must be < SCK_RATE/WS_RATE
        .WS_RATE  (48000),    // 48     kHz, sampling rate
        .SCK_RATE (3072000),  // 307.2  kHz, 64x sampling
        .CLK_RATE (24576000)  // 24.576 MHz, 512x sampling
    ) i2s_tx_u1 (
        .clk        (clk),
        /* I2S interface wires */
        .sck        (out_sck),
        .ws         (out_ws),
        .sd         (out_sd),
        /* Data to be serialised */
        .left_chan  (mixed_sine_value),
        .right_chan (mixed_sine_value),
        .load       (query_sine)
    );

    pll pll_u1 (
        .clock_in  (sys_clk),
        .clock_out (clk),
        .locked    ()
    );

    uart_rx #(
        .CLK_RATE(24576000)
    ) uart_rx_u1 (
        .clk     (clk),
        .rx_bits (rx_pin),
        .receive (tx_ready),
        .valid   (rx_valid),
        .rx_byte (data_byte)
    );
  
    uart_tx #(
  	    .CLK_RATE(24576000)
    ) uart_tx_u1 (
        .clk     (clk),
        .tx_byte (data_byte),
        .send    (rx_valid),
        .ready   (tx_ready),
        .tx_bits (tx_pin)
    );

    /* Light debugging LEDs according to serial input */
    always @ (posedge clk) begin
        if (rx_valid && tx_ready && data_byte[7] && (data_byte[3:0] == 0) ) begin
            led5 <= data_byte[4];
        end
        // if (rx_valid && tx_ready) begin
        //     case(data_byte)
        //         NOTE_C4: {led1,led2,led3,led4} <= 4'b0000;
        //         NOTE_D4: {led1,led2,led3,led4} <= 4'b1000;
        //         NOTE_E4: {led1,led2,led3,led4} <= 4'b0010;
        //         NOTE_F4: {led1,led2,led3,led4} <= 4'b0001;
        //         default: {led1,led2,led3,led4} <= 4'b1111;
        //     endcase
        // end
    end

    always@(*) begin
        led1 = note_value_1 != 0;
        led2 = note_value_2 != 0;
        led3 = 0;
        led4 = 0;
    end

endmodule