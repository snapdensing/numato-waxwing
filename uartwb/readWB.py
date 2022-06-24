import argparse
import serial
import threading
from time import sleep

# Convert hex string to byte stream
def hexstr2byte(hexstream):

  if (len(hexstream)%2) != 0:
    print('Error converting hex string to bytes: odd number of chars')
    print('-> {}'.format(hexstream))
    return b''

  bytestream = b''
  for i in range(len(hexstream)):
    if (i%2)==0:
      curr_int = int(hexstream[i:(i+2)],16)
      bytestream = bytestream + (curr_int).to_bytes(1,'big')

  return bytestream

# Parser
parser = argparse.ArgumentParser()
parser.add_argument("-d", "--device", help="UART device")
parser.add_argument("-b", "--baud", help="UART device")
parser.add_argument("-t", "--timeout", help="Timeout")
parser.add_argument("-w", "--wait", help="Wait time after last tx before closing")
parser.add_argument("-r", "--register", help="1-byte register address in hex")
args = parser.parse_args()

if args.device:
  serdev = args.device
else:
  serdev = '/dev/ttyUSB2'

if args.baud:
  baud = int(args.baud)
else:
  baud = 9600

if args.timeout:
  timeout = float(args.timeout)
else:
  timeout = 1

if args.wait:
  waittime = float(args.wait)
else:
  waittime = 0.25

if args.register:
  addr = args.register
else:
  addr = '00'

# Intialize serial
ser = serial.Serial(port=serdev, baudrate=baud, timeout=timeout)

# Thread for logging data
def uart_rx(ser):
  while True:
    rxdata = ser.readline()
    if rxdata != '':
      for i in rxdata:
        print('{:02X}'.format(i))
    global stop_threads
    if stop_threads:
      break

stop_threads = False
thread = threading.Thread(target=uart_rx, args=(ser,))
thread.start()

## Send Command
str = '00' + addr + '00000000'
cmd = hexstr2byte(str)
ser.write(cmd)

# Terminate script
sleep(waittime)
stop_threads = True
thread.join()
quit()
