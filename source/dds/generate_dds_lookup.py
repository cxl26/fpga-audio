import csv
import math

midi_table_file = 'midi_table.csv'   # Input CSV file name
step_table_file = 'note_lookup.txt'  # Output tone file name
sine_table_file = "sine_lookup.txt"  # Output sine file name

DATA_WIDTH       = 24
ADDR_WIDTH       = 12
CNTR_WIDTH       = 4
SAMPLE_FREQUENCY = 48000               # sampling frequency (e.g. 48 kHZ)
LOOKUP_LENGTH    = 2**(ADDR_WIDTH-2)   # length of quarter sine lookup

print("Generating step sizes...")
with open(midi_table_file, mode='r') as midi_table, open(step_table_file, 'w', ) as step_table:
    reader = csv.reader(midi_table)
    for row in reader:
        frequency = float(row[1])
        step_size_num = 4 * LOOKUP_LENGTH / SAMPLE_FREQUENCY * frequency    # Calculate step size number for each freq
        step_size_str = format(int(step_size_num*(2**CNTR_WIDTH)), "016b")  # Convert to binary string
        step_table.write(step_size_str + "/n")
        #print(step_size_num)

print("Generating sine values...")
with open(sine_table_file, mode='w') as sine_table:
    for t in range(LOOKUP_LENGTH):
        sine_value_num = round(math.sin((t+0.5)/LOOKUP_LENGTH/2*math.pi)*2**(DATA_WIDTH-1))
        sine_value_str = format(int(sine_value_num), "024b")
        sine_table.write(sine_value_str + "/n")
        #print(sine_value_num)
