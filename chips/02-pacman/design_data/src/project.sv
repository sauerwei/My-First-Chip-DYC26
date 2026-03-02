//TODO: delete uio-s?

module project (
        // Inputs
        input  wire [7:0] ui_in,    // Dedicated inputs
        input  wire [7:0] uio_in,   // IOs: Input path
        input  wire       ena,      // always 1 when the design is powered, so you can ignore it
        input  wire       clk,      // clock
        input  wire       rst_n,     // reset_n - low to reset

        // Outputs
        output wire [7:0] uo_out,   // Dedicated outputs
        output wire [7:0] uio_out,  // IOs: Output path
        output wire [7:0] uio_oe   // IOs: Enable path (active high: 0=input, 1=output)
    );

    // Unused outputs assigned to 0.
    assign uio_out = 0;
    assign uio_oe  = 0;

    // Suppress unused signals warning
    wire _unused_ok = &{ena, ui_in[7], ui_in[4:0], uio_in};

    // Game tick generator
    wire game_tick;

    game_tick #(
        .TICK_RATE(60*20) // Simulator runs with 6 fps so we speedup the game ticks to get round about 120 ticks per second
    ) game_tick_gen (
        // Inputs
        .clk(clk),
        .rst_n(rst_n),
        // Outputs
        .game_tick(game_tick)
    );

    // VGA signals
    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    hvsync_generator vga_sync_gen (
        // Inputs
        .clk(clk),
        .rst_n(rst_n),

        // Outputs
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );


    // 2. Deklariere den Output-Bus des Mappers
    wire [3:0] dirs;

    // 3. Gamepad Instanz (angepasste Namen)
    gamepad driver (
        // Inputs
        .clk(clk),
        .rst_n(rst_n),
        .round_reset(round_reset_pulse), // Vom game_state_controller
        .pmod_data(ui_in[6]),
        .pmod_clk(ui_in[5]),
        .pmod_latch(ui_in[4]),

        // Outputs
        .sw_out(dirs)
    );


    // Collision Detection & Game Reset Controller
    wire [9:0] pac_x, pac_y;
    wire [9:0] ghost1_x, ghost1_y, ghost2_x, ghost2_y;
    wire [9:0] ghost3_x, ghost3_y, ghost4_x, ghost4_y;
    
    //Ghost direction signals for rendering
    wire [1:0] ghost1_dir, ghost2_dir, ghost3_dir, ghost4_dir;

    wire ghost1_frightened, ghost2_frightened, ghost3_frightened, ghost4_frightened;
    wire ghost1_eaten, ghost2_eaten, ghost3_eaten, ghost4_eaten;
    wire frightened_mode;
    wire [31:0] frightened_timer;
    wire fright_blink_white;
    wire pill_eaten_pulse;

    wire eat_ghost1, eat_ghost2, eat_ghost3, eat_ghost4;
    wire pacman_died_pulse;
    wire game_active;
    wire start_pressed;
    wire show_start;
    wire show_ready;
    wire show_death_animation;
    wire show_win_flash;
    wire show_game_over;
    wire [3:0] lives;
    wire [9:0] level;
    wire game_reset_pulse;
    wire level_reset_pulse;
    wire round_reset_pulse;
    wire level_cleared;
    wire [21:0] score;

    assign start_pressed = |dirs; // Startet das Spiel, wenn irgendeine Richtung gedrückt wird

    game_state_controller state_ctrl (
        .game_tick(game_tick),
        .clk(clk),
        .rst_n(rst_n),
        .start_pressed(start_pressed),
        .pacman_died_pulse(pacman_died_pulse),
        .level_cleared(level_cleared),
        .score(score),
        .game_active(game_active),
        .show_start(show_start),
        .show_ready(show_ready),
        .show_death_animation(show_death_animation),
        .show_win_flash(show_win_flash),
        .show_game_over(show_game_over),
        .lives(lives),
        .level(level),
        .game_reset_pulse(game_reset_pulse),
        .level_reset_pulse(level_reset_pulse),
        .round_reset_pulse(round_reset_pulse)
    );


    game_reset_controller reset_ctrl (
        // Inputs
        .game_tick(game_tick),
        .clk(clk),
        .rst_n(rst_n),
        .collision_enable(game_active),
        .pac_x(pac_x),
        .pac_y(pac_y),
        .ghost1_x(ghost1_x),
        .ghost1_y(ghost1_y),
        .ghost2_x(ghost2_x),
        .ghost2_y(ghost2_y),
        .ghost3_x(ghost3_x),
        .ghost3_y(ghost3_y),
        .ghost4_x(ghost4_x),
        .ghost4_y(ghost4_y),
        .frightened_mode(frightened_mode),
        .ghost1_frightened(ghost1_frightened),
        .ghost2_frightened(ghost2_frightened),
        .ghost3_frightened(ghost3_frightened),
        .ghost4_frightened(ghost4_frightened),
        .ghost1_eaten(ghost1_eaten),
        .ghost2_eaten(ghost2_eaten),
        .ghost3_eaten(ghost3_eaten),
        .ghost4_eaten(ghost4_eaten),

        // Outputs
        .pacman_died_pulse(pacman_died_pulse),
        .eat_ghost1(eat_ghost1),
        .eat_ghost2(eat_ghost2),
        .eat_ghost3(eat_ghost3),
        .eat_ghost4(eat_ghost4)
    );

    

    wire [3:0] active_dir;
    wire [3:0] requested_dir;
    wire [4:0] pac_tile_x, pac_tile_y;
    wire [1:0] pac_state;

    // Pac-Man Logik Instanz
    pacman_ctrl pac_logic (
        // Inputs
        .game_tick(game_tick),
        .clk(clk),
        .rst_n(rst_n),
        .game_active(game_active),
        .move_dir(dirs),

        // Outputs
        .active_dir(active_dir),
        .requested_dir(requested_dir),
        .pac_x(pac_x),
        .pac_y(pac_y),
        .pac_tile_x(pac_tile_x),
        .pac_tile_y(pac_tile_y),
        .pac_state(pac_state)
    );

    power_pill_manager pill_mgr (
        // Inputs
        .game_tick(game_tick),
        .clk(clk),
        .rst_n(rst_n),
        .game_active(game_active),
        .pill_eaten(pill_eaten_pulse),

        // Outputs
        .frightened_mode(frightened_mode),
        .fright_blink_white(fright_blink_white),
        .frightened_timer(frightened_timer)
    );

    // --- Render coordinates for eaten items checking ---
    // Provide renderer tile coords to the eaten-items RAM so the renderer
    // can query whether the tile being drawn is already eaten.
    wire [4:0] render_tile_x;
    wire [4:0] render_tile_y;
    wire       render_eaten;
    
    wire fruit_display; // Dieses Signal geht an den Renderer
    wire [2:0]  fruit_item_id;
    wire [21:0] fruit_item_points;

    fruit_manager fruit_unit (
        // Inputs
        .game_tick(game_tick),
        .clk(clk),
        .rst_n(rst_n),
        .game_active(game_active),
        .game_reset(game_reset_pulse),
        .level_reset(level_reset_pulse),
        .level(level),
        .dots_eaten(dots_eaten),
        .fruit_eaten_pulse(fruit_eaten_pulse),

        // Outputs
        .fruit_display(fruit_display),
        .fruit_item_id(fruit_item_id),
        .fruit_item_points(fruit_item_points)
    );

    // --- 4a. Maze Map for current tile type ---
    // NOTE: maze_map now produces 6-bit codes, update the wire width accordingly.
    wire [5:0] current_maze_tile;
    maze_map u_maze_current (
        // Inputs
        .x_tile(pac_tile_x),
        .y_tile(pac_tile_y),

        // Outputs
        .tile_type(current_maze_tile)
    );

    // --- 4b. Game Control (detect eating) ---
    wire [4:0] eat_x, eat_y;
    wire       eat_valid;
    wire [1:0] eat_kind;
    wire        fruit_eaten_pulse;
    wire        current_tile_eaten;  // From dot_pill_ram

    game_ctrl u_game_ctrl (
        // Inputs
        .game_tick(game_tick),
        .clk(clk),
        .rst_n(rst_n),
        .round_reset(round_reset_pulse),
        .game_active(game_active),
        .eat_ghost1(eat_ghost1),
        .eat_ghost2(eat_ghost2),
        .eat_ghost3(eat_ghost3),
        .eat_ghost4(eat_ghost4),
        .pac_tile_x(pac_tile_x),
        .pac_tile_y(pac_tile_y),
        .current_tile_type(current_maze_tile),
        .fruit_visible(fruit_display),
        .current_tile_eaten(current_tile_eaten),

        // Outputs
        .eat_x(eat_x),
        .eat_y(eat_y),
        .eat_valid(eat_valid),
        .eat_kind(eat_kind),
        .fruit_eaten(fruit_eaten_pulse),
        .pill_eaten(pill_eaten_pulse)
    );

    // --- 4c. Eaten items RAM ---
    wire [21:0] highscore;
    wire [8:0]  dots_eaten;
  
    dot_pill_ram u_dot_pill_ram (
        // Inputs
        .game_tick(game_tick),
        .clk(clk),
        .rst_n(rst_n),
        .level_reset(level_reset_pulse),
        .game_reset(game_reset_pulse),
        .eat_x(eat_x),
        .eat_y(eat_y),
        .eat_valid(eat_valid),
        .eat_kind(eat_kind),
        .fruit_points(fruit_item_points),
        .check_x(pac_tile_x),
        .check_y(pac_tile_y),
        .render_x(render_tile_x),
        .render_y(render_tile_y),

        // Outputs
        .check_eaten(current_tile_eaten),
        .render_eaten(render_eaten),
        .score(score),
        .highscore(highscore),
        .dots_eaten(dots_eaten),
        .level_cleared(level_cleared)
    );



    ghost_manager ghosts (
        // Inputs
        .game_tick(game_tick),
        .clk(clk),
        .rst_n(rst_n),
        .game_active(game_active),
        .frightened_mode(frightened_mode),
        .frightened_timer(frightened_timer),
        .pacman_tile_x(pac_tile_x),
        .pacman_tile_y(pac_tile_y),
        .eat_ghost1(eat_ghost1), 
        .eat_ghost2(eat_ghost2),
        .eat_ghost3(eat_ghost3),
        .eat_ghost4(eat_ghost4),

        // Outputs
        .ghost1_x(ghost1_x),
        .ghost1_y(ghost1_y),
        .ghost2_x(ghost2_x),
        .ghost2_y(ghost2_y),
        .ghost3_x(ghost3_x),
        .ghost3_y(ghost3_y),
        .ghost4_x(ghost4_x),
        .ghost4_y(ghost4_y),
        .ghost1_dir(ghost1_dir),
        .ghost2_dir(ghost2_dir),
        .ghost3_dir(ghost3_dir),
        .ghost4_dir(ghost4_dir),
        .ghost1_frightened(ghost1_frightened),  
        .ghost2_frightened(ghost2_frightened),  
        .ghost3_frightened(ghost3_frightened),  
        .ghost4_frightened(ghost4_frightened),
        .ghost1_eaten(ghost1_eaten),
        .ghost2_eaten(ghost2_eaten),
        .ghost3_eaten(ghost3_eaten),
        .ghost4_eaten(ghost4_eaten)
    );

    wire [3:0] render_r; 
    wire [3:0] render_g;
    wire [3:0] render_b;



    // --- 5. Map Renderer ---
    map_renderer_wrapper map_inst (
        // Inputs
        .game_tick(game_tick),
        .clk(clk),
        .rst_n(rst_n),
        .hpos(pix_x),
        .vpos(pix_y),
        .pac_x(pac_x),
        .pac_y(pac_y),
        .score(score),
        .highscore(highscore),
        .active_dir(active_dir),
        .requested_dir(requested_dir),
        .show_start(show_start), 
        .show_ready(show_ready),
        .show_death_animation(show_death_animation),
        .show_win_flash(show_win_flash),
        .show_game_over(show_game_over),
        .lives(lives),
        .level(level),
        .render_is_eaten(render_eaten),
        .fruit_visible(fruit_display),
        .fruit_item_id(fruit_item_id),
        .ghost1_x(ghost1_x),
        .ghost1_y(ghost1_y),
        .ghost1_dir(ghost1_dir),
        .ghost1_frightened(ghost1_frightened),
        .ghost2_x(ghost2_x),
        .ghost2_y(ghost2_y),
        .ghost2_dir(ghost2_dir),
        .ghost2_frightened(ghost2_frightened),
        .ghost3_x(ghost3_x),
        .ghost3_y(ghost3_y),
        .ghost3_dir(ghost3_dir),
        .ghost3_frightened(ghost3_frightened),
        .ghost4_x(ghost4_x),
        .ghost4_y(ghost4_y),
        .ghost4_dir(ghost4_dir),
        .ghost4_frightened(ghost4_frightened),
        .fright_blink_white(fright_blink_white),
        .pac_state(pac_state),
        .ghost1_eaten(ghost1_eaten),
        .ghost2_eaten(ghost2_eaten),
        .ghost3_eaten(ghost3_eaten),
        .ghost4_eaten(ghost4_eaten),

        // Outputs
        .render_tile_x(render_tile_x),
        .render_tile_y(render_tile_y),
        .vga_r(render_r),
        .vga_g(render_g),
        .vga_b(render_b)
    );


    // --- 7. VGA Output Multiplexing ---
    wire [1:0] out_r = video_active ? render_r[3:2] : 2'b00;
    wire [1:0] out_g = video_active ? render_g[3:2] : 2'b00;
    wire [1:0] out_b = video_active ? render_b[3:2] : 2'b00;

    // Tiny VGA Pmod Layout korrigiert: 
    // Wir nutzen jetzt out_r, out_g, out_b anstatt der leeren R, G, B Register!
    assign uo_out = {hsync, out_b[0], out_g[0], out_r[0], vsync, out_b[1], out_g[1], out_r[1]};
endmodule