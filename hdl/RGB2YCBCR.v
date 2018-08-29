`default_nettype none
`timescale 1 ps / 1 ps

(* use_dsp = "yes" *)
module RGB2YCBCR (
  input   wire                clk,

  input   wire signed[9-1:0]  iR,
  input   wire signed[9-1:0]  iG,
  input   wire signed[9-1:0]  iB,

  output  reg        [8-1:0]  oY,
  output  reg        [8-1:0]  oCb,
  output  reg        [8-1:0]  oCr
);

localparam
  SCALE   = 8;
localparam  signed[SCALE:0]
  C1      = (1<<SCALE) * 0.299,
  C2      = (1<<SCALE) * 0.587,
  C3      = (1<<SCALE) * 0.144,
  C4      = (1<<SCALE) * 0.492111,
  C5      = (1<<SCALE) * 0.877283;
localparam  signed[SCALE+8:0]
  C6      = (1<<SCALE) * 128;

reg  signed[9-1:0]        rR, rG, rB, rrR, rrB, rrrR, rrrB, rrrrR, rrrrB;
reg  signed[9+SCALE:0]    RC, GC, BC;
reg  signed[11+SCALE:0]   scaleY;
wire       [10-1:0]       Y = scaleY[SCALE +: 10];
reg  signed[9-1:0]        rY, rrY, rrrY, rrrrY;
reg  signed[11-1:0]       BY, RY;
reg  signed[11+SCALE:0]   BYC, RYC;
reg  signed[12+SCALE:0]   scaleCb, scaleCr;
wire signed[12-1:0]       Cb = scaleCb[SCALE +: 12];
wire signed[12-1:0]       Cr = scaleCr[SCALE +: 12];
always @(posedge clk) begin
  // cycle 1
  rR      <= iR;
  rG      <= iG;
  rB      <= iB;

  // cycle 2
  GC      <= rG * C2;
  BC      <= rB * C3;
  RC      <= rR * C1;
  rrB     <= rB;
  rrR     <= rR;

  // cycle 3
  scaleY  <= RC + GC + BC;
  rrrB    <= rrB;
  rrrR    <= rrR;

  // cycle 4
  rY      <= Y>=256 ? 8'd255 : Y;
  rrrrB   <= rrrB;
  rrrrR   <= rrrR;

  // cycle 5
  rrY     <= rY;
  BY      <= rrrrB - rY;
  RY      <= rrrrR - rY;

  // cycle 6
  rrrY    <= rrY;
  BYC     <= BY * C4;
  RYC     <= RY * C5;

  // cycle 7
  rrrrY   <= rrrY;
  scaleCb <= BYC + C6;
  scaleCr <= RYC + C6;

  // cycle 8
  oY      <= rrrrY[0+:8];
  oCb     <= Cb<0 ? 8'd0 : Cb>=256 ? 8'd255 : Cb[0+:8];
  oCr     <= Cr<0 ? 8'd0 : Cr>=256 ? 8'd255 : Cr[0+:8];

end

endmodule

`default_nettype wire

