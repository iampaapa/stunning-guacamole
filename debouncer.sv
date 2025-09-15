`timescale 1ns / 1ps

module debouncer (
    input  logic clk,
    input  logic rst_n,
    input  logic noisy_in,
    output logic clean_out,
    output logic tick_out
);

    parameter CLK_FREQ = 100_000_000;
    parameter DEBOUNCE_TIME_MS = 10;
    localparam COUNTER_MAX = (CLK_FREQ / 1000) * DEBOUNCE_TIME_MS;

    logic [1:0] sync_reg;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            sync_reg <= 2'b00;
        end else begin
            sync_reg <= {sync_reg[0], noisy_in};
        end
    end

    logic synced_in = sync_reg[1];
    logic [$clog2(COUNTER_MAX)-1:0] count_reg;
    logic count_done;

    assign count_done = (count_reg == COUNTER_MAX - 1);

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= '0;
        end else if (clean_out != synced_in || count_done) begin
            count_reg <= '0;
        end else begin
            count_reg <= count_reg + 1'b1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            clean_out <= 1'b0;
        end else if (count_done) begin
            clean_out <= synced_in;
        end
    end

    logic prev_clean_out;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            prev_clean_out <= 1'b0;
        end else begin
            prev_clean_out <= clean_out;
        end
    end

    assign tick_out = clean_out & ~prev_clean_out;

endmodule