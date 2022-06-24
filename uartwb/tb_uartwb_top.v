`timescale 1ns/1ps
`define CLK_PERIOD 10
module tb_uartwb_top;
  reg clk, nrst;
  wire uart_rx;
  wire uart_tx;

  wire wb_clk;
  wire [31:0] wb_addr;
  wire [31:0] wb_data_o;
  wire [31:0] wb_data_i;
  wire wb_we;
  wire wb_cyc;
  wire wb_stb;
  wire wb_ack;

  reg [7:0] input_data;
  reg input_en;
  wire input_ready;

  uarttx #(
    .BAUD_PER(10)
    ) INPUT_GEN(
    .clk   (clk),
    .nrst  (nrst),
    .en    (input_en),
    .din   (input_data),
    .tx    (uart_rx),
    .ready (input_ready)
    );

  uartwb_top #(
    .BAUD_PER(10)
    ) UUT( 
    .clk_i       (clk),
    .nrst_i      (nrst),
    .uart_rx     (uart_rx), 
    .uart_tx     (uart_tx),
    .m_wb_clk_o  (wb_clk),
    .m_wb_addr_o (wb_addr),
    .m_wb_data_o (wb_data_o),
    .m_wb_data_i (wb_data_i),
    .m_wb_we_o   (wb_we),
    .m_wb_cyc_o  (wb_cyc),
    .m_wb_stb_o  (wb_stb),
    .m_wb_ack_i  (wb_ack)
    );

  wb_dummy_slave DUMMY(
    .clk_i       (wb_clk),
    .nrst_i      (nrst),
    .s_wb_addr_i (wb_addr),
    .s_wb_data_i (wb_data_o),
    .s_wb_data_o (wb_data_i),
    .s_wb_we_i   (wb_we),
    .s_wb_cyc_i  (wb_cyc),
    .s_wb_stb_i  (wb_stb),
    .s_wb_ack_o  (wb_ack)
    );

  wire [7:0] output_data;
  wire output_valid; 
  uartrx #(
    .BAUD_PER(10)
    ) OUTPUT_CAPT(
    .clk   (clk),
    .nrst  (nrst),
    .en    (1'b1),
    .rx    (uart_tx),
    .dout  (output_data),
    .valid (output_valid)
    );

  /* Output valid RE detect */
  reg output_valid_q;
  always@(posedge clk)
    if (!nrst)
      output_valid_q <= 1'b1;
    else
      output_valid_q <= output_valid;
  wire output_valid_re;
  assign output_valid_re = (output_valid & !output_valid_q)? 1'b1 : 0;

  always begin
    #(`CLK_PERIOD/2.0) clk = ~clk;
  end

  task send_byte;
    input [7:0] data;
    begin
      input_en = 1'b1;
      input_data = data;
      #(`CLK_PERIOD);
      while (!input_ready) begin
        input_en = 0;
        #(`CLK_PERIOD);
      end
      input_en = 0;
      #(`CLK_PERIOD);
    end
  endtask

  integer output_valid_ctr;
  task tran_write;
    input [31:0] addr;
    input [31:0] data;
    begin
      output_valid_ctr = 0;
      $display("Writing to addr 0x%X: 0x%X (time: %t)", addr, data, $time);
      send_byte(8'd1);
      send_byte(addr[31:24]);
      send_byte(addr[23:16]);
      send_byte(addr[15:8]);
      send_byte(addr[7:0]);
      send_byte(data[31:24]);
      send_byte(data[23:16]);
      send_byte(data[15:8]);
      send_byte(data[7:0]);
      while (!output_valid_re) begin
        #(`CLK_PERIOD);
      end
      $display("Received byte: 0x%X (time: %t)", output_data, $time);

    end
  endtask

  task tran_read;
    input [31:0] addr;
    begin
      output_valid_ctr = 0;
      $display("Reading from addr 0x%X (time: %t)", addr, $time);
      send_byte(8'd0);
      send_byte(addr[31:24]);
      send_byte(addr[23:16]);
      send_byte(addr[15:8]);
      send_byte(addr[7:0]);
      send_byte(8'd0); // dummy
      send_byte(8'd0); // dummy
      send_byte(8'd0); // dummy
      send_byte(8'd0); // dummy
      while (output_valid_ctr < 5) begin
        if (output_valid_re) begin
          $display("Received byte: 0x%X (time: %t)", output_data, $time);
          output_valid_ctr = output_valid_ctr + 1;
        end
        #(`CLK_PERIOD);
      end
    end
  endtask

  initial begin
    clk = 0;
    nrst = 0;
    input_en = 0;
    input_data = 0;

    #(`CLK_PERIOD * 100) nrst = 1'b1;

    #(`CLK_PERIOD * 1000) tran_read(32'd2);
    #(`CLK_PERIOD * 1000) tran_read(32'd2);
    #(`CLK_PERIOD * 1000) tran_read(32'd3);
    #(`CLK_PERIOD * 1000) tran_write(32'd3, 32'habcd1234);
    #(`CLK_PERIOD * 1000) tran_read(32'd3);
    #(`CLK_PERIOD * 1000) tran_read(32'd1);
    #(`CLK_PERIOD * 1000) tran_write(32'd0, 32'habcd1234);
    #(`CLK_PERIOD * 1000) tran_read(32'd100);
  end

endmodule
