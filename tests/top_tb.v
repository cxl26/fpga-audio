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

    //test variables
    reg [7:0] test_bytes [15:0];
    integer i = 0;
    integer j = 0;
    wire       new_byte_valid;
    wire [7:0] new_byte_value;

    initial begin
        test_bytes[0]  = 8'b1_001_0000;
        test_bytes[1]  = 8'd127;
        test_bytes[2]  = 8'd126;
        test_bytes[3]  = 8'b1_001_0000;
        test_bytes[4]  = 8'd100;
        test_bytes[5]  = 8'd99;
        test_bytes[6]  = 8'b1_001_0000;
        test_bytes[7]  = 8'd80;
        test_bytes[8]  = 8'd79;
        test_bytes[9]  = 8'b1_000_0000;
        test_bytes[10] = 8'd100;
        test_bytes[11] = 8'd99;
        test_bytes[12] = 8'b1_001_0000;
        test_bytes[13] = 8'd60;
        test_bytes[14] = 8'd59;
        test_bytes[15] = 8'b1_001_0000;
    end

    always@(posedge sys_clk) begin
        if (i == 30000) begin
            i <= 0;
            j <= (j == 15) ? 0 : j+1;
        end else begin
            i <= i+1;
            j <= j;
        end
    end

    assign new_byte_value = test_bytes[j];
    assign new_byte_valid = (i == 0);

    // drive rx serial
    uart_tx #(
  	    .CLK_RATE(24576000)
    ) uart_tx_u1 (
        .clk     (sys_clk),
        .tx_byte (new_byte_value),
        .send    (new_byte_valid),
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