`timescale 1ns / 1ps

module tb_Pack #(
  parameter PERIOD = 20,
  parameter CLK = PERIOD/2,

  parameter SIZE_BIT_PACK = 1976,
  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 1,
  parameter LENGTHE_INPUT_BIT = SIZE_BIT_PACK / SIZE_INPUT_BIT,
  parameter LENGTHE_OUTPUT_BIT = SIZE_BIT_PACK / SIZE_OUTPUT_BIT,
  parameter SIZE_ADDR_INPUT = $clog2(LENGTHE_INPUT_BIT),
  parameter SIZE_ADDR_OUTPUT = $clog2(LENGTHE_OUTPUT_BIT),
  parameter SISE_PREAMBLE = $clog2(32)
);

// Управляющие сигналы
reg i_clk;
reg i_reset;
wire o_ready;
// Входные данные
reg [SIZE_INPUT_BIT-1:0] i_data;
reg i_ready_output;
reg i_valid_input;
// Выходные данные
wire [SIZE_OUTPUT_BIT-1:0] o_data;
wire o_valid;

Pack tb (
  // Управляющие сигналы
  .i_clk(i_clk),
  .i_reset(i_reset),
  .o_ready(o_ready),
  // Входные данные
  .i_data(i_data),
  .i_ready_output(i_ready_output),
  .i_valid_input(i_valid_input),
  // Выходные данные
  .o_data(o_data),
  .o_valid(o_valid)
);

always #CLK i_clk = ~i_clk;

// Сброс модуля
event reset_trigger;
event reset_trigger_done;
initial begin
  forever begin
    @(reset_trigger)
    @(posedge i_clk);
    i_reset <= 1;
    @(posedge i_clk);
    @(posedge i_clk);
    i_reset <= 0;
    -> reset_trigger_done;
  end
end

event terminate_sim;
initial begin
	@(terminate_sim);
	#5 $finish;
end

event inpute_pack;
initial begin
  @(inpute_pack);

  i_valid_input <= 1'b1;
  for(int i=0; i<LENGTHE_INPUT_BIT-1; i++) begin
    i_data <= {2'b1, {SIZE_INPUT_BIT-3{1'b0}}, 1'b1};
    @(posedge i_clk);
  end
  i_valid_input <= 1'b0;
end

// Начальные условия
initial begin
  i_clk <= 0;
  i_reset <= 0;

  i_data <= {SIZE_INPUT_BIT{1'b0}};
  i_ready_output <= 0;
  i_valid_input <= 0;
end

//Симуляция
// 11001111 10000000 10101010 00110001 - CF 80 AA 31
// 11110011 00000001 01010101 10001100 - F3 01 55 8C
initial begin
  -> reset_trigger;
  @(reset_trigger_done);



  -> terminate_sim;
end

endmodule