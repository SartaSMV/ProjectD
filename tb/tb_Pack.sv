`timescale 1ns / 1ps

module tb_Pack #(
  parameter PERIOD = 20,
  parameter CLK = PERIOD/2,

  parameter SIZE_BIT_PACK = 1976,
  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 1,
  parameter SISE_PREAMBLE = 32,
  parameter LENGTHE_INPUT_BIT = SIZE_BIT_PACK / SIZE_INPUT_BIT,
  parameter LENGTHE_OUTPUT_BIT = SIZE_BIT_PACK / SIZE_OUTPUT_BIT,
  parameter SIZE_ADDR_INPUT = $clog2(LENGTHE_INPUT_BIT),
  parameter SIZE_ADDR_OUTPUT = $clog2(LENGTHE_OUTPUT_BIT),
  parameter ADDR_FIRST_WRITE = SISE_PREAMBLE / SIZE_INPUT_BIT
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

// Начальные условия
int fid;
bit ref_output [0:SIZE_BIT_PACK-1];
bit ref_output_blank [0:SIZE_BIT_PACK-1];
bit module_output [0:SIZE_BIT_PACK-1];
bit [SIZE_INPUT_BIT-1:0] ref_input [0:SIZE_BIT_PACK/8-1];
initial begin
  fid = $fopen("tb_pack.dat", "r");
  for(int i = 0; i<SIZE_BIT_PACK; i++) begin
    $fscanf(fid,"%b",ref_output[i]);
  end
  for(int i = 0; i<SIZE_BIT_PACK; i++) begin
    if(i < SISE_PREAMBLE) ref_output_blank[i] = ref_output[i];
    else ref_output_blank[i] = 0;
  end

  ref_input = {>>8 {ref_output}};

  i_clk <= 0;
  i_reset <= 0;

  i_data <= {SIZE_INPUT_BIT{1'b0}};
  i_ready_output <= 0;
  i_valid_input <= 0;
end

int count = 0;
always @(posedge i_clk) begin
  if(o_valid) begin
    module_output[count] <= o_data;
    if(count == LENGTHE_OUTPUT_BIT-1) begin
      count <= 0;
    end
    else count <= count + 1;
  end
end

// Преамбула
// 11001111 10000000 10101010 00110001 - CF 80 AA 31
// 11110011 00000001 01010101 10001100 - F3 01 55 8C

//Симуляция
initial begin
  // reset data
  -> reset_trigger;
  @(reset_trigger_done);

  // write_pack
  for(int i = ADDR_FIRST_WRITE; i<LENGTHE_INPUT_BIT; i++) begin
    i_valid_input <= 1'b1;
    i_data <= ref_input[i];
    @(posedge i_clk);
    i_valid_input <= 1'b0;
    @(posedge i_clk);
  end
  @(posedge i_clk);
  @(posedge i_clk);

  // read pack
  for(int i=0; i<LENGTHE_OUTPUT_BIT; i++) begin
    i_ready_output <= 1'b1;
    @(posedge i_clk);
    i_ready_output <= 1'b0;
    @(posedge i_clk);
  end
  @(posedge i_clk);
  @(posedge i_clk);

  // compare
  for(int i=0; i<LENGTHE_OUTPUT_BIT; i++) begin
    $display("%d modul %b, ref %b", i, ref_output[i], ref_output[i]);
  end
  $display("modul==ref %b", ref_output==ref_output);

  -> terminate_sim;
end

final begin
  $fclose(fid);
end

endmodule