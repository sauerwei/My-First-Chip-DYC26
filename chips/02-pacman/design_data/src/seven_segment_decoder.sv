module seven_segment_decoder (
    input  logic [3:0]  digit,        // 0-9
    output logic [6:0]  segments      // a,b,c,d,e,f,g
);

    // 7-Segment Patterns für Ziffern 0-9
    // Bit-Order: segments[6:0] = [a, b, c, d, e, f, g]
    //     aaa
    //    f   b
    //     ggg
    //    e   c
    //     ddd
    
    always_comb begin
        case (digit)
            4'd0: segments = 7'b1111110;  // 0: a,b,c,d,e,f
            4'd1: segments = 7'b0110000;  // 1: b,c
            4'd2: segments = 7'b1101101;  // 2: a,b,d,e,g
            4'd3: segments = 7'b1111001;  // 3: a,b,c,d,g
            4'd4: segments = 7'b0110011;  // 4: b,c,f,g
            4'd5: segments = 7'b1011011;  // 5: a,c,d,f,g
            4'd6: segments = 7'b1011111;  // 6: a,c,d,e,f,g
            4'd7: segments = 7'b1110000;  // 7: a,b,c
            4'd8: segments = 7'b1111111;  // 8: alle
            4'd9: segments = 7'b1111011;  // 9: a,b,c,d,f,g
            default: segments = 7'b0000000;
        endcase
    end

endmodule
