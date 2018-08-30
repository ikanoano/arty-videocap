`default_nettype none
`timescale 1ps/1ps

// validator and error correcter for transition-minimized data
module VEC (
  input   wire          clk,
  input   wire[10-1:0]  enc,
  input   wire[ 8-1:0]  dec,
  output  reg [ 8-1:0]  ecdec
);

localparam [0:0]
  U0 = 1'b0,  //unit 0
  U1 = 1'b1;  //unit 1

// n1d is popcount for dec
wire[6-1:0] pcdrslt;
C63 #(4)  pcd[1:0](dec, pcdrslt);
wire[4-1:0] n1d = pcdrslt[0+:3] + pcdrslt[3+:3];
// Branch
wire        br  = n1d>4 || (n1d==4 && ~dec[0]);

wire[9-1:0] q_m = br ?
  {U0, q_m[6:0] ~^ dec[7:1], dec[0]} :
  {U1, q_m[6:0]  ^ dec[7:1], dec[0]};

// Update q_out
reg           valid;
reg [8-1:0]   rdec, rrdec;
reg [10-1:0]  re_enc[0:3-1], renc;
always @(posedge clk) begin
  // cycle 1
  rdec      <= dec;
  renc      <= enc;
  re_enc[0] <= {~q_m[8], q_m[8], q_m[8] ? q_m[7:0] : ~q_m[7:0]};
  re_enc[1] <= {U1,      q_m[8],                     ~q_m[7:0]};
  re_enc[2] <= {U0,      q_m[8],          q_m[7:0]            };

  // cycle 2 - validate
  rrdec     <= rdec;
  valid     <= renc==re_enc[0] || renc==re_enc[1] || renc==re_enc[2];

  // cycle 3 - error correct
  ecdec     <= valid ? rrdec : ecdec; // use last valid dec if not valid
end
endmodule

//http://fpga.org/2014/09/05/quick-fpga-hacks-population-count/
module C63 #(
  parameter WIDTH = 6
) (
  input   wire[WIDTH-1:0] i,
  output  reg [2:0]       o);    // # of 1's in i

always @* begin
  case (i)
    6'h00: o = 0; 6'h01: o = 1; 6'h02: o = 1; 6'h03: o = 2;
    6'h04: o = 1; 6'h05: o = 2; 6'h06: o = 2; 6'h07: o = 3;
    6'h08: o = 1; 6'h09: o = 2; 6'h0A: o = 2; 6'h0B: o = 3;
    6'h0C: o = 2; 6'h0D: o = 3; 6'h0E: o = 3; 6'h0F: o = 4;
    6'h10: o = 1; 6'h11: o = 2; 6'h12: o = 2; 6'h13: o = 3;
    6'h14: o = 2; 6'h15: o = 3; 6'h16: o = 3; 6'h17: o = 4;
    6'h18: o = 2; 6'h19: o = 3; 6'h1A: o = 3; 6'h1B: o = 4;
    6'h1C: o = 3; 6'h1D: o = 4; 6'h1E: o = 4; 6'h1F: o = 5;
    6'h20: o = 1; 6'h21: o = 2; 6'h22: o = 2; 6'h23: o = 3;
    6'h24: o = 2; 6'h25: o = 3; 6'h26: o = 3; 6'h27: o = 4;
    6'h28: o = 2; 6'h29: o = 3; 6'h2A: o = 3; 6'h2B: o = 4;
    6'h2C: o = 3; 6'h2D: o = 4; 6'h2E: o = 4; 6'h2F: o = 5;
    6'h30: o = 2; 6'h31: o = 3; 6'h32: o = 3; 6'h33: o = 4;
    6'h34: o = 3; 6'h35: o = 4; 6'h36: o = 4; 6'h37: o = 5;
    6'h38: o = 3; 6'h39: o = 4; 6'h3A: o = 4; 6'h3B: o = 5;
    6'h3C: o = 4; 6'h3D: o = 5; 6'h3E: o = 5; 6'h3F: o = 6;
  endcase
end
endmodule

`default_nettype wire

