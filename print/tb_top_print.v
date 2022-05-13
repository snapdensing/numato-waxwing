`timescale 1ns/1ps
`define CLK_PERIOD 10
module tb_top_print;
  reg clk_100MHz, nrst_i;
  wire uarttx_ser_o;
  reg [3:0] dbg_sel_i;
  wire [7:0] dbg_disp_o; 

  top_print #(
    .BAUD_PER (10)
    ) UUT(
    .clk_100MHz   (clk_100MHz),
    .nrst_i       (nrst_i),
    .uarttx_ser_o (uarttx_ser_o),
    .dbg_sel_i    (dbg_sel_i),
    .dbg_disp_o   (dbg_disp_o)
    );

  always begin
    #(`CLK_PERIOD/2.0) clk_100MHz = ~clk_100MHz;
  end

  initial begin
    clk_100MHz = 0;
    nrst_i = 0;
    dbg_sel_i = 0;
    #(`CLK_PERIOD * 10) nrst_i = 1'b1;
    #(`CLK_PERIOD * 10);
  end
endmodule
