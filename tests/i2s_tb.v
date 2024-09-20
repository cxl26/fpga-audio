module testbench;
    logic clk;
    logic sck;
    logic ws;
    logic sd;
    logic [23:0] left;
    logic [23:0] right;
  
    i2s_tx i2s_tx_u1 (
        .clk         (clk),
        .sck         (sck),
        .ws          (ws),
        .sd          (sd),
        .left_chan   (24'b111000111110001111100011),
        .right_chan  (24'b100000000000000000000001),
        .load        ()
    );
  
    i2s_rx i2s_rx_u1 (
        .clk         (clk),
        .sck         (),
        .ws          (),
        .sd          (sd),
        .left_chan   (left),
        .right_chan  (right),
        .dump        ()
    );
  
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        clk = 1;
        repeat(3000) #5 clk = ~clk;
        $finish;
    end

endmodule