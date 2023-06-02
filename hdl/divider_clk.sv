


module Divider_clk #(
  parameter DIVIDER = 240,
  parameter SIZE_COUNTER = $clog2(DIVIDER)
)(
  input i_clk,
  input i_reset,
  input i_ready,
  output reg o_clk
);

reg [SIZE_COUNTER-1:0] count;
reg ready;

always @(posedge i_clk) begin
  if(i_reset) begin
    count <= {SIZE_COUNTER{1'b0}};
    o_clk <= 1'b0;
    ready <= 1'b0;
  end
  else if(i_ready && ~ready) begin
    ready <= 1'b1;
  end
  else if(ready) begin
    if(count < DIVIDER - 1) begin
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