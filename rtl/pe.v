// Processing element of an output-stationary array: acc += a * b.
module pe (
  input  wire               clk, rst, clr, en,
  input  wire signed [7:0]  a_in, b_in,
  output reg  signed [7:0]  a_out, b_out,
  output reg  signed [31:0] acc
);
  wire signed [15:0] prod = a_in * b_in;
  always @(posedge clk) begin
    if (rst || clr) begin
      a_out <= 0; b_out <= 0; acc <= 0;
    end else if (en) begin
      a_out <= a_in;                 // pass right
      b_out <= b_in;                 // pass down
      acc   <= acc + prod;           // sign-extended
    end
  end
endmodule
