`default_nettype none
`timescale 1ps/1ps

module ASYNC_FIFO #(parameter
  SIZE_SCALE    = 12,
  WIDTH         = 8,
  FILLED_THRESH = 1024
) (
  input   wire                              rst,// Hold 8 cycle in slower clock
  // Write clock region
  input   wire                              wclk,
  output  reg                               full,
  input   wire                              enqueue,
  input   wire[WIDTH-1:0]                   wdata,
  // Read clock region
  input   wire                              rclk,
  output  reg                               empty,
  output  reg                               filled,
  input   wire                              dequeue,
  output  wire[WIDTH-1:0]                   rdata
);
localparam[SIZE_SCALE-1:0]  SS0 = 0, SS1 = 1;

(* keep = "true" *)
reg [SIZE_SCALE-1:0]  waddr_gray, raddr_gray_sync[0:1];
(* keep = "true" *)
reg [SIZE_SCALE-1:0]  raddr_gray, waddr_gray_sync[0:1];

// Write clock region
reg [SIZE_SCALE-1:0]  waddr, raddr_bin;
wire[SIZE_SCALE-1:0]  next_waddr = waddr + ((~|wrst && enqueue) ? SS1 : SS0);
reg [3-1:0]           wrst;
always @(posedge wclk) begin
  wrst  <= {wrst[0+:2], rst};
  if(|wrst) begin
    full <= 1'b1;
  end else begin
    if(enqueue && full) begin
      $display("Attempt to enqueue while asserting full!");
      $finish();
    end
    // Update full signal
    full <= next_waddr + SS1 == raddr_bin;
  end
  // Asynchronous address exchange
  raddr_gray_sync[0]  <= raddr_gray;
  raddr_gray_sync[1]  <= raddr_gray_sync[0];
  raddr_bin           <= GRAY2BIN(raddr_gray_sync[1]);

  waddr               <= next_waddr;
  waddr_gray          <= BIN2GRAY(next_waddr);
end

// Read clock region
reg [SIZE_SCALE-1:0]  raddr, waddr_bin;
wire[SIZE_SCALE-1:0]  next_raddr = raddr + ((~|rrst && dequeue) ? SS1 : SS0);
reg [3-1:0]           rrst;
always @(posedge rclk) begin
  rrst  <= {rrst[0+:2], rst};
  if(|rrst) begin
    empty       <= 1'b1;
    raddr       <= waddr_bin; // Force empty
    raddr_gray  <= waddr_gray_sync[1];
  end else begin
    if(dequeue && empty) begin
      $display("Attempt to dequeue while asserting empty!");
      $finish();
    end
    // Update empty signal
    empty       <= next_raddr == waddr_bin;
    raddr       <= next_raddr;
    raddr_gray  <= BIN2GRAY(next_raddr);
  end
  // Asynchronous address exchange
  waddr_gray_sync[0]  <= waddr_gray;
  waddr_gray_sync[1]  <= waddr_gray_sync[0];
  waddr_bin           <= GRAY2BIN(waddr_gray_sync[1]);

  // Update filled signal
  filled  <= $unsigned(waddr_bin - raddr) > FILLED_THRESH;
end

RAM #(SIZE_SCALE, WIDTH) rwram (
  wclk,
  enqueue,
  waddr,
  wdata,
  rclk,
  dequeue,
  raddr,
  rdata
);

function[SIZE_SCALE-1:0] BIN2GRAY(input [SIZE_SCALE-1:0]  bin);
  BIN2GRAY = bin ^ (bin>>1);
endfunction

// if GRAY2BIN behaves as reg...
//function[SIZE_SCALE-1:0] GRAY2BIN(input [SIZE_SCALE-1:0]  gray);
//  GRAY2BIN = gray ^ {1'b0, GRAY2BIN[SIZE_SCALE-1:1]};//(GRAY2BIN>>1);
//endfunction
function[SIZE_SCALE-1:0] GRAY2BIN(input [SIZE_SCALE-1:0]  gray);
  integer i;
  for (i = SIZE_SCALE-1; i >= 0; i = i - 1)
    GRAY2BIN[i] = (i == SIZE_SCALE-1) ? gray[i] : (gray[i] ^ GRAY2BIN[i+1]);
endfunction

initial begin
  {waddr, raddr_bin, raddr, waddr_bin, full} = 0;
  {empty, rrst, wrst} = ~0;
end
endmodule

module RAM #(parameter
  SIZE_SCALE  = 8,
  WIDTH       = 8
) (
  input   wire                  wclk,
  input   wire                  we,
  input   wire[SIZE_SCALE-1:0]  waddr,
  input   wire[WIDTH-1:0]       wdata,
  input   wire                  rclk,
  input   wire                  re,
  input   wire[SIZE_SCALE-1:0]  raddr,
  output  reg [WIDTH-1:0]       rdata
);

(* ram_style = "block" *)
reg [WIDTH-1:0] ram[0:2**SIZE_SCALE-1];

integer i;
initial for (i=0; i<2**SIZE_SCALE; i=i+1) ram[i] = 0;

always @(posedge wclk) if(we) ram[waddr] <= wdata;
always @(posedge rclk) if(re) rdata <= ram[raddr];

endmodule
