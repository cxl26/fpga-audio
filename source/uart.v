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
    output wire         tx_bits      // bits serialised
 );

    /* States */
    localparam STATE_IDLE    = 2'd0;
    localparam STATE_START   = 2'd1;
    localparam STATE_TX      = 2'd2;
    localparam STATE_STOP    = 2'd3;
    reg [1:0]  state         = STATE_IDLE;

    /* Shift Register */
    localparam SHIFT_COUNTER_VALUE = DATA_BITS-1;
    localparam SHIFT_COUNTER_WIDTH = $clog2(SHIFT_COUNTER_VALUE+1);
    reg [DATA_BITS-1:0]           shift_register;
    reg [SHIFT_COUNTER_WIDTH-1:0] shift_counter;

    /* Serial Counter */
    localparam SERIAL_COUNTER_VALUE = CLK_RATE/BAUD_RATE-1;
    localparam SERIAL_COUNTER_WIDTH = $clog2(SERIAL_COUNTER_VALUE+1);
    wire                           serial_strobe;
    reg [SERIAL_COUNTER_WIDTH-1:0] serial_counter = SERIAL_COUNTER_VALUE;
  
    /* Finite State Machine */
    always @(posedge clk) begin

        // Drive serial counter
        if (serial_strobe || state==STATE_IDLE) begin
            serial_counter <= SERIAL_COUNTER_VALUE;
        end else begin
            serial_counter <= serial_counter-1;
        end

        // Drive states and shifting
        case (state)
            STATE_IDLE: begin
                if (send) begin
                    state          <= STATE_START;
                    shift_counter  <= DATA_BITS-1;
                    shift_register <= tx_byte;
                end
            end

            STATE_START: begin
                if (serial_strobe) begin
                    state          <= STATE_TX;
                    shift_counter  <= shift_counter;
                    shift_register <= shift_register;
                end
            end

            STATE_TX: begin
                if (serial_strobe) begin
                    state          <= (shift_counter == 0) ? STATE_STOP    : STATE_TX;
                    shift_counter  <= (shift_counter == 0) ? STOP_BITS-1   : shift_counter-1;
                    shift_register <= shift_register >> 1;
                end
            end

            STATE_STOP: begin
                if (serial_strobe) begin
                    state          <= (shift_counter == 0) ? STATE_IDLE    : STATE_STOP;
                    shift_counter  <= (shift_counter == 0) ? DATA_BITS-1   : shift_counter-1;
                    shift_register <= shift_register;
                end
            end
        endcase

    end

    assign ready         = (state == STATE_IDLE);
    assign serial_strobe = (serial_counter == 0);
    assign tx_bits       = state==STATE_STOP || state==STATE_IDLE || (state==STATE_TX && shift_register[0]);

endmodule

module uart_rx_deserialise #(
    parameter       DATA_BITS   = 8,
    parameter       STOP_BITS   = 2,
    parameter       CLK_RATE    = 12000000,
    parameter       BAUD_RATE   = 9600
)(
    input                       clk,         // clock
    input                       rx_bits,     // received bits
    input                       receive,     // receive signal
    output wire                 valid,       // ready flag
    output wire [DATA_BITS-1:0] rx_byte     // byte to serialise
);


    /* States */
    localparam STATE_IDLE    = 2'd0;
    localparam STATE_START   = 2'd1;
    localparam STATE_RX      = 2'd2;
    localparam STATE_DONE    = 2'd3;
    reg [4:0]  state         = 2'd0;

    /* Shift Register */
    localparam SHIFT_COUNTER_VALUE = DATA_BITS-1;
    localparam SHIFT_COUNTER_WIDTH = $clog2(SHIFT_COUNTER_VALUE+1);
    reg [DATA_BITS-1:0]           shift_register;
    reg [SHIFT_COUNTER_WIDTH-1:0] shift_counter;

    /* Serial Counter */
    localparam SERIAL_COUNTER_VALUE = CLK_RATE/BAUD_RATE-1;
    localparam SERIAL_COUNTER_WIDTH = $clog2(SERIAL_COUNTER_VALUE+1);
    wire                           serial_strobe;
    reg [SERIAL_COUNTER_WIDTH-1:0] serial_counter = SERIAL_COUNTER_VALUE;

    /* Synchroniser Registers */
    reg [3:0] rx_reg = 4'b1111;

    /* Double Flop Synchroniser */
    always@(posedge clk) begin  
        rx_reg <= {rx_bits,rx_reg[3:1]};
    end
    
    /* Finite State Machine */
    always @(posedge clk) begin

        // Drive serial counter
        if (state == STATE_IDLE) begin
            serial_counter <= SERIAL_COUNTER_VALUE/2;
        end else if (serial_strobe) begin
            serial_counter <= SERIAL_COUNTER_VALUE;
        end else begin
            serial_counter <= serial_counter-1;
        end

        // Drive states and shifting
        case (state)
            
            STATE_IDLE: begin
              if (rx_reg[2:0]==3'b001) begin
                    state          <= STATE_START;
                    shift_counter  <= DATA_BITS-1;
                    shift_register <= shift_register;
                end
            end

            STATE_START: begin
                if (serial_strobe) begin
                    state          <= STATE_RX;
                    shift_counter  <= shift_counter;
                    shift_register <= shift_register;
                end
            end

            STATE_RX: begin
                if (serial_strobe) begin
                    state          <= (shift_counter == 0) ? STATE_DONE     : STATE_RX;
                    shift_counter  <= (shift_counter == 0) ? DATA_BITS - 1  : shift_counter - 1;
                    shift_register <= {rx_reg[0], shift_register[7:1]};
                end
            end

            STATE_DONE: begin
                if (receive) begin
                    state          <= receive ? STATE_IDLE : STATE_START;
                    shift_counter  <= shift_counter;
                    shift_register <= shift_register;
                end
            end

        endcase
    end

    assign valid         = (state == STATE_DONE);
    assign serial_strobe = (serial_counter == 0);
    assign rx_byte       = shift_register;

endmodule


module clock_divider #(
    parameter DIVISOR = 1250
)(
    input  wire in_clk,
    output reg  out_clk
);
    localparam COUNTER_WIDTH = $clog2(DIVISOR);
    reg [COUNTER_WIDTH-1:0] counter = 0;

    // NOTE: can only divide by integer multiple of 2, would need to clock on both posedge negedge otherwise
    // could fix with a fractional accumulator if we want fractional divisions.
    initial out_clk = 0;
  
    always @ (posedge in_clk) begin
        counter <= (counter >= DIVISOR-1) ? 0 : counter+1;
        out_clk <= (counter < DIVISOR/2)  ? 1 : 0;
    end
endmodule