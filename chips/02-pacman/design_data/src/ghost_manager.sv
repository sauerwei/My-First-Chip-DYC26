module ghost_manager(
    input  logic        game_tick,
    input  logic        clk,
    input  logic        rst_n,
    input  logic        game_active,
    input  logic        frightened_mode,
    input  logic [31:0] frightened_timer,  // Remaining frightened time
    
    // NEW: Pac-Man position inputs for YELLOW ghost chasing behavior
    input  logic [4:0]  pacman_tile_x,
    input  logic [4:0]  pacman_tile_y,

    input  logic        eat_ghost1,
    input  logic        eat_ghost2,
    input  logic        eat_ghost3,
    input  logic        eat_ghost4,
    
    // Ghost position outputs (for rendering and collision)
    output logic [9:0]  ghost1_x,
    output logic [9:0]  ghost1_y,
    output logic [9:0]  ghost2_x,
    output logic [9:0]  ghost2_y,
    output logic [9:0]  ghost3_x,
    output logic [9:0]  ghost3_y,
    output logic [9:0]  ghost4_x,
    output logic [9:0]  ghost4_y,
    
    // Ghost direction outputs (for rendering)
    output logic [1:0]  ghost1_dir,
    output logic [1:0]  ghost2_dir,
    output logic [1:0]  ghost3_dir,
    output logic [1:0]  ghost4_dir,

    output logic        ghost1_frightened,
    output logic        ghost2_frightened,
    output logic        ghost3_frightened,
    output logic        ghost4_frightened,
    
    output logic        ghost1_eaten,
    output logic        ghost2_eaten,
    output logic        ghost3_eaten,
    output logic        ghost4_eaten
);

    // ========== GHOST CONTROLLERS ==========
    // Ghost 1: RED (color_in = 3'b100)
    ghost_ctrl ghost1 (
        // Inputs
        .game_tick(game_tick),
        .clk(clk), 
        .rst_n(rst_n),
        .game_active(game_active),
        .color_in(3'b100), 
        .eat_signal(eat_ghost1),
        .frightened_mode(frightened_mode),
        .frightened_timer(frightened_timer),
        .pacman_tile_x(pacman_tile_x), 
        .pacman_tile_y(pacman_tile_y),

        // Outputs
        .ghost_x(ghost1_x), 
        .ghost_y(ghost1_y),
        .ghost_dir(ghost1_dir),
        .is_frightened(ghost1_frightened),
        .is_eaten(ghost1_eaten)
    );
    
    // Ghost 2: PINK (color_in = 3'b101)
    ghost_ctrl ghost2 (
        .game_tick(game_tick),
        .clk(clk), 
        .rst_n(rst_n),
        .game_active(game_active),
        .color_in(3'b101), 
        .eat_signal(eat_ghost2),
        .frightened_mode(frightened_mode),
        .frightened_timer(frightened_timer),
        .pacman_tile_x(pacman_tile_x), 
        .pacman_tile_y(pacman_tile_y),

        // Outputs
        .ghost_x(ghost2_x), 
        .ghost_y(ghost2_y),
        .ghost_dir(ghost2_dir),
        .is_frightened(ghost2_frightened),
        .is_eaten(ghost2_eaten)
    );
    
    // Ghost 3: CYAN (color_in = 3'b011)
    ghost_ctrl ghost3 (
        .game_tick(game_tick),
        .clk(clk), 
        .rst_n(rst_n),
        .game_active(game_active),
        .color_in(3'b011), 
        .eat_signal(eat_ghost3),
        .frightened_mode(frightened_mode),
        .frightened_timer(frightened_timer),
        .pacman_tile_x(pacman_tile_x), 
        .pacman_tile_y(pacman_tile_y),

        // Outputs
        .ghost_x(ghost3_x), 
        .ghost_y(ghost3_y),
        .ghost_dir(ghost3_dir),
        .is_frightened(ghost3_frightened),
        .is_eaten(ghost3_eaten)
    );
    
    // Ghost 4: YELLOW (color_in = 3'b110) - THE CHASER!
    ghost_ctrl ghost4 (
        .game_tick(game_tick),
        .clk(clk), 
        .rst_n(rst_n),
        .game_active(game_active),
        .color_in(3'b110), 
        .eat_signal(eat_ghost4),
        .frightened_mode(frightened_mode),
        .frightened_timer(frightened_timer),
        .pacman_tile_x(pacman_tile_x), 
        .pacman_tile_y(pacman_tile_y),
        
        // Outputs
        .ghost_x(ghost4_x), 
        .ghost_y(ghost4_y),
        .ghost_dir(ghost4_dir),
        .is_frightened(ghost4_frightened),
        .is_eaten(ghost4_eaten)
    );

endmodule