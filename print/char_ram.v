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

  reg [WIDTH-1 : 0] store [0 : DEPTH-1];

  always@(posedge clk_i)
    if (!nrst_i)
      data_o <= 0;
    else
      data_o <= store[addr_i];

  initial begin
    //$readmemh("/home/snap/Work/rd1088/optikal/printram.mem", store);
    $readmemh("printram.mem", store);
  end

endmodule
