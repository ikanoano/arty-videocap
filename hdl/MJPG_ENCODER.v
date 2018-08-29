`default_nettype none
`timescale 1 ps / 1 ps

module MJPG_ENCODER (
  input   wire          clk,
  input   wire          rst,

  input   wire          pvalid,
  input   wire          vsync,
  input   wire[24-1:0]  ycbcr,

  output  wire          jvalid,
  output  wire[8-1:0]   jpeg
);

reg [12-1:0]  width, height, y, x, x_from_valid;  // 0 <= . < 2047
wire[8-1:0]   h_mcu = width[3+:8];
reg           hvalid, vvalid, start_pulse;
reg [16-1:0]  hsync_shift;
wire          hsync = hsync_shift[15];
always @(posedge clk) begin
  x_from_valid  <= (rst || hsync) ? -1 : x_from_valid + (pvalid | hvalid);
  x             <= (rst || hsync) ?  0 : x + pvalid;
  y             <= (rst || vsync) ?  0 : y + (hvalid & hsync);

  width         <= rst ? 12'd0 : (hvalid & hsync ? x : width);
  height        <= rst ? 12'd0 : (vvalid & vsync ? y : height);
  //$display("y=%d, x=%d", y, x);

  hvalid <=
    rst     ? 1'b0 :
    hsync   ? 1'b0 :
    pvalid  ? 1'b1 : hvalid;
  vvalid <=
    rst     ? 1'b0 :
    vsync   ? 1'b0 :
    pvalid  ? 1'b1 : vvalid;
  start_pulse <= {vvalid, pvalid}==2'b01;

  // assert hsync 16 cycle in 16 cycle after pvalid is deasserted
  hsync_shift <= {hsync_shift[0+:15], ~pvalid & hvalid};
end


reg [6-1:0]   elen;
reg [32-1:0]  edata, edata_nostuff;
wire[3-1:0]   bsrest;
wire          bsvalid;
wire[32-1:0]  bsdata, bsdata_nostuff;
BITSTREAM bs (
  .clk(clk),
  .rst(rst),
  .ilength(elen),  // 0 <= ilength <= 32
  .idata(edata),
  .rest(bsrest),
  .ovalid(bsvalid),
  .odata(bsdata)
);
BITSTREAM bs_stuff (
  .clk(clk),
  .rst(rst),
  .ilength(elen),
  .idata(edata_nostuff),
  .rest(),
  .ovalid(),
  .odata(bsdata_nostuff)
);
INSERT_STUFF is (
  .clk(clk),
  .rst(rst),
  .enqueue(bsvalid),
  .wdata(bsdata),
  .wdata_nostuff(bsdata_nostuff),
  .valid(jvalid),
  .rdata(jpeg)
);

// generate bitstream
localparam
  LEN_FH      = 171,
  DCT_TH_Y    = 4,//28,
  DCT_TH_C    = 2,//6,
  DCT_RC_Y    = DCT_TH_Y+1, // Request assert Cycle
  DCT_RC_C    = DCT_TH_C+1,
  NOBS_CYCLE  = 8;
reg [8-1:0]   idx_fh;
reg [8-1:0]   footer_header[0:LEN_FH-1];
reg [6-1:0]   elen_fh;
reg [32-1:0]  edata_fh;
reg           ereq_master;
reg [6-1:0]   ereq_cnt;
reg [8-1:0]   e_x_mcu[0:2];
reg           ereq_ce[0:2];
initial $readmemh("fh.hex", footer_header, 0, LEN_FH-1);
always @(posedge clk) begin
  if(rst) {elen_fh, edata_fh, ereq_master, idx_fh} <= 47'hFF;
  else begin
    if(start_pulse) begin // byte alignment
      //$display("byte alignment");
      $write("b");
      elen_fh <= {3'd0, bsrest};
      edata_fh<= 32'hxxxxxxff;
      idx_fh  <= 8'h2; // change me to 0 to output footer(EOI), though ffplay doesn't need it.
      if(ereq_master) begin
        $display("invalid encoding timing for component");
        $finish();
      end
    end else if(idx_fh<LEN_FH) begin // output footer and header
      //$display("start to output footer and header");
      if(idx_fh==0) $write("f"); else $write("h");
      elen_fh <= 8;
      edata_fh<= {24'hxxxxxx, footer_header[idx_fh]};
      idx_fh  <= idx_fh + 1;
      case (idx_fh)
        8'd143: footer_header[idx_fh] <= {5'd0, height[8+:3]};
        8'd144: footer_header[idx_fh] <= height[0+:8];
        8'd145: footer_header[idx_fh] <= {5'd0, width[8+:3]};
        8'd146: footer_header[idx_fh] <= width[0+:8];
      endcase
    end else begin  // output entropy-coded image data
      elen_fh <= 0;
      edata_fh<= 32'hxxxxxxxx;
      idx_fh  <= idx_fh;

      if(0<y && y<height && y[0+:3]==0) begin // FIXME: last line cannot be output
        //$display("start to output body");
        if(!ereq_master) $write("<");
        ereq_master <= 1;
      end else if(e_x_mcu[2] >= h_mcu) begin
        if(ereq_master) $write(">");
        ereq_master <= 0;
      end
    end

  end

  if(ereq_master) begin
    ereq_cnt    <= ereq_cnt < DCT_RC_Y+DCT_RC_C*2+NOBS_CYCLE ? ereq_cnt+1 : 0;
    ereq_ce[0]  <=                                ereq_cnt<DCT_RC_Y;
    ereq_ce[1]  <= DCT_RC_Y         <=ereq_cnt && ereq_cnt<DCT_RC_Y+DCT_RC_C;
    ereq_ce[2]  <= DCT_RC_Y+DCT_RC_C<=ereq_cnt && ereq_cnt<DCT_RC_Y+DCT_RC_C*2;
    e_x_mcu[0]  <= e_x_mcu[0] + (ereq_cnt==DCT_RC_Y             ? 1 : 0);
    e_x_mcu[1]  <= e_x_mcu[1] + (ereq_cnt==DCT_RC_Y+DCT_RC_C    ? 1 : 0);
    e_x_mcu[2]  <= e_x_mcu[2] + (ereq_cnt==DCT_RC_Y+DCT_RC_C*2  ? 1 : 0);
  end else begin
    ereq_cnt    <= 0;
    ereq_ce[0]  <= 0;
    ereq_ce[1]  <= 0;
    ereq_ce[2]  <= 0;
    e_x_mcu[0]  <= 0;
    e_x_mcu[1]  <= 0;
    e_x_mcu[2]  <= 0;
  end
  // NOTE:
  // ereq_master はe_x_mcu[2]に依存しているため本来デアサートされるべき
  // タイミングからデアサートされるまでに１サイクルの遅延がある。
  // この際invalidなbitstreamを出力しないように、e_x_mcu[2]が最大になった直後
  // にはNOBS_CYCLEを設けてこの期間ereq_ceをデアサートする。

end


reg [8-1:0] pix_y, pix_b, pix_r;
reg         rpvalid, rvsync;
always @(posedge clk) {pix_y, pix_b, pix_r} <= ycbcr;
always @(posedge clk) rpvalid <= pvalid;
always @(posedge clk) rvsync  <= vsync;

wire[6-1:0]   elen_ce[0:2];
wire[32-1:0]  edata_ce[0:2];
COMPONENT_ENCODER #(.IS_Y(1), .DCT_TH(DCT_TH_Y)) yenc (
  .clk(clk),
  .rst(rst),
  .page(y[3]),

  .valid(rpvalid),
  .pix(pix_y),
  .x_mcu(x_from_valid[3+:8]),      // assign from -1 to h_mcu + 1
  .y_in_mcu(y[0+:3]),
  .x_in_mcu(x_from_valid[0+:3]),
  .vsync(rvsync),

  .e_x_mcu(e_x_mcu[0]),   // must be valid before bsreq is asserted
  .ereq(ereq_ce[0]),
  .elen(elen_ce[0]),
  .edata(edata_ce[0])
);

COMPONENT_ENCODER #(.IS_Y(0), .DCT_TH(DCT_TH_C)) cenc[1:0] (
  .clk(clk),
  .rst(rst),
  .page(y[3]),

  .valid(rpvalid),
  .pix({pix_r, pix_b}),
  .x_mcu(x_from_valid[3+:8]), // from -1 to h_mcu + 1
  .y_in_mcu(y[0+:3]),
  .x_in_mcu(x_from_valid[0+:3]),
  .vsync(rvsync),

  .e_x_mcu({e_x_mcu[2], e_x_mcu[1]}),   // must be valid before bsreq is asserted
  .ereq   ({ereq_ce[2], ereq_ce[1]}),
  .elen   ({elen_ce[2], elen_ce[1]}),
  .edata  ({edata_ce[2],edata_ce[1]})
);

wire[4-1:0]   evalid = {|elen_fh, |elen_ce[2], |elen_ce[1], |elen_ce[0]};
reg [6-1:0]   pre_elen;
reg [32-1:0]  pre_edata[0:3];
always @(posedge clk) begin
  pre_elen      <= elen_fh | elen_ce[2] | elen_ce[1] | elen_ce[0];
  pre_edata[0]  <= evalid[0] ? edata_ce[0] : 0;
  pre_edata[1]  <= evalid[1] ? edata_ce[1] : 0;
  pre_edata[2]  <= evalid[2] ? edata_ce[2] : 0;
  pre_edata[3]  <= evalid[3] ? edata_fh    : 0;

  elen  <= rst ? 0 : pre_elen;
  edata <= rst ? 0 : pre_edata[3] | pre_edata[2] | pre_edata[1] | pre_edata[0];
  edata_nostuff <= rst ? 0 : {24'h0, idx_fh<LEN_FH ? 8'hff : 8'h00};

  if(!rst) case (evalid)
    4'b0000: begin end
    4'b1000,4'b0100,4'b0010,4'b0001: begin end//$write("%d", $clog2(evalid));
    default : begin
      $display("bitstream collision detected: %b", evalid);
      $finish();
    end
  endcase
end

// debug
(* keep = "true" *)
reg [12-1:0]  dbg_width, dbg_height;  // 0 <= . < 2047
always @(posedge clk) begin
  dbg_width     <= (hvalid & hsync) ? x : dbg_width;
  dbg_height    <= (vvalid & vsync) ? y : dbg_height;
end

endmodule

`default_nettype wire

