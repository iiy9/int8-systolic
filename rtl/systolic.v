// N x N signed INT8 matrix multiply, C = A * B, with INT32 results.
// Row i of A and column j of B are skewed so a[i][k] and b[k][j] meet in PE(i,j).
module systolic #(parameter N = 4) (
  input  wire                  clk, rst, start,
  input  wire [N*N*8-1:0]      a_flat, b_flat,   // row-major, element 0 in the low byte
  output wire [N*N*32-1:0]     c_flat,
  output reg                   busy, done        // done is a one-cycle pulse
);
  localparam LAST = 3*N-3;                        // cycle index of the final MAC
  reg [N*N*8-1:0] a_r, b_r;
  reg [7:0] t;

  // Flat buses: column 0 of ah and row 0 of bv are the array inputs.
  wire [N*(N+1)*8-1:0] ah;                        // horizontal, index i*(N+1)+j
  wire [(N+1)*N*8-1:0] bv;                        // vertical,   index i*N+j
  wire clr = start && !busy;

  always @(posedge clk) begin
    done <= 1'b0;
    if (rst) begin
      busy <= 1'b0; t <= 0; a_r <= 0; b_r <= 0;
    end else if (clr) begin
      a_r <= a_flat; b_r <= b_flat; busy <= 1'b1; t <= 0;
    end else if (busy) begin
      t <= t + 1'b1;
      if (t == LAST) begin busy <= 1'b0; done <= 1'b1; end
    end
  end

  genvar i, j;
  generate
    for (i = 0; i < N; i = i + 1) begin : feed
      // The skew is a time offset: row i and column i start i cycles later.
      wire in_win = busy && (t >= i) && (t < i + N);
      wire [7:0] k = t - i;
      assign ah[(i*(N+1))*8 +: 8] = in_win ? a_r[(i*N + k)*8 +: 8] : 8'd0;
      assign bv[i*8 +: 8] = in_win ? b_r[(k*N + i)*8 +: 8] : 8'd0;
    end
    for (i = 0; i < N; i = i + 1) begin : row
      for (j = 0; j < N; j = j + 1) begin : col
        pe u (.clk(clk), .rst(rst), .clr(clr), .en(busy),
              .a_in (ah[(i*(N+1)+j)*8   +: 8]), .b_in (bv[(i*N+j)*8     +: 8]),
              .a_out(ah[(i*(N+1)+j+1)*8 +: 8]), .b_out(bv[((i+1)*N+j)*8 +: 8]),
              .acc(c_flat[(i*N + j)*32 +: 32]));
      end
    end
  endgenerate
endmodule
