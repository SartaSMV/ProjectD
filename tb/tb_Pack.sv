`timescale 1ns / 1ps

module tb_Pack #(
  parameter PERIOD = 10,
  parameter CLK = PERIOD/2,

  parameter DEPTH_PORT_A = 247,
  parameter DEPTH_PORT_B = 1976
);

reg i_clk;
reg i_enable;

reg [7:0] i_addr_write;
reg i_enable_write;
reg [7:0] i_write_data;

reg [11:0] i_addr_read;
wire o_read_bit;

wire [7:0] normalize;
generate
  for (genvar i = 0; i < 8; i++) assign normalize[i] = i_write_data[7-i];
endgenerate

blk_mem_gen_0 tb (
  // BRAB_PORTA
  .addra(i_addr_write),
  .clka(i_clk),
  .dina(normalize),
  .ena(i_enable),
  .wea(i_enable_write),
  // BRAB_PORTB
  .addrb(i_addr_read),
  .clkb(i_clk),
  .doutb(o_read_bit),
  .enb(i_enable)
);

always #CLK i_clk = ~i_clk;

// Сброс модуля
event reset_trigger;
event reset_trigger_done;
initial begin
  forever begin
    @(reset_trigger)
    i_clk <= 0;
    i_enable <= 0;

    i_addr_write <= 8'd4;
    i_enable_write <= 0;
    i_write_data <= {8{1'b0}};

    i_addr_read <= {11{1'b0}};
    @(posedge i_clk);
    @(posedge i_clk);
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
  i_enable <= 0;

  i_addr_write <= 0;
  i_enable_write <= 0;
  i_write_data <= {8{1'b0}};

  i_addr_read <= {11{1'b0}};
end

//Симуляция
initial begin
  -> reset_trigger;
  @(reset_trigger_done);

  i_enable <= 1'b1;
  i_enable_write <= 1'b1;
  i_write_data <= {2'b01, {5{1'b0}}, 1'b1};
  @(posedge i_clk);
  i_enable_write <= 1'b0;
  @(posedge i_clk);
  @(posedge i_clk);
  @(posedge i_clk);

  // 11001111 10000000 10101010 00110001 - CF 80 AA 31
  // 11110011 00000001 01010101 10001100 - F3 01 55 8C
  for(int i = 0; i < 45; i++) begin
    i_addr_read <= i;
    @(posedge i_clk);
    @(posedge i_clk);
  end

  -> terminate_sim;
end

endmodule