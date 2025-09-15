`timescale 1ns / 1ps

module seven_seg_decoder (
    input  logic [3:0] bcd_in,
    output logic [6:0] seg_out
);
    always_comb begin
        case (bcd_in)
            4'h0: seg_out = 7'b1000000;
            4'h1: seg_out = 7'b1111001;
            4'h2: seg_out = 7'b0100100;
            4'h3: seg_out = 7'b0110000;
            4'h4: seg_out = 7'b0011001;
            4'h5: seg_out = 7'b0010010;
            4'h6: seg_out = 7'b0000010;
            4'h7: seg_out = 7'b1111000;
            4'h8: seg_out = 7'b0000000;
            4'h9: seg_out = 7'b0010000;
            default: seg_out = 7'b1111111;
        endcase
    end
endmodule