/*
Модуль генерации псевдо случайной последовательности
основанной на сдвиговом регистре

i_clk - сигнал тактовой частоты
i_reset - сигнал сброса
i_valid - сигнал валидности вызодного бита
o_data - Выходной бит

*/

module lfsr(
  // Сигналы управления
  input i_clk,
  input i_reset,
  // Сигнал валидности
  input i_valid,
  // Выход
  output o_data
);

// Регистр сдвига
reg [8:0] shift_reg;

always @(posedge i_clk) begin
  if(i_reset) shift_reg <= 37;
  else if(i_valid) shift_reg <= {shift_reg[0], shift_reg[8:6], shift_reg[6] ^ shift_reg[0], shift_reg[4:1]};
end

assign o_data = shift_reg[0];

endmodule
