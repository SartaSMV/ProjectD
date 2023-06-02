/*
Модуль QPSK модуляции на вход получает биты
информации на выходе закодированный символ

i_clk - сигнал тактовой частоты
i_reset - сигнал сброса
i_data - входной бит информации
i_valid - сигнал валидности вызодного бита
o_data - выходной символ состоящий из двух числе Q и I
o_valid - сигнал валидности выходной информации

*/

module QPSK (
  // Управляющие сигналы
  input i_clk,
  input i_reset,
  // Входные данные
  input i_data,
  input i_valid,
  // Выходные данные
  output reg [31:0] o_data,
  output reg o_valid
);
// Вспомогающие регистры
reg count;
reg data;

// Параметры I и Q
parameter ZERO_ZERO = {16'd23169, 16'd23169},
ZERO_ONE = {-16'd23169, 16'd23169},
ONE_ZERO = {16'd23169, -16'd23169},
ONE_ONE = {-16'd23169, -16'd23169};

always @(posedge i_clk) begin
  // Сброс
  if(i_reset) begin
    count <= 1'b0;
    o_valid <= 1'b0;
    o_data <= {32{1'b0}};
  end
  // При валидных входных данных
  else if(i_valid) begin
    if(count == 1'b1) begin
      // Модуляция при накоплениии 2 бит
      case ({i_data, data})
        2'b00: o_data <= ZERO_ZERO;
        2'b01: o_data <= ZERO_ONE;
        2'b10: o_data <= ONE_ZERO;
        2'b11: o_data <= ONE_ONE;
        default: o_data <= ZERO_ZERO;
      endcase
      o_valid <= 1'b1;
    end
    else begin
      data <= i_data;
      o_valid <= 1'b0;
    end
    count <= count + 1;
  end
  // Сброс валидности
  else begin
    o_valid <= 1'b0;
  end
end

endmodule