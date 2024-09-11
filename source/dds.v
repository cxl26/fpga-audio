module rom #(
    parameter DATA_WDTH = 64,
    parameter ADDR_WDTH = 12
)
(
    input  wire                 clk,
    input  wire [ADDR_WDTH-1:0] rd_addr, 
    output reg  [DATA_WDTH-1:0] rd_data
);
    
    localparam RAM_SIZE = 2**ADDR_WDTH;
    reg [DATA_WDTH-1:0] ram [RAM_SIZE:0];
    
    initial $readmemb("memfile.txt", ram);

    always @(posedge clk) begin
        rd_data <= ram[rd_addr];
    end

endmodule

module sine_lookup #(
    parameter DATA_WDTH = 24,
    parameter ADDR_WDTH = 12,
    parameter CNTR_WDTH = 2
)
(
    input  wire                             clk,
    input  wire [ADDR_WDTH+CNTR_WDTH+2-1:0] sine_lookup,
    output wire [DATA_WDTH-1:0]             sine_value
);
    
    localparam RAM_SIZE = 2**ADDR_WDTH;
    reg [DATA_WDTH-1:0] rom [RAM_SIZE:0];

    reg                  sine_inv  = 0;  //flag for inverting sine address
    reg                  sine_neg  = 0;  //flag for negating sine value
    reg  [CNTR_WDTH-1:0] sine_cntr = 0; //counter for phase accumulating sine lookup
    reg  [ADDR_WDTH-1:0] sine_addr = 0; //address for selecting lookup sine value
    
    wire [DATA_WDTH-1:0] sine_data;
    reg  [ADDR_WDTH-1:0] sine_addr_inv;
    reg                  delayed_sine_neg;
    
    assign {sine_neg, sine_inv, sine_addr, sine_cntr} = sine_lookup
    assign sine_value    = delayed_sine_neg ? ~sine_data+1 : sine_data;

    always@(*)           sine_addr_inv     = sine_inv ? ~sine_addr : sine_addr;
    always@(posedge clk) delayed_sine_neg <= sine_neg;
    
    initial $readmemb("sine_lookup_init_file.txt", rom);

    always @(posedge clk) begin
        sine_data <= rom[sine_addr];
    end

endmodule

module note_lookup #(
    parameter DATA_WDTH = 16,
    parameter ADDR_WDTH = 7,
) (
    input  wire clk,
    input  wire [ADDR_WDTH-1:0] note_lookup,
    output reg  [DATA_WDTH-1:0] note_value
);

    localparam RAM_SIZE = 2**ADDR_WDTH;
    reg [DATA_WDTH-1:0] rom [RAM_SIZE:0];

    initial $readmemb("note_lookup_init_file.txt", rom);

    always @(posedge clk) begin
        note_value <= rom[note_lookup];
    end

endmodule

module dds #(
    parameter DATA_WDTH = 24,
    parameter ADDR_WDTH = 12,
    parameter CNTR_WDTH = 2
) (
    input  wire clk,
    input  wire change_note,
    input  wire query_sine,
    input  wire note,
    output reg  sine
);
    wire strobe;
    reg  step_size;

    /* Connections for note lookup */
    reg note_lookup;
    wire note_value;

    /* Connections for sine lookup */
    reg  sine_lookup;
    wire sine_value;
    
    // Very generous registers here probably don't need so much pipelining
    // Can reduce later on to reduce latency (not that it matters)
    
    always @(posedge clk) begin
        if (change_note) begin
            note_lookup <= note;
        end

        step_size <= note_value;

        if (query_sine) begin
            sine_lookup <= sine_lookup + step_size;
        end

        sine <= sine_value;

    end

    note_lookup #(
        .DATA_WDTH(),
        .ADDR_WDTH(7),
    ) note_lookup_u1 (
        .clk         (clk),
        .note_lookup (note_lookup),
        .note_value  (note_value)
    );

    sine_lookup #(
        .DATA_WDTH   (),
        .ADDR_WDTH   (),
        .CNTR_WDTH   (),
    ) note_lookup_u1 (
        .clk         (clk),
        .sine_lookup (sine_lookup),
        .sine_value  (sine_value)
    );

endmodule