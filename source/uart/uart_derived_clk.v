module uart_tx_serialise #(
    parameter       DATA_BITS   = 8,
    parameter       STOP_BITS   = 1,
    parameter       CLK_RATE    = 12000000,
    parameter       BAUD_RATE   = 9600
)(
    input               clk,         // clock
    input [DATA_BITS-1:0] tx_byte,   // byte to serialise
    input               send,        // send trigger
    output wire         ready,       // ready flag
    output reg          tx_bits = 1  // bits serialised
 );
 
    /* Divided Clock */
    localparam DIVISOR = CLK_RATE/BAUD_RATE;
    wire serial_clk;

    /* States */
    localparam STATE_IDLE    = 1'b0;
    localparam STATE_TX      = 1'b1;
    reg        state         = 1'b0;

    /* Shift Register */
    localparam COUNTER_VALUE = DATA_BITS+STOP_BITS-1;
    localparam COUNTER_WIDTH = $clog2(COUNTER_VALUE+1);
    reg [DATA_BITS-1:0]     buffer  = 0;
    reg [COUNTER_WIDTH-1:0] counter = COUNTER_VALUE;

    /* Generate Serial Clock */
    clock_divider #(
        .DIVISOR    (DIVISOR)
    ) clock_divider_u1 (
        .in_clk     (clk),
        .out_clk    (serial_clk)
    );
  
    /* Finite State Machine */
    always @(posedge serial_clk) begin
    // NOTE: using divided clock to drive always block bad? maybe but wtver lol
        case (state)
            // if send triggered, send start bit and load tx buffer
            // else stay in idle keep driving 1s on the tx
            STATE_IDLE: begin
                state   <= send ? STATE_TX : STATE_IDLE;
                counter <= COUNTER_VALUE;
                buffer  <= send ? tx_byte : buffer[DATA_BITS-1:0];
                tx_bits <= send ? 1'b0 : 1'b1;
            end
            // shift bits out until the bit counter runs down
            // shift in 1s so that last bits are the stop bits
            STATE_TX: begin
                state   <= (counter==0) ? STATE_IDLE : STATE_TX;
                counter <= counter - 1;
                buffer  <= {1'b1, buffer[DATA_BITS-1:1]};
                tx_bits <= buffer[0];
            end
        endcase
    end

    // NOTE: lazy handshake here would introduce a 1-cycle latency if put with a rdy/vld fifo
    // could probably fix it carefully if i sim it
    assign ready = (state == STATE_IDLE);

endmodule