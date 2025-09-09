/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description   : Clock domain crossing register
 * Documentation : 
 *
 */

`default_nettype none

module cdc_register
  #(
    parameter WIDTH = 1,
    parameter NofOutputRegs = 3,
    parameter NofSyncRegs = 2
    )
   (
    input wire clk_i,
    input wire [WIDTH-1:0] d_i,
    output wire [WIDTH-1:0] q_o
    );

   (* ASYNC_REG="TRUE" *)   reg [WIDTH-1:0] cdc_sync [NofSyncRegs-1:0];
   (* SHREG_EXTRACT="NO" *) reg [WIDTH-1:0] cdc_outregs [NofOutputRegs-1:0];

   integer i;
   always @(posedge clk_i) begin
      for (i=0; i<NofSyncRegs-1; i=i+1) begin
         cdc_sync[i] <= cdc_sync[i+1];
      end
      cdc_sync[NofSyncRegs-1] <= d_i;

      for (i=0; i<NofOutputRegs-1; i=i+1) begin
         cdc_outregs[i] <= cdc_outregs[i+1];
      end
      cdc_outregs[NofOutputRegs-1] <= cdc_sync[0];
   end

   assign q_o = (NofOutputRegs==0) ? cdc_sync[0] : cdc_outregs[0];

endmodule

`default_nettype wire
