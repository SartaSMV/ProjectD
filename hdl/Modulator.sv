/*
QPSK модулятор широкополосного сигнала

i_clk - сигнал тактовой частоты
i_reset - сигнал сброса
i_data - входные данные, по восемь бит
i_valid_input - валидность входных данных
o_ready - готовность принимать данные
o_data - выходные в виде символа из Q и I 64 бита
o_valid_output - валидность выходных данных

*/


module Modulator #(
  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 32
)(
  // Управляющие сигналы
  input i_clk,
  input i_reset,
  // Входные данные
  input [SIZE_INPUT_BIT-1:0] i_data,
  input i_valid_input,
  output o_ready,
  // Выходные данные
  output [SIZE_OUTPUT_BIT*2-1:0] o_data,
  output o_valid_output
);

// Передача данных из пакета
wire o_data_pack;
wire o_valid_pack;

// Передача расширенного сигнала
wire o_data_spread;
wire o_valid_spread;
wire o_ready_spread;

// Передача сформированного знака
wire [SIZE_OUTPUT_BIT-1:0] o_data_fir_filter;
wire o_valid_fir_filter;

// Передача данных с фильтра
wire s_axis_data_tready;

Pack Pack (
  // Управляющие сигналы
  .i_clk(i_clk),
  .i_reset(i_reset),
  .o_ready(o_ready),
  // Входные данные
  .i_data(i_data),
  .i_ready_output(o_ready_spread),
  .i_valid_input(i_valid_input),
  // Выходные данные
  .o_data(o_data_pack),
  .o_valid(o_valid_pack)
);

Spread #(
  .SPREAD(24)
)
Spread (
  // Управляющие сигналы
  .i_clk(i_clk),
  .i_reset(i_reset),
  .o_ready(o_ready_spread),
  // Входные данные
  .i_data(o_data_pack),
  .i_valid(o_valid_pack),
  // Выходные данные
  .o_data(o_data_spread),
  .o_valid(o_valid_spread)
);

QPSK QPSK (
  // Управляющие сигналы
  .i_clk(i_clk),
  .i_reset(i_reset),
  // Входные данные
  .i_data(o_data_spread),
  .i_valid(o_valid_spread),
  // Выходные данные
  .o_data(o_data_fir_filter),
  .o_valid(o_valid_fir_filter)
);

fir_compiler_0 fir_filter (
  .aclk(i_clk),
  .s_axis_data_tvalid(o_valid_fir_filter),
  .s_axis_data_tready(),
  .s_axis_data_tdata(o_data_fir_filter),
  .m_axis_data_tvalid(o_valid_output),
  .m_axis_data_tdata(o_data)
);

endmodule
