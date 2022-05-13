module char_fetch #(
  parameter RAM_DEPTH = 16,
  parameter RAM_DEPL2 = 4,
  parameter DATA_WID  = 8,
  parameter ADDR_WID  = 7 // Log2(Char RAM depth) + 3)
  )(
  input  wire                  clk_i,
  input  wire                  nrst_i,
  input  wire [ADDR_WID-1 : 0] addr_start_i,
  input  wire [ADDR_WID-1 : 0] addr_end_i,
  input  wire                  en_i,
  input  wire                  bypass_i,
  input  wire [DATA_WID-1 : 0] bypass_data_i,
  output reg  [DATA_WID-1 : 0] data_o,
  output reg                   queue_o,
  input  wire                  fifofull_i,
  output wire                  ready_o,

  output wire [7:0]            dbg_cyc_saddr
  );

  reg [ADDR_WID-1 : 0] addr_ctr, addr_end;

  /* State machine */
  reg [1:0] state;
  parameter S_IDLE   = 0;
  parameter S_ADDR   = 1;
  parameter S_BYPASS = 2;
  always@(posedge clk_i)
    if (!nrst_i)
      state <= S_IDLE;
    else
      case(state)
        S_IDLE:
          if (en_i)
            if (bypass_i)
              state <= S_BYPASS;
            else
              state <= S_ADDR;
          else
            state <= S_IDLE;

        S_ADDR:
          //if ((addr_ctr == addr_end_i) && !fifofull_i)
          if ((addr_ctr == addr_end) && !fifofull_i)
            state <= S_IDLE;
          else
            state <= S_ADDR;

        S_BYPASS:
          if (!fifofull_i)
            state <= S_IDLE;
          else
            state <= S_BYPASS;

        default:
          state <= S_IDLE;
      endcase

  always@(posedge clk_i)
    if (!nrst_i)
      addr_end <= 0;
    else
      if ((state == S_IDLE) && en_i)
        addr_end <= addr_end_i;
      else
        addr_end <= addr_end;

  always@(posedge clk_i)
    if (!nrst_i)
      addr_ctr <= 0;
    else
      case(state)
        S_IDLE:
          if (en_i)
            addr_ctr <= addr_start_i;
          else
            addr_ctr <= 0;

        S_ADDR:
          if (!fifofull_i)
            addr_ctr <= addr_ctr + 1;
          else
            addr_ctr <= addr_ctr;

        default:
          addr_ctr <= 0;
      endcase

  /* Char RAM */
  wire [63:0] char_word;
  char_ram #(
    .WIDTH (64),
    .DEPTH (RAM_DEPTH),
    .DEPL2 (RAM_DEPL2)
    ) CHAR_RAM(
    .clk_i  (clk_i),
    .nrst_i (nrst_i),
    .addr_i (addr_ctr[ADDR_WID-1 : 3]), // upper bits for word select
    .data_o (char_word)
    );

  reg [2:0] addr_ctr_sel;
  always@(posedge clk_i)
    if (!nrst_i)
      addr_ctr_sel <= 0;
    else
      addr_ctr_sel <= addr_ctr[2:0];

  reg [DATA_WID-1 : 0] bypass_data;
  always@(posedge clk_i)
    if (!nrst_i)
      bypass_data <= 0;
    else
      if ((state == S_IDLE) && en_i)
        bypass_data <= bypass_data_i;
      else
        bypass_data <= bypass_data;

  reg bypass_sel; /* For selecting bypass_data when fifo initially full */
  always@(posedge clk_i)
    if (!nrst_i)
      bypass_sel <= 0;
    else
      if ((state == S_BYPASS) && !queue_o)
        bypass_sel <= 1'b1;
      else
        bypass_sel <= 0;

  always@(*)
    if ((state == S_BYPASS) || ((state == S_IDLE) && bypass_sel))
      data_o <= bypass_data;
    else
      case(addr_ctr_sel)
        3'd0: data_o <= char_word[63:56];
        3'd1: data_o <= char_word[55:48];
        3'd2: data_o <= char_word[47:40];
        3'd3: data_o <= char_word[39:32];
        3'd4: data_o <= char_word[31:24];
        3'd5: data_o <= char_word[23:16];
        3'd6: data_o <= char_word[15:8];
        3'd7: data_o <= char_word[7:0];
      endcase

  /* Queue signal */
  wire queue_1cc;
  assign queue_1cc = ((state == S_ADDR) && !fifofull_i)? 1'b1 : 0;
  always@(posedge clk_i)
    if (!nrst_i)
      queue_o <= 0;
    else
      case(state)
        S_IDLE:
          if (en_i && bypass_i && !fifofull_i) // bypass, fifo not full
            queue_o <= 1'b1;
          else
            queue_o <= 0;

        S_ADDR:
          queue_o <= queue_1cc;                // Delayed signal to sync with RAM read

        S_BYPASS:
          if (!queue_o && !fifofull_i)         // bypass, fifo initially full
            queue_o <= 1'b1;
          else
            queue_o <= 0;

        default:
          queue_o <= 0;
      endcase

  assign ready_o = (state == S_IDLE)? 1'b1 : 0;

  /* Debug: Cycles at S_ADDR */
  reg [7:0] cyc_saddr;
  always@(posedge clk_i)
    if (!nrst_i)
      cyc_saddr <= 0;
    else
      if (state == S_ADDR)
        cyc_saddr <= cyc_saddr + 1;
      else
        cyc_saddr <= cyc_saddr;

  assign dbg_cyc_saddr = cyc_saddr;
endmodule
