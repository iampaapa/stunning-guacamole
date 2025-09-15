`timescale 1ns / 1ps

module bin2bcd (
    input  logic clk,
    input  logic rst_n,
    input  logic [15:0] bin_in,
    output logic [3:0] bcd3_out,
    output logic [3:0] bcd2_out,
    output logic [3:0] bcd1_out,
    output logic [3:0] bcd0_out
);

    logic [3:0] bcd_regs [3:0];
    logic [15:0] bin_shifted;

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            bin_shifted = bin_in << i;

            logic [3:0] bcd_stage [4];
            logic [15:0] bin_stage;
            
            bcd_stage[3] = 4'd0;
            bcd_stage[2] = 4'd0;
            bcd_stage[1] = 4'd0;
            bcd_stage[0] = 4'd0;
            bin_stage = bin_in;

            for (int j = 0; j < 16; j++) begin
                if (bcd_stage[0] > 4) bcd_stage[0] = bcd_stage[0] + 3;
                if (bcd_stage[1] > 4) bcd_stage[1] = bcd_stage[1] + 3;
                if (bcd_stage[2] > 4) bcd_stage[2] = bcd_stage[2] + 3;
                if (bcd_stage[3] > 4) bcd_stage[3] = bcd_stage[3] + 3;
                
                {bcd_stage[3], bcd_stage[2], bcd_stage[1], bcd_stage[0], bin_stage} = 
                {bcd_stage[3], bcd_stage[2], bcd_stage[1], bcd_stage[0], bin_stage} << 1;
            end
            bcd_regs[3] = bcd_stage[3];
            bcd_regs[2] = bcd_stage[2];
            bcd_regs[1] = bcd_stage[1];
            bcd_regs[0] = bcd_stage[0];
        end
    end

    assign bcd3_out = bcd_regs[3];
    assign bcd2_out = bcd_regs[2];
    assign bcd1_out = bcd_regs[1];
    assign bcd0_out = bcd_regs[0];

endmodule