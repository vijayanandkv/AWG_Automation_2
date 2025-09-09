/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description   : Top level module ADQ14
 * Documentation :
 *
 */

`include "config.v"
`include "device_param_top.vh"

`default_nettype none

module top_adq14
  (
  `ifndef ENABLE_ETH
   //PCIE
   output wire [`PCIE_NO_LANES-1:0]  tx_p,
   output wire [`PCIE_NO_LANES-1:0]  tx_n,

   input wire  [`PCIE_NO_LANES-1:0]  rx_p,
   input wire  [`PCIE_NO_LANES-1:0]  rx_n,
 `else
   output wire [7:4]  tx_p,
   output wire [7:4] tx_n,
   input wire [7:4]  rx_p,
   input wire [7:4] rx_n,
 `endif


`ifdef ENABLE_ETH
     // Ethernet clk
   input wire mgtrefclk2_p,
   input wire mgtrefclk2_n,
`else
   input wire mgtrefclk_p, // PCIe refclk
   input wire mgtrefclk_n,
`endif

   input wire fpga_gtxref_ac_p,
   input wire fpga_gtxref_ac_n,

   input wire fpga_glblclk_p,
   input wire fpga_glblclk_n,

   input wire [3:0] adc1_d_p,
   input wire [3:0] adc1_d_n,
   input wire [3:0] adc2_d_p,
   input wire [3:0] adc2_d_n,

   input wire fpga_sysref_p,
   input wire fpga_sysref_n,

   output wire adc1_sync_p,
   output wire adc1_sync_n,

   output wire adc2_sync_p,
   output wire adc2_sync_n,

   // The clock IBUFGDS are instantiated outside dram controllers.
   input wire                         c0_ddr3_sys_clk_p, // 133 MHz
   input wire                         c0_ddr3_sys_clk_n,
   input wire                         c1_ddr3_sys_clk_p, // 133 MHz
   input wire                         c1_ddr3_sys_clk_n,

`ifdef EN_DRAM
   //DRAM
   // DRAM interface, bank 0 - also referred to as m1_
   inout wire [`DRAM_DQ_WIDTH-1:0]    c0_ddr3_dq,
   inout wire [`DRAM_DQS_WIDTH-1:0]   c0_ddr3_dqs_n,
   inout wire [`DRAM_DQS_WIDTH-1:0]   c0_ddr3_dqs_p,
   output wire [`DRAM_ROW_WIDTH-1:0]  c0_ddr3_addr,
   output wire [`DRAM_BANK_WIDTH-1:0] c0_ddr3_ba,
   output wire                        c0_ddr3_ras_n,
   output wire                        c0_ddr3_cas_n,
   output wire                        c0_ddr3_we_n,
   output wire                        c0_ddr3_reset_n,
   output wire                        c0_ddr3_ck_p,
   output wire                        c0_ddr3_ck_n,
   output wire                        c0_ddr3_cke,
   output wire                        c0_ddr3_odt,

   // DRAM interface, bank 1 - also referred to as m2_
   inout wire [`DRAM_DQ_WIDTH-1:0]    c1_ddr3_dq,
   inout wire [`DRAM_DQS_WIDTH-1:0]   c1_ddr3_dqs_n,
   inout wire [`DRAM_DQS_WIDTH-1:0]   c1_ddr3_dqs_p,
   output wire [`DRAM_ROW_WIDTH-1:0]  c1_ddr3_addr,
   output wire [`DRAM_BANK_WIDTH-1:0] c1_ddr3_ba,
   output wire                        c1_ddr3_ras_n,
   output wire                        c1_ddr3_cas_n,
   output wire                        c1_ddr3_we_n,
   output wire                        c1_ddr3_reset_n,
   output wire                        c1_ddr3_ck_p,
   output wire                        c1_ddr3_ck_n,
   output wire                        c1_ddr3_cke,
   output wire                        c1_ddr3_odt,

`endif //  `ifdef EN_DRAM

   // Other clocks
   input wire clk10m_fpga, // 10 MHz (can disappear when PLL and clock muxes are reconfigured)


   // Power-down signals
   output wire adc1_pdwn,
   output wire adc2_pdwn,
   output wire m1_ddr3_osc_dis,
   output wire m2_ddr3_osc_dis,

   input wire emcosc_en, // Enable emcclk oscillator (set to input for now to avoid configuration issues, has external pull-up)

   input wire fan_fault_n,

   input wire atnsw_fpga_n,

   // SPI bus - General
   inout wire spi_sdio,
   output wire spi_sclk,

   output wire adc1_cs_n,
   output wire adc2_cs_n,
   output wire dac_bias_cd_cs_n,
   output wire dac_bias_ab_cs_n,
   output wire dac_null_cd_cs_n,
   output wire dac_null_ab_cs_n,
   output wire dac_ovp_cs_n,
   output wire pll_cs_n,
   output wire trig_tcxo_cs_n,

   // SPI bus - Parameter EEPROM
   output wire param_sck,
   output wire param_cs_n,
   input wire param_so,
   output wire param_si,

   // SPI bus - Firmware Flash and configration pins (quad)
`ifdef EN_CFGPINS
   (* DONT_TOUCH = "TRUE" *) input wire emcclk, // 100 MHz external configuration clock
   inout wire [3:0] conf_d,
   output wire conf_cs_n,
   // Note: CCLK is accessed via the STARTUPE2 primitive in the quad spi block
`endif

   // I2C bus
   inout wire scl,
   inout wire sda,

   // 1-wire bus - ADX SecEEPROM
   inout wire secee_1wire, //inout

   // USB chip UART
   output wire f2u_rxd,
   input wire u2f_txd,

   // PXIe signals
`ifndef MTCA
   `ifdef ENABLE_ETH
     inout wire pxie_smbd, //inout
     output wire pxie_smbc,
     output wire pxie_alert,
   `else
     input wire pxie_smbd,
     input wire pxie_smbc,
     input wire pxie_alert,
   `endif /* ENABLE_ETH */

   input wire pxie_smbrdy,
   input wire [4:0] pxie_ga,

   inout wire pxi_trig0,
   inout wire pxi_trig1,
   output wire pxi_trig0_dir, //output
   output wire pxi_trig1_dir, //output
   output wire pxie_starc_p,
   output wire pxie_starc_n,

   input wire pxie_stara,

   output wire pxie_100m_en,
   output wire pxie_10m_en,
   output wire pxie_sync_en,
`endif

   // Note: PERST is externally wired to ground on MTCA boards
   input wire pxie_perst,

   // Note: STARB is left unconnected on MTCA boards, so no ifdefing of the whole STARB trigger module is needed
   input wire [1:0] pxie_starb_p, // Routed to dual differential inputs for higher trigger precision via IDELAY/ISERDES
   input wire [1:0] pxie_starb_n, // Only one input should be 100-ohm terminated

   // MTCA signals
`ifdef MTCA
   input wire [3:0] mlvds_rx_i, // Note: the numbering 3:0 corresponds to fabric 20:17 in the MTCA standard
   input wire [3:0] mlvds_tx_i,
   output wire [3:0] mlvds_rx_o,
   output wire [3:0] mlvds_tx_o,

   output wire pp_10m_en,
   output wire pp_pll_cs_n,

   output wire mmc_rst,
   output wire mmc_progen_n,
   output wire mmc_uart_o,
   input wire mmc_uart_i,
   output wire mmc_sck,

   output wire mmc_sdat,
   output wire mmc_sclk,

   input wire [3:0] pp_rx_n,
   input wire [3:0] pp_rx_p,
   output wire [3:0] pp_tx_p,
   output wire [3:0] pp_tx_n,
`endif

   // Frontend
   input wire pol_sense,
   output wire [1:0] sense_sel,

   // PLL/Clocking control
   output wire pll2_clksel,
   output wire pll_sync,
   output wire pxie_refsel,
   output wire xo_vcsel,

   // Trigger
   output wire trig_out,
   output wire trig_out_en_n,
   inout wire trigout_od1_io,
   inout wire trigout_od2_io,

   output wire clkbufout_en_n,
   output wire clkrefout_en_n,

   input wire [3:0] exttrig_p, // Note: Polarity is inversed on exttrig_p[1:0]
   input wire [3:0] exttrig_n, // Note: Polarity is inversed on exttrig_n[1:0]

   // Multiboard sync
   input wire sync_gpio_in,
   output wire sync_out,
   output wire sync_out_en_n,

   // DC/DC regulator control
   output reg dcdcsync_sync_neg = 1'b0,// 1 MHz nominal
   output reg dcdcsync_ltm4633 = 1'b0, // 600 kHz nominal
   output reg dcdcsync_ltm4644 = 1'b0, // 1 MHz nominal
   output wire [5:0] vsel,

`ifdef OCT
   // ADQ14OCT over voltage protection
   output wire reset_ovp_n,
   input wire neg_ov,
   input wire pos_ov,
`endif

   // LEDs
   output wire led_stat, // Red
   output wire led_rdy, // Yellow
   output wire led_pwr, // Green
   output wire led_rsvd_n, // Blue

   input wire pxie_atnled_r,

   // GPIO daughterboard
   inout wire gpio_scl,
   inout wire gpio_sda,

   inout wire [7:0] gpio_p,
   inout wire [7:0] gpio_n,

   inout wire [4:0] gpioctrl_r
   );


   /* Wires / Registers */

   // Clocks
   wire                               clk_cpu; // 100 MHz
   wire                               clk_mem; // 171 MHz
   wire                               clk_idelay; // 200 MHz
   wire                               pcie_sys_clk;
`ifdef PCIE_AXI
   wire                               clk_pcie; //250 MHz (AXI only)
`endif
   // Resets
   wire                               rst_clk_cpu;
   wire                               rst_clk_mem;
   wire                               rst_clk_idelay; // Noodlefish
   wire                               pci_app_rdy;

   // SPD: User register inteface
   wire [32*4-1:0]                    usr_reg_vect_in;
   wire                               usr_dry;
   wire                               usr_ack;
   wire [32*2-1:0]                    usr_reg_vect_out;

    // SPD USER Fast-access FIFOs
   wire                               usr_fifo_reset;

   wire [32-1:0]                      usr_fifo_in_avail;
   wire [32-1:0]                      usr_fifo_in_data;
   wire                               usr_fifo_in_write;

   wire [32-1:0]                      usr_fifo_out_avail;
   wire [32-1:0]                      usr_fifo_out_data;
   wire                               usr_fifo_out_read;

   // SPI signals
   wire [31:0]                        spi_ss;
   wire                               spi_sdio_t;
   wire                               spi_miso_sel;
   wire                               spi_mosi;
   wire                               spi_miso;

   // SPI QUAD signals
   wire                               spi_quad_sclk;
`ifdef EN_CFGPINS
   wire [3:0]                         spi_quad_i;
   wire [3:0]                         spi_quad_o;
   wire [3:0]                         spi_quad_t;
`endif

   // I2C signals
   wire                               iic_rtl_scl_i;
   wire                               iic_rtl_scl_o;
   wire                               iic_rtl_scl_t;
   wire                               iic_rtl_sda_i;
   wire                               iic_rtl_sda_o;
   wire                               iic_rtl_sda_t;

   wire                               iic_gpio_scl_i;
   wire                               iic_gpio_scl_o;
   wire                               iic_gpio_scl_t;
   wire                               iic_gpio_sda_i;
   wire                               iic_gpio_sda_o;
   wire                               iic_gpio_sda_t;

   // Misc signals
   wire [3:0]                         power_down;
   wire [11:0]                        temperature;

   // GPIO
   wire [15:0]                        gpio_out;
   wire [15:0]                        gpio_in;
   wire [15:0]                        gpio_dir;
   wire [4:0]                         gpio_ctrl_out;
   wire [4:0]                         gpio_ctrl_in;
   wire [4:0]                         gpio_ctrl_dir;

   // PXIe triggers (not instantiated on MTCA)
   `ifndef MTCA
      wire                               pxi_trig0_i;
      wire                               pxi_trig0_o;
      wire                               pxi_trig1_i;
      wire                               pxi_trig1_o;

      IOBUF IOBUF_pxitrig0_inst
         (
         .O(pxi_trig0_i), // Buffer output, FPGA input
         .IO(pxi_trig0), // Buffer inout port (connect directly to top-level port)
         .I(pxi_trig0_o), // Buffer input, FPGA output
         .T(~pxi_trig0_dir) // 3-state enable input, high=input, low=output
         );

      IOBUF IOBUF_pxitrig1_inst
         (
         .O(pxi_trig1_i), // Buffer output, FPGA input
         .IO(pxi_trig1), // Buffer inout port (connect directly to top-level port)
         .I(pxi_trig1_o), // Buffer input, FPGA output
         .T(~pxi_trig1_dir) // 3-state enable input, high=input, low=output
         );

   `endif

   // IBUFGDS for DRAM clocks
   wire  c0_ddr3_sys_clk_in;
   wire  c1_ddr3_sys_clk_in;
   wire  ddr3_sys_clk_buf;
   wire  ddr3_sys_clk_buf1;
   IBUFGDS ibufgds_c0
     (
      .I  (c0_ddr3_sys_clk_p),
      .IB (c0_ddr3_sys_clk_n),
      .O  (c0_ddr3_sys_clk_in)
      );
   IBUFGDS ibufgds_c1
     (
      .I  (c1_ddr3_sys_clk_p),
      .IB (c1_ddr3_sys_clk_n),
      .O  (c1_ddr3_sys_clk_in)
      );

   BUFG bufg_uart_clk
     (
      .I  (c0_ddr3_sys_clk_in),
      .O  (ddr3_sys_clk_buf)
      );

`ifdef ENABLE_ETH
   // Used for xaui dclk, probably possible to use ddr3_sys_clk_buf instead
   BUFG bufg_xaui_clk
     (
      .I  (c1_ddr3_sys_clk_in),
      .O  (ddr3_sys_clk_buf1)
      );
`endif


   /* Data clock generator */
   wire                               data_clock_reset;
   wire                               data_clock_locked;
   wire                               clk_data;
   wire                               clk_data_div2;
   wire                               clk_iserdes_io;
   wire                               clk_iserdes_div;
   wire                               clk_data_idelay;
   data_clock_generator data_clock_generator_inst
     (
      .rst_i(data_clock_reset),
      .glblclk_p_i(fpga_glblclk_p),
      .glblclk_n_i(fpga_glblclk_n),
      .clk_data_o(clk_data),
      .clk_data_div2_o(clk_data_div2),
      .clk_iserdes_io_o(clk_iserdes_io),
      .clk_iserdes_div_o(clk_iserdes_div),
      .clk_idelay_o(clk_data_idelay),
      .locked_o(data_clock_locked)
      );


`ifndef ENABLE_ETH
 `ifndef PCIE_AXI
   /* STARTUP module */

   wire                               startup_eos;
   STARTUPE2
     #(
       .PROG_USR("FALSE"),  // Activate program event security feature. Requires encrypted bitstreams.
       .SIM_CCLK_FREQ(0.0)  // Set the Configuration Clock Frequency(ns) for simulation.
       )
   STARTUPE2_inst
     (
      .CFGCLK(),       // 1-bit output: Configuration main clock output
      .CFGMCLK(),     // 1-bit output: Configuration internal oscillator clock output
      .EOS(startup_eos),             // 1-bit output: Active high output signal indicating the End Of Startup.
      .PREQ(),           // 1-bit output: PROGRAM request to fabric output
      .CLK(1'b0),             // 1-bit input: User start-up clock input
      .GSR(1'b0),             // 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
      .GTS(1'b0),             // 1-bit input: Global 3-state input (GTS cannot be used for the port name)
      .KEYCLEARB(1'b0), // 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
      .PACK(1'b0),           // 1-bit input: PROGRAM acknowledge input
      .USRCCLKO(spi_quad_sclk),   // 1-bit input: User CCLK input
      .USRCCLKTS(1'b0), // 1-bit input: User CCLK 3-state enable input
      .USRDONEO(1'b1),   // 1-bit input: User DONE pin output control
      .USRDONETS(1'b0)  // 1-bit input: User DONE 3-state enable output
      );
  `endif
`endif /* ENABLE_ETH */

`ifndef EN_CFGPINS
   assign spi_quad_sclk = 1'b0;
`endif

`ifndef ENABLE_ETH
     /* PCIE Interface */
     wire                               pxie_ref_clk;
     wire                               clk_transfer;

      wire [7:0] pcie_drpen;
      wire [7:0] pcie_drprdy;
      wire [7:0] pcie_drpwe;
      wire [16*8-1:0] pcie_drpdo;
      wire [16*8-1:0] pcie_drpdi;
      wire [9*8-1:0] pcie_drpaddr;

      wire [31:0] pcie_status_reg;

  `ifndef EN_PCIE_LOOPBACK

     wire                               host_write_wr;
     wire [`PCI_EXP_TRN_DATA_WIDTH-1:0] host_write_data;
     wire                               host_write_afull;

     wire                               host_read_reset_clk_transfer;
     wire                               host_read_reset;
     wire                               host_read_afull;
     wire                               host_read_wr;
     wire [`PCI_EXP_TRN_DATA_WIDTH-1:0] host_read_data;

  `else

     wire [`PCI_EXP_TRN_DATA_WIDTH-1:0] rx_data;
     wire                               rx_data_wr;
     wire [`PCI_EXP_TRN_DATA_WIDTH-1:0] dma_data;
     wire                               dma_data_wr;
     wire                               data_fifo_0_empty;


     data_fifo_0 data_fifo_0_inst
       (
        .clk(clk_cpu),
        .rst(rst_clk_cpu),
        .wr_en(rx_data_wr),
        .rd_en(~data_fifo_0_empty),
        .din(rx_data),
        .dout(dma_data),
        .full(),
        .empty(data_fifo_0_empty)
        );
     assign dma_data_wr  = ~data_fifo_0_empty;

  `endif
`else
   wire                               clk_transfer;
   wire                               host_write_wr;
   wire [`PCI_EXP_TRN_DATA_WIDTH-1:0] host_write_data;
   wire                               host_write_afull;

   wire                               host_read_reset_clk_transfer;
   wire                               host_read_reset;
   wire                               host_read_afull;
   wire                               host_read_wr;
   wire [`PCI_EXP_TRN_DATA_WIDTH-1:0] host_read_data;
`endif

   wire pxie_perst_poweron;

`ifndef ENABLE_ETH

`ifdef PCIE_AXI
    wire pcie_sys_clk_buf;
    IBUFDS_GTE2 refclk_ibuf (.O(pcie_sys_clk), .ODIV2(), .I(mgtrefclk_p), .CEB(1'b0), .IB(mgtrefclk_n));
    BUFG        refclk_bufg (.O(pcie_sys_clk_buf), .I(pcie_sys_clk));
`else
    xilinx_pcie_top  xilinx_pcie_top_inst
     (
     `ifndef MTCA
      .pci_exp_txp(tx_p),
      .pci_exp_txn(tx_n),
      .pci_exp_rxp(rx_p),
      .pci_exp_rxn(rx_n),
      `else
      .pci_exp_txp({pp_tx_p, tx_p}), // TEMPORARY FIX TO AVOID CHANGING PCIE WIDTH
      .pci_exp_txn({pp_tx_n, tx_n}),
      .pci_exp_rxp({pp_rx_p, rx_p}),
      .pci_exp_rxn({pp_rx_n, rx_n}),
      `endif

      .sys_clk_p(mgtrefclk_p),
      .sys_clk_n(mgtrefclk_n),
      .sys_rst_n(pxie_perst_poweron),
      .startup_eos(startup_eos),
      .ref_clk(pxie_ref_clk),
      .user_clk(clk_transfer),
      .pci_app_rdy_o(pci_app_rdy),

`ifndef EN_PCIE_LOOPBACK
      // SPD: DMA fifo
      .usr_dma_clk_i(clk_transfer),
      .usr_dma_rst_i(host_read_reset_clk_transfer),
      .usr_dma_data_i(host_read_data),
      .usr_dma_wr_i(host_read_wr),
      .usr_dma_afull_o(host_read_afull),

      // RX Data interface
      .usr_rx_data_o(host_write_data),
      .usr_rx_addr_o(),
      .usr_rx_wr_o(host_write_wr),
`else
      // SPD: DMA fifo
      .usr_dma_clk_i(clk_cpu),
      .usr_dma_rst_i(rst_clk_cpu|pcie_dma_fifo_rst),
      .usr_dma_data_i(dma_data),
      .usr_dma_wr_i(dma_data_wr),
      .usr_dma_afull_o(),

      // RX Data interface
      .usr_rx_data_o(rx_data),
      .usr_rx_addr_o(),
      .usr_rx_wr_o(rx_data_wr),
`endif /* EN_PCIE_LOOPBACK */

      // SPD: User register inteface
      .usr_reg_vect_o(usr_reg_vect_in),
      .usr_dry_o(usr_dry),
      .usr_ack_i(usr_ack),
      .usr_reg_vect_i(usr_reg_vect_out),

      // SPD USER Fast-access FIFOs

      .usr_fifo_reset_o(usr_fifo_reset),

      .usr_fifo_in_avail_i(usr_fifo_in_avail),
      .usr_fifo_in_data_o(usr_fifo_in_data),
      .usr_fifo_in_write_o(usr_fifo_in_write),

      .usr_fifo_out_avail_i(usr_fifo_out_avail),
      .usr_fifo_out_data_i(usr_fifo_out_data),
      .usr_fifo_out_read_o(usr_fifo_out_read),

      .ext_ch_gt_drpclk                           (clk_cpu),
      .ext_ch_gt_drpaddr                          (pcie_drpaddr),
      .ext_ch_gt_drpen                            (pcie_drpen),
      .ext_ch_gt_drpdi                            (pcie_drpdi),
      .ext_ch_gt_drpwe                            (pcie_drpwe),
      .ext_ch_gt_drpdo                            (pcie_drpdo),
      .ext_ch_gt_drprdy                           (pcie_drprdy),

      .pcie_status_reg_o                          (pcie_status_reg),

      .sys_clk_o(pcie_sys_clk)
      );
`endif
`else /* ENABLE_ETH */

    wire clk156_out;
    wire clk156_lock;
    wire rst_clk_eth;
    wire rst_clk_xaui;

    // Satus and config vectors
    wire [5:0] xaui_debug;
    wire [7:0] xaui_status_vector;
    reg [6:0] xaui_configuration_vector;

    wire xaui_link_up_o;

    wire s_axi_aclk_eth_udp;
    wire s_axi_aresetn_eth_udp;
    wire [`ETH_UDP_AXI_ADDR_WIDTH-1:0] s_axi_awaddr_eth_udp;
    wire [2:0] s_axi_awprot_eth_udp;
    wire s_axi_awvalid_eth_udp;
    wire s_axi_awready_eth_udp;
    wire [`ETH_UDP_AXI_DATA_WIDTH-1:0] s_axi_wdata_eth_udp;
    wire [`ETH_UDP_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb_eth_udp;
    wire s_axi_wvalid_eth_udp;
    wire s_axi_wready_eth_udp;
    wire [1:0] s_axi_bresp_eth_udp;
    wire s_axi_bvalid_eth_udp;
    wire s_axi_bready_eth_udp;
    wire [`ETH_UDP_AXI_ADDR_WIDTH-1:0] s_axi_araddr_eth_udp;
    wire [2:0] s_axi_arprot_eth_udp;
    wire s_axi_arvalid_eth_udp;
    wire s_axi_arready_eth_udp;
    wire [`ETH_UDP_AXI_DATA_WIDTH-1:0] s_axi_rdata_eth_udp;
    wire [1:0] s_axi_rresp_eth_udp;
    wire s_axi_rvalid_eth_udp;
    wire s_axi_rready_eth_udp;

    wire usr_ack_sync;
    wire usr_dry_sync;

    assign clk_transfer = clk156_out;

    // Reset phy after power up for proper operation
    wire phy_rst;
    assign pxie_alert = phy_rst;

    cdc_sync_gen7 #(.NofStages(3)) cdc_sync_gen7_usr_ack_inst(
      .clk(clk156_out),
      .data_i(usr_ack),
      .sync_o(usr_ack_sync)
    );

    cdc_sync_gen7 #(.NofStages(3)) cdc_sync_gen7_usr_dry_inst (
      .clk(clk_cpu),
      .data_i(usr_dry),
      .sync_o(usr_dry_sync)
    );

    wire [63:0] xgmii_txd;
    wire [63:0] xgmii_rxd;
    wire [7:0]  xgmii_txc;
    wire [7:0]  xgmii_rxc;

    ethernet_xaui ethernet_xaui_inst (
       .dclk(ddr3_sys_clk_buf1),  // input wire dclk
       .reset(rst_clk_xaui),      // input wire reset
       .clk156_out(clk156_out),   // output wire clk156_out
       .refclk_p(mgtrefclk2_p),   // input wire refclk_p
       .refclk_n(mgtrefclk2_n),   // input wire refclk_n
       .clk156_lock(clk156_lock), // output wire clk156_lock
       .xgmii_txd(xgmii_txd),     // input wire [63 : 0] xgmii_txd
       .xgmii_txc(xgmii_txc),     // input wire [7 : 0] xgmii_txc
       .xgmii_rxd(xgmii_rxd),     // output wire [63 : 0] xgmii_rxd
       .xgmii_rxc(xgmii_rxc),     // output wire [7 : 0] xgmii_rxc
       .xaui_tx_l0_p(tx_p[4]),    // output wire xaui_tx_l0_p
       .xaui_tx_l0_n(tx_n[4]),    // output wire xaui_tx_l0_n
       .xaui_tx_l1_p(tx_p[5]),    // output wire xaui_tx_l1_p
       .xaui_tx_l1_n(tx_n[5]),    // output wire xaui_tx_l1_n
       .xaui_tx_l2_p(tx_p[6]),    // output wire xaui_tx_l2_p
       .xaui_tx_l2_n(tx_n[6]),    // output wire xaui_tx_l2_n
       .xaui_tx_l3_p(tx_p[7]),    // output wire xaui_tx_l3_p
       .xaui_tx_l3_n(tx_n[7]),    // output wire xaui_tx_l3_n
       .xaui_rx_l0_p(rx_p[4]),    // input wire xaui_rx_l0_p
       .xaui_rx_l0_n(rx_n[4]),    // input wire xaui_rx_l0_n
       .xaui_rx_l1_p(rx_p[5]),    // input wire xaui_rx_l1_p
       .xaui_rx_l1_n(rx_n[5]),    // input wire xaui_rx_l1_n
       .xaui_rx_l2_p(rx_p[6]),    // input wire xaui_rx_l2_p
       .xaui_rx_l2_n(rx_n[6]),    // input wire xaui_rx_l2_n
       .xaui_rx_l3_p(rx_p[7]),    // input wire xaui_rx_l3_p
       .xaui_rx_l3_n(rx_n[7]),    // input wire xaui_rx_l3_n
       .signal_detect(4'b1111),  // input wire [3 : 0] signal_detect
       .debug(xaui_debug),                  // output wire [5 : 0] debug
       .configuration_vector(xaui_configuration_vector),
       .status_vector(xaui_status_vector)
    );

   wire s_axis_tready;
   wire [63:0] s_axis_tdata;
   wire s_axis_tvalid;
   wire eth_buffer_empty;
   wire eth_buffer_rd_en;
   wire eth_buffer_wr_en;
   wire eth_buffer_afull;
   wire eth_buffer_progfull;
   wire eth_buffer_full;

   assign s_axis_tvalid = ~eth_buffer_empty;
   assign eth_buffer_rd_en = ~eth_buffer_empty & s_axis_tready;
   assign eth_buffer_wr_en = host_read_wr;
   assign host_read_afull = eth_buffer_progfull;

   `ifdef PCIE_128
      fifo_128to64_x512 eth_buffer_inst (
        .rst(host_read_reset_clk_transfer), // input wire rst
        .wr_clk(clk_transfer),            // input wire wr_clk
        .rd_clk(clk_transfer),            // input wire rd_clk
        .din({host_read_data[63:0], host_read_data[127:64]}),                  // input wire [127 : 0] din
        .wr_en(eth_buffer_wr_en),              // input wire wr_en
        .rd_en(eth_buffer_rd_en),              // input wire rd_en
        .dout(s_axis_tdata),                // output wire [63 : 0] dout
        .full(eth_buffer_full),                         // output wire full
        .almost_full(eth_buffer_afull),  // output wire almost_full
        .empty(eth_buffer_empty),              // output wire empty
        .prog_full(eth_buffer_progfull)      // output wire prog_full
      );
   `else
      ERROR__PCIE_width_not_supported_by_ethernet();
   `endif

   SPD_Ethernet_10G_v1_0 #(
      .C_s_axi_DATA_WIDTH(`ETH_UDP_AXI_DATA_WIDTH),
      .C_s_axi_ADDR_WIDTH(`ETH_UDP_AXI_ADDR_WIDTH)
   ) SPD_Ethernet_10G_v1_0_inst (
      .rx_clk_i(clk156_out),
      .tx_clk_i(clk156_out),
      .rx_rst_i(rst_clk_eth),
      .tx_rst_i(rst_clk_eth),
      .clk_data_i(clk_transfer), // = clk156_out

      .xgmii_rxd_i(xgmii_rxd),
      .xgmii_rxc_i(xgmii_rxc),
      .xgmii_txd_o(xgmii_txd),
      .xgmii_txc_o(xgmii_txc),

      /* Microblaze command port */
      .mb_com_command_o(usr_reg_vect_in),
      .mb_com_dry_o(usr_dry),
      .mb_com_ack_i(usr_ack_sync),
      .mb_com_return_i(usr_reg_vect_out),

      .mb_com_fifo_reset_o(),

      .mb_com_fifo_in_avail_i(usr_fifo_in_avail),
      .mb_com_fifo_in_data_o(usr_fifo_in_data),
      .mb_com_fifo_in_write_o(usr_fifo_in_write),

      .mb_com_fifo_out_avail_i(usr_fifo_out_avail),
      .mb_com_fifo_out_data_i(usr_fifo_out_data),
      .mb_com_fifo_out_read_o(usr_fifo_out_read),

      /* Datapath */
      .s_axis_tdata_i(s_axis_tdata),
      .s_axis_tvalid_i(s_axis_tvalid),
      .s_axis_tlast_i(1'b0),
      .s_axis_tready_o(s_axis_tready),

      // Reset and clocking status
      .pcs_pma_qpll0lock_i(clk156_lock),

      // SFP+ MDIO
      .mdio_clk_o(pxie_smbc),
      .mdio_o(pxie_smbd),

      // Configuration
      .pcs_pma_configuration_vector_o(),
      .pma_pmd_type_o(),

      // Status
      .core_status_i(8'd0),
      .txuserrdy_i(clk156_lock), // QPLL locked signal synced to tx_clk

      .link_up_n(),
      .link_active_n(),

      // Reset
      .pcs_pma_reset_o(phy_rst),

      .resetn_interface_syncfifo_i(~host_read_reset_clk_transfer),


      // Do not modify the ports beyond this line
      // Ports of Axi Slave Bus Interface s_axi
      .s_axi_aclk(s_axi_aclk_eth_udp),
      .s_axi_aresetn(s_axi_aresetn_eth_udp),
      .s_axi_awaddr(s_axi_awaddr_eth_udp),
      .s_axi_awprot(s_axi_awprot_eth_udp),
      .s_axi_awvalid(s_axi_awvalid_eth_udp),
      .s_axi_awready(s_axi_awready_eth_udp),
      .s_axi_wdata(s_axi_wdata_eth_udp),
      .s_axi_wstrb(s_axi_wstrb_eth_udp),
      .s_axi_wvalid(s_axi_wvalid_eth_udp),
      .s_axi_wready(s_axi_wready_eth_udp),
      .s_axi_bresp(s_axi_bresp_eth_udp),
      .s_axi_bvalid(s_axi_bvalid_eth_udp),
      .s_axi_bready(s_axi_bready_eth_udp),
      .s_axi_araddr(s_axi_araddr_eth_udp),
      .s_axi_arprot(s_axi_arprot_eth_udp),
      .s_axi_arvalid(s_axi_arvalid_eth_udp),
      .s_axi_arready(s_axi_arready_eth_udp),
      .s_axi_rdata(s_axi_rdata_eth_udp),
      .s_axi_rresp(s_axi_rresp_eth_udp),
      .s_axi_rvalid(s_axi_rvalid_eth_udp),
      .s_axi_rready(s_axi_rready_eth_udp)
   );

   // Requried to clear the error bits in xaui status vector
   reg [4:0] xaui_config_counter = 5'b1;
   always@(posedge clk156_out) begin
     if(rst_clk_eth)
       xaui_configuration_vector <= 7'b0;
     else if(~xaui_link_up_o) begin
       if (xaui_config_counter == 5'b0)
         xaui_configuration_vector <= 7'b0001100;
       else
         xaui_configuration_vector <= 7'b0;

       xaui_config_counter <= xaui_config_counter + 1;
     end
   end

   cdc_register cdc_sync_usr_fifo_reset (
      .clk_i(clk_transfer),
      .d_i(rst_clk_eth),
      .q_o(usr_fifo_reset)
   );

   assign host_write_data = {`PCI_EXP_TRN_DATA_WIDTH{1'b0}};
   assign host_write_wr = 1'b0;
`endif /* ENABLE_ETH */

   wire [1:0]                         dram_error;
   wire [1:0]                         dram_phy_init_done;
   wire [1:0]                         dram_use_tb;
   wire                               mcu2dram_rst;
   wire [31:0]                        dram_ctrl_reg;
   wire [31:0]                        dram_status_reg;
   wire [31:0]                        dram_status_reg_sync;
   wire                               dram_present;

`ifdef EN_DRAM
   assign dram_present = 1;
`else
   assign dram_present = 0;
`endif


   // Dram control and status
   cdc_register cdc_sync_use_tb1 (.clk_i(app_clk1), .d_i(dram_ctrl_reg[1]   ), .q_o(dram_use_tb[0]) );
   cdc_register cdc_sync_use_tb2 (.clk_i(app_clk2), .d_i(dram_ctrl_reg[16+1]), .q_o(dram_use_tb[1]) );

   assign mcu2dram_rst    = dram_ctrl_reg[0];
   assign dram_status_reg = {~dram_present, // 1=DRAM not present, 0=DRAM is present
                             13'd0,
                             dram_error[1],
                             dram_phy_init_done[1],
                             ~dram_present, // 1=DRAM not present, 0=DRAM is present
                             13'd0,
                             dram_error[0],
                             dram_phy_init_done[0]};

   cdc_register #(.WIDTH(32)) cdc_sync_dram_status (.clk_i(clk_cpu), .d_i(dram_status_reg), .q_o(dram_status_reg_sync));

   // Dram debug
   wire [31:0]                        dram_dbg_reg0;
   wire [31:0]                        dram_dbg_reg0_sync;
   wire [31:0]                        dram_dbg_reg1;
   wire [31:0]                        dram_dbg_reg2;
   wire [31:0]                        dram_dbg_reg3;
   wire [31:0]                        dram_dbg_reg4;

   cdc_register #(.WIDTH(32)) cdc_sync_dram_dbg0 (.clk_i(clk_cpu), .d_i(dram_dbg_reg0), .q_o(dram_dbg_reg0_sync));

`ifndef dram_debug
   assign dram_dbg_reg1 = 0;
`endif

   /**** DRAM controller ****/
   // Application interface, bank 1
   wire                          app_clk1;
   wire                          app_wdf_full1;
   wire                          app_wdf_wren1;
   wire [(8*`DRAM_DQ_WIDTH)-1:0] app_wdf_data1;
   wire                          app_wdf_end1;

   wire                          app_full1;
   wire                          app_en1;
   wire [2:0]                    app_cmd1;
   wire [`DRAM_ADDR_WIDTH-1:0]   tg_addr1;

   wire [(8*`DRAM_DQ_WIDTH)-1:0] app_rd_data1;
   wire                          app_rd_data_valid1;

   // Application interface, bank 2
   wire                          app_clk2;
   wire                          app_wdf_full2;
   wire                          app_wdf_wren2;
   wire [(8*`DRAM_DQ_WIDTH)-1:0] app_wdf_data2;
   wire                          app_wdf_end2;

   wire                          app_full2;
   wire                          app_en2;
   wire [2:0]                    app_cmd2;
   wire [`DRAM_ADDR_WIDTH-1:0]   tg_addr2;

   wire [(8*`DRAM_DQ_WIDTH)-1:0] app_rd_data2;
   wire                          app_rd_data_valid2;
   wire                          rst_dram;
   wire                          rst_dram_from_power_down;


   reg rst_clk_idelay_reg = 1'b1;
`ifdef EN_DRAM
   dram_controller_ddr3 dram_controller_inst
     (
      .clk_iodelay_i                     (clk_idelay),
      .rst_i                             (rst_dram), // | rst_dram_from_power_down),
      .device_temp_i                     (temperature),
    `ifdef dram_debug
      .dbg_reg0_o                        (dram_dbg_reg0),
      .dbg_reg1_i                        (dram_dbg_reg1),
      .dbg_reg2_o                        (dram_dbg_reg2),
      .dbg_reg3_o                        (dram_dbg_reg3),
      .dbg_reg4_o                        (dram_dbg_reg4),
    `endif
      .use_tb1_i                         (dram_use_tb[0]),
      .use_tb2_i                         (dram_use_tb[1]),

      .c0_ddr3_dq                        (c0_ddr3_dq),
      .c0_ddr3_dqs_n                     (c0_ddr3_dqs_n),
      .c0_ddr3_dqs_p                     (c0_ddr3_dqs_p),
      .c0_ddr3_addr                      (c0_ddr3_addr),
      .c0_ddr3_ba                        (c0_ddr3_ba),
      .c0_ddr3_ras_n                     (c0_ddr3_ras_n),
      .c0_ddr3_cas_n                     (c0_ddr3_cas_n),
      .c0_ddr3_we_n                      (c0_ddr3_we_n),
      .c0_ddr3_reset_n                   (c0_ddr3_reset_n),
      .c0_ddr3_ck_n                      (c0_ddr3_ck_n),
      .c0_ddr3_ck_p                      (c0_ddr3_ck_p),
      .c0_ddr3_cke                       (c0_ddr3_cke),
      .c0_ddr3_odt                       (c0_ddr3_odt),
      .c0_sys_clk_i                      (c0_ddr3_sys_clk_in),

      .c1_ddr3_dq                        (c1_ddr3_dq),
      .c1_ddr3_dqs_n                     (c1_ddr3_dqs_n),
      .c1_ddr3_dqs_p                     (c1_ddr3_dqs_p),
      .c1_ddr3_addr                      (c1_ddr3_addr),
      .c1_ddr3_ba                        (c1_ddr3_ba),
      .c1_ddr3_ras_n                     (c1_ddr3_ras_n),
      .c1_ddr3_cas_n                     (c1_ddr3_cas_n),
      .c1_ddr3_we_n                      (c1_ddr3_we_n),
      .c1_ddr3_reset_n                   (c1_ddr3_reset_n),
      .c1_ddr3_ck_n                      (c1_ddr3_ck_n),
      .c1_ddr3_ck_p                      (c1_ddr3_ck_p),
      .c1_ddr3_cke                       (c1_ddr3_cke),
      .c1_ddr3_odt                       (c1_ddr3_odt),
      .c1_sys_clk_i                      (c1_ddr3_sys_clk_in),

      .clk1_o(app_clk1),
      .app_wdf_wren1(app_wdf_wren1),
      .app_wdf_data1(app_wdf_data1),
      .app_wdf_end1(app_wdf_end1),
      .app_cmd1(app_cmd1),
      .app_en1(app_en1),
      .app_full1(app_full1),
      .app_wdf_full1(app_wdf_full1),
      .app_rd_data1(app_rd_data1),
      .app_rd_data_valid1(app_rd_data_valid1),
      .tg_addr1(tg_addr1),//_remap
      .error1(dram_error[0]),
      .phy_init_done1(dram_phy_init_done[0]),

      .clk2_o(app_clk2),
      .app_wdf_wren2(app_wdf_wren2),
      .app_wdf_data2(app_wdf_data2),
      .app_wdf_end2(app_wdf_end2),
      .app_cmd2(app_cmd2),
      .app_en2(app_en2),
      .app_full2(app_full2),
      .app_wdf_full2(app_wdf_full2),
      .app_rd_data2(app_rd_data2),
      .app_rd_data_valid2(app_rd_data_valid2),
      .tg_addr2(tg_addr2),//_remap
      .error2(dram_error[1]),
      .phy_init_done2(dram_phy_init_done[1])
    );
`endif

   cdc_register cdc_sync_host_read_reset_sync_inst (.clk_i(clk_transfer), .d_i(host_read_reset), .q_o(host_read_reset_clk_transfer));

  /* JESD204B Interface */
   wire rx_sync;
   wire rx_sysref;

   IBUFDS
     #(
       .DIFF_TERM("FALSE"), // Differential Termination
       .IBUF_LOW_PWR("TRUE"), // Low power="TRUE", Highest performance="FALSE"
       .IOSTANDARD("DEFAULT") // Specify the input I/O standard
       ) IBUFDS_rx_sysref
       (
        .O(rx_sysref),
        .I(fpga_sysref_p),
        .IB(fpga_sysref_n)
        );

   OBUFDS
     #(
       .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
       .SLEW("SLOW") // Specify the output slew rate
       ) OBUFDS_rx_sync1
       (
        .O(adc1_sync_p),
        .OB(adc1_sync_n),
        .I(rx_sync)
        );
   OBUFDS
     #(
       .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
       .SLEW("SLOW") // Specify the output slew rate
       ) OBUFDS_rx_sync2
       (
        .O(adc2_sync_n),
        .OB(adc2_sync_p),
        .I(~rx_sync)
        );

   wire led_rsvd;
   assign led_rsvd_n = ~led_rsvd;

`ifdef OCT
   wire oct_reset_ovp_n;
   wire oct_neg_ov;
   wire oct_pos_ov;
`endif

`ifdef OCTX
   wire octx_kclk_att;
`endif

   wire [0:0] interrupt;
   wire pcie_dma_fifo_rst;

`ifndef ENABLE_ETH
   assign interrupt = usr_dry;
`else
   assign interrupt = usr_dry_sync;
`endif /* ENABLE_ETH */

   System_wrapper system_inst
     (
    `ifdef ENABLE_ETH
      .s_axi_aclk_eth_udp_o(s_axi_aclk_eth_udp),
      .s_axi_aresetn_eth_udp_o(s_axi_aresetn_eth_udp),
      .s_axi_awaddr_eth_udp_o(s_axi_awaddr_eth_udp),
      .s_axi_awprot_eth_udp_o(s_axi_awprot_eth_udp),
      .s_axi_awvalid_eth_udp_o(s_axi_awvalid_eth_udp),
      .s_axi_awready_eth_udp_i(s_axi_awready_eth_udp),
      .s_axi_wdata_eth_udp_o(s_axi_wdata_eth_udp),
      .s_axi_wstrb_eth_udp_o(s_axi_wstrb_eth_udp),
      .s_axi_wvalid_eth_udp_o(s_axi_wvalid_eth_udp),
      .s_axi_wready_eth_udp_i(s_axi_wready_eth_udp),
      .s_axi_bresp_eth_udp_i(s_axi_bresp_eth_udp),
      .s_axi_bvalid_eth_udp_i(s_axi_bvalid_eth_udp),
      .s_axi_bready_eth_udp_o(s_axi_bready_eth_udp),
      .s_axi_araddr_eth_udp_o(s_axi_araddr_eth_udp),
      .s_axi_arprot_eth_udp_o(s_axi_arprot_eth_udp),
      .s_axi_arvalid_eth_udp_o(s_axi_arvalid_eth_udp),
      .s_axi_arready_eth_udp_i(s_axi_arready_eth_udp),
      .s_axi_rdata_eth_udp_i(s_axi_rdata_eth_udp),
      .s_axi_rresp_eth_udp_i(s_axi_rresp_eth_udp),
      .s_axi_rvalid_eth_udp_i(s_axi_rvalid_eth_udp),
      .s_axi_rready_eth_udp_o(s_axi_rready_eth_udp),
    `endif /* ENABLE_ETH */
      .Clk(clk_cpu),
      .interrupt1(interrupt),
      .reset_rtl(rst_clk_cpu),

      .refclk_p(fpga_gtxref_ac_p),
      .refclk_n(fpga_gtxref_ac_n),

      .ref10m_i(clk10m_fpga),

      .data_clock_reset_o(data_clock_reset),
      .data_clock_locked_i(data_clock_locked),
      .clk_data_i(clk_data),
      .clk_data_div2_i(clk_data_div2),
      .clk_iserdes_io_i(clk_iserdes_io),
      .clk_iserdes_div_i(clk_iserdes_div),

      .rxp({adc2_d_p, adc1_d_p}),
      .rxn({adc2_d_n, adc1_d_n}),
      .rx_sysref(rx_sysref),
      .rx_sync(rx_sync),

      .usr_reg_vect_i(usr_reg_vect_in),
      .usr_ack_o(usr_ack),
      .usr_reg_vect_o(usr_reg_vect_out),

      .clk_transfer_i(clk_transfer),
      `ifndef ENABLE_ETH
        .rst_clk_transfer_i(~pci_app_rdy),
        .usr_dry_i(usr_dry),
      `else
        .rst_clk_transfer_i(rst_clk_eth),
        .usr_dry_i(usr_dry_sync),
      `endif

`ifdef PCIE_AXI
        .pcie_gt_rxn(rx_n),
        .pcie_gt_rxp(rx_p),
        .pcie_gt_txn(tx_n),
        .pcie_gt_txp(tx_p),
        .pcie_perstn(pxie_perst_poweron),
        .pcie_refclk(pcie_sys_clk),
        .pcie_linkup(pci_app_rdy),
        .clk_pcie_o(clk_pcie),
`endif
      .usr_fifo_reset_i(usr_fifo_reset),

      .usr_fifo_in_avail_o(usr_fifo_in_avail),
      .usr_fifo_in_data_i(usr_fifo_in_data),
      .usr_fifo_in_write_i(usr_fifo_in_write),

      .usr_fifo_out_avail_o(usr_fifo_out_avail),
      .usr_fifo_out_data_o(usr_fifo_out_data),
      .usr_fifo_out_read_i(usr_fifo_out_read),

      .temperature_o(temperature),

      // Clocking control
      .pll2_clksel_o(pll2_clksel),
      .pll_sync_o(pll_sync),
      .pxie_refsel_o(pxie_refsel),
      .xo_vcsel_o(xo_vcsel),
      .clkrefout_en_n_o(clkrefout_en_n),
      .clkbufout_en_n_o(clkbufout_en_n),

      // Calibration
      .sense_sel_o(sense_sel),
      .pol_sense_i(pol_sense),

      // Triggers
      .clk_idelay_cal_i(clk_data_idelay),

      .ext_trig_p_pins(exttrig_p),
      .ext_trig_n_pins(exttrig_n),
      .pxie_starb_p_pins(pxie_starb_p),
      .pxie_starb_n_pins(pxie_starb_n),
`ifndef MTCA
      .pxie_starc_p(pxie_starc_p),
      .pxie_starc_n(pxie_starc_n),
      .pxie_stara(pxie_stara),
      .pxi_trig0_o(pxi_trig0_o),
      .pxi_trig1_o(pxi_trig1_o),
      .pxi_trig0_i(pxi_trig0_i),
      .pxi_trig1_i(pxi_trig1_i),
      .pxi_trig0_dir(pxi_trig0_dir),
      .pxi_trig1_dir(pxi_trig1_dir),
      .pxie_clken_o({pxie_100m_en, pxie_10m_en, pxie_sync_en}),
      .mlvds_rx_i(4'd0),
      .mlvds_rx_o(),
      .mlvds_tx_i(4'd0),
      .mlvds_tx_o(),
      .mmc_sclk_o(),
      .mmc_sdat_o(),
`else // !`ifndef MTCA
      .pxie_starc_p(),
      .pxie_starc_n(),
      .pxi_trig0_dir(),
      .pxi_trig1_dir(),
      .pxi_trig0_o(),
      .pxi_trig1_o(),
      .pxi_trig0_i(1'b0),
      .pxi_trig1_i(1'b0),
      .pxie_stara(1'b0),
      .pxie_clken_o(),
      .mlvds_rx_i(mlvds_rx_i),
      .mlvds_rx_o(mlvds_rx_o),
      .mlvds_tx_i(mlvds_tx_i),
      .mlvds_tx_o(mlvds_tx_o),
      .mmc_sclk_o(mmc_sclk),
      .mmc_sdat_o(mmc_sdat),
`endif
      .trigout_o(trig_out),
      .trigout_od1_io(trigout_od1_io),
      .trigout_od2_io(trigout_od2_io),
      .trig_out_en_n_o(trig_out_en_n),

      .sync_i(sync_gpio_in),

      .sync_o(sync_out),
      .sync_oe_n_o(sync_out_en_n),

      // General I/O
      .vsel_o(vsel), // XADC MUX
      .leds_o({led_rsvd,led_stat,led_rdy,led_pwr}),   //PANEL LEDs
      .power_down_o(power_down), // Power-down signal for ADCs and DDR3 clocks

      .dram_reg_i(dram_status_reg_sync),
      .dram_reg_o(dram_ctrl_reg), //DRAM control

      .uart_clk_i(ddr3_sys_clk_buf),
      .uart_rstn_i(~rst_clk_cpu),

`ifdef OCT
      .oct_reset_ovp_n_o (oct_reset_ovp_n),
      .oct_neg_ov_i      (oct_neg_ov),
      .oct_pos_ov_i      (oct_pos_ov),
`endif

`ifdef OCTX
      .octx_kclk_att_o   (octx_kclk_att),
`endif

      // Quad SPI bus
`ifdef EN_CFGPINS
      .spi_quad_io0_i(spi_quad_i[0]),
      .spi_quad_io0_o(spi_quad_o[0]),
      .spi_quad_io0_t(spi_quad_t[0]),
      .spi_quad_io1_i(spi_quad_i[1]),
      .spi_quad_io1_o(spi_quad_o[1]),
      .spi_quad_io1_t(spi_quad_t[1]),
      .spi_quad_io2_i(spi_quad_i[2]),
      .spi_quad_io2_o(spi_quad_o[2]),
      .spi_quad_io2_t(spi_quad_t[2]),
      .spi_quad_io3_i(spi_quad_i[3]),
      .spi_quad_io3_o(spi_quad_o[3]),
      .spi_quad_io3_t(spi_quad_t[3]),
      .spi_quad_ss_o(conf_cs_n),
      .spi_quad_sck_o(spi_quad_sclk),
`else
      .spi_quad_io0_i(1'b0),
      .spi_quad_io1_i(1'b0),
      .spi_quad_io2_i(1'b0),
      .spi_quad_io3_i(1'b0),

`endif

      // Unused SPI signals
      .spi_io0_i(1'b0),
      .spi_quad_sck_i(1'b0),
      .spi_quad_ss_i(1'b0),
      .spi_sck_i(1'b0),
      .spi_ss_i(32'd0),

      // Standard SPI bus
      .spi_io0_o(spi_mosi),
      .spi_io1_i(spi_miso_sel),
      .spi_ss_o(spi_ss),
      .spi_sck_o(spi_sclk),

      // I2C bus
      .iic_rtl_scl_i(iic_rtl_scl_i),
      .iic_rtl_scl_o(iic_rtl_scl_o),
      .iic_rtl_scl_t(iic_rtl_scl_t),
      .iic_rtl_sda_i(iic_rtl_sda_i),
      .iic_rtl_sda_o(iic_rtl_sda_o),
      .iic_rtl_sda_t(iic_rtl_sda_t),

      // I2C bus (daughterboard/gpio)
      .iic_gpio_scl_i(iic_gpio_scl_i),
      .iic_gpio_scl_o(iic_gpio_scl_o),
      .iic_gpio_scl_t(iic_gpio_scl_t),
      .iic_gpio_sda_i(iic_gpio_sda_i),
      .iic_gpio_sda_o(iic_gpio_sda_o),
      .iic_gpio_sda_t(iic_gpio_sda_t),

      // USB UART
      .usb_uart_rxd(u2f_txd),
      .usb_uart_txd(f2u_rxd),

      // GPIO
      .gpio_out_o(gpio_out),
      .gpio_in_i(gpio_in),
      .gpio_dir_o(gpio_dir),
      .gpio_ctrl_in_i(gpio_ctrl_in),
      .gpio_ctrl_dir_o(gpio_ctrl_dir),
      .gpio_ctrl_out_o(gpio_ctrl_out),

      // Memcomm
      .clk_mem_i(clk_mem),
      .rst_clk_mem_i(rst_clk_mem),

      //DRAM Debug
      .dram_dbg_reg0_i(dram_dbg_reg0_sync),
      .dram_dbg_reg1_o(dram_dbg_reg1),
      .dram_dbg_reg2_i(dram_dbg_reg2),
      .dram_dbg_reg3_i(dram_dbg_reg3),
      .dram_dbg_reg4_i(dram_dbg_reg4),

`ifndef ENABLE_ETH
      // PCIe GTX DRP buses
      .drp_pcie_0_daddr(pcie_drpaddr[0*9 +: 9]),
      .drp_pcie_0_den(pcie_drpen[0]),
      .drp_pcie_0_di(pcie_drpdi[0*16 +: 16]),
      .drp_pcie_0_do(pcie_drpdo[0*16 +: 16]),
      .drp_pcie_0_drdy(pcie_drprdy[0]),
      .drp_pcie_0_dwe(pcie_drpwe[0]),

      .drp_pcie_1_daddr(pcie_drpaddr[1*9 +: 9]),
      .drp_pcie_1_den(pcie_drpen[1]),
      .drp_pcie_1_di(pcie_drpdi[1*16 +: 16]),
      .drp_pcie_1_do(pcie_drpdo[1*16 +: 16]),
      .drp_pcie_1_drdy(pcie_drprdy[1]),
      .drp_pcie_1_dwe(pcie_drpwe[1]),

      .drp_pcie_2_daddr(pcie_drpaddr[2*9 +: 9]),
      .drp_pcie_2_den(pcie_drpen[2]),
      .drp_pcie_2_di(pcie_drpdi[2*16 +: 16]),
      .drp_pcie_2_do(pcie_drpdo[2*16 +: 16]),
      .drp_pcie_2_drdy(pcie_drprdy[2]),
      .drp_pcie_2_dwe(pcie_drpwe[2]),

      .drp_pcie_3_daddr(pcie_drpaddr[3*9 +: 9]),
      .drp_pcie_3_den(pcie_drpen[3]),
      .drp_pcie_3_di(pcie_drpdi[3*16 +: 16]),
      .drp_pcie_3_do(pcie_drpdo[3*16 +: 16]),
      .drp_pcie_3_drdy(pcie_drprdy[3]),
      .drp_pcie_3_dwe(pcie_drpwe[3]),

      .drp_pcie_4_daddr(pcie_drpaddr[4*9 +: 9]),
      .drp_pcie_4_den(pcie_drpen[4]),
      .drp_pcie_4_di(pcie_drpdi[4*16 +: 16]),
      .drp_pcie_4_do(pcie_drpdo[4*16 +: 16]),
      .drp_pcie_4_drdy(pcie_drprdy[4]),
      .drp_pcie_4_dwe(pcie_drpwe[4]),

      .drp_pcie_5_daddr(pcie_drpaddr[5*9 +: 9]),
      .drp_pcie_5_den(pcie_drpen[5]),
      .drp_pcie_5_di(pcie_drpdi[5*16 +: 16]),
      .drp_pcie_5_do(pcie_drpdo[5*16 +: 16]),
      .drp_pcie_5_drdy(pcie_drprdy[5]),
      .drp_pcie_5_dwe(pcie_drpwe[5]),

      .drp_pcie_6_daddr(pcie_drpaddr[6*9 +: 9]),
      .drp_pcie_6_den(pcie_drpen[6]),
      .drp_pcie_6_di(pcie_drpdi[6*16 +: 16]),
      .drp_pcie_6_do(pcie_drpdo[6*16 +: 16]),
      .drp_pcie_6_drdy(pcie_drprdy[6]),
      .drp_pcie_6_dwe(pcie_drpwe[6]),

      .drp_pcie_7_daddr(pcie_drpaddr[7*9 +: 9]),
      .drp_pcie_7_den(pcie_drpen[7]),
      .drp_pcie_7_di(pcie_drpdi[7*16 +: 16]),
      .drp_pcie_7_do(pcie_drpdo[7*16 +: 16]),
      .drp_pcie_7_drdy(pcie_drprdy[7]),
      .drp_pcie_7_dwe(pcie_drpwe[7]),

      .pcie_status_reg_i(pcie_status_reg),
      .pcie_dma_fifo_rst_o(pcie_dma_fifo_rst),
`else /* ENALBE_ETH */
      .drp_pcie_0_do(16'b0),
      .drp_pcie_0_drdy(1'b0),
      .drp_pcie_1_do(16'b0),
      .drp_pcie_1_drdy(1'b0),
      .drp_pcie_2_do(16'b0),
      .drp_pcie_2_drdy(1'b0),
      .drp_pcie_3_do(16'b0),
      .drp_pcie_3_drdy(1'b0),
      .drp_pcie_4_do(16'b0),
      .drp_pcie_4_drdy(1'b0),
      .drp_pcie_5_do(16'b0),
      .drp_pcie_5_drdy(1'b0),
      .drp_pcie_6_do(16'b0),
      .drp_pcie_6_drdy(1'b0),
      .drp_pcie_7_do(16'b0),
      .drp_pcie_7_drdy(1'b0),
      .pcie_status_reg_i(32'b0),
      .pcie_dma_fifo_rst_o(),
`endif /* ENABLE_ETH */

      .secee_1wire(secee_1wire),

      // DRAM interface
      .app_clk1_i(app_clk1),
      .app_wdf_full1_i(app_wdf_full1),
      .app_wdf_wren1_o(app_wdf_wren1),
      .app_wdf_data1_o(app_wdf_data1),
      .app_wdf_end1_o(app_wdf_end1),
      .app_full1_i(app_full1),
      .app_en1_o(app_en1),
      .app_cmd1_o(app_cmd1),
      .app_addr1_o(tg_addr1),
      .app_rd_data1_i(app_rd_data1),
      .app_rd_data_valid1_i(app_rd_data_valid1),

      .app_clk2_i(app_clk2),
      .app_wdf_full2_i(app_wdf_full2),
      .app_wdf_wren2_o(app_wdf_wren2),
      .app_wdf_data2_o(app_wdf_data2),
      .app_wdf_end2_o(app_wdf_end2),
      .app_full2_i(app_full2),
      .app_en2_o(app_en2),
      .app_cmd2_o(app_cmd2),
      .app_addr2_o(tg_addr2),
      .app_rd_data2_i(app_rd_data2),
      .app_rd_data_valid2_i(app_rd_data_valid2),

      .rst_dram_o(rst_dram),
      .dram_phy_init_done_i(dram_phy_init_done),
      .mcu2dram_rst_i(mcu2dram_rst),

      // PCIe interface
      .usr_dma_data_o(host_read_data),
      .usr_dma_wr_o(host_read_wr),
      .usr_dma_afull_i(host_read_afull),

      .host_write_data_i(host_write_data),
      .host_write_wr_i(host_write_wr),
      .host_read_reset_o(host_read_reset)
      );

`ifdef MTCA
  // MTCA logic
   assign pp_10m_en = 1'b1;

   assign mmc_rst = 1'b0;
   assign mmc_progen_n = 1'b1;
   assign mmc_uart_o = 1'b0;
   assign mmc_sck = 1'b0;

   /*input wire pp_rx_n[3:0],
   input wire pp_rx_p[3:0],
   output wire pp_tx_p[3:0],
   output wire pp_tx_n[3:0],*/
`endif

  // SPI 4-to-3-wire adapter, counts 8-bit sections of the SCLK and toggles
  // tristate for each byte depending on the rw_flags register, set on the
  // rising edge of load_flags
  spi_3wire_adapter spi_3wire_inst
  (
     .mcu_clk_i(clk_cpu),
     .rw_flags_i(spi_ss[31:28]),
     .load_flags_i(spi_ss[27]),
     .spi_sclk_i(spi_sclk),
     .sclk_pol_i(spi_ss[26]),
     .spi_sdio_t_o(spi_sdio_t)
  );

  // SPI IO buffer
  // Use low drive strength to avoid death and destruction if the direction of
  // the data wire is incorrectly set up
  IOBUF #(
    .DRIVE(2),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  ) spi_sdio_iobuf (
    .O(spi_miso),
    .IO(spi_sdio),
    .I(spi_mosi),
    .T(spi_sdio_t)
  );

  assign param_sck = spi_sclk;

  // SPI slave selection
  assign spi_miso_sel = param_cs_n ? spi_miso : param_so;
  assign param_si = spi_mosi;

  assign param_cs_n = spi_ss[0];
  assign pll_cs_n = spi_ss[1];
  assign adc1_cs_n = spi_ss[2];
  assign adc2_cs_n = spi_ss[3];
  assign dac_ovp_cs_n = spi_ss[4];
`ifdef OCTX
  // One of the SPI slave select pins is used for KCLK attenuator control,
  // the nulling DACs are removed in OCTX
  assign dac_null_ab_cs_n = octx_kclk_att;
`else
  assign dac_null_ab_cs_n = spi_ss[5];
`endif
  assign dac_null_cd_cs_n = spi_ss[6];
  assign dac_bias_ab_cs_n = spi_ss[7];
  assign dac_bias_cd_cs_n = spi_ss[8];
  assign trig_tcxo_cs_n = spi_ss[9];
`ifdef MTCA
  assign pp_pll_cs_n = spi_ss[10];
`endif

`ifdef EN_CFGPINS
   // SPI QUAD IO buffers
   // Use low drive strength to avoid death and destruction if the direction of
   // the data wire is incorrectly set up
  IOBUF
    #(
      .DRIVE(2),
      .IBUF_LOW_PWR("TRUE"),
      .IOSTANDARD("DEFAULT"),
      .SLEW("SLOW")
      )
   spi_quad_iobuf[3:0]
    (
     .O(spi_quad_i),
     .IO(conf_d),
     .I(spi_quad_o),
     .T(spi_quad_t)
     );
`endif

  // I2C IOBUFs
  IOBUF iic_rtl_scl_iobuf (
          .I(iic_rtl_scl_o),
          .IO(scl),
          .O(iic_rtl_scl_i),
          .T(iic_rtl_scl_t));

  IOBUF iic_rtl_sda_iobuf (
          .I(iic_rtl_sda_o),
          .IO(sda),
          .O(iic_rtl_sda_i),
          .T(iic_rtl_sda_t));

  IOBUF iic_gpio_scl_iobuf (
          .I(iic_gpio_scl_o),
          .IO(gpio_scl),
          .O(iic_gpio_scl_i),
          .T(iic_gpio_scl_t));

  IOBUF iic_gpio_sda_iobuf (
          .I(iic_gpio_sda_o),
          .IO(gpio_sda),
          .O(iic_gpio_sda_i),
          .T(iic_gpio_sda_t));

  // Power-down logic
  assign adc1_pdwn = ~power_down[0];
  assign adc2_pdwn = ~power_down[1];
  // Always power on oscillators
  // (to get the power down functionality we connect power_down to dram reset)
  assign m1_ddr3_osc_dis = 1'b0;
  assign m2_ddr3_osc_dis = 1'b0;
  //
  assign rst_dram_from_power_down = (power_down[2] | power_down[3]);

  // Clock and reset generation
  system_clock_reset system_clock_reset_inst
    (
`ifndef ENABLE_ETH
   `ifdef PCIE_AXI
       // Clock in ports
       .pxie_ref_clk_i(clk_pcie),
       .pci_app_rdy_i(pci_app_rdy),
   `else
       .pxie_ref_clk_i(pxie_ref_clk),
       .pci_app_rdy_i(pci_app_rdy),
   `endif
`else
       // Clock in ports
       .pxie_ref_clk_i(ddr3_sys_clk_buf),
       .pci_app_rdy_i(1'b1),
`endif
     // Clock out ports
     .clk_cpu_o(clk_cpu),
     .clk_mem_o(clk_mem),
     .clk_idelay_o(clk_idelay),
     // Status and control signals
     .system_clock_locked_o(),
     // Synchronous reset outputs
     .rst_clk_cpu_o(rst_clk_cpu),
     .rst_clk_mem_o(rst_clk_mem),
     .rst_clk_idelay_o(rst_clk_idelay)
     );

`ifdef ENABLE_ETH
    // Ethernet reset generation
    ethernet_clock_reset ethernet_clock_reset_inst(
      .ddr3_sys_clk_i(ddr3_sys_clk_buf1), // For rst_clk_xaui

      .eth_ref_clk_i(clk156_out),
      .eth_rdy_i(clk156_lock),

      .rst_clk_eth_o(rst_clk_eth),
      .rst_clk_xaui_o(rst_clk_xaui)
    );
`endif


`ifndef ENABLE_ETH
  `ifdef MTCA
    /*poweron_reset
    #(
     .PERST_CYCLES(256),
     .WAIT_BEFORE_RESET_CYCLES(256)
    )
    poweron_reset_inst
    (
     .clk_i(pcie_sys_clk),
     .resetn_i(~pxie_perst),
     .resetn_o(pxie_perst_poweron)
    );
    */
    assign pxie_perst_poweron = ~pxie_perst;
  `else
       assign pxie_perst_poweron = ~pxie_perst;
  `endif
`endif


  // Temporary logic for creating DC/DC sync signals, until we implement a spread-spectrum block
  reg [7:0] dcdc_counter1;
  reg [7:0] dcdc_counter2;
  always @(posedge clk_cpu) begin
    // 1 MHz for LTM4644 and LT8582
    if(dcdc_counter1 >= 8'd49) begin
      dcdc_counter1 <= 8'd0;
      dcdcsync_sync_neg <= ~dcdcsync_sync_neg;
      dcdcsync_ltm4644 <= ~dcdcsync_ltm4644;
    end else begin
      dcdc_counter1 <= dcdc_counter1 + 8'd1;
    end

    // 600 kHz for LTM4633
    if(dcdc_counter2 >= 8'd83) begin
      dcdc_counter2 <= 8'd0;
      dcdcsync_ltm4633 <= ~dcdcsync_ltm4633;
    end else begin
      dcdc_counter2 <= dcdc_counter2 + 8'd1;
    end
  end

  // GPIO
`ifdef LVDS_GPIO
  IOBUFDS_INTERMDISABLE #(
     .DIFF_TERM("TRUE"),
     .IBUF_LOW_PWR("TRUE"),
     .IOSTANDARD("LVDS_25"),
     .SLEW("SLOW"),
     .USE_IBUFDISABLE("FALSE")
  ) IOBUFDS_GPIO_inst[7:0] (
     .O(gpio_in[7:0]),
     .IO(gpio_p),
     .IOB(gpio_n),
     .I(gpio_out[7:0]),
     .IBUFDISABLE(1'b0),
     .INTERMDISABLE(~gpio_dir[7:0]), // Disable termination when set as output
     .T(gpio_dir[7:0])
  );
  assign gpio_in[15:8] = 8'd0;
`else
  wire [15:0] gpio_io;
  assign {gpio_n[7], gpio_p[7], gpio_n[6], gpio_p[6], gpio_n[5], gpio_p[5],
          gpio_n[4], gpio_p[4], gpio_n[3], gpio_p[3], gpio_n[2], gpio_p[2],
          gpio_n[1], gpio_p[1], gpio_n[0], gpio_p[0]} = gpio_io;
   IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
      .IOSTANDARD("LVCMOS25"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_GPIO_inst[15:0] (
      .O(gpio_in),     // Buffer output
      .IO(gpio_io),   // Buffer inout port (connect directly to top-level port)
      .I(gpio_out),     // Buffer input
      .T(gpio_dir)      // 3-state enable input, high=input, low=output
   );
`endif

   IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
      .IOSTANDARD("LVCMOS33"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_GPIOCTRL_inst[4:0] (
      .O(gpio_ctrl_in),     // Buffer output
      .IO(gpioctrl_r),   // Buffer inout port (connect directly to top-level port)
      .I(gpio_ctrl_out),     // Buffer input
      .T(gpio_ctrl_dir)      // 3-state enable input, high=input, low=output
   );

`ifdef OCT
   OBUF obuf_reset_ovp_n
     (
      .O (reset_ovp_n),
      .I (oct_reset_ovp_n)
      );
   IBUF ibuf_neg_ov
     (
      .O (oct_neg_ov),
      .I (neg_ov)
      );
   IBUF ibuf_pos_ov
     (
      .O (oct_pos_ov),
      .I (pos_ov)
      );
`endif

endmodule
`default_nettype wire
