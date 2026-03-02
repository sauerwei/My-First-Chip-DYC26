module score_display #(
    parameter logic [9:0] DISPLAY_START_X = 10'd490,
    parameter logic [9:0] DISPLAY_START_Y = 10'd20
) (
    input  logic [9:0]  hpos,
    input  logic [9:0]  vpos,
    input  logic [21:0] score,
    output logic is_digit
);

    localparam DIGIT_WIDTH = 8'd22;        // Breite pro Ziffer (inkl. Abstand)
    localparam DIGIT_HEIGHT = 8'd30;       // Höhe Segment-Anzeige
    localparam NUM_DIGITS = 3'd7;          // 7 Ziffern (0-4194303)
    
    logic in_display_area;
    logic [8:0] rel_x;
    logic [7:0] rel_y;
    logic [7:0] digit_rel_x;
    logic [3:0] digit_idx, current_digit;
    logic digit_visible;
    logic [6:0] segments;

    
    // BCD Dezimal-Umwandlung: Score zu 7 Ziffern (0-4194303)
    logic [3:0] digit6, digit5, digit4, digit3, digit2, digit1, digit0;
    
    // Dezimal-Ziffern extrahieren
    assign digit6 = 4'((score / 22'd1000000) % 22'd10); // Millionen
    assign digit5 = 4'((score / 22'd100000) % 22'd10);  // Hunderttausender
    assign digit4 = 4'((score / 22'd10000) % 22'd10);   // Zehntausender
    assign digit3 = 4'((score / 22'd1000) % 22'd10);    // Tausender
    assign digit2 = 4'((score / 22'd100) % 22'd10);     // Hunderter
    assign digit1 = 4'((score / 22'd10) % 22'd10);      // Zehner
    assign digit0 = 4'(score % 22'd10);                 // Einer
    
    // Prüfe ob Pixel im Display-Bereich
    assign in_display_area = (hpos >= DISPLAY_START_X && 
                              hpos < DISPLAY_START_X + {2'd0, NUM_DIGITS * DIGIT_WIDTH}) &&
                             (vpos >= DISPLAY_START_Y && 
                              vpos < DISPLAY_START_Y + {2'd0, DIGIT_HEIGHT});
    
    assign rel_x = 9'(hpos - DISPLAY_START_X);
    assign rel_y = 8'(vpos - DISPLAY_START_Y);
    
    // Welche Ziffer wird gerade gerendert?
    assign digit_idx = 4'(rel_x / {1'b0, DIGIT_WIDTH});
    
    // Aktuelle Ziffer basierend auf Index
    always_comb begin
        case (digit_idx)
            4'd0: current_digit = digit6;
            4'd1: current_digit = digit5;
            4'd2: current_digit = digit4;
            4'd3: current_digit = digit3;
            4'd4: current_digit = digit2;
            4'd5: current_digit = digit1;
            4'd6: current_digit = digit0;
            default: current_digit = 4'b0;
        endcase
    end

    // Führende Nullen unterdrücken, Einerstelle immer anzeigen
    always_comb begin
        case (digit_idx)
            4'd0: digit_visible = (digit6 != 4'd0);
            4'd1: digit_visible = (digit6 != 4'd0) || (digit5 != 4'd0);
            4'd2: digit_visible = (digit6 != 4'd0) || (digit5 != 4'd0) || (digit4 != 4'd0);
            4'd3: digit_visible = (digit6 != 4'd0) || (digit5 != 4'd0) || (digit4 != 4'd0) || (digit3 != 4'd0);
            4'd4: digit_visible = (digit6 != 4'd0) || (digit5 != 4'd0) || (digit4 != 4'd0) || (digit3 != 4'd0) || (digit2 != 4'd0);
            4'd5: digit_visible = (digit6 != 4'd0) || (digit5 != 4'd0) || (digit4 != 4'd0) || (digit3 != 4'd0) || (digit2 != 4'd0) || (digit1 != 4'd0);
            4'd6: digit_visible = 1'b1;
            default: digit_visible = 1'b0;
        endcase
    end
    
    // 7-Segment Decoder
    seven_segment_decoder u_decoder (
        .digit(current_digit),
        .segments(segments)
    );
    
    // Pixel-x-Position innerhalb einer Ziffer (relativ zu Ziffer-Start)
    assign digit_rel_x = 8'(rel_x % {1'b0, DIGIT_WIDTH});
    
    // 7-Segment Rendering
    // Layout:
    //     aaa       (y: 0-2)
    //    f   b      (y: 3-12)
    //     ggg       (y: 13-15)
    //    e   c      (y: 16-27)
    //     ddd       (y: 28-30)
    
    always_comb begin
        is_digit = 1'b0;
        
        if(in_display_area && digit_visible) begin
    
            // Segment a (oben, horizontal)
            if (rel_y < 3) begin
                if (segments[6] && digit_rel_x >= 3 && digit_rel_x <= 14)
                    is_digit = 1'b1;
            end
            // Segment f (oben-links, vertikal) und b (oben-rechts, vertikal)
            else if (rel_y >= 3 && rel_y < 13) begin
                if (segments[1] && digit_rel_x < 3)
                    is_digit = 1'b1;
                if (segments[5] && digit_rel_x >= 15 && digit_rel_x < 18)
                    is_digit = 1'b1;
            end
            // Segment g (Mitte, horizontal)
            else if (rel_y >= 13 && rel_y < 16) begin
                if (segments[0] && digit_rel_x >= 3 && digit_rel_x <= 14)
                    is_digit = 1'b1;
            end
            // Segment e (unten-links, vertikal) und c (unten-rechts, vertikal)
            else if (rel_y >= 16 && rel_y < 28) begin
                if (segments[2] && digit_rel_x < 3)
                    is_digit = 1'b1;
                if (segments[4] && digit_rel_x >= 15 && digit_rel_x < 18)
                    is_digit = 1'b1;
            end
            // Segment d (unten, horizontal)
            else if (rel_y >= 28 && rel_y < 31) begin
                if (segments[3] && digit_rel_x >= 3 && digit_rel_x <= 14)
                    is_digit = 1'b1;
            end
        end
    end


endmodule
