module uarttx #(
  parameter BAUD_PER = 10416
  )(
  input  wire       clk,
  input  wire       nrst,
  input  wire       en,
  input  wire [7:0] din,
  output reg        tx,
  output wire       ready
  );

  // Baud counter
  reg [13:0] baud_ctr;
  reg baud_ctr_en;
  always@(posedge clk)
    if (baud_ctr < BAUD_PER) begin
      baud_ctr    <= baud_ctr + 1;
      baud_ctr_en <= 0;
    end
    else begin
      baud_ctr    <= 0;
      baud_ctr_en <= 1'b1;
    end

  reg [1:0] state;
  reg [2:0] bit_ctr;
  parameter S_IDLE  = 0;
  parameter S_SYNC  = 1;
  parameter S_START = 2;
  parameter S_DATA  = 3;
  always@(posedge clk)
    if (!nrst)
      state <= S_IDLE;
    else
      case(state)
        S_IDLE:
          if (en)
            state <= S_SYNC;
          else
            state <= S_IDLE;

        S_SYNC:
          if (baud_ctr_en)
            state <= S_START;
          else
            state <= S_SYNC;

        S_START:
          if (baud_ctr_en)
            state <= S_DATA;
          else
            state <= S_START;

        S_DATA:
          if (baud_ctr_en)
            if (bit_ctr == 3'd7)
              state <= S_IDLE;
            else
              state <= S_DATA;
          else
            state <= S_DATA;

        default:
          state <= S_IDLE;
      endcase

  always@(posedge clk)
    if (!nrst)
      bit_ctr <= 0;
    else
      case(state)
        S_DATA:
          if (baud_ctr_en)
            bit_ctr <= bit_ctr + 1;
          else
            bit_ctr <= bit_ctr;
        default:
          bit_ctr <= 0;
      endcase

  reg [7:0] sr;
  always@(posedge clk)
    if (!nrst)
      sr <= 0;
    else
      case(state)
        S_IDLE:
          if (en)
            sr <= din;
          else
            sr <= sr;

        S_DATA:
          if (baud_ctr_en)
            sr <= {1'b0, sr[7:1]};
          else
            sr <= sr;
        default:
          sr <= sr;
      endcase

  always@(*)
    case(state)
      S_START:
        tx <= 0;
      S_DATA:
        tx <= sr[0];
      default:
        tx <= 1'b1;
    endcase

  assign ready = (state == S_IDLE)? 1'b1 : 0;
endmodule
