module sine_lookup #(
    parameter DATA_WDTH = 24,
    parameter ADDR_WDTH = 12,
    parameter CNTR_WDTH = 4
)
(
    input  wire                             clk,
    input  wire [ADDR_WDTH+CNTR_WDTH-1:0]   sine_lookup,
    output wire [DATA_WDTH-1:0]             sine_value
);
    
    localparam RAM_SIZE = 2**(ADDR_WDTH-2)-1;
    reg [DATA_WDTH-1:0] rom [0:RAM_SIZE];

    wire                  sine_inv;  //flag for inverting sine address
    wire                  sine_neg;  //flag for negating sine value
    wire  [CNTR_WDTH-1:0] sine_cntr;  //counter for phase accumulating sine lookup
    wire  [ADDR_WDTH-3:0] sine_addr;  //address for selecting lookup sine value
    
    reg  [DATA_WDTH-1:0] sine_data;
    reg  [ADDR_WDTH-3:0] sine_addr_inv;
    reg                  delayed_sine_neg;
    
    assign {sine_neg, sine_inv, sine_addr, sine_cntr} = sine_lookup;
    assign sine_value    = delayed_sine_neg ? ~sine_data+1 : sine_data;

    always@(*)           sine_addr_inv     = sine_inv ? ~sine_addr : sine_addr;
    always@(posedge clk) delayed_sine_neg <= sine_neg;
    
    initial $readmemb("../tools/sine_lookup.txt", rom);

    always @(posedge clk) begin
        sine_data <= rom[sine_addr_inv];
    end

endmodule