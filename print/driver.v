module driver(
  input  wire clk_i,
  input  wire nrst_i,

  output wire [6:0] addr_start_o,
  output wire [6:0] addr_end_o,
  output reg        en_o,
  output wire       bypass_o,
  output wire [7:0] bypass_data_o,
  input  wire       ready_i
  );

  reg [1:0] state;
  parameter S_RESET = 0;
  parameter S_START = 1;
  parameter S_SINK  = 2;

  always@(posedge clk_i)
    if (!nrst_i)
      state <= S_RESET;
    else
      case(state)
        S_RESET:
          state <= S_START;
        S_START:
          state <= S_SINK;
        S_SINK:
          state <= S_SINK;
        default:
          state <= S_START;
      endcase

  reg [13:0] addr_pair;
  always@(*)
    case(state)
      S_START:
        addr_pair <= {7'd0, 7'd5};
      default:
        addr_pair <= 0; 
    endcase

  assign {addr_start_o, addr_end_o} = addr_pair;

  always@(*)
    case(state)
      S_START:
        en_o <= 1'b1;

      default:
        en_o <= 0;
    endcase

  assign bypass_o = 0;
  assign bypass_data_o = 0;

  
endmodule
