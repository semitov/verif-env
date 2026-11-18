// Hello-world design under test: an 8-bit counter with enable.
// Used only to prove that the toolchain works end to end.
module counter #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             en,
    output logic [WIDTH-1:0] count
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) count <= '0;
    else if (en) count <= count + 1'b1;
  end
endmodule
