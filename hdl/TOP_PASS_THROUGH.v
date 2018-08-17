`default_nettype none
`timescale 1 ps / 1 ps

module TOP_PASS_THROUGH (
  input   wire          clk_src_raw,  // 100MHz
  input   wire          rst_raw_n,

  output  wire[3:0]     tmds_tx_p,
  output  wire[3:0]     tmds_tx_n,
  input   wire          hpd_tx_n,
  inout   wire          scl_tx,
  inout   wire          sda_tx,
  input   wire[3:0]     tmds_rx_p,
  input   wire[3:0]     tmds_rx_n,
  output  wire          hpd_rx,
  inout   wire          scl_rx,
  inout   wire          sda_rx,

  output  wire[7:4]     led,      //LEDs LD4-7
  input   wire[3:0]     btn,
  input   wire[3:0]     sw//,
);
assign  hpd_rx            = 1'b1;   // HPD
assign  {sda_tx, scl_tx}  = 2'hz;

wire
  tmds_rx_ddc_scl_i,
  tmds_rx_ddc_scl_o,
  tmds_rx_ddc_scl_t,
  tmds_rx_ddc_sda_i,
  tmds_rx_ddc_sda_o,
  tmds_rx_ddc_sda_t;

design_1 design_1_i (
  .clk_100(clk_src_raw),
  .tmds_rx_clk_n(tmds_rx_n[3]),
  .tmds_rx_clk_p(tmds_rx_p[3]),
  .tmds_rx_n(tmds_rx_n[2:0]),
  .tmds_rx_p(tmds_rx_p[2:0]),
  .tmds_tx_clk_n(tmds_tx_n[3]),
  .tmds_tx_clk_p(tmds_tx_p[3]),
  .tmds_tx_n(tmds_tx_n[2:0]),
  .tmds_tx_p(tmds_tx_p[2:0]),
  .tmds_rx_ddc_scl_i(tmds_rx_ddc_scl_i),
  .tmds_rx_ddc_scl_o(tmds_rx_ddc_scl_o),
  .tmds_rx_ddc_scl_t(tmds_rx_ddc_scl_t),
  .tmds_rx_ddc_sda_i(tmds_rx_ddc_sda_i),
  .tmds_rx_ddc_sda_o(tmds_rx_ddc_sda_o),
  .tmds_rx_ddc_sda_t(tmds_rx_ddc_sda_t)
);
IOBUF tmds_rx_ddc_scl_iobuf (
  .I(tmds_rx_ddc_scl_o),
  .O(tmds_rx_ddc_scl_i),
  .T(tmds_rx_ddc_scl_t),
  .IO(scl_rx)
);
IOBUF tmds_rx_ddc_sda_iobuf (
  .I(tmds_rx_ddc_sda_o),
  .O(tmds_rx_ddc_sda_i),
  .T(tmds_rx_ddc_sda_t),
  .IO(sda_rx)
);
endmodule

`default_nettype wire

