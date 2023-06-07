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

  parameter OUT_FILE = 109000000,
  parameter SIZE_COUNTER = $clog2(OUT_FILE)
);

reg i_clk = 0;
reg i_reset = 1;

reg [SIZE_INPUT_BIT-1:0] i_data;
wire o_valid_output;
reg i_valid_input;

wire o_ready;
wire [31:0] o_data;

Modulator tb (
  .i_clk(i_clk),
  .i_reset(i_reset),

  .i_data(i_data),
  .i_valid_input(i_valid_input),
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
    repeat (11) begin
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
  for(int i = 0; i < SIZE_BIT_PACK; i++) begin
    $fscanf(fid_o,"%b",ref_output[i]);
  end
  for(int i = 0; i < SIZE_BIT_PACK; i++) begin
    if(i < SISE_PREAMBLE) ref_output_blank[i] = ref_output[i];
    else ref_output_blank[i] = 0;
  end

  fid_i = $fopen("ProjectD.txt", "w");


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


parameter SIZE_QI = 16;
wire signed [SIZE_QI-1:0] q_out;
wire signed [SIZE_QI-1:0] i_out;
assign i_out = o_data[31:16];
assign q_out = o_data[15:0];
reg ok;
reg [SIZE_COUNTER-1:0] count_spread;
//reg [15:0] test_write_i = 16'h0, test_write_q = 16'h0;
always @(posedge i_clk or posedge i_reset) begin
  if(i_reset) begin
    count_spread <= {SIZE_COUNTER{1'b0}};
    ok <= 0;
  end
  else if(o_valid_output) begin
    if(count_spread < OUT_FILE - 1) begin
      count_spread <= count_spread + 1;
      $fwrite(fid_i, "%d\t%d\n", i_out, q_out);
      /*if(count_spread >= 9000) begin
        $fwrite(fid_i, "%u", {test_write_i, test_write_q});
        test_write_i <= i_out;
        test_write_q<= q_out;
      end*/
    end
    else begin
      count_spread <= {SIZE_COUNTER{1'b0}};
      $fwrite(fid_i, "%d\t%d\n", i_out, q_out);
      //$fwrite(fid_i, "%b", {i_out, q_out});
      ok <= 1;
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
