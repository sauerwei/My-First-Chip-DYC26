module pill_bitmap(
    input  logic [3:0] y_offset,
    input  logic [3:0] x_offset,
    output logic       is_pill
);
    // Wir deklarieren row_data als einfaches 16-Bit Signal (Little Endian für Stabilität)
    logic [15:0] row_data;

    always_comb begin
        case (y_offset)
            4'd0:  row_data = 16'b0000011111100000;
            4'd1:  row_data = 16'b0001111111111000;
            4'd2:  row_data = 16'b0011111111111100;
            4'd3:  row_data = 16'b0111111111111110;
            4'd4:  row_data = 16'b0111111111111110;
            4'd5:  row_data = 16'b1111111111111111;
            4'd6:  row_data = 16'b1111111111111111;
            4'd7:  row_data = 16'b1111111111111111; 
            4'd8:  row_data = 16'b1111111111111111; 
            4'd9:  row_data = 16'b1111111111111111;
            4'd10: row_data = 16'b1111111111111111;
            4'd11: row_data = 16'b0111111111111110;
            4'd12: row_data = 16'b0111111111111110;
            4'd13: row_data = 16'b0011111111111100;
            4'd14: row_data = 16'b0001111111111000;
            4'd15: row_data = 16'b0000011111100000;
            default: row_data = 16'b0;
        endcase
    end

    // Big Endian Zugriff simulieren: x=0 ist Bit 15, x=15 ist Bit 0
    assign is_pill = row_data[x_offset];

endmodule
