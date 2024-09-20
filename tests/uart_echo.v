// RX and TX echo

module uart_echo (
    input      sys_clk, 
    output reg  led1,
    output reg  led2,
    output reg  led3,
    output reg  led4,
    output reg  led5,
    input      rx_pin,
    output     tx_pin, 
);
    wire tx_ready;
    wire rx_valid;
    wire [7:0] data_byte;

    localparam ASCII_0 = 8'd48;
    localparam ASCII_1 = 8'd49;
    localparam ASCII_2 = 8'd50;
    localparam ASCII_3 = 8'd51;
    localparam ASCII_4 = 8'd52;

    uart_rx_deserialise #(
        .CLK_RATE(12000000)
    ) uart_rx_deserialise_u1 (
        .clk     (clk),
        .rx_bits (rx_pin),
        .receive (tx_ready),
        .valid   (rx_valid),
        .rx_byte (data_byte)
    );
  
    uart_tx_serialise #(
  	    .CLK_RATE(12000000)
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