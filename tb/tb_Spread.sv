`timescale 1ns / 1ps

module tb_Spread #(
  parameter PERIOD = 10,
  parameter CLK = PERIOD/2,
  parameter SPREAD = 24
);

reg i_clk;
reg i_reset;

reg i_data;
reg i_valid;
wire o_ready;

reg i_enable;
wire o_data;
wire o_valid;

Spread #(
  .SPREAD(SPREAD)
)
tb (
  .i_clk(i_clk),
  .i_reset(i_reset),

  .i_data(i_data),
  .i_valid(i_valid),
  .o_ready(o_ready),

  .i_enable(i_enable),
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
  i_enable <= 1;
end

always @(posedge i_clk) begin
  if(i_reset) begin
    i_valid <= 0;
  end
  else if(o_ready) begin
    i_valid <= 1;
  end
  else begin
    i_valid <= 0;
  end
end

//Симуляция
initial begin
  -> reset_trigger;
  @(reset_trigger_done);

  #20;

  @(posedge o_ready);
  @(posedge o_valid);
  i_enable <= 0;
  @(negedge o_valid);

  @(posedge i_clk);
  @(posedge i_clk);
  i_enable <= 1;
  @(posedge o_ready);
  @(posedge o_ready);

  -> terminate_sim;
end

endmodule
