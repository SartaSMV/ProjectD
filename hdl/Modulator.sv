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
  output [79:0] o_data,
  output o_valid_output
);

// Передача данных из пакета
wire o_data_pack;
wire o_valid_pack;

// Передача расширенного сигнала
wire o_data_spread;
wire o_valid_spread;
wire o_ready_spread;
wire i_enable_spread;

// Работа fifo для соблюдения частоты
wire prog_full_fifo_with_spread;
wire i_rd_en_fifo_with_spread;
wire valid_fifo_with_spread;
wire o_data_fifo_with_spread;

// Передача сформированного знака
wire [SIZE_OUTPUT_BIT-1:0] o_data_fir_filter;
wire o_valid_fir_filter;

// Передача данных с фильтра
wire s_axis_data_tready_firx2;
wire m_axis_data_tvalid_firx2;
wire [63:0] m_axis_data_tdata_firx2;

// fifo_for_firx4
wire [31:0] din_fifo_for_firx4;
wire i_rd_en_fifo_for_firx4;
wire prog_full_fifo_for_firx4;
wire valid_fifo_for_firx4;
wire [31:0] o_data_fifo_for_firx4;


assign i_enable_spread = ~prog_full_fifo_with_spread;
assign din_fifo_for_firx4 = {m_axis_data_tdata_firx2[63:48], m_axis_data_tdata_firx2[31:16]};

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
  .i_enable(i_enable_spread),
  .o_data(o_data_spread),
  .o_valid(o_valid_spread)
);

Divider_clk #(
  .DIVIDER(120)
)
Divider_clk_for_fifo_with_spread (
  .i_clk(i_clk),
  .i_reset(i_reset),
  .i_ready(prog_full_fifo_with_spread),
  .o_clk(i_rd_en_fifo_with_spread)
);

fifo_generator_0 fifo_with_spread (
  .clk(i_clk),
  .srst(i_reset),
  .din(o_data_spread),
  .wr_en(o_valid_spread),
  .rd_en(i_rd_en_fifo_with_spread),
  .dout(o_data_fifo_with_spread),
  .full(),
  .empty(),
  .valid(valid_fifo_with_spread),
  .prog_full(prog_full_fifo_with_spread)
);

QPSK QPSK (
  // Управляющие сигналы
  .i_clk(i_clk),
  .i_reset(i_reset),
  // Входные данные
  .i_data(o_data_fifo_with_spread),
  .i_valid(valid_fifo_with_spread),
  // Выходные данные
  .o_data(o_data_fir_filter),
  .o_valid(o_valid_fir_filter)
);

fir_compiler_0 fir_filterx2 (
  .aclk(i_clk),
  .s_axis_data_tvalid(o_valid_fir_filter),
  .s_axis_data_tready(),
  .s_axis_data_tdata(o_data_fir_filter),
  .m_axis_data_tvalid(m_axis_data_tvalid_firx2),
  .m_axis_data_tdata(m_axis_data_tdata_firx2)
);

Divider_clk #(
  .DIVIDER(120)
)
Divider_clk_for_fifo_with_fir_filterx2 (
  .i_clk(i_clk),
  .i_reset(i_reset),
  .i_ready(prog_full_fifo_for_firx4),
  .o_clk(i_rd_en_fifo_for_firx4)
);

fifo_for_firx4 fifo_for_firx4 (
  .clk(i_clk),
  .srst(i_reset),
  .din(din_fifo_for_firx4),
  .wr_en(m_axis_data_tvalid_firx2),
  .rd_en(i_rd_en_fifo_for_firx4),
  .dout(o_data_fifo_for_firx4),
  .full(),
  .empty(),
  .valid(valid_fifo_for_firx4),
  .prog_full(prog_full_fifo_for_firx4)
);

fir_4x fir_4x(
  .aclk(i_clk),
  .s_axis_data_tvalid(valid_fifo_for_firx4),
  .s_axis_data_tready(),
  .s_axis_data_tdata(o_data_fifo_for_firx4),
  .m_axis_data_tvalid(o_valid_output),
  .m_axis_data_tdata(o_data)
);




endmodule
