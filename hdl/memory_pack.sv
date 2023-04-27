

module memory_pack #(
  parameter SIZE_BIT_PACK = 1976,
  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 1,
  parameter LENGTHE_INPUT_BIT = SIZE_BIT_PACK / SIZE_INPUT_BIT,
  parameter LENGTHE_OUTPUT_BIT = SIZE_BIT_PACK / SIZE_OUTPUT_BIT,
  parameter SIZE_ADDR_INPUT = $clog2(LENGTHE_INPUT_BIT),
  parameter SIZE_ADDR_OUTPUT = $clog2(LENGTHE_OUTPUT_BIT),
  parameter SISE_PREAMBLE = 32
)(
  // Управляющие сигналы
  input i_clk,
  input i_reset,
  output reg o_ready,
  // Входные данные
  input [SIZE_ADDR_INPUT-1:0] addr_pack_in,
  input i_valid,
  input [SIZE_INPUT_BIT-1:0] i_data,
  input [SIZE_ADDR_OUTPUT-1:0] addr_pack_out,
  // Выходные данные
  output [SIZE_OUTPUT_BIT-1:0] o_data
);

// Регистр обозначающий какой сейчас пакет заполняется
reg enable_packs;

// Регистр обозначающий какой сейчас пакет заполняется
reg input_pack;

// Регистр обозначающий какой сейчас пакет выводиться
reg [1:0] output_pack;

// Заполненость пакетов
reg [1:0] fill_packs;

// Правода для разных пакетов
wire out_pack_1, out_pack_2, out_blank_pack;
wire write_enable_pack_1, write_enable_pack_2;

wire next_fill_in_packs, next_fill_out_packs;

// Разворота входных данных
wire [SIZE_INPUT_BIT-1:0] reverse_i_data;
generate
  for (genvar i = 0; i < SIZE_INPUT_BIT; i++) begin
    assign reverse_i_data[i] = i_data[SIZE_INPUT_BIT-1-i];
  end
endgenerate

assign write_enable_pack_1 = (~input_pack) & i_valid & o_ready;
assign write_enable_pack_2 = input_pack & i_valid & o_ready;

assign next_fill_in_packs = fill_packs | (2'b01 << input_pack);
assign next_fill_out_packs = fill_packs & (2'b01 << input_pack + 1);

blk_mem_gen_0 pack_1 (
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
  .enb(enable_packs)
);

blk_mem_gen_0 pack_2 (
  // BRAB_PORTA
  .addra(addr_pack_in),
  .clka(i_clk),
  .dina(reverse_i_data),
  .ena(enable_packs),
  .wea(write_enable_pack_2),
  // BRAB_PORTB
  .addrb(addr_pack_out),
  .clkb(i_clk),
  .doutb(out_pack_2),
  .enb(enable_packs)
);

blk_mem_gen_1 blank_pack (
  // BRAB_PORTA
  .addra(addr_pack_in),
  .clka(i_clk),
  .douta(out_blank_pack),
  .ena(enable_packs)
);

assign out_pack = (output_pack==2'b00 & out_blank_pack) 
  | (output_pack==2'b01 & out_pack_1) 
  | (output_pack==2'b10 & out_pack_2);

always @(posedge i_clk or posedge i_reset) begin
  // Сброс
  if(i_reset) begin
    input_pack <= 1'b0;
    output_pack <= 2'b00;
    fill_packs <= 2'b00;
    enable_packs <= 1'b1;

    o_ready <= 1'b1;
  end
  // Заполнения пакета
  else if(addr_pack_in == SIZE_INPUT_BIT - 1) begin
    if(&next_fill_in_packs) begin
      o_ready <= 1'b0;
    end
    else begin
      input_pack <= input_pack + 1;
      o_ready <= 1'b1;
    end
    fill_packs <= next_fill_in_packs;
  end
  // Освобождения пакета
  else if(addr_pack_out == LENGTHE_OUTPUT_BIT - 1) begin
    if(|next_fill_out_packs) begin
      output_pack <= next_fill_out_packs;
    end
    else begin
      output_pack <= 2'b00;
    end
    fill_packs <= next_fill_out_packs;
  end
  else begin

  end
end

endmodule