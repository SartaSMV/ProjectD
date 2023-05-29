`timescale 1ns / 1ps


module tb_Modulator #(
  parameter PERIOD = 10,
  parameter CLK = PERIOD/2,

  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 32,

  parameter SIZE_BIT_PACK = 1976,
  parameter SISE_PREAMBLE = 32,
  parameter ADDR_FIRST_WRITE = SISE_PREAMBLE / SIZE_INPUT_BIT,
  parameter SIZE_ADDR_OUTPUT = $clog2(SIZE_BIT_PACK),

  parameter SPREAD = 24,
  parameter SIZE_COUNTER = $clog2(SPREAD)
);

reg i_clk;
reg i_reset;

reg [SIZE_INPUT_BIT-1:0] i_data;
wire o_valid_output;
reg i_valid_input;

wire o_ready;
wire [0:0] o_data;

Modulator tb (
  .i_clk(i_clk),
  .i_reset(i_reset),

  .i_data(i_data),
  .i_valid_input(o_valid_output),
  .o_ready(o_ready),
  // Выходные данные
  .o_data(o_data),
  .o_valid_output(o_valid_output)
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
    repeat (4) begin
      @(posedge i_clk);
    end
    i_reset <= 0;
    -> reset_trigger_done;
  end
end

// Начальные условия
int fid_o, fid_i;
bit ref_output [0:SIZE_BIT_PACK-1];
bit ref_output_blank [0:SIZE_BIT_PACK-1];
bit module_output [0:SIZE_BIT_PACK-1];
bit [SIZE_INPUT_BIT-1:0] ref_input [0:SIZE_BIT_PACK/8-1];
initial begin
  fid_o = $fopen("tb_pack.dat", "r");
  for(int i = 0; i<SIZE_BIT_PACK; i++) begin
    $fscanf(fid_o,"%b",ref_output[i]);
  end
  for(int i = 0; i<SIZE_BIT_PACK; i++) begin
    if(i < SISE_PREAMBLE) ref_output_blank[i] = ref_output[i];
    else ref_output_blank[i] = 0;
  end

  fid_i = $fopen("output.txt", "w");


  i_clk <= 0;
  i_reset <= 0;

  i_data <= {SIZE_INPUT_BIT{1'b0}};
  i_valid_input <= 0;
end

event terminate_sim;
initial begin
	@(terminate_sim);
	#5 $finish;
end


reg ok;
reg [SIZE_COUNTER-1:0] count_spread;
reg [SIZE_ADDR_OUTPUT-1:0] count_size_pack;
always @(posedge i_clk or posedge i_reset) begin
  if(i_reset) begin
    count_spread <= {SIZE_COUNTER{1'b0}};
    count_size_pack <= {SIZE_ADDR_OUTPUT{1'b0}};
    ok <= 0;
  end
  else if(o_valid_output) begin
    if(count_spread + 1 < SPREAD) begin
      count_spread <= count_spread + 1;
      $fwrite(fid_i, "%b ", o_data);
    end
    else begin
      count_spread <= {SIZE_COUNTER{1'b0}};
      $fwrite(fid_i, "%b\n", o_data);
      count_size_pack <= count_size_pack + 1;
      if(count_size_pack + 1 == SIZE_BIT_PACK) begin
        ok <= 1;
      end
    end
  end
end

//Симуляция
initial begin
  -> reset_trigger;
  @(reset_trigger_done);

  @(posedge ok);

  -> terminate_sim;
end

final begin
  $fclose(fid_o);
  $fclose(fid_i);
end

endmodule