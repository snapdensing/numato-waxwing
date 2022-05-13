module top_print #(
  parameter BAUD_PER = 10416 //9600 @ 100MHz
  )(
  input  wire       clk_100MHz,
  input  wire       nrst_i,
  output wire       uarttx_ser_o,
  input  wire [3:0] dbg_sel_i,
  output reg  [7:0] dbg_disp_o
  );

  wire clk_i;

  /* System Clock */
  assign clk_i = clk_100MHz;
  //parameter BAUD_PER = 10416; //9600

  wire [6:0] addr_start, addr_end;
  wire       print_en, print_bypass;
  wire [7:0] print_bypass_data;
  wire       print_ready;
  wire [7:0] uarttx_data;
  wire       uarttx_en, uarttx_ready;
  wire [7:0] dbg_uarttx_o;
  wire [7:0] dbg_fifoin_o;
  wire [7:0] dbg_addr_start_o;
  wire [7:0] dbg_addr_end_o;
  wire [7:0] dbg_cyc_saddr_o;

  driver DRIVER(
    .clk_i         (clk_i),
    .nrst_i        (nrst_i),
    .en_o          (print_en),
    .bypass_o      (print_bypass),
    .bypass_data_o (print_bypass_data),
    .ready_i       (print_ready),
    .addr_start_o  (addr_start),
    .addr_end_o    (addr_end)
    );

  char_chain #(
    .ADDR_WID (7)
    ) PRINT(
    .clk_i         (clk_i),
    .nrst_i        (nrst_i),
    .addr_start_i  (addr_start),
    .addr_end_i    (addr_end),
    .en_i          (print_en),
    .bypass_i      (print_bypass),
    .bypass_data_i (print_bypass_data),
    .ready_o       (print_ready),

    .uart_ready_i  (uarttx_ready),
    .uart_data_o   (uarttx_data),
    .uart_en_o     (uarttx_en),

    .dbg_uarttx_o  (dbg_uarttx_o),
    .dbg_fifoin_o  (dbg_fifoin_o),

    .dbg_addr_start_o (dbg_addr_start_o),
    .dbg_addr_end_o   (dbg_addr_end_o),
    .dbg_cyc_saddr_o  (dbg_cyc_saddr_o)
    );

  uarttx #(
    .BAUD_PER (BAUD_PER)
    ) UARTTX(
    .clk    (clk_i),
    .nrst   (nrst_i),
    .en     (uarttx_en),
    .din    (uarttx_data),
    .tx     (uarttx_ser_o),
    .ready  (uarttx_ready)
    );

  always@(*)
    case(dbg_sel_i)
      4'd0:    dbg_disp_o <= dbg_uarttx_o;
      4'd1:    dbg_disp_o <= dbg_fifoin_o;
      4'd2:    dbg_disp_o <= dbg_addr_start_o;
      4'd3:    dbg_disp_o <= dbg_addr_end_o;
      4'd4:    dbg_disp_o <= dbg_cyc_saddr_o;
      default: dbg_disp_o <= 8'ha5;
    endcase

endmodule
