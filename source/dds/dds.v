module dds #(
    parameter DATA_WDTH = 24,
    parameter ADDR_WDTH = 12,
    parameter CNTR_WDTH = 4
) (
    input  wire                 clk,
    input  wire                 query_sine,
    input  wire [6:0]           note,
    output reg  [DATA_WDTH-1:0] sine
);
    reg  [ADDR_WDTH+CNTR_WDTH-1:0] step_size;

    /* Connections for note lookup */
    reg  [6:0]                     note_lookup = 0;
    wire [ADDR_WDTH+CNTR_WDTH-1:0] note_value;

    /* Connections for sine lookup */
    reg  [ADDR_WDTH+CNTR_WDTH-1:0] sine_lookup = 0;
    wire [DATA_WDTH-1:0]           sine_value;
    
    // Very generous registers here probably don't need so much pipelining
    // Can reduce later on to reduce latency (not that it matters)

    // When changing note, a 2-cycle latency is not noticeable
    // When loading sine values, we load the registered value
    // Next load will be in >> 3 cycles (48 kHz sample rate vs ~MHz clock rate)

    // 2 cycle latency from change_note to sine value appearing:
        // 1. bram read latency for note lookup
        // 2. put looked up step on step size register

    // 3 cycle latency from query_sine to sine value appearing:
        // 1. update sine_lookup address register
        // 2. bram read latency for sine lookup
        // 3. put sine_value on sine register

    always @(posedge clk) begin

        step_size <= note_value;

        if (query_sine) begin
            sine_lookup <= sine_lookup + step_size;
        end

        sine <= sine_value;

    end

    note_lookup #(
        .DATA_WDTH(ADDR_WDTH+CNTR_WDTH),
        .ADDR_WDTH(7)
    ) note_lookup_u1 (
        .clk         (clk),
        .note_lookup (note),
        .note_value  (note_value)
    );

    sine_lookup #(
        .DATA_WDTH   (DATA_WDTH),
        .ADDR_WDTH   (ADDR_WDTH),
        .CNTR_WDTH   (CNTR_WDTH)
    ) sine_lookup_u1 (
        .clk         (clk),
        .sine_lookup (sine_lookup),
        .sine_value  (sine_value)
    );

endmodule