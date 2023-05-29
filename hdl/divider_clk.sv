


module Divider_clk #(
  parameter DIVIDER = 240,
  parameter SIZE_COUNTER = $clog2(DIVIDER)
)(
  input i_clk,
  input i_reset,
  output reg o_clk
);

reg [SIZE_COUNTER-1:0] count;

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset) begin
    count <= {SIZE_COUNTER{1'b0}};
    o_clk <= 1'b0;
  end
  else begin
    if(count < DIVIDER) begin
      count <= count + 1;
      o_clk <= 1'b0;
    end
    else begin
      count <= {SIZE_COUNTER{1'b0}};
      o_clk <= 1'b1;
    end
  end
end


endmodule