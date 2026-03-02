module dot_pill_ram
(
    input  logic        game_tick,
    input  logic        clk,
    input  logic        rst_n,
    input  logic        level_reset,
    input  logic        game_reset,
    
    // Write port: When pacman eats something - mit gamectrl verbunden
    input  logic [4:0]  eat_x,        // x tile coordinate
    input  logic [4:0]  eat_y,        // y tile coordinate
    input  logic        eat_valid,    // signal to mark eaten
    input  logic [1:0]  eat_kind,
    input  logic [21:0] fruit_points,
    
    // Read port 1: Check if pacman's tile is eaten
    input  logic [4:0]  check_x,      // x tile coordinate
    input  logic [4:0]  check_y,      // y tile coordinate
    output logic        check_eaten,  // 1 if pacman's tile is eaten

    // Read port 2: Check if renderer tile is eaten
    input  logic [4:0]  render_x,     // renderer tile x
    input  logic [4:0]  render_y,     // renderer tile y
    output logic        render_eaten, // 1 if renderer tile is eaten
    
    // Score output
    output logic [21:0] score,        // current score
    output logic [21:0] highscore,    // best score (persists across game_reset)
    output logic [8:0]  dots_eaten,   // number of eaten dots in current level
    output logic        level_cleared
);

    // 28 x 31 Tiles (16x16 Pixel) = 448 x 496 Pixel
    localparam GRID_WIDTH  = 5'd28;
    localparam GRID_HEIGHT = 5'd31;
    localparam CONSUMABLES_PER_LEVEL = 9'd244;

    localparam EAT_DOT   = 2'd0;
    localparam EAT_PILL  = 2'd1;
    localparam EAT_FRUIT = 2'd2;
    localparam EAT_GHOST = 2'd3;

    localparam DOT_POINTS   = 22'd10;
    localparam PILL_POINTS  = 22'd50;
    localparam GHOST_POINTS = 22'd200;
    
    // RAM to track eaten dots/pills (28 x 31)
    logic [GRID_HEIGHT-1:0][GRID_WIDTH-1:0] eaten_map;
    logic [8:0] remaining_consumables;
    logic [1:0] ghost_combo_step;
    logic [21:0] ghost_points_award;

    always_comb begin
        case (ghost_combo_step)
            2'd0: ghost_points_award = GHOST_POINTS;          // 200
            2'd1: ghost_points_award = GHOST_POINTS << 1;     // 400
            2'd2: ghost_points_award = GHOST_POINTS << 2;     // 800
            default: ghost_points_award = GHOST_POINTS << 3;  // 1600 (saturates)
        endcase
    end
    
    // Combinational read port 1 (check if pacman's tile is eaten)
    always_comb begin
        if (check_x < GRID_WIDTH && check_y < GRID_HEIGHT) 
            check_eaten = eaten_map[check_y][check_x];
        else 
            check_eaten = 1'b1; // Out of bounds = treated as eaten
    end
    
    // Combinational read port 2 (for renderer's tiles)
    always_comb begin
        if (render_x < GRID_WIDTH && render_y < GRID_HEIGHT) 
            render_eaten = eaten_map[render_y][render_x];
        else 
            render_eaten = 1'b1; // Out of bounds = treated as eaten
    end

    //output
    assign level_cleared = (remaining_consumables == 9'd0);
    
    // Sequential scorekeeping and RAM update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin //Hardware-Reset: Alle Werte zurücksetzen
            eaten_map             <= '0;
            score                 <= '0;
            highscore             <= '0;
            dots_eaten            <= '0;
            remaining_consumables <= CONSUMABLES_PER_LEVEL;
            ghost_combo_step      <= 2'd0;
        end
        else if (game_tick) begin
            if (game_reset) begin //Neues Spiel: Alle Werte zurücksetzen (außer Highscore)
                eaten_map             <= '0;
                score                 <= '0;
                dots_eaten            <= '0;
                remaining_consumables <= CONSUMABLES_PER_LEVEL;
                ghost_combo_step      <= 2'd0;
            end else if (level_reset) begin
                eaten_map             <= '0;
                dots_eaten            <= '0;
                remaining_consumables <= CONSUMABLES_PER_LEVEL;
                ghost_combo_step      <= 2'd0;
            end else if (eat_valid) begin
                case (eat_kind)
                    EAT_DOT,
                    EAT_PILL: begin
                        if (eat_x < GRID_WIDTH &&
                            eat_y < GRID_HEIGHT &&
                            !eaten_map[eat_y][eat_x]) begin
                            eaten_map[eat_y][eat_x] <= 1'b1;
                            if (remaining_consumables > 0)
                                    remaining_consumables <= remaining_consumables - 9'd1;
                            if (eat_kind == EAT_PILL) begin
                                score <= score + PILL_POINTS;
                                ghost_combo_step <= 2'd0; // New frightened phase starts at 200
                            end else begin
                                score <= score + DOT_POINTS;
                                dots_eaten <= dots_eaten + 9'd1;
                            end
                        end
                    end

                    EAT_FRUIT: begin
                        score <= score + fruit_points;
                    end

                    EAT_GHOST: begin
                        score <= score + ghost_points_award;
                        if (ghost_combo_step < 2'd3)
                            ghost_combo_step <= ghost_combo_step + 2'd1;
                    end

                    default: begin
                    end
                endcase
            end

            // Zentraler Highscore-Update (1 Zyklus verzögert durch Nonblocking-Updates)
            if (score > highscore)
                highscore <= score;
        end
    end
    
endmodule
