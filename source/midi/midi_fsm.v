module midi_fsm #(
    // number of polyphonic voices (i.e. how many dds modules used)
    // paramterisable, but only 2 possible on icestick due to limited bram
    parameter NUM_DDS = 2,
    // midi commands are addressed to 1 of 16 channels, each is an instrument
    // we listen out only for messages addressed to channel zero in this case
    parameter MY_MIDI_CH_ADDR = 0
)(
    input  wire                 clk,
    input  wire                 new_byte_valid,
    input  wire [7:0]           new_byte_value,
    output reg  [7*4-1:0]       note_values = 0,
    output reg  [7*4-1:0]       velocity_values = 0
);
    // at the moment only implementing 2 msg types NOTE_ON and NOTE_OFF, maybe CTRL_CHANGE later
    // actually 8 possible midi msgs (3-bit value) but really just using first bit rn
    reg [2:0] midi_fsm_msg = 0;
    localparam NOTE_OFF     = 3'd0;
    localparam NOTE_ON      = 3'd1;

    // messages can be up to 3 bytes, so three states in the fsm
    reg [1:0] midi_fsm_state = IDLE;
    localparam IDLE  = 3'd0;
    localparam DATA1 = 3'd1;
    localparam DATA2 = 3'd2;


    reg [7*NUM_DDS-1:0]     next_note_values;
    reg [7*NUM_DDS-1:0]     next_velocity_values;
    reg [6:0]               compare_val;
    reg [6:0]               note_val;
    reg [6:0]               note_val_reg = 0;
    reg [NUM_DDS-1:0]       one_hot;
    reg [NUM_DDS-1:0]       one_hot_reg = 0;

    integer i;
    

    // STATUS BYTE
    // Bit  [7]   status indicator (1)
    // Bits [6:4] message type
    // Bits [3:0] channel address

    // NOTE BYTE
    // Bit  [7]   status indicator (0)
    // Bits [6:0] note value

    // VELOCITY BYTE
    // Bit  [7]   status indicator (0)
    // Bits [6:0] velocity value


    // Combinational logic for DATA1 state NOTE_ON/NOTE_OFF messages
    always@(*) begin
        // Multiplexer to select value based on NOTE_ON or NOTE_OFF
        compare_val = midi_fsm_msg[0] ? 7'b0 : new_byte_value[6:0];
        note_val    = midi_fsm_msg[0] ? new_byte_value[6:0] : 7'b0;
        // Comparator and one-hot priority encoder to select which dds note to change
        one_hot[0] = (note_values[0:7] == compare_val);
        for (i=1; i<NUM_DDS; i++) begin
            one_hot[i] = (note_values[i*7+:7] == compare_val) && ~|one_hot[i-1:0];
        end
        // one_hot[0] = (note_values[0*7+:7] == compare_val);
        // one_hot[1] = (note_values[1*7+:7] == compare_val) && ~|one_hot[0];
        // one_hot[2] = (note_values[2*7+:7] == compare_val) && ~|one_hot[1:0];
        // one_hot[3] = (note_values[3*7+:7] == compare_val) && ~|one_hot[2:0];
    end

    // Combinational logic for DATA2 sate NOTE_ON/NOTE_OFF messages
    always@(*) begin
        // Mux next note
        for (i=0; i<NUM_DDS; i++) begin
            next_note_values[i*7+:7] = one_hot_reg[i] ? note_val_reg : note_values[i*7+:7];
        end
        // Mux next velocity
        for (i=0; i<NUM_DDS; i++) begin
            next_velocity_values[i*7+:7] = one_hot_reg[i] ? new_byte_value[6:0] : velocity_values[i*7+:7];
        end
    end

    // Sequential logic MIDI FSM
    always@(posedge clk) begin
        if (new_byte_valid) begin
            if (new_byte_value[7] == 1'b1 && new_byte_value[3:0] == MY_MIDI_CH_ADDR) begin
                midi_fsm_state  <= DATA1;
                midi_fsm_msg    <= new_byte_value[6:4];
            end else if (midi_fsm_state == DATA1) begin
                one_hot_reg     <= one_hot;
                note_val_reg    <= note_val;
                midi_fsm_state  <= DATA2;
            end else if (midi_fsm_state == DATA2) begin
                note_values     <= next_note_values;
                velocity_values <= next_velocity_values;
                midi_fsm_state  <= IDLE;
            end else begin
                midi_fsm_state  <= IDLE;
            end
        end
    end

endmodule