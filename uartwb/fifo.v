module fifo #(
  parameter DATA_WID = 8,
  parameter DEPTH    = 8,
  parameter DEPL2    = 3
  )(
  input  wire                  clk,
  input  wire                  nrst,
  input  wire                  push,
  input  wire                  pop,
  input  wire [DATA_WID-1 : 0] data_in,
  output reg  [DATA_WID-1 : 0] data_out,
  output reg                   full,
  output reg                   empty
);
  
  
  reg                   wr_en;
  reg  [DEPL2-1:0]      rd_addr,wr_addr;
  wire [DATA_WID-1 : 0] rf_out;
  
  /*regfile U0(
    .clk(clk),
    .wr_addr(wr_addr),
    .wr_en(wr_en),
    .wr_data(data_in),
    .rd_addr(rd_addr),
    .rd_data(rf_out)
  );*/

  reg [DATA_WID-1 : 0] store [0 : DEPTH-1];
  always@(posedge clk)
    if (wr_en)
      store[wr_addr] <= data_in;

  assign rf_out = store[rd_addr];
  
  wire [DEPL2-1:0] next_wr_addr, next_rd_addr;
  assign next_wr_addr = wr_addr + 1;
  assign next_rd_addr = rd_addr + 1;
  
  always@(*)
    if (!full && push)
      wr_en <= 1'b1;
  	else
      wr_en <= 0;
  
  always@(posedge clk)
    if (!nrst)
      wr_addr <= 0;
  	else
      if (!full && push)
        wr_addr <= next_wr_addr;
  
  always@(*)
    if (next_wr_addr == rd_addr)
      full <= 1'b1;
  	else
      full <= 0;
   
  always@(posedge clk)
    if (!nrst)
      rd_addr <= 0;
  	else
      if (!empty && pop)
        rd_addr <= next_rd_addr;
  
  always@(*)
    if (wr_addr == rd_addr)
      empty <= 1'b1;
  	else
      empty <= 0;
  
  always@(posedge clk)
    if (!nrst)
      data_out <= 0;
  	else
      if (!empty && pop)
        data_out <= rf_out;
  
endmodule
