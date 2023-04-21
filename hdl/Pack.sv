


module Pack #(
  parameter SIZE_MEMORY = 8,
  parameter SIZE_BIT_PACK = 1976,
  parameter SIZE_RAM = 1 << ($clog2(SIZE_BIT_PACK/SIZE_MEMORY) + 1),
  parameter SIZE_ADDR_RAM = $clog2(SIZE_RAM),
  parameter SIZE_ITERATOR_OUT_PACK = $clog2(SIZE_MEMORY)
)(
  input wea,
  // Управляющие сигналы
  input i_clk,
  input i_reset,
  // Входные данные
  input [SIZE_MEMORY-1:0] i_data,
  input i_ready_output,
  input i_valid_input,
  // Выходные данные
  output reg o_data,
  output reg o_valid
);

// Память для хранения пакетов
reg [SIZE_MEMORY-1:0] ram [SIZE_RAM-1:0];

// Регистр обозначающий какой сейчас пакет заполняется
reg input_pack;
// Заполненость следующего пакета
reg fill_next_pack;

// Регистры для хранения адреса ячейки
reg [SIZE_ADDR_RAM-2:0] addr_pack_in;
reg [SIZE_ADDR_RAM-2:0] addr_pack_out;

// Адрес записи и считывание данных
assign addr_input = {input_pack, addr_pack_in[SIZE_ADDR_RAM-2:0]};
assign addr_output = {~input_pack, addr_pack_out[SIZE_ADDR_RAM-2:0]};

always @(posedge i_clk or posedge i_reset) begin
  // Сброс
  if (i_reset) begin
    addr_pack_in <= {(SIZE_ADDR_RAM-1){1'b0}};
    fill_next_pack <= 1'b0;
    fill_next_pack <= 1'b0;
  end
  // 
  else if (i_valid_input) begin
    if (wea) ram[addr_input] <= i_data;
  end
end

reg [SIZE_ITERATOR_OUT_PACK-1:0] iterator_output_pack;
always @(posedge i_clk or posedge i_reset) begin
  // Сброс
  if (i_reset) begin
    input_pack <= 1'b0;
    fill_next_pack <= 1'b0;
    iterator_output_pack <= 0;
    addr_pack_out <= {(SIZE_ADDR_RAM-1){1'b0}};
  end
  // 
  else if (i_ready_output) begin
    o_data <= ram[addr_output][iterator_output_pack];
  end
end

endmodule