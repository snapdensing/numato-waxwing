`timescale 1ns / 1ps

module uartrx_simple(
    input clk,
    input nrst,
    input en,
    input rx,
    output [7:0] dout,
    output out_state,
    output [2:0] out_sample_ctr
    );
    
    // Baud counter
    parameter BAUD_PER = 10416; //9600 bits per second, 100 MHz clk (10ns period)
    reg [13:0] baud_ctr;
    reg baud_ctr_en;
    always@(posedge clk)
      if (baud_ctr < BAUD_PER) begin
        baud_ctr = baud_ctr + 1;
        baud_ctr_en = 0;
      end
      else begin
        baud_ctr = 0;
        baud_ctr_en = 1'b1;
      end
    
    // Sampling enable
    wire en_sample;
    assign en_sample = en & baud_ctr_en;

    // State machine
    reg state;
    parameter S_IDLE = 1'd0;
    parameter S_SAMPLE = 1'd1;
    reg [2:0] sample_ctr;
    
    always@(posedge clk)
    if (!nrst)
      state = S_IDLE;
    else
      if (en_sample)
        case(state)
          S_IDLE:
            if (rx == 0)
              state = S_SAMPLE;
            else
              state = S_IDLE;
              
          S_SAMPLE:
            if (sample_ctr == 3'd7)
              state = S_IDLE;
            else
              state = S_SAMPLE;
        endcase

    always@(posedge clk)
    if (!nrst)
      sample_ctr = 0;
    else
      if (en_sample)
        case(state)
          //S_IDLE:
            //sample_ctr = 0;
              
          S_SAMPLE:
            sample_ctr = sample_ctr + 1;
        endcase
        
    // Shift register
    reg [7:0] rxsr;
    always@(posedge clk)
    if (!nrst)
      rxsr = 0;
    else
      if (en_sample && (state == S_SAMPLE))
        rxsr = {rx, rxsr[7:1]};
      

    //dummy output
    assign dout = rxsr;
    assign out_state = state;
    assign out_sample_ctr = sample_ctr;
endmodule
