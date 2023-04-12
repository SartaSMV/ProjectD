


module top(
  input clk,
  input reset,

  input bits,

  output [31:0] data
);

// Передача данных из пакета
wire o_data_Pack;
wire o_valid_Pack;

// Передача оасширенного сигнала
wire o_data_spread;
wire o_valid_spread;

Pack Pack (
  .i_clk(clk),
  .i_reset(reset),

  .i_data(bits),
  .i_valid(),

  .o_data(o_data_Pack),
  .o_valid(o_valid_Pack)
);

Spread #(
  .SPREAD(24)
)
Spread (
  .i_clk(clk),
  .i_reset(reset),
  .o_readi(),

  .i_data(o_data_Pack),
  .i_valid(o_valid_Pack),

  .o_data(o_data_spread),
  .o_valid(o_valid_spread)
);

QPSK QPSK (
  .i_clk(clk),
  .i_reset(reset),

  .i_data(o_data_spread),
  .i_valid(o_valid_spread),

  .o_data(),
  .o_valid()
);

endmodule
