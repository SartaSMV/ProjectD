`timescale 1ns / 1ps

module tb_lfsr #(
  parameter PERIOD = 10,
  parameter CLK = PERIOD/2
);

reg i_clk;
reg i_reset;
reg i_valid;
wire o_data;

lfsr tb (
  .i_clk(i_clk),
  .i_reset(i_reset),

  .i_valid(i_valid),
  .o_data(o_data)
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
	@ (terminate_sim);
	#5 $finish;
end

// Начальные условия
initial begin
  i_clk <= 0;
  i_reset <= 0;
  i_valid <= 0;
end

//Симуляция
initial begin
  -> reset_trigger;
  @(reset_trigger_done);
  #20;

  i_valid <= 1;
  #1000;

  -> terminate_sim;
end

endmodule
