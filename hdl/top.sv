


module top #(
  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 32
)(
  // Управляющие сигналы
  input i_clk,
  input i_reset,
  // Входные данные
  input [SIZE_INPUT_BIT-1:0] o_bits,
  input i_valid_input,
  output ready,
  // Выходные данные
  output [SIZE_OUTPUT_BIT*2-1:0] o_data,
  output o_valid_output
);

Modulator Modulator (
  // Управляющие сигналы
  .i_clk(),
  .i_reset(),
  // Входные данные
  .i_data(),
  .i_valid_input(),
  .o_ready(),
  // Выходные данные
  .o_data(),
  .o_valid_output()
);

endmodule
