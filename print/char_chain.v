module char_chain #(
  //parameter FIFO_DEPTH = 8,
  parameter FIFO_DEPTH = 16,
  //parameter FIFO_DEPL2 = 3,
  parameter FIFO_DEPL2 = 4,
  parameter RAM_DEPTH  = 16,
  parameter RAM_DEPL2  = 4,
  parameter ADDR_WID   = 7   // Log2(RAM_DEPTH) + 3
  )(
  input  wire                  clk_i,
  input  wire                  nrst_i,

  /* Fetch Interface */
  input  wire [ADDR_WID-1 : 0] addr_start_i,
  input  wire [ADDR_WID-1 : 0] addr_end_i,
  input  wire                  en_i,
  input  wire                  bypass_i,
  input  wire [7:0]            bypass_data_i,
  output wire                  ready_o,

  /* Tx Interface */
  input  wire                  uart_ready_i,
  output wire [7:0]            uart_data_o,
  output wire                  uart_en_o,

  /* Debug */
  output wire [7:0]            dbg_uarttx_o,
  output wire [7:0]            dbg_fifoin_o,
  output wire [7:0]            dbg_addr_start_o,
  output wire [7:0]            dbg_addr_end_o,
  output wire [7:0]            dbg_cyc_saddr_o
  );

  wire fifo_empty, fifo_pop, fifo_full, fifo_push;
  wire [7:0] fifo_data_i, fifo_data_o;

  /* String Fetch */
  char_fetch #(
    .DATA_WID  (8),
    .ADDR_WID  (ADDR_WID),
    .RAM_DEPTH (RAM_DEPTH),
    .RAM_DEPL2 (RAM_DEPL2)
    ) FETCH(
    .clk_i         (clk_i),
    .nrst_i        (nrst_i),
    .addr_start_i  (addr_start_i),
    .addr_end_i    (addr_end_i),
    .en_i          (en_i),
    .data_o        (fifo_data_i),
    .queue_o       (fifo_push),
    .fifofull_i    (fifo_full),
    .bypass_i      (bypass_i),
    .bypass_data_i (bypass_data_i),
    .ready_o       (ready_o),

    .dbg_cyc_saddr (dbg_cyc_saddr_o)
    );

  /* FIFO */
  char_fifo #(
    .DATA_WID (8),
    .DEPTH    (FIFO_DEPTH),
    .DEPL2    (FIFO_DEPL2)
    )FIFO(
    .clk      (clk_i),
    .nrst     (nrst_i),
    .push     (fifo_push),
    .pop      (fifo_pop),
    .data_in  (fifo_data_i),
    .data_out (fifo_data_o),
    .full     (fifo_full),
    .empty    (fifo_empty)
    );

  /* UART Tx wrapper */
  char_tx UART_WRP(
    .clk_i        (clk_i),
    .nrst_i       (nrst_i),
    .fifo_empty_i (fifo_empty),
    .fifo_data_i  (fifo_data_o),
    .fifo_pop_o   (fifo_pop),
    .uart_ready_i (uart_ready_i),
    .uart_data_o  (uart_data_o),
    .uart_en_o    (uart_en_o) 
    );

  /* Debug Counters */
  reg [7:0] uarttx_en_ctr;
  always@(posedge clk_i)
    if (!nrst_i)
      uarttx_en_ctr <= 0;
    else
      if (uart_en_o)
        uarttx_en_ctr <= uarttx_en_ctr + 1;
      else
        uarttx_en_ctr <= uarttx_en_ctr;

  reg [7:0] fifo_push_ctr;
  always@(posedge clk_i)
    if (!nrst_i)
      fifo_push_ctr <= 0;
    else
      if (uart_en_o)
        fifo_push_ctr <= fifo_push_ctr + 1;
      else
        fifo_push_ctr <= fifo_push_ctr;

  reg [7:0] cap_addr_start;
  always@(posedge clk_i)
    if (!nrst_i)
      cap_addr_start <= 0;
    else
      if (en_i)
        cap_addr_start <= addr_start_i;
      else
        cap_addr_start <= cap_addr_start;

  reg [7:0] cap_addr_end;
  always@(posedge clk_i)
    if (!nrst_i)
      cap_addr_end <= 0;
    else
      if (en_i)
        cap_addr_end <= addr_end_i;
      else
        cap_addr_end <= cap_addr_end;

  assign dbg_uarttx_o = uarttx_en_ctr;
  assign dbg_fifoin_o = fifo_push_ctr;
  assign dbg_addr_start_o = cap_addr_start;
  assign dbg_addr_end_o   = cap_addr_end;

endmodule
