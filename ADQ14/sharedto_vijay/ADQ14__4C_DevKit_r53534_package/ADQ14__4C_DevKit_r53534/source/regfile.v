/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description   : User register file
 * Documentation :
 *
 */

module regfile
  #(
    parameter ADDR_WIDTH = 0
   )
   (
    input wire                  clk,
    input wire                  rst_i,
    input wire [ADDR_WIDTH-1:0] addr_i,
    input wire                  wr_i,
    output reg                  wr_ack_o,
    input wire [31:0]           wr_data_i,
    input wire                  rd_i,
    output reg                  rd_ack_o,
    output reg [31:0]           rd_data_o,

    input wire [31:0]           reg_0x10_i,
    input wire [31:0]           reg_0x11_i,
    input wire [31:0]           reg_0x12_i,
    input wire [31:0]           reg_0x13_i,

    output wire [31:0]          reg_0x10_o,
    output wire [31:0]          reg_0x11_o,
    output wire [31:0]          reg_0x12_o,
    output wire [31:0]          reg_0x13_o
    );

   reg [31:0]         regfile_out [0:3];
   wire [31:0]        regfile_in [0:3];

   assign reg_0x10_o = regfile_out[0];
   assign reg_0x11_o = regfile_out[1];
   assign reg_0x12_o = regfile_out[2];
   assign reg_0x13_o = regfile_out[3];

   assign regfile_in[0] = reg_0x10_i;
   assign regfile_in[1] = reg_0x11_i;
   assign regfile_in[2] = reg_0x12_i;
   assign regfile_in[3] = reg_0x13_i;

   always @(posedge clk) begin
      wr_ack_o <= wr_i;
      rd_ack_o <= rd_i;
   end
   
   always @(posedge clk) begin
      if (rd_i) begin
         case (addr_i)
           14'h10:rd_data_o <= regfile_in[0];
           14'h11:rd_data_o <= regfile_in[1];
           14'h12:rd_data_o <= regfile_in[2];
           14'h13:rd_data_o <= regfile_in[3];
         endcase 
      end
   end

   integer           i;
   always @(posedge clk) begin
      if (rst_i)
        begin
           for (i = 0; i < 4; i = i + 1) begin
              regfile_out[i] <= 0;
           end
        end
      else
        begin
           if (wr_i)
             case (addr_i)
               14'h10:regfile_out[0] <= wr_data_i;
               14'h11:regfile_out[1] <= wr_data_i;
               14'h12:regfile_out[2] <= wr_data_i;
               14'h13:regfile_out[3] <= wr_data_i;
             endcase
        end
   end
endmodule
