`timescale 1ns / 1ps


module tb_QPSK #(
  parameter PERIOD = 10,
  parameter CLK = PERIOD/2
);

reg i_clk;
reg i_reset;
reg i_data;
reg i_valid;
wire o_valid;
wire [31:0] o_data;

QPSK tb (
  .i_clk(i_clk),
  .i_reset(i_reset),

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

// Запись данный модуля
reg [1:0] temp_input_data;
reg input_data_delay;
event input_deta_trigger;
event input_deta_done;
initial begin
  forever begin
    @(input_deta_trigger);
    @(posedge i_clk);

    // Загрузка первого бита
    i_valid <= 1;
    i_data <= temp_input_data[0];
    @(posedge i_clk);

    // Загрузка второго бита
    if (input_data_delay == 1'b1) begin
      i_valid <= 0;
      @(posedge i_clk);
      @(posedge i_clk);
      i_valid <= 1;
      i_data <= temp_input_data[1];
    end
    else begin
      i_data <= temp_input_data[1];
    end
    @(posedge i_clk);
    i_valid <= 0;

    -> input_deta_done;
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
  i_data <= 0;
  i_valid <= 0;

  temp_input_data <= 2'b00;
  input_data_delay <= 0;
end

//Симуляция
initial begin
  -> reset_trigger;
  @(reset_trigger_done);
  #20;

  -> input_deta_trigger;
  @(input_deta_done);
  #20;

  temp_input_data <= 2'b10;
  input_data_delay <= 1'b1;
  -> input_deta_trigger;
  @(input_deta_done);

  #20;
  -> terminate_sim;
end


endmodule
