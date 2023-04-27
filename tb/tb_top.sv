module tb_top #(
  parameter PERIOD = 10,
  parameter CLK = PERIOD/2,

  parameter SIZE_INPUT_BIT = 8,
  parameter SIZE_OUTPUT_BIT = 32
);

reg i_clk;
reg i_reset;

reg [SIZE_INPUT_BIT-1:0] i_data;
reg i_valid;

wire [SIZE_OUTPUT_BIT-1:0] o_data;
wire o_valdi;
wire o_ready;

top tb (
  // Управляющие сигналы
  .clk(i_clk),
  .reset(i_reset),
  .ready(o_ready),
  // Входные данные
  .bits(i_data),
  .i_valid_input(i_valid),
  // Выходные данные
  .data(o_data),
  .o_valid_output(o_valdi)
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

  i_data <= {SIZE_INPUT_BIT{1'b0}};
  i_valid <= 0;
end

//Симуляция
initial begin
  -> reset_trigger;
  @(reset_trigger_done);
  #20;


end

endmodule