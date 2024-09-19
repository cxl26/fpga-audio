module sine_lookup #(
    parameter DATA_WDTH = 24,
    parameter ADDR_WDTH = 12,
    parameter CNTR_WDTH = 4
)
(
    input  wire                             clk,
    input  wire [ADDR_WDTH+CNTR_WDTH-1:0] sine_lookup,
    output wire [DATA_WDTH-1:0]             sine_value
);
    
    localparam RAM_SIZE = 2**ADDR_WDTH;
    reg [DATA_WDTH-1:0] rom [RAM_SIZE:0];

    reg                  sine_inv  = 0;  //flag for inverting sine address
    reg                  sine_neg  = 0;  //flag for negating sine value
    reg  [CNTR_WDTH-1:0] sine_cntr = 0; //counter for phase accumulating sine lookup
    reg  [ADDR_WDTH-3:0] sine_addr = 0; //address for selecting lookup sine value
    
    wire [DATA_WDTH-1:0] sine_data;
    reg  [ADDR_WDTH-3:0] sine_addr_inv;
    reg                  delayed_sine_neg;
    
    assign {sine_neg, sine_inv, sine_addr, sine_cntr} = sine_lookup
    assign sine_value    = delayed_sine_neg ? ~sine_data+1 : sine_data;

    always@(*)           sine_addr_inv     = sine_inv ? ~sine_addr : sine_addr;
    always@(posedge clk) delayed_sine_neg <= sine_neg;
    
    initial $readmemb("sine_lookup.txt", rom);

    always @(posedge clk) begin
        sine_data <= rom[sine_addr];
    end

endmodule