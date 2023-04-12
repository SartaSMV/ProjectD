


module Spread #(
  parameter SPREAD = 24,
  parameter SIZE_COUNTER = $clog2(SPREAD)
)(
  // Управляющие сигналы
  input i_clk,
  input i_reset,
  output reg o_readi,
  // Входные данные
  input i_data,
  input i_valid,
  // Выходные данные
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

// ПСП
lfsr lfsr (
  .i_clk(i_clk),
  .i_reset(i_reset),

  .i_valid(i_lfsr_valid),
  .o_data(o_lfsr_data)
);

assign o_data = spreading_code[counter] ^ input_data;

always @(posedge i_clk or posedge i_reset) begin
  // Сброс
  if (i_reset) begin
    o_readi <= 1'b0;
    o_valid <= 1'b0;

    spreading_code <= {SPREAD{1'b0}};
    counter <= {SIZE_COUNTER{1'b0}};
    input_data <= 1'b0;
    i_lfsr_valid <= 1'b1;
  end
  else if(i_lfsr_valid || o_valid) begin
    if(counter == SPREAD - 1) begin 
      i_lfsr_valid <= 1'b0;
      o_readi <= 1'b1;
      o_valid <= 1'b0;
    end
    else begin
      if(i_lfsr_valid) spreading_code[counter] <= o_lfsr_data;
      counter <= counter + 1;
    end
  end
  // Загрузка бита
  else if(o_readi && i_valid) begin
    input_data <= i_data;
    o_valid <= 1'b1;

    counter <= {SIZE_COUNTER{1'b0}};
    o_readi <= 1'b0;
  end
  else o_valid <= 1'b0;
end


endmodule