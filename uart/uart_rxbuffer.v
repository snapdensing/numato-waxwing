`timescale 1ns / 1ps
module uart_rxbuffer(
    input clk,
    input nrst,
    input en,
    input rx,
    input [2:0] addr,
    output reg [7:0] data,
    output reg [2:0] tail_addr,
    output data_rcvd
    );
    
  // Receive buffer
  reg [7:0] rxsr;

  // Register file (RAM instantiation)
  reg [7:0] rf[0:7];
  
  always@(*)
    data <= rf[addr];
    
  reg rf_wr;
  always@(posedge clk)
    if (rf_wr)
      rf[tail_addr] <= rxsr;
      
  // Register file (Register instantiation)
  /*reg [7:0] rf0, rf1, rf2, rf3;
  reg [7:0] rf4, rf5, rf6, rf7;
  
  always@(*)
    case(addr)
      3'd0: data <= rf0;
      3'd1: data <= rf1;
      3'd2: data <= rf2;
      3'd3: data <= rf3;
      3'd4: data <= rf4;
      3'd5: data <= rf5;
      3'd6: data <= rf6;
      3'd7: data <= rf7;
    endcase
  
  reg rf_wr;
  always@(posedge clk)
    if (!nrst) begin
      rf0 <= 0;
      rf1 <= 0;
      rf2 <= 0;
      rf3 <= 0;
      rf4 <= 0;
      rf5 <= 0;
      rf6 <= 0;
      rf7 <= 0;
    end
    else
      if (rf_wr)
        case(tail_addr)
          3'd0: rf0 <= rxsr;
          3'd1: rf1 <= rxsr;
          3'd2: rf2 <= rxsr;
          3'd3: rf3 <= rxsr;
          3'd4: rf4 <= rxsr;
          3'd5: rf5 <= rxsr;
          3'd6: rf6 <= rxsr;
          3'd7: rf7 <= rxsr;
        endcase*/
      
  // Baud counter
  parameter BAUD_PER = 10416; //9600 bits per second, 100 MHz clk (10ns period)
  reg [13:0] baud_ctr;
  reg baud_ctr_en;
  always@(posedge clk)
    if (baud_ctr < BAUD_PER) begin
      baud_ctr <= baud_ctr + 1;
      baud_ctr_en <= 0;
    end
    else begin
      baud_ctr <= 0;
      baud_ctr_en <= 1'b1;
    end
    
  wire en_sample;
  assign en_sample = baud_ctr_en & en;
  
  // State machine
  reg [2:0] state;
  parameter S_IDLE    = 3'd0;
  parameter S_SAMPLE  = 3'd1;
  parameter S_RXSTOP  = 3'd2;
  reg [2:0] sample_ctr;
  
  always@(posedge clk)
  if (!nrst)
    state <= S_IDLE;
  else
    if (en_sample)
      case(state)
        S_IDLE:
          if (rx == 0)
            state <= S_SAMPLE;
          else
            state <= S_IDLE;
            
        S_SAMPLE:
          if (sample_ctr == 3'd7)
            state <= S_RXSTOP;
          else
            state <= S_SAMPLE;
            
        S_RXSTOP:
          state <= S_IDLE;
          
        default:
          state <= S_IDLE;
      endcase

  always@(posedge clk)
  if (!nrst)
    sample_ctr <= 0;
  else
    if (en_sample)
      case(state)
        S_SAMPLE:
          sample_ctr <= sample_ctr + 1;
      endcase
      
  // Shift register
  always@(posedge clk)
  if (!nrst)
    rxsr <= 0;
  else
    if (en_sample)
      case(state)  
        S_SAMPLE:
          rxsr <= {rx, rxsr[7:1]};         
      endcase
      
  // Write enable for register file
  always@(*)
    case(state)
      S_RXSTOP:
        rf_wr <= 1'b1;
      default:
        rf_wr <= 0;
    endcase
    
  // Data received signal
  assign data_rcvd = rf_wr;
  
  // Buffer tail address
  always@(posedge clk)
    if (!nrst)
      tail_addr <= 0;
    else
      if ((en_sample) && (state == S_RXSTOP))
        tail_addr <= tail_addr + 1;
endmodule
