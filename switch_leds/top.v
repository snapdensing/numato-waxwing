`timescale 1ns / 1ps

module top(
  input clk,
  input mode,
  input invert,
  input [6:0] pb,
  input start,
  input cntup,
  output [7:0] led
  );
 
  reg [7:0] led_counter;
  reg [7:0] led_combi;
 
  assign led = mode ? led_counter : led_combi;
 
  // Mode 0: push button pass through
  always@(*) begin
    if (invert) begin
      led_combi[6:0] = ~pb;
      led_combi[7] = ~pb[6];
    end
    else begin
      led_combi[6:0] = pb;
      led_combi[7] = pb[6];
    end
  end

  // Clock divider
  //clkdiv100M DIV(clk,clk_1Hz);

  // Mode 1: counter
  parameter CLKDIV = 32'd100000000;
  reg [31:0] clkdiv_ctr;
  always@(posedge clk) begin
    if (clkdiv_ctr <= CLKDIV)
      clkdiv_ctr = clkdiv_ctr + 1;
    else
      clkdiv_ctr = 0;
  end
  
  always@(posedge clk) begin
    if (mode && start && (clkdiv_ctr == 0))
      if (cntup)
        led_counter = led_counter + 1;
      else
        led_counter = led_counter - 1;
  end

endmodule
