module char_ram #(
  parameter WIDTH = 64,
  parameter DEPTH = 16,
  parameter DEPL2 = 4
  )(
  input  wire               clk_i,
  input  wire               nrst_i,
  input  wire [DEPL2-1 : 0] addr_i,
  output reg  [WIDTH-1 : 0] data_o
  );

  /*reg [WIDTH-1 : 0] store [0 : DEPTH-1];

  always@(posedge clk_i)
    if (!nrst_i)
      data_o <= 0;
    else
      data_o <= store[addr_i];

  initial begin
    $readmemh("printram.mem", store);
  end*/

  always@(posedge clk_i)
    if (!nrst_i)
      data_o <= 0;
    else
      case(addr_i)
        0:       data_o <= 64'h68656c6c6f0a0000; //"hello\n"
        1:       data_o <= 64'h457865637574650a;
        2:       data_o <= 64'h436c6561720a2020;
        3:       data_o <= 64'h57726974650a2020;
        4:       data_o <= 64'h526561643a307800;
        5:       data_o <= 64'h526561640a000000;
        6:       data_o <= 64'h5175657565200000;
        default: data_o <= 64'h0000000000000000;
      endcase

endmodule
