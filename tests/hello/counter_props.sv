// Formal hello-world: two properties of the counter, checked by SymbiYosys.
// Passing proves Yosys, SymbiYosys and the Boolector solver work together.
module counter_props (
    input logic clk,
    input logic rst_n,
    input logic en
);
  logic [7:0] count;

  counter #(.WIDTH(8)) dut (
      .clk  (clk),
      .rst_n(rst_n),
      .en   (en),
      .count(count)
  );

  // Start the check in reset
  logic init = 1'b1;
  always_ff @(posedge clk) init <= 1'b0;
  always_comb if (init) assume (!rst_n);

  always_ff @(posedge clk) begin
    if (!init && rst_n && $past(rst_n)) begin
      // When disabled, the count holds its value
      if (!$past(en)) assert (count == $past(count));
      // When enabled, the count goes up by exactly one (wrapping at 255)
      if ($past(en)) assert (count == 8'($past(count) + 1));
    end
  end
endmodule
