/*
Генератор пакетов, считывает данные комплектует с преамбулой,
получая пакет. И отправляет его. Если есть запрос на выдачу,
а пакет не сформирован начинает считываться пакето холостого
хода.

i_clk - сигнал тактовой частоты
i_reset - сигнал сброса
o_ready - сигнал готовности принимать данные
i_data - входные данные
i_valid_input - валидность входных данных
i_ready_output - сигнал информирующий о выдаче следующих данных
o_data - выходные данные
o_valid - валидность выходных данных

*/


module Pack #(
  parameter SIZE_BIT_PACK = 1976,
  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 1,
  parameter SISE_PREAMBLE = 32,
  parameter LENGTHE_INPUT_BIT = SIZE_BIT_PACK / SIZE_INPUT_BIT,
  parameter LENGTHE_OUTPUT_BIT = SIZE_BIT_PACK / SIZE_OUTPUT_BIT,
  parameter SIZE_ADDR_INPUT = $clog2(LENGTHE_INPUT_BIT),
  parameter SIZE_ADDR_OUTPUT = $clog2(LENGTHE_OUTPUT_BIT),
  parameter ADDR_FIRST_WRITE = SISE_PREAMBLE / SIZE_INPUT_BIT
)(
  // Управляющие сигналы
  input i_clk,
  input i_reset,
  // Сигналы для входных данных
  output reg o_ready,
  input [SIZE_INPUT_BIT-1:0] i_data,
  input i_valid_input,
  // Сигналы для выходных данных
  input i_ready_output,
  output reg [SIZE_OUTPUT_BIT-1:0] o_data,
  output reg o_valid
);

// Регистр включающий память
reg enable_packs;

// Заполняемый пакет
reg input_package;

// Вывод пустого пакета
reg output_blank_package;

// Регистры для хранения адреса ячейки
reg [SIZE_ADDR_INPUT-1:0] addr_pack_in;
reg [SIZE_ADDR_OUTPUT-1:0] addr_pack_out;
reg [SIZE_ADDR_OUTPUT-1:0] addr_pack_blank;

// Правода для разных пакетов
wire out_pack_0, out_pack_1, out_blank_pack;
wire write_enable_pack_0, write_enable_pack_1;

// Разворота входных данных
wire [SIZE_INPUT_BIT-1:0] reverse_i_data;
generate
  for (genvar i = 0; i < SIZE_INPUT_BIT; i++) begin
    assign reverse_i_data[i] = i_data[SIZE_INPUT_BIT-1-i];
  end
endgenerate

// Состояние пакетов ввода и вывода
reg is_full_pack, is_empty_pack;
wire is_empty_pack_blank;
assign is_empty_pack_blank = (LENGTHE_OUTPUT_BIT-1) == addr_pack_blank;

// Включение ввода битов
assign write_enable_pack_0 = ~input_package && i_valid_input && o_ready;
assign write_enable_pack_1 = input_package && i_valid_input && o_ready;

// Включение вывода битов
assign read_enable_pack_0 = enable_packs && input_package && ~output_blank_package;
assign read_enable_pack_1 = ~enable_packs && input_package && ~output_blank_package;

// Вывод бита с нужного пакета
wire data;
assign data = output_blank_package ? out_blank_pack
  : (input_package ? out_pack_0 : out_pack_1);

blk_mem_gen_0 pack_1 (
  // BRAB_PORTA
  .addra(addr_pack_in),
  .clka(i_clk),
  .dina(reverse_i_data),
  .ena(enable_packs),
  .wea(write_enable_pack_0),
  // BRAB_PORTB
  .addrb(addr_pack_out),
  .clkb(i_clk),
  .doutb(out_pack_0),
  .enb(read_enable_pack_0)
);

blk_mem_gen_0 pack_2 (
  // BRAB_PORTA
  .addra(addr_pack_in),
  .clka(i_clk),
  .dina(reverse_i_data),
  .ena(enable_packs),
  .wea(write_enable_pack_1),
  // BRAB_PORTB
  .addrb(addr_pack_out),
  .clkb(i_clk),
  .doutb(out_pack_1),
  .enb(read_enable_pack_1)
);

blk_mem_gen_1 blank_pack (
  // BRAB_PORTA
  .addra(addr_pack_blank),
  .clka(i_clk),
  .douta(out_blank_pack),
  .ena(enable_packs)
);

// Ввод битов в пакет
always @(posedge i_clk) begin
  // Сброс
  if(i_reset) begin
    enable_packs <= 1'b1;

    input_package <= 1'b0;
    o_ready <= 1'b1;

    addr_pack_in <= ADDR_FIRST_WRITE;
    is_full_pack <= 1'b0;
  end
  // Заполнение пакета
  else if(i_valid_input) begin
    if(o_ready) begin
      if(is_full_pack) begin
        o_ready <= 1'b0;
      end
      else begin
        if(addr_pack_in < LENGTHE_INPUT_BIT-1) begin
          addr_pack_in <= addr_pack_in + 1;
        end
      end
      is_full_pack <= (LENGTHE_INPUT_BIT-1) == addr_pack_in;
    end
  end

  // Сменна пакета
  else if(is_full_pack && is_empty_pack && ~i_ready_output) begin
    input_package <= ~input_package;
    addr_pack_in <= ADDR_FIRST_WRITE;
    is_full_pack <= 1'b0;
    o_ready <= 1'b1;
  end
end

// Вывод битов из пакета
always @(posedge i_clk) begin
  // Сброс
  if(i_reset) begin
    is_empty_pack <= 1'b1;
    addr_pack_out <= LENGTHE_OUTPUT_BIT-1;

    output_blank_package <= 1'b1;
    addr_pack_blank <= {SIZE_ADDR_OUTPUT{1'b0}};
  end
  // Вывод бита
  else if(i_ready_output) begin
    // При выводи пакета холостого хода
    if(output_blank_package) begin
      if(is_empty_pack_blank) begin
        output_blank_package <= is_empty_pack;
        addr_pack_blank <= {SIZE_ADDR_OUTPUT{1'b0}};
      end
      // Увеличение счетчика
      else begin
        addr_pack_blank <= addr_pack_blank + 1;
      end
    end
    // При выводе из пакета
    else begin
      // Увеличение счетчика
      if(addr_pack_out < (LENGTHE_OUTPUT_BIT-1)) begin
        addr_pack_out <= addr_pack_out + 1;
      end
      else begin
        output_blank_package <= 1'b1;
      end 
    end
    is_empty_pack <= (LENGTHE_OUTPUT_BIT-1) == addr_pack_out;
    o_valid <= 1;
    o_data <= data;
  end
  else begin
    o_valid <= 1'b0;
    // Смена пакета
    if(is_full_pack && is_empty_pack && ~i_valid_input) begin
      if(addr_pack_blank == {SIZE_ADDR_OUTPUT{1'b0}}) begin
        output_blank_package <= 1'b0;
      end
      addr_pack_out <= {SIZE_ADDR_OUTPUT{1'b0}};
      is_empty_pack <= 1'b0;
    end
  end
end

endmodule