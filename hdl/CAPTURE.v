`default_nettype none
`timescale 1 ps / 1 ps

module CAPTURE #(
  parameter [4-1:0] RX_INV  = 4'b0110,
  parameter [4-1:0] TX_INV  = 4'b1100
) (
  input   wire            clk_src_raw,  // 100MHz
  input   wire            rst_raw_n,

  output  wire[4-1:0]     tmds_tx_p,
  output  wire[4-1:0]     tmds_tx_n,
  input   wire[4-1:0]     tmds_rx_p,
  input   wire[4-1:0]     tmds_rx_n,

  output  wire[3-1:0]     led0,     // RGB LEDs
  output  wire[3-1:0]     led1,     // RGB LEDs
  output  wire[3-1:0]     led2,     // RGB LEDs
  output  wire[3-1:0]     led3,     // RGB LEDs
  output  wire[7:4]       led,      // LEDs LD4-7
  input   wire[4-1:0]     btn,
  input   wire[4-1:0]     sw,

  inout   wire            eth_mdio,
  output  wire            eth_mdc,
  output  wire            eth_rstn,
  output  wire[4-1:0]     eth_tx_d,
  output  wire            eth_tx_en,
  input   wire            eth_tx_clk,
  input   wire[4-1:0]     eth_rx_d,
  input   wire            eth_rx_err,
  input   wire            eth_rx_dv,
  input   wire            eth_rx_clk,
  input   wire            eth_col,
  input   wire            eth_crs,
  output  wire            eth_ref_clk
);

wire  clk100;
BUFG bufg_des(.I(clk_src_raw), .O(clk100));

localparam[10-1:0]
  CTLTKN0 = 10'b1101010100,
  CTLTKN1 = 10'b0010101011,
  CTLTKN2 = 10'b0101010100,
  CTLTKN3 = 10'b1010101011,
  START0  = 10'b1011001100;

// TMDS pass through
wire            clk, rst, valid;
wire[30-1:0]    data;
PASS_THROUGH #(.RX_INV(RX_INV), .TX_INV(TX_INV)) pt (
  .clk_src_raw(clk100),
  .rst_raw_n(rst_raw_n),

  .tmds_tx_p(tmds_tx_p),
  .tmds_tx_n(tmds_tx_n),
  .tmds_rx_p(tmds_rx_p),
  .tmds_rx_n(tmds_rx_n),

  .led0(led0), .led1(led1),
  .led2(led2), .led3(led3),
  .led(led[5:4]), .btn(btn), .sw(sw),

  .clk_data(clk),
  .rst_data(rst),
  .valid_data(valid),
  .data(data)
);

// decode for color
reg [30-1:0]  rdata;
wire[24-1:0]  rgb, ecrgb, ycbcr;
DECODER dec [3-1:0] (.clk(clk), .rst(rst), .D(data), .Q(rgb));  // + 1 cycle
always @(posedge clk) rdata <= data;
VEC val [3-1:0] (.clk(clk), .enc(rdata), .dec(rgb), .ecdec(ecrgb)); // + 3 cycle
RGB2YCBCR cnv_color ( // + 8 cycle
  .clk(clk),
  .iR({1'b0, ecrgb[8*2+:8]}),
  .iG({1'b0, ecrgb[8*1+:8]}),
  .iB({1'b0, ecrgb[8*0+:8]}),
  .oY (ycbcr[8*2+:8]),
  .oCb(ycbcr[8*1+:8]),
  .oCr(ycbcr[8*0+:8])
);

// decode for control
wire
  c0  = data[0+:10] == CTLTKN0,
  c1  = data[0+:10] == CTLTKN1,
  c2  = data[0+:10] == CTLTKN2,
  c3  = data[0+:10] == CTLTKN3,
  s0  = data[0+:10] == START0,
  vd  = c0 | c1,  // vsync deassert
  va  = c2 | c3,  // vcync assert
  pd  = (c0 | c1 | c2 | c3),  // pvalid deassert
  pa  = s0;       // pvalid assert
reg           pvalid, vsync, frame_mask, rpvalid, rvsync, vsync_inv;
reg [16-1:0]  rvd, rva, rpd, rpa; // for vsync (de)assert and pvalid (de)assert
always @(posedge clk) begin
  if(rst) begin
    {pvalid, vsync, frame_mask, rpvalid, rvsync, rvd, rva, rpd, rpa, vsync_inv} <= 0;
  end else begin
    // robust pixel valid / vsync detection
    rpa <= {rpa[0+:15], pa};
    rpd <= {rpd[0+:15], pd};
    pvalid  <=
      &rpd[ 9-:4] ? 1'b0 :
      &rpa[11-:2] ? 1'b1 : pvalid;
    rpvalid <= pvalid & frame_mask;

    rva <= {rva[0+:15], va};
    rvd <= {rvd[0+:15], vd};
    vsync   <=
      &rvd[ 9-:4] ? 1'b0^vsync_inv :
      &rva[ 9-:4] ? 1'b1^vsync_inv : vsync;
    rvsync  <= vsync & frame_mask;

    // half frame rate
    if(!vsync && &rva[9-:4]) frame_mask <= ~frame_mask; // posedge vsync
    vsync_inv <= sw[1];
  end
end

// encode frames to jpegs -> concatinated jpegs will be mjpeg
wire        jvalid;
wire[8-1:0] jpeg;
MJPG_ENCODER me (
  .clk(clk),
  .rst(rst),

  .pvalid(rpvalid),
  .vsync(rvsync),
  .ycbcr(ycbcr),

  .jvalid(jvalid),
  .jpeg(jpeg)
);

reg         rjvalid, eth_en;
reg [8-1:0] rjpeg;
always @(posedge clk) begin
  eth_en  <= sw[0];
  rjvalid <= jvalid & eth_en;
  rjpeg   <= jpeg;
end

// buffer
wire          clk_eth;
wire          start_send, nibble_valid, nibble_user_data, with_usr_valid;
wire[3:0]     nibble, with_usr;
BRIDGE_ENC2ETH be2e (
  .enc_clk(clk),
  .rst(rst),
  .enqueue(rjvalid),
  .jpeg(rjpeg),

  .eth_clk(clk_eth),
  .start_send(start_send),
  .nibble(nibble),
  .nibble_user_data(nibble_user_data),
  .nibble_valid(nibble_valid),
  .with_usr(with_usr),
  .with_usr_valid(with_usr_valid)
);

// send mjpeg
ethernet_test et (
  .CLK100MHZ(clk100),

  .eth_mdio(eth_mdio),
  .eth_mdc(eth_mdc),
  .eth_rstn(eth_rstn),
  .eth_tx_d(eth_tx_d),
  .eth_tx_en(eth_tx_en),
  .eth_tx_clk(eth_tx_clk),
  .eth_rx_d(eth_rx_d),
  .eth_rx_err(eth_rx_err),
  .eth_rx_dv(eth_rx_dv),
  .eth_rx_clk(eth_rx_clk),
  .eth_col(eth_col),
  .eth_crs(eth_crs),
  .eth_ref_clk(eth_ref_clk),

  .start_sending(start_send),
  .nibble_clk(clk_eth),
  .nibble(nibble),
  .nibble_user_data(nibble_user_data),
  .nibble_valid(nibble_valid),
  .with_usr(with_usr),
  .with_usr_valid(with_usr_valid)
);

// indicator
localparam[18-1:0]  LEDCNT_TH1  = (1<<18) - (1<<13);
reg [18-1:0]  ledcnt=0;
reg [1:0]     rled;
always @(posedge clk) begin
  ledcnt  <= ledcnt+1;
  rled    <= ledcnt<LEDCNT_TH1 ? 0 : {vsync_inv, eth_en};
end
assign  led[7:6]  = rled;

// debug
(* keep = "true" *)
reg [32-1:0]  dbg_data;
always @(posedge clk_eth) if(with_usr_valid)
  dbg_data <= {with_usr, dbg_data[4+:28]};

endmodule

`default_nettype wire

