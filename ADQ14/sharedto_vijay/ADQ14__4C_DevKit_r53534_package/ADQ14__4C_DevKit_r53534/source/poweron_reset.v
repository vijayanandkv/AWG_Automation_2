/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description :
 *
 * Documentation :
 *
 */

`timescale 1 ns / 1 ps
`default_nettype none

module poweron_reset #(

   parameter PERST_CYCLES = 20,
   parameter WAIT_BEFORE_RESET_CYCLES = 10

)(

   (* KEEP = "TRUE" *) input wire clk_i,
   input wire resetn_i,
   output reg resetn_o

   );

   reg resetn;
   reg [31:0] reset_counter = PERST_CYCLES;
   reg [31:0] wait_counter = WAIT_BEFORE_RESET_CYCLES;
   reg resetn_d;
   reg end_of_reset;
    
   initial begin
      if(WAIT_BEFORE_RESET_CYCLES == 0) resetn = 0;
      else                              resetn = 1;
   end
   
   always@(posedge clk_i) begin
     resetn_d <= resetn_i;
     if (~resetn_d & resetn_i) begin// rising edge
       end_of_reset <= 1;
     end
   end

   always@(posedge clk_i) begin
      if(reset_counter == 0)
         resetn <= 1'b1;
      else if (wait_counter == 0) begin
         reset_counter <= reset_counter - 1;
         resetn <= 1'b0;
      end
      else begin
         wait_counter <= wait_counter - 1;
         resetn <= 1'b1;
      end
   end

   always@(posedge clk_i) begin
     if (end_of_reset) begin
       resetn_o <= 1'b1;
     end
     else begin
       resetn_o <= resetn;
     end
   end
  
endmodule
`default_nettype wire
