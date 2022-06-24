module uartwb_top #(
  parameter [7:0] ADDR_WID = 32,
  parameter [7:0] DATA_WID = 32,
  parameter       BAUD_PER = 10416
  )(
  input  wire clk_i,
  input  wire nrst_i,

  input  wire uart_rx,
  output wire uart_tx,

  output wire                m_wb_clk_o, //use clk_i
  output wire [ADDR_WID-1:0] m_wb_addr_o,
  output wire [DATA_WID-1:0] m_wb_data_o,
  input  wire [DATA_WID-1:0] m_wb_data_i,
  output wire                m_wb_we_o,
  output wire                m_wb_cyc_o,
  output wire                m_wb_stb_o,
  input  wire                m_wb_ack_i
  );

  wire [DATA_WID-1 : 0] uartwb_data_o; // control to wrapper
  wire [DATA_WID-1 : 0] uartwb_data_i; // wrapper to control
  wire [ADDR_WID-1 : 0] uartwb_addr_o; // control to wrapper

  wire wrapper_valid_o;
  wire wrapper_en_i;
  wire wrapper_wr_i;

  wire fifo_push_i;
  wire [7:0] fifo_data_i;

  wire [7:0] uartrx_data_o;
  wire uartrx_valid;

  uartrx #(
    .BAUD_PER (BAUD_PER)
    ) RX(
    .clk   (clk_i),
    .nrst  (nrst_i),
    .en    (1'b1),
    .rx    (uart_rx),
    .dout  (uartrx_data_o),
    .valid (uartrx_valid_o)
    );

  uartwb_control #(
    .ADDR_WID (ADDR_WID),
    .DATA_WID (DATA_WID)
    ) CONTROL(
    .clk_i           (clk_i),
    .nrst_i          (nrst_i),
    .uartrx_valid_i  (uartrx_valid_o),
    .uartrx_data_i   (uartrx_data_o),
    .uarttx_en_o     (fifo_push_i),
    .uarttx_data_o   (fifo_data_i),
    .wrapper_wr_o    (wrapper_wr_i),
    .wrapper_en_o    (wrapper_en_i),
    .wrapper_valid_i (wrapper_valid_o),
    .wrapper_addr_o  (uartwb_addr_o),
    .wrapper_data_o  (uartwb_data_o),
    .wrapper_data_i  (uartwb_data_i)
    );

  wb_wrapper_master #(
    .ADDR_WID (ADDR_WID),
    .DATA_WID (DATA_WID)
    ) WB(
    .clk_i       (clk_i),
    .nrst_i      (nrst_i),
    .wr          (wrapper_wr_i),
    .en          (wrapper_en_i),
    .addr        (uartwb_addr_o),
    .dout        (uartwb_data_o),
    .din         (uartwb_data_i),
    .valid       (wrapper_valid_o),

    .m_wb_clk_o  (m_wb_clk_o),
    .m_wb_addr_o (m_wb_addr_o),
    .m_wb_data_o (m_wb_data_o),
    .m_wb_data_i (m_wb_data_i),
    .m_wb_we_o   (m_wb_we_o),
    .m_wb_cyc_o  (m_wb_cyc_o),
    .m_wb_stb_o  (m_wb_stb_o),
    .m_wb_ack_i  (m_wb_ack_i)
    );

  wire fifo_full_o;
  wire fifo_empty_o;
  wire [7:0] fifo_data_o;
  reg fifo_pop_i;
  fifo #(
    .DATA_WID (8),
    .DEPTH    (16),
    .DEPL2    (4)
    ) FIFO_TX( 
    .clk      (clk_i),
    .nrst     (nrst_i),
    .push     (fifo_push_i),
    .pop      (fifo_pop_i),
    .data_in  (fifo_data_i),
    .data_out (fifo_data_o),
    .full     (fifo_full_o),
    .empty    (fifo_empty_o)
    );

  wire uarttx_ready_o;
  reg uarttx_en_i;

  /* Glue Logic for FIFO and UART Tx */
  reg [1:0] txfifo_state;
  localparam TS_IDLE = 0;
  localparam TS_TXEN = 1;
  localparam TS_BUSY = 2;
  always@(posedge clk_i)
    if (!nrst_i)
      txfifo_state <= TS_IDLE;
    else
      case(txfifo_state)
        TS_IDLE:
          if (!fifo_empty_o && uarttx_ready_o)
            txfifo_state <= TS_TXEN;
          else
            txfifo_state <= TS_IDLE;

        TS_TXEN:
          txfifo_state <= TS_BUSY;

        TS_BUSY:
          if (uarttx_ready_o)
            txfifo_state <= TS_IDLE;
          else
            txfifo_state <= TS_BUSY;

        default:
          txfifo_state <= TS_IDLE;
      endcase

  always@(*)
    if ((txfifo_state == TS_IDLE) && uarttx_ready_o)
      fifo_pop_i <= 1'b1;
    else
      fifo_pop_i <= 0;

  always@(*)
    if (txfifo_state == TS_TXEN)
      uarttx_en_i <= 1'b1;
    else
      uarttx_en_i <= 0;

  uarttx #(
    .BAUD_PER (BAUD_PER)
    ) TX(
    .clk    (clk_i),
    .nrst   (nrst_i),
    .en     (uarttx_en_i),
    .din    (fifo_data_o),
    .tx     (uart_tx),
    .ready  (uarttx_ready_o)
    );
endmodule
