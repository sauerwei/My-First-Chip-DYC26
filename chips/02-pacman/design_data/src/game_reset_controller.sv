module game_reset_controller #(
    parameter COLLISION_MARGIN = 1,  // Small margin for edge collision detection
    parameter V_SHIFT = 4            // Ghost Y coordinate offset
)(
    input  logic game_tick,
    input  logic clk,
    input  logic rst_n,
    input  logic collision_enable,

    input  logic [9:0] pac_x, pac_y,
    input  logic [9:0] ghost1_x, ghost1_y,
    input  logic [9:0] ghost2_x, ghost2_y,
    input  logic [9:0] ghost3_x, ghost3_y,
    input  logic [9:0] ghost4_x, ghost4_y,

    input  logic frightened_mode,
    input  logic ghost1_frightened,
    input  logic ghost2_frightened,
    input  logic ghost3_frightened,
    input  logic ghost4_frightened,
    
    input  logic ghost1_eaten,
    input  logic ghost2_eaten,
    input  logic ghost3_eaten,
    input  logic ghost4_eaten,

    output logic pacman_died_pulse,

    output logic eat_ghost1,
    output logic eat_ghost2,
    output logic eat_ghost3,
    output logic eat_ghost4
);

    logic [3:0] collision_ghost;
    logic pacman_died;

    // Sprites are rendered from (x-5, y-5), so actual sprite bounds are:
    // Left edge: x - 5, Right edge: x + 21 (26 pixels wide)
    // Top edge: y - 5, Bottom edge: y + 21 (26 pixels tall)
    wire [9:0] p_left   = (pac_x - 10'd5) + COLLISION_MARGIN;
    wire [9:0] p_right  = (pac_x + 10'd21) - COLLISION_MARGIN;
    wire [9:0] p_top    = (pac_y - 10'd5) + COLLISION_MARGIN;
    wire [9:0] p_bottom = (pac_y + 10'd21) - COLLISION_MARGIN;

    always_comb begin
        collision_ghost[0] = (p_left < (ghost1_x + 10'd21) - COLLISION_MARGIN) &&
                             (p_right > (ghost1_x - 10'd5) + COLLISION_MARGIN) &&
                             (p_top < (ghost1_y + V_SHIFT + 10'd21) - COLLISION_MARGIN) &&
                             (p_bottom > (ghost1_y + V_SHIFT - 10'd5) + COLLISION_MARGIN);

        collision_ghost[1] = (p_left < (ghost2_x + 10'd21) - COLLISION_MARGIN) &&
                             (p_right > (ghost2_x - 10'd5) + COLLISION_MARGIN) &&
                             (p_top < (ghost2_y + V_SHIFT + 10'd21) - COLLISION_MARGIN) &&
                             (p_bottom > (ghost2_y + V_SHIFT - 10'd5) + COLLISION_MARGIN);

        collision_ghost[2] = (p_left < (ghost3_x + 10'd21) - COLLISION_MARGIN) &&
                             (p_right > (ghost3_x - 10'd5) + COLLISION_MARGIN) &&
                             (p_top < (ghost3_y + V_SHIFT + 10'd21) - COLLISION_MARGIN) &&
                             (p_bottom > (ghost3_y + V_SHIFT - 10'd5) + COLLISION_MARGIN);

        collision_ghost[3] = (p_left < (ghost4_x + 10'd21) - COLLISION_MARGIN) &&
                             (p_right > (ghost4_x - 10'd5) + COLLISION_MARGIN) &&
                             (p_top < (ghost4_y + V_SHIFT + 10'd21) - COLLISION_MARGIN) &&
                             (p_bottom > (ghost4_y + V_SHIFT - 10'd5) + COLLISION_MARGIN);
    end

    always_comb begin
        pacman_died = 1'b0;
        eat_ghost1 = 1'b0;
        eat_ghost2 = 1'b0;
        eat_ghost3 = 1'b0;
        eat_ghost4 = 1'b0;

        // Ghost 1: ignore collision if eaten
        if (collision_ghost[0] && !ghost1_eaten) begin
            if (ghost1_frightened)
                eat_ghost1 = 1'b1;
            else
                pacman_died = 1'b1;
        end

        // Ghost 2: ignore collision if eaten
        if (collision_ghost[1] && !ghost2_eaten) begin
            if (ghost2_frightened)
                eat_ghost2 = 1'b1;
            else
                pacman_died = 1'b1;
        end

        // Ghost 3: ignore collision if eaten
        if (collision_ghost[2] && !ghost3_eaten) begin
            if (ghost3_frightened)
                eat_ghost3 = 1'b1;
            else
                pacman_died = 1'b1;
        end

        // Ghost 4: ignore collision if eaten
        if (collision_ghost[3] && !ghost4_eaten) begin
            if (ghost4_frightened)
                eat_ghost4 = 1'b1;
            else
                pacman_died = 1'b1;
        end
    end

    logic collision_prev;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_prev <= 1'b0;
            pacman_died_pulse <= 1'b0;
        end else if (game_tick) begin
            collision_prev <= (pacman_died && collision_enable);
            pacman_died_pulse <= (!collision_prev && pacman_died && collision_enable);
        end
    end

    wire _unused_ok = frightened_mode;

endmodule

//Original:
// deathanimation ca 2+ sekunden
// ready-Bilschirm + game-over ca 3+ Sekunden
// tod/ game over -> startbildschirm: start mit tastendruck bestätigen => großer_reset/rst_n
// tod/ noch nicht game over -> ready-Bildschirm => kleiner Reset
// sieg -> nächstes Lvl -> ready-Bildschirm => dritte Art reset?