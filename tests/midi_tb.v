module testbench;
    logic       clk;
    logic       new_byte_valid;
    logic [7:0] new_byte_value;
    logic [7:0] test_bytes [15:0];
    int i = 0;
    int j = 0;

    midi_fsm midi_fsm_u1 (
        .clk            (clk),
        .new_byte_valid (new_byte_valid),
        .new_byte_value (new_byte_value),
        .note_values    (),
        .velocity_values()
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        clk = 1;
        repeat(3000) #5 clk = ~clk;
        $finish;
    end

    initial begin
        test_bytes[0]  = 8'b1_001_0000;
        test_bytes[1]  = 8'b0_0001000;
        test_bytes[2]  = 8'b0_0010000;
        test_bytes[3]  = 8'b1_001_0000;
        test_bytes[4]  = 8'b0_0000010;
        test_bytes[5]  = 8'b0_0000001;
        test_bytes[6]  = 8'b1_001_0000;
        test_bytes[7]  = 8'b0_1000000;
        test_bytes[8]  = 8'b0_0100000;
        test_bytes[9]  = 8'b1_000_0000;
        test_bytes[10] = 8'b0_0000010;
        test_bytes[11] = 8'b0_0000001;
        test_bytes[12] = 8'b1_001_0000;
        test_bytes[13] = 8'b0_1100000;
        test_bytes[14] = 8'b0_1100000;
        test_bytes[15] = 8'b1_001_0000;
    end

    always@(posedge clk) begin
        if (i == 32) begin
            i <= 0;
            j <= (j == 15) ? 0 : j+1;
        end else begin
            i <= i+1;
            j <= j;
        end
    end

    assign new_byte_value = test_bytes[j];
    assign new_byte_valid = (i == 0);

endmodule