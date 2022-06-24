module demo_uartwb #(
  parameter BAUD_PER = 10416
  )(
  input  wire clk,
  input  wire nrst,
  input  wire uart_rx,
  output wire uart_tx,

  output wire debug_rx,
  output wire debug_tx
  );

  wire wb_clk;
  wire [31:0] wb_addr;
  wire [31:0] wb_data_o;
  wire [31:0] wb_data_i;
  wire wb_we;
  wire wb_cyc;
  wire wb_stb;
  wire wb_ack;

  uartwb_top #(
    .BAUD_PER(BAUD_PER)
    ) UUT( 
    .clk_i       (clk),
    .nrst_i      (nrst),
    .uart_rx     (uart_rx), 
    .uart_tx     (uart_tx),
    .m_wb_clk_o  (wb_clk),
    .m_wb_addr_o (wb_addr),
    .m_wb_data_o (wb_data_o),
    .m_wb_data_i (wb_data_i),
    .m_wb_we_o   (wb_we),
    .m_wb_cyc_o  (wb_cyc),
    .m_wb_stb_o  (wb_stb),
    .m_wb_ack_i  (wb_ack)
    );

  wb_dummy_slave DUMMY(
    .clk_i       (wb_clk),
    .nrst_i      (nrst),
    .s_wb_addr_i (wb_addr),
    .s_wb_data_i (wb_data_o),
    .s_wb_data_o (wb_data_i),
    .s_wb_we_i   (wb_we),
    .s_wb_cyc_i  (wb_cyc),
    .s_wb_stb_i  (wb_stb),
    .s_wb_ack_o  (wb_ack)
    );

  assign debug_rx = uart_rx;
  assign debug_tx = uart_tx;

endmodule
