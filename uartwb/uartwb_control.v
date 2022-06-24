module uartwb_control #(
  parameter [7:0] ADDR_WID = 32,
  parameter [7:0] DATA_WID = 32
  )(
  input  wire                  clk_i,
  input  wire                  nrst_i,

  /* UART Rx Interface */
  input  wire                  uartrx_valid_i,  // Rising-edge enable
  input  wire [7:0]            uartrx_data_i,

  /* UART Tx (Buffer) Interface */
  output reg                   uarttx_en_o,     // Single pulse enable
  output reg  [7:0]            uarttx_data_o,

  /* WB Wrapper Interface */
  output wire                  wrapper_wr_o,
  output reg                   wrapper_en_o,
  input  wire                  wrapper_valid_i,
  output wire [ADDR_WID-1 : 0] wrapper_addr_o,
  output wire [DATA_WID-1 : 0] wrapper_data_o,
  input  wire [DATA_WID-1 : 0] wrapper_data_i
  );

  localparam [4:0] ADDR_BYTES = ADDR_WID[7:3];
  localparam [4:0] DATA_BYTES = DATA_WID[7:3];

  reg [4:0] byte_ctr;
  reg [7:0] cmd;
  reg [ADDR_WID-1 : 0] addr;
  reg [DATA_WID-1 : 0] dout, din;
  reg wr;

  /* UART Rx rising edge detect */
  reg uartrx_valid_q;
  always@(posedge clk_i)
    if (!nrst_i)
      uartrx_valid_q <= 1'b1;
    else
      uartrx_valid_q <= uartrx_valid_i;

  wire uartrx_en;
  assign uartrx_en = (uartrx_valid_i & !uartrx_valid_q)? 1'b1 : 0;

  reg [2:0] state;
  localparam S_IDLE    = 0;
  localparam S_RX_ADDR = 1;
  localparam S_RX_DATA = 2;
  localparam S_WB_REQ  = 3;
  localparam S_TX_CMD  = 4;
  localparam S_TX_DATA = 5;
  
  always@(posedge clk_i)
    if (!nrst_i)
      state <= S_IDLE;
    else
      case(state)
        S_IDLE:
          if (uartrx_en)
            state <= S_RX_ADDR;
          else
            state <= S_IDLE;

        S_RX_ADDR:
          if (uartrx_en && (byte_ctr == (ADDR_BYTES-1)))
            state <= S_RX_DATA;
          else
            state <= S_RX_ADDR;

        S_RX_DATA:
          if (uartrx_en && (byte_ctr == (DATA_BYTES-1)))
            state <= S_WB_REQ;
          else
            state <= S_RX_DATA;

        S_WB_REQ:
          if (wrapper_valid_i)
            state <= S_TX_CMD;
          else
            state <= S_WB_REQ;

        S_TX_CMD:
          if (!wr)
            state <= S_TX_DATA;
          else
            state <= S_IDLE;

        S_TX_DATA:
          if (byte_ctr == (DATA_BYTES-1))
            state <= S_IDLE;
          else
            state <= S_TX_DATA;
            
        default:
          state <= S_IDLE;
      endcase

  always@(posedge clk_i)
    if (!nrst_i)
      byte_ctr <= 0;
    else
      case(state)
        S_RX_ADDR:
          if (uartrx_en)
            if (byte_ctr == (ADDR_BYTES-1))
              byte_ctr <= 0;
            else
              byte_ctr <= byte_ctr + 1;
          else
            byte_ctr <= byte_ctr;

        S_RX_DATA:
          if (uartrx_en)
            if (byte_ctr == (DATA_BYTES-1))
              byte_ctr <= 0;
            else
              byte_ctr <= byte_ctr + 1;

        S_TX_DATA:
          if (byte_ctr == (DATA_BYTES-1))
            byte_ctr <= 0;
          else
            byte_ctr <= byte_ctr + 1;

        default:
          byte_ctr <= 0;
      endcase

  always@(posedge clk_i)
    if (!nrst_i)
      wr <= 0;
    else
      if ((state == S_IDLE) && uartrx_en)
        if (uartrx_data_i == 8'd1)
          wr <= 1'b1;
        else
          wr <= 0;

      else
        wr <= wr;

  always@(posedge clk_i)
    if (!nrst_i)
      cmd <= 0;
    else
      if ((state == S_IDLE) && uartrx_en)
        cmd <= uartrx_data_i;
      else
        cmd <= cmd;

  always@(posedge clk_i)
    if (!nrst_i)
      addr <= 0;
    else
      if ((state == S_RX_ADDR) && uartrx_en)
        addr <= {addr[ADDR_WID-9 : 0], uartrx_data_i};
      else
        addr <= addr;
      
  always@(posedge clk_i)
    if (!nrst_i)
      dout <= 0;
    else
      if ((state == S_RX_DATA) && uartrx_en)
        dout <= {dout[DATA_WID-9 : 0], uartrx_data_i};
      else
        dout <= dout;

  always@(posedge clk_i)
    if (!nrst_i)
      din <= 0;
    else
      case(state)
        S_WB_REQ:
          if (wrapper_valid_i)
            din <= wrapper_data_i;

        S_TX_DATA:
          din <= {din[DATA_WID-9 : 0], 8'd0};
        default:
          din <= din;
      endcase

  always@(*)
    case(state)
      S_TX_CMD:
        uarttx_data_o <= cmd;

      S_TX_DATA:
        uarttx_data_o <= din[DATA_WID-1 : DATA_WID-8]; 

      default:
        uarttx_data_o <= 0;
    endcase

  always@(*)
    case(state)
      S_TX_CMD, S_TX_DATA:
        uarttx_en_o <= 1'b1;
      default:
        uarttx_en_o <= 0;
    endcase

  assign wrapper_wr_o   = wr;
  assign wrapper_addr_o = addr;
  assign wrapper_data_o = dout;
  always@(posedge clk_i)
    if (!nrst_i)
      wrapper_en_o <= 0;
    else
      if ((state == S_RX_DATA) && uartrx_en && (byte_ctr == (DATA_BYTES-1)))
        wrapper_en_o <= 1'b1;
      else
        wrapper_en_o <= 0;
      
endmodule
