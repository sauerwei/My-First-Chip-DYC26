module ready_bitmap(
    input  logic [4:0] y_offset,    // row in map (0-31)
    input  logic [6:0] x_offset,    // pixel in row (0-127)
    output logic       is_letter     // 1 = on, 0 = off
);
    logic [13:0] row_data;
    logic [2:0]  letter_idx;
    logic [3:0]  letter_x;

    always_comb begin
        row_data   = 14'b0;
        letter_idx = x_offset[6:4]; // 16px Zelle = 14px Buchstabe + 2px Abstand
        letter_x   = x_offset[3:0];

        if (y_offset < 5'd14 && letter_x < 4'd14) begin
            case (letter_idx)
            3'd0: begin // Buchstabe: R
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b11111111111100;
                    4'd1:  row_data = 14'b11111111111100;
                    4'd2:  row_data = 14'b11110000001111;
                    4'd3:  row_data = 14'b11110000001111;
                    4'd4:  row_data = 14'b11110000001111;
                    4'd5:  row_data = 14'b11110000001111;
                    4'd6:  row_data = 14'b11110000111111;
                    4'd7:  row_data = 14'b11110000111111;
                    4'd8:  row_data = 14'b11111111110000;
                    4'd9:  row_data = 14'b11111111110000;
                    4'd10: row_data = 14'b11110011111100;
                    4'd11: row_data = 14'b11110011111100;
                    4'd12: row_data = 14'b11110000011111;
                    4'd13: row_data = 14'b11110000011111;
                    default: row_data = 14'b0;
                endcase
            end
            
            3'd1: begin // Buchstabe: E
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b11111111111111;
                    4'd1:  row_data = 14'b11111111111111;
                    4'd2:  row_data = 14'b11110000000000;
                    4'd3:  row_data = 14'b11110000000000;
                    4'd4:  row_data = 14'b11110000000000;
                    4'd5:  row_data = 14'b11110000000000;
                    4'd6:  row_data = 14'b11111111111100;
                    4'd7:  row_data = 14'b11111111111100;
                    4'd8:  row_data = 14'b11110000000000;
                    4'd9:  row_data = 14'b11110000000000;
                    4'd10: row_data = 14'b11110000000000;
                    4'd11: row_data = 14'b11110000000000;
                    4'd12: row_data = 14'b11111111111111;
                    4'd13: row_data = 14'b11111111111111;
                    default: row_data = 14'b0;
                endcase
            end
            
            3'd2: begin // Buchstabe: A
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b00001111110000;
                    4'd1:  row_data = 14'b00001111110000;
                    4'd2:  row_data = 14'b00111100111100;
                    4'd3:  row_data = 14'b00111100111100;
                    4'd4:  row_data = 14'b11110000001111;
                    4'd5:  row_data = 14'b11110000001111;
                    4'd6:  row_data = 14'b11110000001111;
                    4'd7:  row_data = 14'b11110000001111;
                    4'd8:  row_data = 14'b11111111111111;
                    4'd9:  row_data = 14'b11111111111111;
                    4'd10: row_data = 14'b11110000001111;
                    4'd11: row_data = 14'b11110000001111;
                    4'd12: row_data = 14'b11110000001111;
                    4'd13: row_data = 14'b11110000001111;
                    default: row_data = 14'b0;
                endcase
            end
            
            3'd3: begin // Buchstabe: D
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b11111111110000;
                    4'd1:  row_data = 14'b11111111110000;
                    4'd2:  row_data = 14'b11110000111100;
                    4'd3:  row_data = 14'b11110000111100;
                    4'd4:  row_data = 14'b11110000001111;
                    4'd5:  row_data = 14'b11110000001111;
                    4'd6:  row_data = 14'b11110000001111;
                    4'd7:  row_data = 14'b11110000001111;
                    4'd8:  row_data = 14'b11110000001111;
                    4'd9:  row_data = 14'b11110000001111;
                    4'd10: row_data = 14'b11110000111100;
                    4'd11: row_data = 14'b11110000111100;
                    4'd12: row_data = 14'b11111111110000;
                    4'd13: row_data = 14'b11111111110000;
                    default: row_data = 14'b0;
                endcase
            end
            
            3'd4: begin // Buchstabe: Y
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b11110000001111;
                    4'd1:  row_data = 14'b11110000001111;
                    4'd2:  row_data = 14'b11110000001111;
                    4'd3:  row_data = 14'b11110000001111;
                    4'd4:  row_data = 14'b11110000001111;
                    4'd5:  row_data = 14'b11110000001111;
                    4'd6:  row_data = 14'b00111111111100;
                    4'd7:  row_data = 14'b00111111111100;
                    4'd8:  row_data = 14'b00000111100000;
                    4'd9:  row_data = 14'b00000111100000;
                    4'd10: row_data = 14'b00000111100000;
                    4'd11: row_data = 14'b00000111100000;
                    4'd12: row_data = 14'b00000111100000;
                    4'd13: row_data = 14'b00000111100000;
                    default: row_data = 14'b0;
                endcase
            end
            3'd5: begin //  !
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b00000011111111;
                    4'd1:  row_data = 14'b00000011111111;
                    4'd2:  row_data = 14'b00000011111111;
                    4'd3:  row_data = 14'b00000011111111;
                    4'd4:  row_data = 14'b00001111110000;
                    4'd5:  row_data = 14'b00001111110000;
                    4'd6:  row_data = 14'b00001111000000;
                    4'd7:  row_data = 14'b00001111000000;
                    4'd8:  row_data = 14'b00001100000000;
                    4'd9:  row_data = 14'b00001100000000;
                    4'd10: row_data = 14'b00000000000000;
                    4'd11: row_data = 14'b00000000000000;
                    4'd12: row_data = 14'b11000000000000;
                    4'd13: row_data = 14'b11000000000000;
                    default: row_data = 14'b0;
                endcase
            end

            default: row_data = 14'b0;
        endcase
        end
    end

    assign is_letter = (y_offset < 5'd14 && letter_x < 4'd14) ? row_data[13 - letter_x] : 1'b0;

endmodule