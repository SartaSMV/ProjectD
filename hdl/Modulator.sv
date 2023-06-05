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
  output [31:0] o_data,
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

// firx4
wire [31:0] s_axis_data_tdata_firx4;
wire m_axis_data_tvalid_firx4;
wire [79:0] m_axis_data_tdata_firx4;

// cic_I
wire m_axis_data_tvalid_cic_I;
wire signed [15:0] s_axis_data_tdata_cic_I;
wire signed [31:0] m_axis_data_tdata_cic_I;

// cic_Q
wire m_axis_data_tvalid_cic_Q;
wire signed [15:0] s_axis_data_tdata_cic_Q;
wire signed [31:0] m_axis_data_tdata_cic_Q;

// immit_data_coder
wire psp_data_out_en;
wire [7:0] psp_data_out;

assign i_enable_spread = ~prog_full_fifo_with_spread;

assign s_axis_data_tdata_firx4 = {m_axis_data_tdata_firx2[63:48], m_axis_data_tdata_firx2[31:16]};

assign s_axis_data_tdata_cic_I = m_axis_data_tdata_firx4[72-2:55];
assign s_axis_data_tdata_cic_Q = m_axis_data_tdata_firx4[32-2:15];

immit_data_coder immit_data_coder(
  .clk(i_clk),
  .reset(i_reset),
  .enable(o_ready),

  .data_out_en(psp_data_out_en),
  .data_out(psp_data_out)
);

Pack Pack (
  // Управляющие сигналы
  .i_clk(i_clk),
  .i_reset(i_reset),
  .o_ready(o_ready),
  // Входные данные
  .i_data(psp_data_out),
  .i_ready_output(o_ready_spread),
  .i_valid_input(psp_data_out_en),
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

wire tready_firx2;
fir_compiler_0 fir_filterx2 (
  .aclk(i_clk),
  .s_axis_data_tvalid(o_valid_fir_filter),
  .s_axis_data_tready(tready_firx2),
  .s_axis_data_tdata(o_data_fir_filter),
  .m_axis_data_tvalid(m_axis_data_tvalid_firx2),
  .m_axis_data_tdata(m_axis_data_tdata_firx2)
);

fir_4x fir_4x(
  .aclk(i_clk),
  .s_axis_data_tvalid(m_axis_data_tvalid_firx2),
  .s_axis_data_tready(),
  .s_axis_data_tdata(s_axis_data_tdata_firx4),
  .m_axis_data_tvalid(m_axis_data_tvalid_firx4),
  .m_axis_data_tdata(m_axis_data_tdata_firx4)
);

cic cic_I (
  .aclk(i_clk),
  .s_axis_data_tdata(s_axis_data_tdata_cic_I),
  .s_axis_data_tvalid(m_axis_data_tvalid_firx4),
  .s_axis_data_tready(),
  .m_axis_data_tdata(m_axis_data_tdata_cic_I),
  .m_axis_data_tvalid(m_axis_data_tvalid_cic_I)
);

cic cic_Q (
  .aclk(i_clk),
  .s_axis_data_tdata(s_axis_data_tdata_cic_Q),
  .s_axis_data_tvalid(m_axis_data_tvalid_firx4),
  .s_axis_data_tready(),
  .m_axis_data_tdata(m_axis_data_tdata_cic_Q),
  .m_axis_data_tvalid(m_axis_data_tvalid_cic_Q)
);

assign o_data = {m_axis_data_tdata_cic_I[31-2:14], m_axis_data_tdata_cic_Q[31-2:14]};
assign o_valid_output = m_axis_data_tvalid_cic_I && m_axis_data_tvalid_cic_Q;

endmodule
