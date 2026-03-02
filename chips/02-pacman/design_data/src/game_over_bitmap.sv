module game_over_bitmap(
    input  logic [4:0] y_offset,    // row in map (0-31)
    input  logic [7:0] x_offset,    // pixel in row
    output logic       is_letter     // 1 = on, 0 = off
);
    logic [13:0] row_data;
    logic [2:0]  letter_idx;
    logic [3:0]  letter_x;
    logic        letter_valid;
    logic [6:0]  x_over;

    always_comb begin
        row_data   = 14'b0;
        letter_idx = 3'd0;
        letter_x   = 4'd0;
        letter_valid = 1'b0;
        x_over       = 7'd0;

        // GAME (4 letters, 2px spacing)
        if (x_offset < 8'd62) begin
            letter_idx   = 3'(x_offset[6:4]); // /16 
            letter_x     = x_offset[3:0]; // %16 
            letter_valid = (letter_x < 4'd14);
        end
        // OVER (starts after 32px word gap)
        else if (x_offset >= 8'd94 && x_offset < 8'd156) begin
            // 8-Bit Addition vermeiden, direkt in 3 Bit addieren und casten
            x_over       = 7'(x_offset - 8'd94);
            letter_idx   = 3'd4 + 3'(x_over[6:4]);
            letter_x     = x_over[3:0];
            letter_valid = (letter_x < 4'd14);
        end

        if (y_offset < 5'd14 && letter_valid) begin
            case (letter_idx)
            3'd0: begin // Buchstabe: G
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b00001111111111;
                    4'd1:  row_data = 14'b00001111111111;
                    4'd2:  row_data = 14'b00111100000000;
                    4'd3:  row_data = 14'b00111100000000;
                    4'd4:  row_data = 14'b11110000000000;
                    4'd5:  row_data = 14'b11110000000000;
                    4'd6:  row_data = 14'b11110000111111;
                    4'd7:  row_data = 14'b11110000111111;
                    4'd8:  row_data = 14'b11110000001111;
                    4'd9:  row_data = 14'b11110000001111;
                    4'd10: row_data = 14'b00111100001111;
                    4'd11: row_data = 14'b00111100001111;
                    4'd12: row_data = 14'b00001111111111;
                    4'd13: row_data = 14'b00001111111111;
                    default: row_data = 14'b0;
                endcase
            end
            
            3'd1: begin // Buchstabe: A
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
            
            3'd2: begin // Buchstabe: M
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b11110000001111;
                    4'd1:  row_data = 14'b11110000001111;
                    4'd2:  row_data = 14'b11111100111111;
                    4'd3:  row_data = 14'b11111100111111;
                    4'd4:  row_data = 14'b11111111111111;
                    4'd5:  row_data = 14'b11111111111111;
                    4'd6:  row_data = 14'b11111111111111;
                    4'd7:  row_data = 14'b11111111111111;
                    4'd8:  row_data = 14'b11110011001111;
                    4'd9:  row_data = 14'b11110011001111;
                    4'd10: row_data = 14'b11110000001111;
                    4'd11: row_data = 14'b11110000001111;
                    4'd12: row_data = 14'b11110000001111;
                    4'd13: row_data = 14'b11110000001111;
                    default: row_data = 14'b0;
                endcase
            end
            
            3'd3,
            3'd6: begin // Buchstabe: E
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
            
            3'd4: begin // Buchstabe: O
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b00111111111100;
                    4'd1:  row_data = 14'b00111111111100;
                    4'd2:  row_data = 14'b11110000001111;
                    4'd3:  row_data = 14'b11110000001111;
                    4'd4:  row_data = 14'b11110000001111;
                    4'd5:  row_data = 14'b11110000001111;
                    4'd6:  row_data = 14'b11110000001111;
                    4'd7:  row_data = 14'b11110000001111;
                    4'd8:  row_data = 14'b11110000001111;
                    4'd9:  row_data = 14'b11110000001111;
                    4'd10: row_data = 14'b11110000001111;
                    4'd11: row_data = 14'b11110000001111;
                    4'd12: row_data = 14'b00111111111100;
                    4'd13: row_data = 14'b00111111111100;
                    default: row_data = 14'b0;
                endcase
            end

            3'd5: begin //  V
                case (y_offset[3:0])
                    4'd0:  row_data = 14'b11110000001111;
                    4'd1:  row_data = 14'b11110000001111;
                    4'd2:  row_data = 14'b11110000001111;
                    4'd3:  row_data = 14'b11110000001111;
                    4'd4:  row_data = 14'b11110000001111;
                    4'd5:  row_data = 14'b11110000001111;
                    4'd6:  row_data = 14'b11110000001111;
                    4'd7:  row_data = 14'b11110000001111;
                    4'd8:  row_data = 14'b00111100111100;
                    4'd9:  row_data = 14'b00111100111100;
                    4'd10: row_data = 14'b00001111110000;
                    4'd11: row_data = 14'b00001111110000;
                    4'd12: row_data = 14'b00000011000000;
                    4'd13: row_data = 14'b00000011000000;
                    default: row_data = 14'b0;
                endcase
            end
            
            3'd7: begin // R
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

            default: row_data = 14'b0;
        endcase
        end
    end

    assign is_letter = (y_offset < 5'd14 && letter_valid) ? row_data[13 - letter_x] : 1'b0;

endmodule