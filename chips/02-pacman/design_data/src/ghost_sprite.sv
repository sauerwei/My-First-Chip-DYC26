module ghost_sprite(
    input  logic [4:0]  row,          // Row index (0-25) for 26x26 sprite 
    input  logic [3:0]  direction,    // Direction (1=Up, 2=Down, 4=Left, 8=Right)
    input  logic        frightened,   // Frightened mode (scared face)
    output logic [25:0] data,         // 26-bit output representing one row of the sprite
    output logic [25:0] eye_bits,     // 26-bit output for eye/mouth pixels (for coloring)
    output logic [25:0] pupil_bits    // 26-bit output for pupil pixels only (for blue coloring)
);

    logic [25:0] body_data;
    logic [25:0] eye_data;
    logic [25:0] pupil_data;
    logic [1:0] dir_code; // 00=right, 01=left, 10=up, 11=down

    // Decode direction
    always_comb begin
        case(direction)
            4'b1000: dir_code = 2'b00; // Right
            4'b0100: dir_code = 2'b01; // Left
            4'b0001: dir_code = 2'b10; // Up
            4'b0010: dir_code = 2'b11; // Down
            default: dir_code = 2'b00; // Default right
        endcase
    end

    // Ghost body sprite (26x26) - scaled from 16x16
    always_comb begin
        case(row)
            5'd0:  body_data = 26'b00000000111111111110000000;   // Top of head
            5'd1:  body_data = 26'b00000011111111111111100000;   // Head upper part
            5'd2:  body_data = 26'b00000111111111111111110000;   // Head upper part  
            5'd3:  body_data = 26'b00001111111111111111111000;   // Head expanding
            5'd4:  body_data = 26'b00011111111111111111111100;   // Head expanding
            5'd5:  body_data = 26'b00111111111111111111111110;   // Head wider
            5'd6:  body_data = 26'b01111111111111111111111111;   // Head wider
            5'd7:  body_data = 26'b11111111111111111111111111;   // Full width body
            5'd8:  body_data = 26'b11111111111111111111111111;   // Eyes area (body behind)
            5'd9:  body_data = 26'b11111111111111111111111111;   // Eyes area
            5'd10: body_data = 26'b11111111111111111111111111;   // Eyes area
            5'd11: body_data = 26'b11111111111111111111111111;   // Eyes area
            5'd12: body_data = 26'b11111111111111111111111111;   // Eyes area
            5'd13: body_data = 26'b11111111111111111111111111;   // Body continues
            5'd14: body_data = 26'b11111111111111111111111111;   // Body continues
            5'd15: body_data = 26'b11111111111111111111111111;   // Body middle
            5'd16: body_data = 26'b11111111111111111111111111;   // Body middle
            5'd17: body_data = 26'b11111111111111111111111111;   // Body lower middle
            5'd18: body_data = 26'b11111111111111111111111111;   // Body lower middle
            5'd19: body_data = 26'b11111111111111111111111111;   // Body approaching bottom
            5'd20: body_data = 26'b11111111111111111111111111;   // Body approaching bottom
            5'd21: body_data = 26'b11111111111111111111111111;   // Body near bottom
            5'd22: body_data = 26'b11111111111111111111111111;   // Body near bottom
            5'd23: body_data = 26'b11111111111111111111111111;   // Wavy bottom edge
            5'd24: body_data = 26'b11011110011111110011111011;   // Wavy bottom edge
            5'd25: body_data = 26'b10011001100110011001100110;   // Feet at bottom
            default: body_data = 26'b0;                          // Default: no sprite
        endcase
    end

    // Eyes and mouth for normal/frightened modes
    always_comb begin
        eye_data = 26'b0; // Default: no eyes/mouth
        pupil_data = 26'b0; // Default: no pupils
        
        if (frightened) begin
            // Frightened mode: scared face with wavy mouth (scaled to 26x26)
            case(row)
                // Eyes - simple dots positioned lower and closer
                5'd10: eye_data = 26'b00000111110000000111110000;  // Eye dots
                5'd11: eye_data = 26'b00000111110000000111110000;  // Eye dots
                5'd12: eye_data = 26'b00000111110000000111110000;  // Eye dots
                // Wavy scared mouth
                5'd16: eye_data = 26'b00011010110101101011010000;  // Wavy mouth top
                5'd17: eye_data = 26'b00101010101010101010101000;  // Wavy mouth middle
                5'd18: eye_data = 26'b00010101010101010101010000;  // Wavy mouth middle
                5'd19: eye_data = 26'b00000000000000000000000000;  // Wavy mouth bottom
                default: eye_data = 26'b0;
            endcase
            pupil_data = 26'b0; // No pupils in frightened mode
        end else begin
            // Normal mode: eyes with bigger pupils looking in movement direction (scaled to 26x26)
            case(dir_code)
                2'b00: begin // Looking RIGHT
                    case(row)
                        5'd8:  begin eye_data = 26'b00001111110000001111110000; pupil_data = 26'b00000000000000000000000000; end
                        5'd9:  begin eye_data = 26'b00011111111000011111111000; pupil_data = 26'b00000000000000000000000000; end
                        5'd10: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00000111100000000111100000; end
                        5'd11: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00000111100000000111100000; end
                        5'd12: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00000111100000000111100000; end
                        5'd13: begin eye_data = 26'b00011111111100011111111100; pupil_data = 26'b00000000000000000000000000; end // Pupils right
                        5'd14: begin eye_data = 26'b00001111111000001111111000; pupil_data = 26'b00000000000000000000000000; end // Pupils right lower
                        5'd15: begin eye_data = 26'b00000111110000000111110000; pupil_data = 26'b00000000000000000000000000; end // Pupils right lower
                        default: begin eye_data = 26'b0; pupil_data = 26'b0; end
                    endcase
                end
                2'b01: begin // Looking LEFT
                    case(row)
                        5'd8:  begin eye_data = 26'b00001111110000001111110000; pupil_data = 26'b00000000000000000000000000; end
                        5'd9:  begin eye_data = 26'b00011111111000011111111000; pupil_data = 26'b00000000000000000000000000; end
                        5'd10: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00011110000000011110000000; end
                        5'd11: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00011110000000011110000000; end
                        5'd12: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00011110000000011110000000; end
                        5'd13: begin eye_data = 26'b00111111110000111111110000; pupil_data = 26'b00000000000000000000000000; end // Pupils left
                        5'd14: begin eye_data = 26'b00011111100000011111100000; pupil_data = 26'b00000000000000000000000000; end // Pupils left lower
                        5'd15: begin eye_data = 26'b00000111110000000111110000; pupil_data = 26'b00000000000000000000000000; end // Pupils left lower
                        default: begin eye_data = 26'b0; pupil_data = 26'b0; end
                    endcase
                end
                2'b10: begin // Looking UP
                    case(row)
                        5'd8:  begin eye_data = 26'b00001111110000001111110000; pupil_data = 26'b00000000000000000000000000; end
                        5'd9:  begin eye_data = 26'b00001111110000001111110000; pupil_data = 26'b00000000000000000000000000; end
                        5'd10: begin eye_data = 26'b00011111111000011111111000; pupil_data = 26'b00000111100000000111100000; end // Pupils up
                        5'd11: begin eye_data = 26'b00011111111000011111111000; pupil_data = 26'b00000111100000000111100000; end // Pupils up
                        5'd12: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00000111100000000111100000; end
                        5'd13: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00000000000000000000000000; end
                        5'd14: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00000000000000000000000000; end
                        5'd15: begin eye_data = 26'b00001111110000001111110000; pupil_data = 26'b00000000000000000000000000; end
                        default: begin eye_data = 26'b0; pupil_data = 26'b0; end
                    endcase
                end
                2'b11: begin // Looking DOWN
                    case(row)
                        5'd8:  begin eye_data = 26'b00001111110000001111110000; pupil_data = 26'b00000000000000000000000000; end
                        5'd9:  begin eye_data = 26'b00011111111000011111111000; pupil_data = 26'b00000000000000000000000000; end
                        5'd10: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00000000000000000000000000; end
                        5'd11: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00000000000000000000000000; end
                        5'd12: begin eye_data = 26'b00111111111100111111111100; pupil_data = 26'b00000111100000000111100000; end
                        5'd13: begin eye_data = 26'b00011111111000011111111000; pupil_data = 26'b00000111100000000111100000; end // Pupils down
                        5'd14: begin eye_data = 26'b00001111110000001111110000; pupil_data = 26'b00000111100000000111100000; end // Pupils down
                        5'd15: begin eye_data = 26'b00001111110000001111110000; pupil_data = 26'b00000000000000000000000000; end // Pupils down lower
                        default: begin eye_data = 26'b0; pupil_data = 26'b0; end
                    endcase
                end
            endcase
        end
    end

    // Output body data and eye bits
    always_comb begin
        data = body_data;
        eye_bits = eye_data;
        pupil_bits = pupil_data;
    end

endmodule