`default_nettype none
`timescale 1 ps / 1 ps

module PASS_THROUGH #(
  parameter [4-1:0] RX_INV  = 4'b0110,
  parameter [4-1:0] TX_INV  = 4'b1100
) (
  input   wire          clk_src_raw,  // 100MHz
  input   wire          rst_raw_n,

  output  wire[3:0]     tmds_tx_p,
  output  wire[3:0]     tmds_tx_n,
  input   wire[3:0]     tmds_rx_p,
  input   wire[3:0]     tmds_rx_n,

  output  wire[7:4]     led,      //LEDs LD4-7
  input   wire[3:0]     btn,
  input   wire[3:0]     sw//,
);
reg   rst_ref, rst_des, rst_ser;

// clocking (Create these modules using clocking wizard in vivado, MANUALLY!)
wire
  clk, locked_ref,
  clk_des, clk5x_des, locked_des,
  clk_ser, clk5x_ser, locked_ser;
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
  .clk_out1(clk_des),         // X MHz,   BUFG
  .clk_out2(clk5x_des),       // 5X MHz,  No buffer
  .locked(locked_des)
);
// serializer clock
clk_wiz_2 clocking_ser (      // MMCM
  .clk_in1_p(clk_des),        // X MHz
  .reset(rst_ref),
  .clk_out1(clk_ser),         // X MHz,   BUFG
  .clk_out2(clk5x_ser),       // 5X MHz,  No buffer
  .locked(locked_ser)
);

// reset
(* keep = "true" *)
reg rst_b, rst_des_b, rst_ser_b;
always @(posedge clk)     begin rst_ref<=rst_b;     rst_b    <=~rst_raw_n; end
always @(posedge clk_des) begin rst_des<=rst_des_b; rst_des_b<=rst_ref;    end
always @(posedge clk_ser) begin rst_ser<=rst_ser_b; rst_ser_b<=rst_ref;    end

// receiver
wire[3-1:0]   vld_cb, rdy_cb;
wire[10-1:0]  ch_des[0:3-1];
generate genvar gi;
for (gi = 0; gi < 3; gi = gi + 1) begin
  TMDS_Receiver # (
    .kRefClkFrqMHz   (200),       // what is the RefClk frequency
    .kIDLY_TapValuePs(78),        // delay in ps per tap
    .kIDLY_TapWidth  (5),         // number of bits for IDELAYE2 tap counter
    .kInvert         (RX_INV[gi]) // invert input
  ) rx (
    .PixelClk(clk_des),
    .SerialClk(clk5x_des),
    .RefClk(clk),
    .aRst(~locked_des),

    // Encoded serial data
    .sDataIn_p(tmds_rx_p[gi]),
    .sDataIn_n(tmds_rx_n[gi]),

    // Parallel data
    .pDataInBnd(ch_des[gi]),

    // Channel bonding (three data channels in total)
    .pOtherChVld({vld_cb[(gi+2)%3], vld_cb[(gi+1)%3]}),
    .pOtherChRdy({rdy_cb[(gi+2)%3], rdy_cb[(gi+1)%3]}),
    .pMeVld(vld_cb[gi]),
    .pMeRdy(rdy_cb[gi])
  );
end
endgenerate

// cross over clock region
(* keep = "true" *)
reg [10-1:0]  rch_des[0:4-1], rch_ser[0:4-1];
always @(posedge clk_des) begin
  rch_des[0]  <= ch_des[0];
  rch_des[1]  <= ch_des[1];
  rch_des[2]  <= ch_des[2];
end
initial rch_des[3] = 10'b0000011111;

always @(posedge clk_ser) begin
  rch_ser[0]  <= TX_INV[0] ? ~rch_des[0] : rch_des[0];
  rch_ser[1]  <= TX_INV[1] ? ~rch_des[1] : rch_des[1];
  rch_ser[2]  <= TX_INV[2] ? ~rch_des[2] : rch_des[2];
  rch_ser[3]  <= TX_INV[3] ? ~rch_des[3] : rch_des[3];
end

// sender
wire  [4-1:0] serialized;
SERIALIZER10 tx [4-1:0] (
  .clk_parallel_sdr(clk_ser),
  .clk_serial_ddr(clk5x_ser),
  .rst(rst_ser),
  .parallel_in({rch_ser[3], rch_ser[2], rch_ser[1], rch_ser[0]}),
  .serial_out(serialized)
);
OBUFDS #(.IOSTANDARD("TMDS_33")) tmdsbuf [4-1:0] (
  .O(tmds_tx_p),
  .OB(tmds_tx_n),
  .I(serialized)
);

initial if(RX_INV[3]) begin $display("not supported RX_INV"); $finish(); end
endmodule

`default_nettype wire

