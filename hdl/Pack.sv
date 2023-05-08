


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
  output o_ready,
  // Входные данные
  input [SIZE_INPUT_BIT-1:0] i_data,
  input i_ready_output,
  input i_valid_input,
  // Выходные данные
  output reg [SIZE_OUTPUT_BIT-1:0] o_data,
  output reg o_valid
);


// Регистры для хранения адреса ячейки
reg [SIZE_ADDR_INPUT-1:0] addr_pack_in;
reg [SIZE_ADDR_OUTPUT-1:0] addr_pack_out;

// Провод с выхода пакета
wire [SIZE_OUTPUT_BIT-1:0] o_data_generate_pack;

// Модуль с хранением пакетов и их заполнением
memory_pack #(
  .SIZE_BIT_PACK(SIZE_BIT_PACK),
  .SIZE_INPUT_BIT(SIZE_INPUT_BIT),
  .SIZE_OUTPUT_BIT(SIZE_OUTPUT_BIT)
) 
generate_pack (
  // Управляющие сигналы
  .i_clk(i_clk),
  .i_reset(i_reset),
  .o_ready(o_ready),
  // Входные данные
  .addr_pack_in(addr_pack_in),
  .i_valid(i_valid_input),
  .i_data(i_data),
  
  .addr_pack_out(addr_pack_out),
  // Выходные данные
  .o_data(o_data_generate_pack)
);

// Работа для ввода бит
always @(posedge i_clk or posedge i_reset) begin
  // Сброс
  if(i_reset) begin
    addr_pack_in <= ADDR_FIRST_WRITE;
  end
  else if(i_valid_input && o_ready) begin
    if(addr_pack_in == LENGTHE_INPUT_BIT - 1) begin
      addr_pack_in <= ADDR_FIRST_WRITE;
    end
    else begin
      addr_pack_in <= addr_pack_in + 1;
    end
  end
end

// Работа для вывода бит
always @(posedge i_ready_output or posedge i_reset) begin
  if(i_reset) begin
    addr_pack_out <= 1;
    o_valid <= 1'b0;
  end
  else if(i_ready_output) begin
    if (addr_pack_out == LENGTHE_OUTPUT_BIT - 1) begin
      addr_pack_out <= 1;
    end
    else begin
      addr_pack_out <= addr_pack_out + 1;
    end
    o_data <= o_data_generate_pack;
    o_valid <= 1'b1;
  end
  else begin
    o_valid <= 1'b0;
  end
end

endmodule