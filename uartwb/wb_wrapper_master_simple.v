module wb_wrapper_master #(
  parameter CLKSCALE = 10, //ignored
  parameter ADDR_WID = 32,
  parameter DATA_WID = 32
  )(
  input  wire                clk_i,
  input  wire                nrst_i,

  /* wrapper interface */
  input  wire                wr,
  input  wire                en,
  input  wire [ADDR_WID-1:0] addr, 
  input  wire [DATA_WID-1:0] dout,
  output reg  [DATA_WID-1:0] din,
  output reg                 valid,

  /* wishbone interface */
  output wire                m_wb_clk_o, //use clk_i
  output wire [ADDR_WID-1:0] m_wb_addr_o,
  output wire [DATA_WID-1:0] m_wb_data_o,
  input  wire [DATA_WID-1:0] m_wb_data_i,
  output wire                m_wb_we_o,
  output wire                m_wb_cyc_o,
  output wire                m_wb_stb_o,
  input  wire                m_wb_ack_i
  );

  reg [2:0] state;
  localparam S_IDLE = 3'd0;
  localparam S_RD1  = 3'd2;
  localparam S_RD2  = 3'd3;
  localparam S_WR1   = 3'd1; 
  localparam S_WR2 = 3'd4;
  always@(posedge clk_i)
    if (!nrst_i)
      state <= S_IDLE;
    else
      case(state)
        S_IDLE:
          if (en)
            if (wr)
              state <= S_WR1;
            else
              state <= S_RD1;
          else
            state <= S_IDLE;

        S_WR1:
          if (m_wb_ack_i)
            state <= S_WR2;
          else
            state <= S_WR1;

        S_RD1:
          if (m_wb_ack_i)
            state <= S_RD2;
          else
            state <= S_RD1;

        default:
          state <= S_IDLE;
      endcase

  reg [ADDR_WID-1 : 0] m_wb_addr;
  reg [DATA_WID-1 : 0] m_wb_data;
  always@(posedge clk_i)
    if (!nrst_i) begin
      m_wb_addr <= 0;
      m_wb_data <= 0;
    end
    else
      if ((state == S_IDLE) && en) begin
        m_wb_addr <= addr;
        if (wr)
          m_wb_data <= dout;
        else
          m_wb_data <= m_wb_data;
      end
      else begin
        m_wb_addr <= m_wb_addr;
        m_wb_data <= m_wb_data;
      end

  reg m_wb_we;
  always@(posedge clk_i)
    if (!nrst_i)
      m_wb_we <= 0;
    else
      if ((state == S_IDLE) && en)
        m_wb_we <= wr;
      else
        m_wb_we <= m_wb_we;

  reg m_wb_cyc, m_wb_stb;
  always@(*)
    case(state)
      //S_RD1, S_WR1, S_RD2, S_WR2: begin
      S_RD1, S_WR1: begin
        m_wb_cyc <= 1'b1;
        m_wb_stb <= 1'b1;
      end

      default: begin
        m_wb_cyc <= 0;
        m_wb_stb <= 0;
      end
    endcase

  always@(posedge clk_i)
    if (!nrst_i) begin
      din   <= 0;
      valid <= 0;
    end
    else
      if (((state == S_RD1) || (state == S_WR1)) && m_wb_ack_i) begin
        din   <= m_wb_data_i;
        valid <= 1'b1;
      end
      else begin
        din   <= din;
        valid <= 0;
      end

  assign m_wb_addr_o = m_wb_addr;
  assign m_wb_data_o = m_wb_data;
  assign m_wb_we_o   = m_wb_we;
  assign m_wb_cyc_o  = m_wb_cyc;
  assign m_wb_stb_o  = m_wb_stb;
  assign m_wb_clk_o  = clk_i;

endmodule
