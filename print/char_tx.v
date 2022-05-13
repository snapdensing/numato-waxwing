module char_tx (
  input  wire       clk_i,
  input  wire       nrst_i,
  input  wire       fifo_empty_i,
  input  wire [7:0] fifo_data_i,
  output reg        fifo_pop_o,
  input  wire       uart_ready_i,
  output wire [7:0] uart_data_o,
  output reg        uart_en_o
  );

  /* State machine */
  reg [1:0] state;
  parameter S_IDLE = 0;
  parameter S_SEND = 1;
  parameter S_WAIT = 2;

  always@(posedge clk_i)
    if (!nrst_i)
      state <= S_IDLE;
    else
      case(state)
        S_IDLE:
          if (!fifo_empty_i)
            state <= S_SEND;
          else
            state <= S_IDLE;

        S_SEND:
          if (uart_ready_i)
            state <= S_WAIT;
          else
            state <= S_SEND;

        S_WAIT:
          if (uart_ready_i)
            state <= S_IDLE;
          else
            state <= S_WAIT;

        default:
          state <= S_IDLE;
      endcase

  always@(*)
    if ((state == S_SEND) && uart_ready_i)
      uart_en_o <= 1'b1;
    else
      uart_en_o <= 0;

  always@(*)
    if ((state == S_IDLE) && !fifo_empty_i)
      fifo_pop_o <= 1'b1;
    else
      fifo_pop_o <= 0;
     
  assign uart_data_o = fifo_data_i;
endmodule
