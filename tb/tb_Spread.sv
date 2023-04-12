`timescale 1ns / 1ps

module tb_Spread #(
  parameter PERIOD = 10,
  parameter CLK = PERIOD/2,
  parameter SPREAD = 24
);

reg i_clk;
reg i_reset;
wire o_readi;
reg i_data;
reg i_valid;
wire o_data;
wire o_valid;

Spread #(
  .SPREAD(SPREAD)
)
tb (
  .i_clk(i_clk),
  .i_reset(i_reset),
  .o_readi(o_readi),

  .i_data(i_data),
  .i_valid(i_valid),

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
	@ (terminate_sim);
	#5 $finish;
end

// Начальные условия
initial begin
  i_clk <= 0;
  i_reset <= 0;
  i_valid <= 0;
  i_data <= 0;
end

//Симуляция
initial begin
  -> reset_trigger;
  @(reset_trigger_done);
  #20;

  i_valid <= 0;
  @(posedge o_readi);
  i_valid <= 1;
  #10;
  i_valid <= 0;
  @(posedge o_readi);
  #50;

  -> terminate_sim;
end

endmodule
