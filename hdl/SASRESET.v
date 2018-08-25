`default_nettype none
`timescale 1 ps / 1 ps

module SASRESET (
  input   wire  clk,
  input   wire  sync_rst_src,
  input   wire  async_rst_src,
  (* keep = "true" *)
  output  reg   rst
);

(* keep = "true" *)
reg         sync_rst_src_b;
reg [8-1:0] delaycnt = 0;
always @(posedge clk or posedge async_rst_src) begin
  delaycnt <=
    async_rst_src ?  0 :
    &delaycnt     ? ~0 : delaycnt+1;
  sync_rst_src_b  <= sync_rst_src;
  rst             <= sync_rst_src_b | ~&delaycnt;
end

endmodule

`default_nettype wire

