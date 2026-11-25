`timescale 1ns/1ps
module tb_systolic;
  localparam N = 4, CASES = 300, E = N*N;
  reg clk = 0, rst = 1, start = 0; reg [E*8-1:0] a = 0, b = 0; wire [E*32-1:0] c; wire busy, done;
  systolic #(.N(N)) dut(.clk(clk), .rst(rst), .start(start), .a_flat(a), .b_flat(b), .c_flat(c), .busy(busy), .done(done));
  always #5 clk = ~clk;
  reg [7:0] av [0:CASES*E-1], bv [0:CASES*E-1]; reg [31:0] cv [0:CASES*E-1];
  integer errors = 0, n, e, cyc, lat = 0;

  initial begin
    $readmemh("build/a.hex", av); $readmemh("build/b.hex", bv); $readmemh("build/c.hex", cv);
    repeat (3) @(negedge clk); rst = 0;
    for (n=0;n<CASES;n=n+1) begin
      for (e=0;e<E;e=e+1) begin a[e*8 +: 8] = av[n*E+e]; b[e*8 +: 8] = bv[n*E+e]; end
      start = 1; @(negedge clk); start = 0;
      a = {E{8'h5a}}; b = {E{8'ha5}};                    // inputs must be latched
      cyc = 1;
      while (!done && cyc < 100) begin start = (cyc == 3); @(negedge clk); cyc = cyc+1; end
      start = 0;
      if (!done) begin errors = errors+1; $display("FAIL timeout"); end
      lat = cyc;
      for (e=0;e<E;e=e+1) if (c[e*32 +: 32] !== cv[n*E+e]) begin
        errors = errors+1; if (errors < 10) $display("FAIL case %0d elem %0d got %h exp %h", n, e, c[e*32 +: 32], cv[n*E+e]);
      end
      if (n % 3 == 0) repeat (n % 5) @(negedge clk);     // mix back-to-back and idle gaps
    end
    if (errors == 0) $display("PASS systolic: %0d cases, %0d cycles each", CASES, lat);
    $finish;
  end
endmodule
