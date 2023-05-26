/*
Модуль расширения спекрта, на вход приходит бит информации
и этот бит раширяется путем побитого xor с псевдослучайной
сгенерированой последовательностью.

i_clk - сигнал тактовой частоты
i_reset - сигнал сброса
o_ready - готовнось принимать следующий бит
i_data - входной бит информации
i_valid - сигнал валидности вызодного бита
o_data - выходной бит
o_valid - сигнал валидности выходной информации

*/


module Spread #(
  parameter SPREAD = 24,
  parameter SIZE_COUNTER = $clog2(SPREAD)
)(
  // Управляющие сигналы
  input i_clk,
  input i_reset,
  // Сигналы для входа
  input i_data,
  input i_valid,
  output reg o_ready,
  // Сигналы для вывода
  input i_enable,
  output o_data,
  output reg o_valid
);

// Вспомогательные регистры для расширения
reg [SPREAD-1:0] spreading_code;
reg [SIZE_COUNTER-1:0] counter;
reg input_data;

// Вспомогательные регистры для ПСП
wire o_lfsr_data;
reg i_lfsr_valid;
reg [SIZE_COUNTER-1:0] spread_counter;
reg lfsr_ready;

// Генератор ПСП
lfsr lfsr (
  .i_clk(i_clk),
  .i_reset(i_reset),

  .i_valid(i_lfsr_valid),
  .o_data(o_lfsr_data)
);

assign o_data = spreading_code[counter] ^ input_data;

// Генерация ПСП
always @(posedge i_clk or posedge i_reset) begin
  // Сброс
  if (i_reset) begin
    spreading_code <= {SPREAD{1'b0}};
    spread_counter <= {SIZE_COUNTER{1'b0}};
    i_lfsr_valid <= 1'b1;
  end
  // Генерируем ПСП
  else if(i_lfsr_valid) begin
    if(spread_counter == SPREAD - 1) begin 
      i_lfsr_valid <= 1'b0;
    end
    spreading_code[spread_counter] <= o_lfsr_data;
    spread_counter <= spread_counter + 1;
  end
end

// Генерация расширенного бита
always @(posedge i_clk or posedge i_reset) begin
  // Сброс
  if (i_reset) begin
    o_ready <= 1'b0;
    o_valid <= 1'b0;

    counter <= {SIZE_COUNTER{1'b0}};
    input_data <= 1'b0;
    lfsr_ready <= 1'b0;
  end
  // ПСП сгенерировано
  else if (lfsr_ready) begin
    // Расширяем бит
    if(o_valid) begin
      if(counter == SPREAD - 1) begin
        // Ждем воз
        if(~i_enable) begin
          lfsr_ready <= 1'b0;
        end
        // Считываем новый бит
        else if(i_valid) begin
          input_data <= i_data;
        end
        o_ready <= 1'b0;
        counter <= {SIZE_COUNTER{1'b0}};
        o_valid <= i_valid;
      end
      else begin
        //увеличения счетчика
        counter <= counter + 1;
        // Подача сигнала заранее, чтобы расширять непрерывно
        if(counter == SPREAD - 3 && i_enable) begin
          o_ready <= 1'b1;
        end
        else begin
          o_ready <= 1'b0;
        end
      end
    end
    // Ждем валидных данных
    else if(i_valid) begin
      input_data <= i_data;
      counter <= {SIZE_COUNTER{1'b0}};
      o_ready <= 1'b0;
      o_valid <= 1'b1;
    end
    // Сброс готовности и валидности
    else begin
      o_valid <= 1'b0;
      o_ready <= 1'b0;
    end
  end
  // Включения расширения спектра
  else if(~i_lfsr_valid) begin
    lfsr_ready <= i_enable;
    o_ready <= i_enable;
  end
end


endmodule