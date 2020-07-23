`timescale 1ns / 1ps

module top(
    input clk,
    input enable,
    input in0,
    output reg out0
    );

  always@(posedge clk)
  if (enable)
    out0 = in0;

endmodule
