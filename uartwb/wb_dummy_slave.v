module wb_dummy_slave #(
  parameter ADDR_WID = 32,
  parameter DATA_WID = 32
  )(
  input wire clk_i,
  input wire nrst_i,

  input  wire [ADDR_WID-1 : 0] s_wb_addr_i,
  input  wire [DATA_WID-1 : 0] s_wb_data_i,
  output reg  [DATA_WID-1 : 0] s_wb_data_o,
  input  wire                  s_wb_we_i,
  input  wire                  s_wb_cyc_i,
  input  wire                  s_wb_stb_i,
  output reg                   s_wb_ack_o
  );

  reg clr;
  reg state;
  parameter S_IDLE = 0;
  parameter S_ACK  = 1;

  always@(posedge clk_i)
    if (!nrst_i)
      state <= S_IDLE;
    else
      case(state)
        S_IDLE:
          if (s_wb_cyc_i & s_wb_stb_i)
            state <= S_ACK;
          else
            state <= S_IDLE;

        default:
          state <= S_IDLE;
      endcase

  /* Clear: Write to 0 */
  always@(*)
    if ((state == S_IDLE)
        && s_wb_cyc_i && s_wb_stb_i
        && s_wb_we_i
        && (s_wb_addr_i == 0))

      clr <= 1'b1;
    
    else
      clr <= 0;

  /* Dummy register */
  reg [DATA_WID-1 : 0] dummy_reg;
  always@(posedge clk_i)
    if (!nrst_i)
      dummy_reg <= 0;
    else
      if ((state == S_ACK) && s_wb_we_i)
        dummy_reg <= s_wb_data_i;
      else
        dummy_reg <= dummy_reg;

  /* Read Tracker */
  reg [DATA_WID-1 : 0] readtrack_reg;
  always@(posedge clk_i)
    if (!nrst_i)
      readtrack_reg <= 0;
    else
      if (clr)
        readtrack_reg <= 0;
      else
        if ((state == S_ACK) && !s_wb_we_i)
          readtrack_reg <= readtrack_reg + 1;
        else
          readtrack_reg <= readtrack_reg;

  /* Write Tracker */
  reg [DATA_WID-1 : 0] writetrack_reg;
  always@(posedge clk_i)
    if (!nrst_i)
      writetrack_reg <= 0;
    else
      if (clr)
        writetrack_reg <= 0;
      else
        if ((state == S_ACK) && s_wb_we_i && (s_wb_addr_i != 0))
          writetrack_reg <= writetrack_reg + 1;
        else
          writetrack_reg <= writetrack_reg;

  /* Read */
  always@(*)
    if (state == S_ACK)
      case(s_wb_addr_i)
        0:
          s_wb_data_o <= 0;
        1:
          s_wb_data_o <= dummy_reg;
        2:
          s_wb_data_o <= readtrack_reg;
        3:
          s_wb_data_o <= writetrack_reg;
        default:
          s_wb_data_o <= s_wb_addr_i + 1;
      endcase

    else
      s_wb_data_o <= 0;

  //assign s_wb_ack_o = (state == S_ACK)? 1'b1 : 0;
  always@(*)
    if (state == S_ACK)
      s_wb_ack_o <= 1'b1;
    else
      s_wb_ack_o <= 0;
endmodule
