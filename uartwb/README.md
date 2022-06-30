# UART to Wishbone interface

This interface allows sending of wishbone read or write transactions via UART.

## Command Format

To initiate a WB transaction, the following command format must be sent through UART:

| Byte | Description                                      |
| ---- | ------------------------------------------------ |
| 0    | Transaction type (0x00 for read, 0x01 for write) |
| 1    | Address [31:24]                                  |
| 2    | Address [23:16]                                  |
| 3    | Address [15:8]                                   |
| 4    | Address [7:0]                                    |
| 6    | Data [31:24]                                     |
| 7    | Data [23:16]                                     |
| 8    | Data [15:8]                                      |
| 9    | Data [7:0]                                       |
| 10   | Checksum                                         |

The table shown above assumes 32-bit address and 32-bit data for the wishbone bus. For reads, Data bytes (6 to 9) are ignored (but must still be sent). The Checksum is simply the XOR of all non-checksum bytes and 0xFF.

## Response

After sending a command, the interface should reply with a byte stream through UART if a successful acknowledge is received by the wishbone bus. The first byte sent just echoes byte 0 (transaction type). For reads, the succeeding bytes are the data bytes read, MSB first. For writes, there are no further bytes sent after the first. Detection of incorrect packets sent is done by recalculating the checksum at the FPGA side and comparing it to the received checksum. In case of mismatch, the interface returns 0xFF.

# UART to Wishbone interface demo

Demo code using the interface with a dummy wishbone slave is provided by the file [demo_uartwb.v](./demo_uartwb.v). The dummy slave has the following registers:

| Address | Description    |
| ------- | -------------- |
| 0       | Clear register |
| 1       | Dummy register |
| 2       | Read tracker   |
| 3       | Write tracker  |

Reading from a register with an address not shown in the table above returns the value of the address + 1. Performing a write, regardless of the address, saves the data to the Dummy register.

A read transaction increments the Read tracker, while a write transaction increments the write tracker. To clear the trackers, simply perform a write on the clear register. Reading the clear register will always return a zero value.