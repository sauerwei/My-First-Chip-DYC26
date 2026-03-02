module map_renderer_wrapper (
    input  logic        game_tick,
    input  logic        clk,
    input  logic        rst_n,
    input  logic [9:0]  hpos,
    input  logic [9:0]  vpos,
    input  logic [9:0]  pac_x,    
    input  logic [9:0]  pac_y, 
    input  logic [3:0]  active_dir,      // Current movement direction
    input  logic [3:0]  requested_dir,   // Player's requested direction
    input  logic        show_start,
    input  logic        show_ready,
    input  logic        show_death_animation,
    input  logic        show_win_flash,
    input  logic        show_game_over,
    input  logic [3:0]  lives,
    input  logic [9:0]  level,
    input  logic        render_is_eaten, // Whether current tile is eaten
    input  logic        fruit_visible,   // Whether fruits are spawned
    input  logic [2:0]  fruit_item_id,
    input  logic [9:0]  ghost1_x,
    input  logic [9:0]  ghost1_y,
    input  logic [1:0]  ghost1_dir,
    input  logic        ghost1_frightened, 
    input  logic [9:0]  ghost2_x,
    input  logic [9:0]  ghost2_y,
    input  logic [1:0]  ghost2_dir,
    input  logic        ghost2_frightened, 
    input  logic [9:0]  ghost3_x,
    input  logic [9:0]  ghost3_y,
    input  logic [1:0]  ghost3_dir,
    input  logic        ghost3_frightened, 
    input  logic [9:0]  ghost4_x,
    input  logic [9:0]  ghost4_y,
    input  logic [1:0]  ghost4_dir,
    input  logic        ghost4_frightened,
    input  logic        fright_blink_white,  // Blink white in last 1.5s of frightened
    input  logic [1:0]  pac_state,      // Pacman mouth animation state
    
    input  logic        ghost1_eaten,
    input  logic        ghost2_eaten,
    input  logic        ghost3_eaten,
    input  logic        ghost4_eaten,
    
    input  logic [21:0] score,           // Score from dot_pill_ram
    input  logic [21:0] highscore,
    
    output logic [4:0]  render_tile_x,   // Current rendering tile X (for eaten lookup)
    output logic [4:0]  render_tile_y,   // Current rendering tile Y (for eaten lookup)
    output logic [3:0]  vga_r,
    output logic [3:0]  vga_g,
    output logic [3:0]  vga_b
);

    // Koordinaten-Berechnung & Tile-Mapping
    // Karte ist um 8 Pixel verschoben, damit sie zentriert ist
    wire [9:0] v_shifted = vpos + 10'd8; 

    logic [5:0] raw_tile_x, raw_tile_y;
    logic [3:0] offset_x, offset_y; 

    assign raw_tile_x = hpos[9:4];      // hpos / 16
    assign raw_tile_y = v_shifted[9:4]; // v_shifted / 16
    assign offset_x   = hpos[3:0];      // hpos % 16
    assign offset_y   = v_shifted[3:0]; // v_shifted % 16
    
    // Output tile coordinates for eaten lookup
    assign render_tile_x = raw_tile_x[4:0];
    assign render_tile_y = raw_tile_y[4:0];

    // Fruit-Pixel-Area (fruits ataround [17,13] and [17,14], 24x24 Pixel)
    wire in_fruit_area = (hpos >= 10'd212 && hpos < 10'd236) && (v_shifted >= 10'd268 && v_shifted < 10'd292);
    // Relative Pixel innerhalb des 24x24 Fruit-Bereichs
    wire [4:0] fruit_rel_x = 5'(hpos - 10'd212); 
    wire [4:0] fruit_rel_y = 5'(v_shifted - 10'd268); 

    // Pacman-Arrow-Area (around Pac-Man, 16x16)
    wire in_arrow_area = (hpos >= (pac_x - 10'd16) && hpos < pac_x + 10'd32) && (v_shifted >= (pac_y - 10'd16) && v_shifted < pac_y + 10'd32);
    // Relative Pixel innerhalb des Arrow-Bereichs
    wire [5:0] arrow_rel_x = 6'(hpos - (pac_x - 10'd16)); 
    wire [5:0] arrow_rel_y = 6'(v_shifted - (pac_y - 10'd16));

    // Ready-Pixel-Area (around [17,13] and [17,14], 104x14 Pixel)
    wire in_ready_area = (hpos >= 10'd178 && hpos < 10'd282) && (v_shifted >= 10'd273 && v_shifted < 10'd287);
    // Relative Pixel innerhalb des 104x14 Ready-Bereichs
    wire [6:0] ready_rel_x = 7'(hpos - 10'd178); 
    wire [4:0] ready_rel_y = 5'(v_shifted - 10'd273); 

    // Game-Over-Pixel-Area (around [17,13] and [17,14], 156x14 Pixel) 
    wire in_game_over_area = (hpos >= 10'd149 && hpos < 10'd305) && (v_shifted >= 10'd273 && v_shifted < 10'd287);
    // Relative Pixel innerhalb des 156x14 Game-Over-Bereichs
    wire [7:0] game_over_rel_x = 8'(hpos - 10'd149); 
    wire [4:0] game_over_rel_y = 5'(v_shifted - 10'd273); 

    // Highscore-Pixel-Area  
    wire in_highscore_area = (hpos >= 10'd495 && hpos < 10'd639) && (v_shifted >= 10'd100 && v_shifted < 10'd114);
    // Relative Pixel innerhalb des 144x14 Highscore-Bereichs (9*16)
    wire [7:0] highscore_rel_x = 8'(hpos - 10'd495); 
    wire [4:0] highscore_rel_y = 5'(v_shifted - 10'd100);

    // Level-Pixel-Area  
    wire in_level_area = (hpos >= 10'd530 && hpos < 10'd610) && (v_shifted >= 10'd200 && v_shifted < 10'd214);
    // Relative Pixel innerhalb des 80x14 Level-Bereichs (5*16)
    wire [6:0] level_rel_x = 7'(hpos - 10'd530); 
    wire [4:0] level_rel_y = 5'(v_shifted - 10'd200);

    // Start Screen Text-Pixel Area (2x von 236x32 => 472x64)
    wire in_start_screen_text_area = (hpos >= 10'd90 && hpos < 10'd562) && (v_shifted >= 10'd200 && v_shifted < 10'd264);
    // Relative Pixel innerhalb des 472x64 Start Screen-Bereichs
    wire [10:0] start_screen_rel_x = 11'(hpos - 10'd90); 
    wire [6:0] start_screen_rel_y = 7'(v_shifted - 10'd200); 
    logic [3:0] life_icon_index;
    wire [3:0] lives_to_draw = (lives > 4'd0) ? (lives - 4'd1) : 4'd0;
    logic [4:0] life_icon_cell_x;

    // Life-Icons-Pixel-Area (26x26 pro Icon, 2px Abstand)
    wire in_life_icons_area = (hpos >= 10'd455 && hpos < 10'd595) && (v_shifted >= 10'd462 && v_shifted < 10'd488) // rechts neben maze, unten
                                && (life_icon_index < lives_to_draw) && (life_icon_cell_x < 5'd26); // nur vorhandene Leben anzeigen && 2 Pixel Abstand
    // Relative Pixel innerhalb des Life-Icons-Bereichs
    wire [7:0] life_icons_rel_x = 8'(hpos - 10'd455); 
    wire [4:0] life_icons_rel_y = 5'(v_shifted - 10'd462); 
    always_comb begin // ersetzt DIV und MOD durch Bereichsprüfungen und Subtraktionen
        if (life_icons_rel_x < 8'd28) begin
            life_icon_index  = 4'd0;
            life_icon_cell_x = 5'(life_icons_rel_x);
        end else if (life_icons_rel_x < 8'd56) begin
            life_icon_index  = 4'd1;
            life_icon_cell_x = 5'(life_icons_rel_x - 8'd28);
        end else if (life_icons_rel_x < 8'd84) begin
            life_icon_index  = 4'd2;
            life_icon_cell_x = 5'(life_icons_rel_x - 8'd56);
        end else if (life_icons_rel_x < 8'd112) begin
            life_icon_index  = 4'd3;
            life_icon_cell_x = 5'(life_icons_rel_x - 8'd84);
        end else begin
            life_icon_index  = 4'd4;
            life_icon_cell_x = 5'(life_icons_rel_x - 8'd112);
        end 
    end

    
    // Bereichsprüfung für Pac-Man
    wire is_pacman_area = (hpos >= (pac_x - 10'd5) && hpos < (pac_x + 10'd21)) && (v_shifted >= (pac_y - 10'd5) && v_shifted < (pac_y + 10'd21));
    // Relative Pixel-Position innerhalb der 26x26 Pac-Man Box
    wire [4:0] pac_rel_x = 5'(hpos - (pac_x - 10'd5)); 
    wire [4:0] pac_rel_y = 5'(v_shifted - (pac_y - 10'd5)); 

    // Ghost Rendering Logic
    localparam GHOST_SIZE = 26;
    
    // Ghost 1 (RED) rendering
    wire [9:0] g1_dx = hpos - (ghost1_x - 10'd5);
    wire [9:0] g1_dy = v_shifted - (ghost1_y - 10'd5);
    wire [4:0] g1_row = g1_dy[4:0];
    wire [4:0] g1_col = g1_dx[4:0];
    wire g1_sprite_area = (g1_dx < GHOST_SIZE) && (g1_dy < GHOST_SIZE);
    
    wire [25:0] g1_bits;
    wire [25:0] g1_eye_bits;
    wire [25:0] g1_pupil_bits;
    ghost_sprite g1_sprite (
        .row(g1_row),
        .direction({2'b00, ghost1_dir}),
        .frightened(ghost1_frightened),
        .data(g1_bits),
        .eye_bits(g1_eye_bits),
        .pupil_bits(g1_pupil_bits)
    );
    wire g1_pixel = g1_sprite_area && g1_bits[25 - g1_col] && !ghost1_eaten;
    wire g1_eye_pixel = g1_pixel && g1_eye_bits[25 - g1_col];
    wire g1_pupil_pixel = g1_pixel && g1_pupil_bits[25 - g1_col];
    
    // Ghost 2 (PINK) rendering
    wire [9:0] g2_dx = hpos - (ghost2_x - 10'd5);
    wire [9:0] g2_dy = v_shifted - (ghost2_y - 10'd5);
    wire [4:0] g2_row = g2_dy[4:0];
    wire [4:0] g2_col = g2_dx[4:0];
    wire g2_sprite_area = (g2_dx < GHOST_SIZE) && (g2_dy < GHOST_SIZE);
    
    wire [25:0] g2_bits;
    wire [25:0] g2_eye_bits;
    wire [25:0] g2_pupil_bits;
    ghost_sprite g2_sprite (
        .row(g2_row),
        .direction({2'b00, ghost2_dir}),
        .frightened(ghost2_frightened),
        .data(g2_bits),
        .eye_bits(g2_eye_bits),
        .pupil_bits(g2_pupil_bits)
    );
    wire g2_pixel = g2_sprite_area && g2_bits[25 - g2_col] && !ghost2_eaten;
    wire g2_eye_pixel = g2_pixel && g2_eye_bits[25 - g2_col];
    wire g2_pupil_pixel = g2_pixel && g2_pupil_bits[25 - g2_col];
    
    // Ghost 3 (CYAN) rendering
    wire [9:0] g3_dx = hpos - (ghost3_x - 10'd5);
    wire [9:0] g3_dy = v_shifted - (ghost3_y - 10'd5);
    wire [4:0] g3_row = g3_dy[4:0];
    wire [4:0] g3_col = g3_dx[4:0];
    wire g3_sprite_area = (g3_dx < GHOST_SIZE) && (g3_dy < GHOST_SIZE);
    
    wire [25:0] g3_bits;
    wire [25:0] g3_eye_bits;
    wire [25:0] g3_pupil_bits;
    ghost_sprite g3_sprite (
        .row(g3_row),
        .direction({2'b00, ghost3_dir}),
        .frightened(ghost3_frightened),
        .data(g3_bits),
        .eye_bits(g3_eye_bits),
        .pupil_bits(g3_pupil_bits)
    );
    wire g3_pixel = g3_sprite_area && g3_bits[25 - g3_col] && !ghost3_eaten;
    wire g3_eye_pixel = g3_pixel && g3_eye_bits[25 - g3_col];
    wire g3_pupil_pixel = g3_pixel && g3_pupil_bits[25 - g3_col];
    
    // Ghost 4 (YELLOW) rendering
    wire [9:0] g4_dx = hpos - (ghost4_x - 10'd5);
    wire [9:0] g4_dy = v_shifted - (ghost4_y - 10'd5);
    wire [4:0] g4_row = g4_dy[4:0];
    wire [4:0] g4_col = g4_dx[4:0];
    wire g4_sprite_area = (g4_dx < GHOST_SIZE) && (g4_dy < GHOST_SIZE);
    
    wire [25:0] g4_bits;
    wire [25:0] g4_eye_bits;
    wire [25:0] g4_pupil_bits;
    ghost_sprite g4_sprite (
        .row(g4_row),
        .direction({2'b00, ghost4_dir}),
        .frightened(ghost4_frightened),
        .data(g4_bits),
        .eye_bits(g4_eye_bits),
        .pupil_bits(g4_pupil_bits)
    );
    wire g4_pixel = g4_sprite_area && g4_bits[25 - g4_col] && !ghost4_eaten;
    wire g4_eye_pixel = g4_pixel && g4_eye_bits[25 - g4_col];
    wire g4_pupil_pixel = g4_pixel && g4_pupil_bits[25 - g4_col];
    
    // Check if any ghost is active at current pixel
    wire any_ghost = g1_pixel | g2_pixel | g3_pixel | g4_pixel;
    wire any_eye_pixel = g1_eye_pixel | g2_eye_pixel | g3_eye_pixel | g4_eye_pixel;
    wire any_pupil_pixel = g1_pupil_pixel | g2_pupil_pixel | g3_pupil_pixel | g4_pupil_pixel;




    // --- Maze Map & Bitmaps 
    logic [5:0] maze_tile_type, final_tile_type;
    logic [2:0] fruit_pixel_color;
    logic pac_pixel_on, pixel_digit, pixel_high_digit, pixel_level_digit, pixel_letterHS, pixel_text, pixel_dot, pixel_letterLVL, pixel_pill, pixel_gate, pixel_live_icon, pixel_wall, pixel_arrow, pixel_letter, pixel_letterGO;
    logic [21:0] level_display_value;
    assign level_display_value = {12'd0, level}; // das score Modul braucht 22-Bit input

    maze_map u_maze (
        .x_tile(raw_tile_x[4:0]), 
        .y_tile(raw_tile_y[4:0]), 
        .tile_type(maze_tile_type)
    );

    // Kartenbegrenzung: 28 Spalten, 31 Zeilen
    always_comb begin
        if (raw_tile_x < 28 && raw_tile_y < 31) 
            final_tile_type = maze_tile_type;
        else 
            final_tile_type = 6'd40; // Außerhalb ist schwarz (invisible Wall)
    end

    // Dot 
    dot_bitmap u_dot (
        .y_offset(offset_y), 
        .x_offset(offset_x + 4'd1), 
        .is_dot(pixel_dot)
    );
    // Pill
    pill_bitmap u_pill (
        .y_offset(offset_y), 
        .x_offset(offset_x), 
        .is_pill(pixel_pill)
    );
    // gate
    gate_bitmap u_gate (
        .y_offset(offset_y), 
        .x_offset(offset_x), 
        .is_gate(pixel_gate)
    );
    // wall 
    wall_bitmap u_wall (
        .wall_type(final_tile_type),
        .y_offset(offset_y), 
        .x_offset(offset_x), 
        .is_wall(pixel_wall)
    );
    // Score Display
    score_display u_score (
        .hpos(hpos),
        .vpos(v_shifted),
        .score(score),
        .is_digit(pixel_digit)
    );
    score_display #(
        .DISPLAY_START_Y(10'd130)
    ) u_highscore (
        .hpos(hpos),
        .vpos(v_shifted),
        .score(highscore),
        .is_digit(pixel_high_digit)
    );
    score_display #(
        .DISPLAY_START_Y(10'd230)
    ) u_level (
        .hpos(hpos),
        .vpos(v_shifted),
        .score(level_display_value),
        .is_digit(pixel_level_digit)
    );
     // Arrow Bitmap
    arrow_bitmap u_arrow (
        .y_offset(arrow_rel_y),
        .x_offset(arrow_rel_x),
        .requested_dir(requested_dir),
        .is_arrow(pixel_arrow)
    );
    //Fruit Bitmap
    fruit_bitmap u_fruit (
        .y_offset(fruit_rel_y),
        .x_offset(fruit_rel_x),
        .item_id(fruit_item_id),
        .pixel_color(fruit_pixel_color)
    );
    // Ready Bitmap
    ready_bitmap u_ready (
        .y_offset(ready_rel_y),
        .x_offset(ready_rel_x),
        .is_letter(pixel_letter)
    );
    // Game Over Bitmap
    game_over_bitmap u_game_over (
        .y_offset(game_over_rel_y),
        .x_offset(game_over_rel_x),
        .is_letter(pixel_letterGO)
    );
    // Highscore Bitmap
    highscore_bitmap u_highscore_text (
        .y_offset(highscore_rel_y),
        .x_offset(highscore_rel_x),
        .is_letter(pixel_letterHS)
    );
    // Level Bitmap
    level_bitmap u_level_text (
        .y_offset(level_rel_y),
        .x_offset(level_rel_x), 
        .is_letter(pixel_letterLVL)
    );
    // Life Icons Bitmap
    pacman_sprite u_life (
        .y_offset(life_icons_rel_y), 
        .x_offset(life_icon_cell_x[4:0]), 
        .direction(4'b1000), // Immer RECHTS für Life-Icons
        .state(2'd1),   // Life icons always open mouth
        .is_pacman(pixel_live_icon)
    );
    // Pacman-Bitmap
    pacman_sprite u_pacman (
        .y_offset(pac_rel_y), 
        .x_offset(pac_rel_x), 
        .direction(active_dir),
        .state(pac_state), 
        .is_pacman(pac_pixel_on)
    );
    // Start Screen Bitmap
    start_screen_bitmap u_start_screen (
        .y_offset(start_screen_rel_y),
        .x_offset(start_screen_rel_x),
        .is_text(pixel_text)
    );

    logic any_frightened;
    assign any_frightened = (g1_pixel && ghost1_frightened) || 
                           (g2_pixel && ghost2_frightened) ||
                           (g3_pixel && ghost3_frightened) ||
                           (g4_pixel && ghost4_frightened);

    logic win_flash_phase;
    logic [4:0] win_flash_div;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            win_flash_div   <= 5'd0;
            win_flash_phase <= 1'b0;
        end
        else if (game_tick) begin
            if (show_win_flash) begin
                if (win_flash_div == 5'd6) begin
                    win_flash_div   <= 5'd0;
                    win_flash_phase <= ~win_flash_phase;
                end else begin
                    win_flash_div <= win_flash_div + 5'd1;
                end
            end else begin
                win_flash_div   <= 5'd0;
                win_flash_phase <= 1'b0;
            end
        end
    end

    // Placeholder wiring for upcoming state/lives rendering.
    wire _unused_state_inputs = &{show_death_animation};

    // --- 4. VGA Farbausgabe (Multiplexer) ---
    always_comb begin
        // Standardfarbe Schwarz
        vga_r = 0; vga_g = 0; vga_b = 0;

        // Score Display
        if ((pixel_digit || pixel_high_digit || pixel_level_digit) && !show_start) begin
            vga_r = 4'd15; vga_g = 4'd15; vga_b = 4'd12;
        end
        // Highscore-Screen
        else if (in_highscore_area && pixel_letterHS && !show_start) begin
            vga_r = 4'd15; vga_g = 4'd15; vga_b = 4'd12;
        end
        // Levelanzeige
        else if (in_level_area && pixel_letterLVL && !show_start) begin
            vga_r = 4'd15; vga_g = 4'd15; vga_b = 4'd12;
        end
        // Lifes indicator (x-1 icons)
        else if (in_life_icons_area && pixel_live_icon && !show_start) begin
            vga_r = 4'd15; vga_g = 4'd15; vga_b = 4'd0; //gelb
        end
        // Pac-Man
        else if (is_pacman_area && pac_pixel_on && !show_start) begin
            vga_r = 15; vga_g = 15; vga_b = 0; // Gelb
        end 
        // Pac-Man-Arrow
        else if (in_arrow_area && pixel_arrow && !show_start) begin
            vga_r = 15; vga_g = 15; vga_b = 0; // Gelb
        end
        // Ready-Screen
        else if (in_ready_area && pixel_letter && show_ready) begin
            vga_r = 15; vga_g = 15; vga_b = 0; // Gelb
        end
        // Game-Over-Screen
        else if (in_game_over_area && pixel_letterGO && show_game_over) begin
            vga_r = 15; vga_g = 0; vga_b = 0; // Rot
        end
        // Start-Screen
        else if (show_start) begin
            if (in_start_screen_text_area && pixel_text) begin
                vga_r = 0; vga_g = 0; vga_b = 0; // Schwarz
            end else begin
                vga_r = 12; vga_g = 15; vga_b = 0; // Gelb
            end
        end
        // Ghosts
        else if (any_ghost) begin  
            if (any_frightened) begin
                // Frightened mode
                if (fright_blink_white) begin
                    // Blinking phase: white ghost body with RED eyes/mouth
                    if (any_eye_pixel) begin
                        // Eyes/mouth in RED
                        vga_r = 4'd15;
                        vga_g = 4'd0;
                        vga_b = 4'd0;
                    end else begin
                        // Body in white
                        vga_r = 4'd15;
                        vga_g = 4'd15;
                        vga_b = 4'd15;
                    end
                end else begin
                    // Normal frightened: dark blue body with WHITE eyes/mouth
                    if (any_eye_pixel) begin
                        // Eyes/mouth in WHITE
                        vga_r = 4'd15;
                        vga_g = 4'd15;
                        vga_b = 4'd15;
                    end else begin
                        // Body in blue
                        vga_r = 4'd0;
                        vga_g = 4'd0;
                        vga_b = 4'd15; // Bright blue body
                    end
                end
            end else begin
                // Normal mode: individual ghost colors with white eyes and BLUE pupils
                if (any_pupil_pixel) begin
                    // Pupils are BLUE
                    vga_r = 4'd0;
                    vga_g = 4'd0;
                    vga_b = 4'd15;
                end else if (any_eye_pixel) begin
                    // Eyes (white part) are white
                    vga_r = 4'd15;
                    vga_g = 4'd15;
                    vga_b = 4'd15;
                end else begin
                    // Normal ghost colors (OR operation for overlap)
                    vga_r = (g1_pixel | g2_pixel | g4_pixel) ? 4'd15 : 4'd0;  // RED + PINK + YELLOW
                    vga_g = (g3_pixel | g4_pixel) ? 4'd15 : 4'd0;              // CYAN + YELLOW
                    vga_b = (g2_pixel | g3_pixel) ? 4'd15 : 4'd0;              // PINK + CYAN
                end
            end
        end
        // Fruits 
        else if (in_fruit_area && fruit_visible && (fruit_pixel_color != 3'd0)) begin
            case (fruit_pixel_color)
                3'd1: begin vga_r = 4'd15; vga_g = 4'd0;  vga_b = 4'd0;  end // Rot
                3'd2: begin vga_r = 4'd0;  vga_g = 4'd15; vga_b = 4'd0;  end // Grün
                3'd3: begin vga_r = 4'd15; vga_g = 4'd15; vga_b = 4'd15; end // Weiß
                3'd4: begin vga_r = 4'd15; vga_g = 4'd8;  vga_b = 4'd0;  end // Orange
                3'd5: begin vga_r = 4'd15; vga_g = 4'd15; vga_b = 4'd0;  end // Gelb
                3'd6: begin vga_r = 4'd8;  vga_g = 4'd4;  vga_b = 4'd0;  end // Braun ?
                3'd7: begin vga_r = 4'd6;  vga_g = 4'd12; vga_b = 4'd15; end // Hellblau ?
                default: begin end
            endcase
        end
        // Maze Map
        else if (final_tile_type < 38 ) begin // WALL -> blue
            if (pixel_wall) begin
                if (show_win_flash) begin
                    if (win_flash_phase) begin
                        vga_r = 15; vga_g = 15; vga_b = 15; // Weiß
                    end else begin
                        vga_r = 0;  vga_g = 0;  vga_b = 15; // Blau
                    end
                end else begin
                    vga_b = 15;
                end
            end
        end 
        else if (final_tile_type == 41 ) begin // GATE -> rosa
            if (pixel_gate) begin
                vga_r = 15; vga_g = 11; vga_b = 15;
            end
        end 
        else if (final_tile_type == 43 ) begin // DOT -> peach
            if (pixel_dot && !render_is_eaten) begin
                vga_r = 13; vga_g = 9; vga_b = 8; 
            end
        end 
        else if (final_tile_type == 44 ) begin // PILL -> peach
            if (pixel_pill && !render_is_eaten) begin
                    vga_r = 13; vga_g = 9; vga_b = 8;
            end
        end

        
        
    end
endmodule