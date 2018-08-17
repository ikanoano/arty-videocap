`default_nettype none
`timescale 1 ps / 1 ps

(* use_dsp48 = "yes" *)
module DSP (
  input   wire                clk,

  input   wire                load,
  input   wire                clear,
  input   wire                idelay,

  input   wire signed[ 8-1:0] A,
  input   wire signed[ 8-1:0] B,
  input   wire signed[24-1:0] rrC,
  input   wire signed[ 8-1:0] D,

  output  reg  signed[24-1:0] P,
  output  wire                odelay_pre1,
  output  reg                 odelay
);

reg                 rload, rclear, rdelay;
reg  signed[ 8-1:0] rA, rB, rD;
always @(posedge clk) begin
  rload   <= load;
  rclear  <= clear;
  rdelay  <= idelay;
  rA      <= A;
  rB      <= B;
//rC      <= C;
  rD      <= D;
end

reg                 rrload, rrclear, rrdelay;
reg  signed[ 9-1:0] rrAD;
reg  signed[ 8-1:0] rrB;
always @(posedge clk) begin
  rrload  <= rload;
  rrclear <= rclear;
  rrdelay <= rdelay;
  rrAD    <= rA - rD;
  rrB     <= rB;
//rrC     <= rC;
end

reg                 rrrload, rrrclear, rrrdelay;
reg  signed[17-1:0] rrrM;
reg  signed[24-1:0] rrrC;
always @(posedge clk) begin
  rrrload <= rrload;
  rrrclear<= rrclear;
  rrrdelay<= rrdelay;
  rrrM    <= rrAD * rrB;
  rrrC    <= rrC;
end
assign  odelay_pre1 = rrrdelay;

wire signed[24-1:0] zero = 0;
wire signed[17-1:0] X = rrrM;
wire signed[24-1:0] Z = /*rrrclear ? zero : (*/rrrload ? rrrC : P;//);

always @(posedge clk) begin
  P       <= X + Z;
  odelay  <= rrrdelay;
end

endmodule

`default_nettype wire

