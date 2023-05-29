`timescale 1ns / 1ps


module tb_Modulator #(
  parameter PERIOD = 10,
  parameter CLK = PERIOD/2,

  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 32
);

reg i_clk;
reg i_reset;

reg [SIZE_INPUT_BIT-1:0] i_data;
wire o_valid_output;
reg i_valid_input;

wire o_ready;
wire [SIZE_OUTPUT_BIT*2-1:0] o_data;

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

event terminate_sim;
initial begin
	@ (terminate_sim);
	#5 $finish;
end

// Начальные условия
initial begin
  i_clk <= 0;
  i_reset <= 0;

  i_data <= {SIZE_INPUT_BIT{1'b0}};
  i_valid_input <= 0;
end

//Симуляция
initial begin
  -> reset_trigger;
  @(reset_trigger_done);



  -> terminate_sim;
end

final begin
  
end

endmodule