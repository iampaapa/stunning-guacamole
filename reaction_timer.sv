`timescale 1ns / 1ps

module reaction_timer (
    input  logic clk,
    input  logic start_low,
    input  logic clr_low,
    input  logic stop_low,
    output logic stimulus_led,
    output logic [6:0] seg_out,
    output logic [3:0] sel_out
);

    parameter CLK_FREQ = 100_000_000;
    localparam SEC_COUNT_MAX = CLK_FREQ;
    localparam MS_COUNT_MAX  = CLK_FREQ / 1000;

    typedef enum logic [2:0] {
        S_IDLE, S_WAIT_RANDOM, S_PLAY,
        S_SHOW_RESULT, S_TIMEOUT, S_FALSE_START
    } state_e;

    state_e state_reg, state_nxt;

    logic rst_n;
    logic start_tick, stop_tick;
    
    logic [$clog2(SEC_COUNT_MAX)-1:0] sec_counter_reg, sec_counter_nxt;
    logic [$clog2(MS_COUNT_MAX)-1:0] ms_counter_reg, ms_counter_nxt;
    
    logic [15:0] reaction_time_reg, reaction_time_nxt;
    logic [3:0] rand_delay_reg, rand_delay_nxt;
    logic [3:0] sec_delay_reg, sec_delay_nxt;
    logic [7:0] rand_lfsr_reg, rand_lfsr_nxt;

    logic sec_tick;
    logic ms_tick;

    assign sec_tick = (sec_counter_reg == SEC_COUNT_MAX - 1);
    assign ms_tick = (ms_counter_reg == MS_COUNT_MAX - 1);
    
    debouncer clr_debouncer (
        .clk(clk), .rst_n(1'b1), .noisy_in(~clr_low), .clean_out(rst_n), .tick_out()
    );
    debouncer start_debouncer (
        .clk(clk), .rst_n(rst_n), .noisy_in(~start_low), .clean_out(), .tick_out(start_tick)
    );
    debouncer stop_debouncer (
        .clk(clk), .rst_n(rst_n), .noisy_in(~stop_low), .clean_out(), .tick_out(stop_tick)
    );

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state_reg         <= S_IDLE;
            sec_counter_reg   <= '0;
            ms_counter_reg    <= '0;
            reaction_time_reg <= '0;
            rand_delay_reg    <= '0;
            sec_delay_reg     <= '0;
            rand_lfsr_reg     <= 8'hA7;
        end else begin
            state_reg         <= state_nxt;
            sec_counter_reg   <= sec_counter_nxt;
            ms_counter_reg    <= ms_counter_nxt;
            reaction_time_reg <= reaction_time_nxt;
            rand_delay_reg    <= rand_delay_nxt;
            sec_delay_reg     <= sec_delay_nxt;
            rand_lfsr_reg     <= rand_lfsr_nxt;
        end
    end
    
    always_comb begin
        rand_lfsr_nxt = {rand_lfsr_reg[6:0], rand_lfsr_reg[7] ^ rand_lfsr_reg[5] ^ rand_lfsr_reg[4] ^ rand_lfsr_reg[3]};
    end

    always_comb begin
        state_nxt           = state_reg;
        sec_counter_nxt     = sec_counter_reg;
        ms_counter_nxt      = ms_counter_reg;
        reaction_time_nxt   = reaction_time_reg;
        rand_delay_nxt      = rand_delay_reg;
        sec_delay_nxt       = sec_delay_reg;
        stimulus_led        = 1'b0;

        case (state_reg)
            S_IDLE: begin
                if (start_tick) begin
                    rand_delay_nxt = (rand_lfsr_reg % 14) + 2;
                    sec_delay_nxt = '0;
                    state_nxt = S_WAIT_RANDOM;
                end
            end
            S_WAIT_RANDOM: begin
                sec_counter_nxt = sec_tick ? '0' : sec_counter_reg + 1;
                if (sec_tick) begin
                    sec_delay_nxt = sec_delay_reg + 1;
                    if (sec_delay_nxt == rand_delay_reg) begin
                        ms_counter_nxt = '0;
                        reaction_time_nxt = '0;
                        state_nxt = S_PLAY;
                    end
                end
                if (stop_tick) begin
                    state_nxt = S_FALSE_START;
                end
            end
            S_PLAY: begin
                stimulus_led = 1'b1;
                ms_counter_nxt = ms_tick ? '0' : ms_counter_reg + 1;
                if (ms_tick) begin
                    reaction_time_nxt = reaction_time_reg + 1;
                    if (reaction_time_nxt == 1000) begin
                        state_nxt = S_TIMEOUT;
                    end
                end
                if (stop_tick) begin
                    state_nxt = S_SHOW_RESULT;
                end
            end
            S_SHOW_RESULT, S_TIMEOUT, S_FALSE_START: begin
                // Hold state until reset
            end
            default: begin
                state_nxt = S_IDLE;
            end
        endcase
    end

    logic [15:0] display_val;
    always_comb begin
        case (state_reg)
            S_PLAY:         display_val = reaction_time_reg;
            S_SHOW_RESULT:  display_val = reaction_time_reg;
            S_TIMEOUT:      display_val = 1000;
            S_FALSE_START:  display_val = 9999;
            default:        display_val = 16'hFFFF;
        endcase
    end
    
    logic [3:0] bcd3, bcd2, bcd1, bcd0;
    bin2bcd bcd_converter (
        .clk(clk), .rst_n(rst_n), .bin_in(display_val),
        .bcd3_out(bcd3), .bcd2_out(bcd2), .bcd1_out(bcd1), .bcd0_out(bcd0)
    );

    logic [6:0] seg3, seg2, seg1, seg0;
    seven_seg_decoder dec3 (.bcd_in(bcd3), .seg_out(seg3));
    seven_seg_decoder dec2 (.bcd_in(bcd2), .seg_out(seg2));
    seven_seg_decoder dec1 (.bcd_in(bcd1), .seg_out(seg1));
    seven_seg_decoder dec0 (.bcd_in(bcd0), .seg_out(seg0));

    localparam SEG_H = 7'b0001001;
    localparam SEG_I = 7'b1111001;
    localparam SEG_BLANK = 7'b1111111;

    logic [6:0] final_seg3, final_seg2, final_seg1, final_seg0;
    always_comb begin
        case(state_reg)
            S_IDLE: begin
                final_seg3 = SEG_BLANK;
                final_seg2 = SEG_BLANK;
                final_seg1 = SEG_H;
                final_seg0 = SEG_I;
            end
            S_WAIT_RANDOM: begin
                final_seg3 = SEG_BLANK;
                final_seg2 = SEG_BLANK;
                final_seg1 = SEG_BLANK;
                final_seg0 = SEG_BLANK;
            end
            default: begin
                final_seg3 = seg3;
                final_seg2 = seg2;
                final_seg1 = seg1;
                final_seg0 = seg0;
            end
        endcase
    end

    LED_mux display_mux (
        .clk(clk), .rst_n(rst_n),
        .in0(final_seg0), .in1(final_seg1), .in2(final_seg2), .in3(final_seg3),
        .seg_out(seg_out), .sel_out(sel_out)
    );

endmodule