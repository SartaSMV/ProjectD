


module top #(
  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 32
)(
  // Управляющие сигналы
  input clk,
  input reset,
  output ready,
  // Входные данные
  input [SIZE_INPUT_BIT-1:0] bits,
  input i_valid_input,
  // Выходные данные
  output [SIZE_OUTPUT_BIT-1:0] data,
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

Pack Pack (
  // Управляющие сигналы
  .i_clk(clk),
  .i_reset(reset),
  .o_ready(ready),
  // Входные данные
  .i_data(bits),
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
  .i_clk(clk),
  .i_reset(reset),
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
  .i_clk(clk),
  .i_reset(reset),
  // Входные данные
  .i_data(o_data_spread),
  .i_valid(o_valid_spread),
  // Выходные данные
  .o_data(o_data_fir_filter),
  .o_valid(o_valid_fir_filter)
);

fir_filter your_instance_name (
  .aclk(aclk),                              // input wire aclk
  .s_axis_data_tvalid(s_axis_data_tvalid),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(s_axis_data_tdata),    // input wire [31 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(m_axis_data_tdata)    // output wire [63 : 0] m_axis_data_tdata
);

assign data = o_data_fir_filter;
assign o_valid_output = o_valid_fir_filter;

endmodule
