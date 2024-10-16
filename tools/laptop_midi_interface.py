import serial
import time
from pynput.keyboard import KeyCode, Listener, Key

key_to_midi = {
    KeyCode(char='a'):60, #C4
    KeyCode(char='s'):62, #D4
    KeyCode(char='d'):64, #E4
    KeyCode(char='f'):65, #F4
    KeyCode(char='g'):67, #G4
    KeyCode(char='h'):69, #A4
    KeyCode(char='j'):71, #B4
    KeyCode(char='k'):72  #C5
}

ser = serial.Serial('/dev/tty.usbserial-11101')  # open serial port
print(ser.name)
ser.write((64).to_bytes())         # write a byte
keys_held = set()

exit_key = KeyCode(char='e')

def on_press(key):
    if not key in keys_held:
        print('Key: ', key, ' was held')
        keys_held.add(key)
        ser.write((0b1001_0000).to_bytes()) # status byte for NOTE_ON
        ser.write((key_to_midi.get(key,64)).to_bytes())
        ser.write((key_to_midi.get(key,64)).to_bytes()) 

def on_release(key):
    if key in keys_held:
        print('Key: ', key, ' was released')
        keys_held.remove(key)
        ser.write((0b1000_0000).to_bytes()) # status byte for NOTE_OFF
        ser.write((key_to_midi.get(key,64)).to_bytes())
        ser.write((key_to_midi.get(key,64)).to_bytes()) 

with Listener(on_press=on_press, on_release=on_release) as listener:
    print('listener starts')
    listener.join()

ser.close()             # close port