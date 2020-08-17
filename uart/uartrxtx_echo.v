`timescale 1ns / 1ps

module uartrxtx_echo(
    input clk,
    input nrst,
    input en,
    input rx,
    output reg tx
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
      
    wire en_sample;
    assign en_sample = baud_ctr_en;
      
    // State machine
    reg [2:0] state;
    parameter S_IDLE    = 3'd0;
    parameter S_SAMPLE  = 3'd1;
    parameter S_RXSTOP  = 3'd2;
    parameter S_DELAY   = 3'd3;
    parameter S_TXSTART = 3'd4;
    parameter S_TXSEND  = 3'd5;
    parameter S_TXSTOP  = 3'd6;
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
              state = S_RXSTOP;
            else
              state = S_SAMPLE;
              
          S_RXSTOP:
            state = S_DELAY;
            
          S_DELAY:
            state = S_TXSTART;
            
          S_TXSTART:
            state = S_TXSEND;
          
          S_TXSEND:
            if (sample_ctr == 3'd7)
              state = S_TXSTOP;
            else
              state = S_TXSEND;
              
          S_TXSTOP:
            state = S_IDLE;
            
          default:
            state = S_IDLE;
        endcase

    always@(posedge clk)
    if (!nrst)
      sample_ctr = 0;
    else
      if (en_sample)
        case(state)
          //S_IDLE:
            //sample_ctr = 0;
              
          S_SAMPLE, S_TXSEND:
            sample_ctr = sample_ctr + 1;
        endcase
        
    // Shift register
    reg [7:0] rxsr;
    always@(posedge clk)
    if (!nrst)
      rxsr = 0;
    else
      if (en_sample)
        case(state)
        
          S_SAMPLE:
            rxsr = {rx, rxsr[7:1]};
          
          S_TXSEND:
            rxsr = {1'b0,rxsr[7:1]};
            
        endcase
        
    always@(*)
      case(state)
        S_TXSTART:
          tx = 1'b0;
        S_TXSEND:
          tx = rxsr[0];
        default:
          tx = 1'b1;
      endcase

endmodule