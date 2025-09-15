`timescale 1ns / 1ps

module LED_mux (
    input  logic clk,
    input  logic rst_n,
    input  logic [6:0] in0, in1, in2, in3,
    output logic [6:0] seg_out,
    output logic [3:0] sel_out
);
    parameter CLK_FREQ = 100_000_000;
    parameter REFRESH_RATE_HZ = 1000;
    localparam COUNTER_MAX = CLK_FREQ / (REFRESH_RATE_HZ * 4);

    logic [$clog2(COUNTER_MAX)-1:0] prescaler_reg;
    logic [1:0] sel_reg;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            prescaler_reg <= '0;
            sel_reg <= '0;
        end else begin
            if (prescaler_reg == COUNTER_MAX - 1) begin
                prescaler_reg <= '0;
                sel_reg <= sel_reg + 1'b1;
            end else begin
                prescaler_reg <= prescaler_reg + 1'b1;
            end
        end
    end

    always_comb begin
        case (sel_reg)
            2'b00:  seg_out = in0;
            2'b01:  seg_out = in1;
            2'b10:  seg_out = in2;
            2'b11:  seg_out = in3;
            default: seg_out = 7'b1111111;
        endcase
    end
    
    assign sel_out = ~(4'b1 << sel_reg);

endmodule