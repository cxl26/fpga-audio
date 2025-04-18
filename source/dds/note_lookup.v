module note_lookup #(
    parameter DATA_WDTH = 16,
    parameter ADDR_WDTH = 7
) (
    input  wire clk,
    input  wire [ADDR_WDTH-1:0] note_lookup,
    output reg  [DATA_WDTH-1:0] note_value
);

    localparam RAM_SIZE = 2**ADDR_WDTH-1;
    reg [DATA_WDTH-1:0] rom [0:RAM_SIZE];

    initial $readmemb("../tools/note_lookup.txt", rom);

    always @(posedge clk) begin
        note_value <= rom[note_lookup];
    end

endmodule