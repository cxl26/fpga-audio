module top_tb;
    //outputs
    wire  out_mclk;
    wire  out_ws;
    wire  out_sck;
    wire  out_sd;
    wire  led1;
    wire  led2;
    wire  led3;
    wire  led4;
    wire  led5;
    wire tx_pin;

    //inputs
    wire rx_pin;
    reg  sys_clk;

    // drive rx serial
    uart_tx #(
  	    .CLK_RATE(24576000)
    ) uart_tx_u1 (
        .clk     (sys_clk),
        .tx_byte (8'd64),
        .send    (1'b1),
        .ready   (),
        .tx_bits (rx_pin)
    );

    assign top_u1.clk = sys_clk;

    // instantiate top dut
    top top_u1 (
        .sys_clk(sys_clk), 
        .out_mclk(out_mclk),
        .out_ws(out_ws),
        .out_sck(out_sck),
        .out_sd(out_sd),
        .led1(led1),
        .led2(led2),
        .led3(led3),
        .led4(led4),
        .led5(led5),
        .rx_pin(rx_pin),
        .tx_pin(tx_pin)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        sys_clk = 1;
        repeat(900000) #5 sys_clk = ~sys_clk;
        $finish;
    end

endmodule