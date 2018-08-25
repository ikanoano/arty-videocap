`default_nettype none
`timescale 1 ps / 1 ps

module PASS_THROUGH #(
  parameter [4-1:0] RX_INV  = 4'b0110,
  parameter [4-1:0] TX_INV  = 4'b1100
) (
  input   wire          clk_src_raw,  // 100MHz
  input   wire          rst_raw_n,

  output  wire[4-1:0]     tmds_tx_p,
  output  wire[4-1:0]     tmds_tx_n,
  input   wire[4-1:0]     tmds_rx_p,
  input   wire[4-1:0]     tmds_rx_n,

  output  reg [3-1:0]     led0,     // RGB LEDs
  output  reg [3-1:0]     led1,     // RGB LEDs
  output  reg [3-1:0]     led2,     // RGB LEDs
  output  reg [3-1:0]     led3,     // RGB LEDs
  output  reg [7:4]       led,      // LEDs LD4-7
  input   wire[4-1:0]     btn,
  input   wire[4-1:0]     sw//,
);
wire  rst_ref, rst_des, rst_g, rst_ser, rst_idly;

// clocking (Create these modules using clocking wizard in vivado, MANUALLY!)
wire
  clk, locked_ref, clk1x,
  clk5x_des_nb, clk1x_des, clk5x_des, locked_des,
  clk5x_ser_nb, clk1x_ser, clk5x_ser, locked_ser;

// reference clock
clk_wiz_0 clocking (          // PLL
  .clk_in1(clk_src_raw),      // 100 MHz
  .reset(1'b0),
  .clk_out1(clk),             // 200 MHz, BUFG
  .locked(locked_ref)
);

// deserializer clock
clk_wiz_1 clocking_des (      // MMCM
  .clk_in1_p(tmds_rx_p[3]),   // X MHz
  .clk_in1_n(tmds_rx_n[3]),
  .reset(rst_ref),
  .clk_out1(),                // X MHz,   BUFG
  .clk_out2(clk5x_des_nb),    // 5X MHz,  No buffer
  .locked(locked_des)
);
BUFIO bufio_des (.I(clk5x_des_nb), .O(clk5x_des));  // buffer for high freq
BUFR #(.BUFR_DIVIDE("5"),.SIM_DEVICE("7SERIES")) bufr_des (
  .I(clk5x_des_nb), .O(clk1x_des), .CE(1'b1), .CLR(1'b0));
BUFG bufg_des(.I(clk1x_des), .O(clk1x));

// serializer clock
clk_wiz_2 clocking_ser (      // MMCM
  .clk_in1(clk1x),            // X MHz
  .reset(rst_ref),
  .clk_out1(),                // X MHz,   BUFG
  .clk_out2(clk5x_ser_nb),    // 5X MHz,  No buffer
  .locked(locked_ser)
);
BUFIO bufio_ser (.I(clk5x_ser_nb), .O(clk5x_ser));  // buffer for high freq
BUFR #(.BUFR_DIVIDE("5"),.SIM_DEVICE("7SERIES")) bufr_ser (
  .I(clk5x_ser_nb), .O(clk1x_ser), .CE(1'b1), .CLR(1'b0));

// reset
SASRESET sas_idly (
  .clk(clk), .sync_rst_src(1'b0),    .async_rst_src(~locked_ref), .rst(rst_idly));
SASRESET sas_ref (
  .clk(clk), .sync_rst_src(rst_idly),.async_rst_src(~rst_raw_n),  .rst(rst_ref));
SASRESET sas_des (
  .clk(clk1x_des), .sync_rst_src(rst_ref), .async_rst_src(~locked_des), .rst(rst_des));
SASRESET sas_g (
  .clk(clk1x),     .sync_rst_src(rst_ref), .async_rst_src(~locked_des), .rst(rst_g));
SASRESET sas_ser (
  .clk(clk1x_ser), .sync_rst_src(rst_des), .async_rst_src(~locked_ser), .rst(rst_ser));

// receiver
wire[3-1:0]   vld_cb, rdy_cb, dbg_pAlignErr;
wire[30-1:0]  ch_des;
generate genvar gi;
for (gi = 0; gi < 3; gi = gi + 1) begin
  TMDS_Receiver # (
    .kRefClkFrqMHz   (200),       // what is the RefClk frequency
    .kIDLY_TapValuePs(78),        // delay in ps per tap
    .kIDLY_TapWidth  (5),         // number of bits for IDELAYE2 tap counter
    .kInvert         (RX_INV[gi]) // invert input
  ) rx (
    .PixelClk(clk1x_des),
    .SerialClk(clk5x_des),
    .RefClk(clk),
    .aRst(~locked_des),
    .pRst(rst_des),

    // Encoded serial data
    .sDataIn_p(tmds_rx_p[gi]),
    .sDataIn_n(tmds_rx_n[gi]),

    // Parallel data
    .pDataInBnd(ch_des[10*gi +: 10]),

    // Channel bonding (three data channels in total)
    .pOtherChVld({vld_cb[(gi+1)%3], vld_cb[(gi+2)%3]}),
    .pOtherChRdy({rdy_cb[(gi+1)%3], rdy_cb[(gi+2)%3]}),
    .pMeVld(vld_cb[gi]),
    .pMeRdy(rdy_cb[gi]),

    .dbg_pAlignErr(dbg_pAlignErr[gi])
  );
end
endgenerate
// IDELAY calibrator
wire        ideready;
IDELAYCTRL idc (
  .RDY(ideready),
  .REFCLK(clk),
  .RST(rst_idly)
);

// cross over clock region
wire          full1, empty1, full2, empty2;
wire[30-1:0]  ch_g,  ch_ser;
reg [30-1:0]  rch_g;
reg [40-1:0]  rch_ser;
ASYNC_FIFO #(.SIZE_SCALE(12), .WIDTH(30), .FILLED_THRESH(2**10)) cdc_fifo1 (
  .rst(rst_des),
  // Write clock region
  .wclk(clk1x_des),
  .full(full1),
  .enqueue(~full1),
  .wdata(ch_des),
  // Read clock region
  .rclk(clk1x),
  .empty(empty1),
  .filled(),
  .dequeue(~empty1),
  .rdata(ch_g)
);
always @(posedge clk1x) rch_g <= ch_g;
ASYNC_FIFO #(.SIZE_SCALE(12), .WIDTH(30), .FILLED_THRESH(2**10)) cdc_fifo2 (
  .rst(rst_g),
  // Write clock region
  .wclk(clk1x),
  .full(full2),
  .enqueue(~full2),
  .wdata(rch_g),
  // Read clock region
  .rclk(clk1x_ser),
  .empty(empty2),
  .filled(),
  .dequeue(~empty2),
  .rdata(ch_ser)
);
always @(posedge clk1x_ser) begin
  rch_ser <= {10'b0000011111, ch_ser} ^ {
      {10{TX_INV[3]}},
      {10{TX_INV[2]}},
      {10{TX_INV[1]}},
      {10{TX_INV[0]}}
    };
end

// sender
wire  [4-1:0] serialized;
SERIALIZER10 tx [4-1:0] (
  .clk_parallel_sdr(clk1x_ser),
  .clk_serial_ddr(clk5x_ser),
  .rst(rst_ser),
  .parallel_in(rch_ser),
  .serial_out(serialized)
);
OBUFDS #(.IOSTANDARD("TMDS_33")) tmdsbuf [4-1:0] (
  .O(tmds_tx_p),
  .OB(tmds_tx_n),
  .I(serialized)
);

// indicator
localparam[20-1:0]  LEDCNT_TH1  = (1<<20) - (1<<19);
localparam[20-1:0]  LEDCNT_TH2  = (1<<20) - (1<<17);
reg [20-1:0]  ledcnt=0;
always @(posedge clk) begin
  ledcnt  <= ledcnt+1;
  led     <= ledcnt<LEDCNT_TH1 ? 0 : {ch_ser[0], &vld_cb, locked_des, ideready};
  led0[2] <= ledcnt<LEDCNT_TH2 ? 0 : vld_cb[0]; // Blue Channel
  led1[1] <= ledcnt<LEDCNT_TH2 ? 0 : vld_cb[1]; // Green Channel
  led2[0] <= ledcnt<LEDCNT_TH2 ? 0 : vld_cb[2]; // Red Channel
  led3    <= ledcnt<LEDCNT_TH2 ? 0 : {dbg_pAlignErr[0], dbg_pAlignErr[1], dbg_pAlignErr[2]};
end

initial if(RX_INV[3]) begin $display("not supported RX_INV"); $finish(); end
endmodule

`default_nettype wire

