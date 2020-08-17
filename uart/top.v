`timescale 1ns / 1ps

module top(
    input clk,
    input nrst,
    input [3:0] dip,
    output [7:0] led,
    input rx
    );

  wire [7:0] data;
  wire [2:0] tail_addr;
  wire data_rcvd;

  uart_rxbuffer U0(
    .clk(clk),
    .nrst(nrst),
    .en(1'b1),
    .rx(rx),
    .addr(dip[2:0]),
    .data(data),
    .tail_addr(tail_addr),
    .data_rcvd(data_rcvd)
    );
    
  assign led = (dip[3])? {5'd0,tail_addr} : data;

endmodule
