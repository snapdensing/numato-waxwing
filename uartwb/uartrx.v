module uartrx #(
  parameter [13:0] BAUD_PER = 10416 //9600 bits per second, 100 MHz clk (10ns period)
  )(
  input  wire       clk,
  input  wire       nrst,
  input  wire       en,
  input  wire       rx,
  output wire [7:0] dout,
  output wire       valid
  );
    
  // Baud counter
  //parameter BAUD_PER = 10416; //9600 bits per second, 100 MHz clk (10ns period)
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
    
  // Sampling enable
  wire en_sample;
  assign en_sample = en & baud_ctr_en;

  // Input filter
  localparam [13:0] BAUD_HALF = {1'b0, BAUD_PER[13:1]};
  reg [13:0] rx_ctr;
  always@(posedge clk)
    if (!nrst)
      rx_ctr <= BAUD_PER;
    else
      if (rx) // Increment
        if (rx_ctr == BAUD_PER)
          rx_ctr <= rx_ctr;
        else
          rx_ctr <= rx_ctr + 1;

      else    // Decrement
        if (rx_ctr == 0)
          rx_ctr <= rx_ctr;
        else
          rx_ctr <= rx_ctr - 1;

  reg rx_filtered;
  always@(*)
    if (rx_ctr > BAUD_HALF)
      rx_filtered <= 1'b1;
    else
      rx_filtered <= 0;

  // State machine
  reg state;
  parameter S_IDLE = 1'd0;
  parameter S_SAMPLE = 1'd1;
  reg [2:0] sample_ctr;
    
  always@(posedge clk)
    if (!nrst)
      state <= S_IDLE;
    else
      if (en_sample)
        case(state)
          S_IDLE:
            //if (rx == 0)
            if (rx_filtered == 0)
              state <= S_SAMPLE;
            else
              state <= S_IDLE;
                
          S_SAMPLE:
            if (sample_ctr == 3'd7)
              state <= S_IDLE;
            else
              state <= S_SAMPLE;
        endcase

  always@(posedge clk)
    if (!nrst)
      sample_ctr <= 0;
    else
      if (en_sample)
        case(state)
          //S_IDLE:
            //sample_ctr = 0;
                
          S_SAMPLE:
            sample_ctr <= sample_ctr + 1;

          default:
            sample_ctr <= sample_ctr;
        endcase
        
  // Shift register
  reg [7:0] rxsr;
  always@(posedge clk)
    if (!nrst)
      rxsr <= 0;
    else
      if (en_sample && (state == S_SAMPLE))
        //rxsr <= {rx, rxsr[7:1]};
        rxsr <= {rx_filtered, rxsr[7:1]};
      
  assign dout  = rxsr;
  assign valid = (state == S_IDLE)? 1'b1 : 0;

endmodule
