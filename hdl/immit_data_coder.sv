`timescale 1ns / 1ps
//------------------------------------------------------------------------------
//
// Модуль:      immit_data_coder
// Описание:    Имитирует формирование данных от кодера.
//
// Входы:       clk - Тактирование
//              reset - Синхронный сброс
//              enable - Разрешение формирования данных
//
// Выходы:      data_out_en - валидность выходных данных
//              data_out - выходные данные
//
// Подробное описание
//
// Имитатор формирует псевдослучайные данные при сигнале enable = 1.
// Длина псевдослучайной последовательности равна 2^23 бит. Генератор ПСП
// реализован по стандарту O.150. Данные упаковываются в восьми битовую шину,
// порядок расположение битов BIG-ENDIAN
//
//------------------------------------------------------------------------------
module immit_data_coder (
    input clk,
    input reset,
    input enable,

    output psp_out_en,
    output psp_out_data,
    output data_out_en,
    output [7:0] data_out
);

reg enable_reg, data_out_en_reg, fix_data_en;
reg [2:0] count_data;
reg [7:0] temp_par_data, fix_data_out;
reg [22:0] register_generate_inf;

wire control_psp_reg;

assign psp_out_en = enable_reg;
assign psp_out_data = control_psp_reg;

assign data_out_en = data_out_en_reg;
assign data_out = fix_data_out;
assign control_psp_reg = register_generate_inf[17] ^ register_generate_inf[22];

// Процесс формирования ПСП
always @(posedge clk) begin
    if (reset) begin
        enable_reg <= 1'b0;
        register_generate_inf <= 23'h7FFFFF;
    end
    else begin
        if (register_generate_inf == 23'h0) begin
            register_generate_inf <= 23'h7FFFFF;
        end
        else begin
            if (enable_reg) begin
                register_generate_inf <= {register_generate_inf[21:0], control_psp_reg};
            end
        end
        enable_reg <= enable;
    end
end

// Процесс формирования параллельных данных
always @(posedge clk) begin
    if (reset) begin
        fix_data_en <= 1'b0;
        data_out_en_reg <= 1'b0;
        count_data <= 3'b000;
        fix_data_out <= 8'h0;
    end
    else begin
        if (fix_data_en) begin
            fix_data_out <= temp_par_data;
            data_out_en_reg <= 1'b1;
        end
        else begin
            data_out_en_reg <= 1'b0;
        end
        if (count_data == 3'b111) begin
            fix_data_en <= 1'b1;
        end
        else begin
            fix_data_en <= 1'b0;
        end
        if (enable_reg) begin
            temp_par_data <= {temp_par_data[6:0], control_psp_reg};
            count_data <= count_data + 1'b1;
        end
        else begin
            if (count_data == 3'b111) begin
                count_data <= 3'b000;
            end
        end
    end
end

endmodule
