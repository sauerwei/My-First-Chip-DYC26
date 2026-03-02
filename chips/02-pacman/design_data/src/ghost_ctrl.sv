module ghost_ctrl(
    input  logic        game_tick,
    input  logic        clk,
    input  logic        rst_n,
    input  logic        game_active,
    input  logic [2:0]  color_in,
    input  logic        eat_signal,      // Signal when this ghost is eaten
    input  logic        frightened_mode,
    input  logic [31:0] frightened_timer, // Remaining frightened time
    // Pac-Man position inputs for chasing behavior
    input  logic [4:0]  pacman_tile_x,
    input  logic [4:0]  pacman_tile_y,
    
    //output
    output logic [9:0]  ghost_x,
    output logic [9:0]  ghost_y,
    output logic [1:0]  ghost_dir,  // output current direction
    output logic        is_frightened,
    output logic        is_eaten        // Flag indicating ghost is eaten and respawning
);

    // Sprite and tile parameters
    localparam TILE_SIZE = 10'd16;         // Tile size in pixels
    localparam WALL_END   = 6'd40;         // letztes Wall-Tile
    localparam GATE = 6'd41;               // Gate tile type (ghosts can pass through)
    localparam SPEED_LIMIT = 20'd0;        // Movement speed control (higher = slower)
    localparam SPEED_LIMIT_FRIGHT = 20'd1; // Slower when frightened (2x slower)
    localparam V_SHIFT = 10'd4;            // Vertical shift to align with map offset
    
    // AI Mode definitions (classic Pac-Man behavior)
    localparam logic [1:0] MODE_SCATTER = 2'b00;    // Go to corner
    localparam logic [1:0] MODE_CHASE = 2'b01;      // Chase Pac-Man
    localparam logic [1:0] MODE_FRIGHTENED = 2'b10; // Vulnerable (random movement)
    localparam logic [1:0] MODE_SPAWN = 2'b11;      // Return to spawn after eaten
    
    // Mode timing (in game ticks)
    localparam SCATTER_TIME = 32'd420*2; // 7 seconds
    localparam CHASE_TIME = 32'd1200*2;   // 20 seconds
    
    // Respawn delay
    localparam RESPAWN_DELAY = 32'd15*2;  // Fast respawn
    
    // Release delay for gate ghosts
    localparam RELEASE_DELAY_1SEC = 32'd15*2;   // 0.25 second
    localparam RELEASE_DELAY_2SEC = 32'd30*2;  // 0.5 second
   
    

    // State machine states
    typedef enum logic [1:0] {
        ST_IDLE   = 2'b00,   // Idle state (initial)
        ST_DECIDE = 2'b01,   // Decision state (choose direction)
        ST_MOVE   = 2'b10    // Movement state (moving to target tile)
    } state_t;

    state_t state;

    
    // Ghost position and tile tracking
    logic [9:0] x, y;                            // Current pixel position
    logic [4:0] curr_tile_x, curr_tile_y;        // Current tile coordinates
    logic [4:0] target_tile_x, target_tile_y;    // Target tile for movement
    logic [1:0] ai_dir;                          // Current AI direction (00=right, 01=left, 10=up, 11=down)
    logic [19:0] speed_cnt;                      // Speed counter for movement timing
    logic just_exited_gate;                      // Flag: just exited from gate
    logic fully_exited_gate;                     // Flag: completely left gate area (one tile away)
    logic cleared_gate_area;                     // Flag: moved far enough from gate
    logic [7:0] turn_counter;                    // Counter for random turn decisions
    logic eaten; 
    logic reached_center;                        // Flag: CYAN/YELLOW reached center position (13,14)

    logic [31:0] respawn_counter;
    logic waiting_respawn;
    logic [31:0] immunity_timer;  // Immunity timer after respawn
    
    // Release timer for delayed gate exit
    logic [31:0] release_timer;
    logic released;  // Flag: ghost is released and can move
    
    // AI Mode system
    logic [1:0] ai_mode;                         // Current AI mode (SCATTER/CHASE/FRIGHTENED/SPAWN)
    logic [1:0] prev_mode;                       // Mode before FRIGHTENED (to restore after)
    logic [31:0] mode_timer;                     // Timer for SCATTER/CHASE switching
    
    assign is_frightened = (ai_mode == MODE_FRIGHTENED);  // Only frightened when in FRIGHTENED mode
    assign ghost_dir = ai_dir;  // Export direction
    assign is_eaten = eaten;     // Export eaten status

    // Output assignments
    always_comb begin
        ghost_x = x;
        ghost_y = y;
    end

    //Dynamic speed limit based on frightened mode
    wire [19:0] current_speed_limit = (ai_mode == MODE_FRIGHTENED) ? SPEED_LIMIT_FRIGHT : SPEED_LIMIT;

    // Calculate neighboring tile coordinates
    logic [4:0] right_x, right_y, left_x, left_y, up_x, up_y, down_x, down_y;
    logic [5:0] right_type, left_type, up_type, down_type;
    
    always_comb begin
        // Right tile (with wraparound at x=27)
        right_x = (curr_tile_x == 5'd27) ? 5'd0 : curr_tile_x + 5'd1;
        right_y = curr_tile_y;
        
        // Left tile (with wraparound at x=0)
        left_x = (curr_tile_x == 5'd0) ? 5'd27 : curr_tile_x - 5'd1;
        left_y = curr_tile_y;
        
        // Up tile
        up_x = curr_tile_x;
        up_y = curr_tile_y - 5'd1;
        
        // Down tile
        down_x = curr_tile_x;
        down_y = curr_tile_y + 5'd1;
    end

    // Get tile types for all neighboring tiles
    maze_map map_right (.x_tile(right_x), .y_tile(right_y), .tile_type(right_type));
    maze_map map_left (.x_tile(left_x), .y_tile(left_y), .tile_type(left_type));
    maze_map map_up (.x_tile(up_x), .y_tile(up_y), .tile_type(up_type));
    maze_map map_down (.x_tile(down_x), .y_tile(down_y), .tile_type(down_type));

    // Gate blocking: prevent fully exited ghosts from re-entering gate area (one-way gate)
    wire is_gate_tile_right = (right_type == GATE);
    wire is_gate_tile_left = (left_type == GATE);
    wire is_gate_tile_up = (up_type == GATE);
    wire is_gate_tile_down = (down_type == GATE);

    // Check which directions are passable (not walls, and not gate for exited ghosts)
    wire can_go_right = (right_type > WALL_END) && !(fully_exited_gate && is_gate_tile_right);
    wire can_go_left = (left_type > WALL_END) && !(fully_exited_gate && is_gate_tile_left);
    wire can_go_up = (up_type > WALL_END) && !(fully_exited_gate && is_gate_tile_up);
    wire can_go_down = (down_type > WALL_END) && !(fully_exited_gate && is_gate_tile_down);

    // Get current tile type
    logic [5:0] current_tile_type;
    maze_map map_current (.x_tile(curr_tile_x), .y_tile(curr_tile_y), .tile_type(current_tile_type));

    // Intersection detection (3 or more available directions = intersection)
    wire [2:0] available_dirs_count = {2'b0, can_go_right} + {2'b0, can_go_left} + 
                                       {2'b0, can_go_up} + {2'b0, can_go_down};
    wire is_intersection = (available_dirs_count >= 3);

    // Ghost behavior configuration based on color
    logic [1:0] preferred_dir;   // Preferred direction after exiting gate
    logic is_gate_ghost;          // Flag: ghost starts behind gate
    logic [4:0] scatter_target_x, scatter_target_y;  // Scatter mode corner targets
    
    always_comb begin
        case(color_in)
            3'b100: begin  // RED ghost (Blinky): starts ABOVE gate, scatter to top-right
                preferred_dir = 2'b01;  
                is_gate_ghost = 1'b0;  // Not behind gate
                scatter_target_x = 5'd25;
                scatter_target_y = 5'd0;
            end
            3'b101: begin  // PINK ghost (Pinky): starts behind gate (center), exits UP then RIGHT, scatter to top-left
                preferred_dir = 2'b00;  
                is_gate_ghost = 1'b1;
                scatter_target_x = 5'd2;
                scatter_target_y = 5'd0;
            end
            3'b011: begin  // CYAN ghost (Inky): starts behind gate (left), exits UP then LEFT, scatter to bottom-right
                preferred_dir = 2'b01;  
                is_gate_ghost = 1'b1;
                scatter_target_x = 5'd27;
                scatter_target_y = 5'd31;
            end
            3'b110: begin  // YELLOW ghost (Clyde): starts behind gate (right), exits UP then RIGHT, scatter to bottom-left
                preferred_dir = 2'b00;  
                is_gate_ghost = 1'b1;
                scatter_target_x = 5'd0;
                scatter_target_y = 5'd31;
            end
            default: begin
                preferred_dir = 2'b00;
                is_gate_ghost = 1'b0;
                scatter_target_x = 5'd0;
                scatter_target_y = 5'd0;
            end
        endcase
    end
    
    // Calculate goal tile based on current AI mode
    logic [4:0] goal_tile_x, goal_tile_y;
    
    always_comb begin
        case(ai_mode)
            MODE_SCATTER: begin
                // Go to assigned corner
                goal_tile_x = scatter_target_x;
                goal_tile_y = scatter_target_y;
            end
            MODE_CHASE: begin
                // All ghosts chase Pac-Man directly (Blinky behavior)
                goal_tile_x = pacman_tile_x;
                goal_tile_y = pacman_tile_y;
            end
            MODE_FRIGHTENED: begin
                // In frightened mode, no specific goal (random movement)
                goal_tile_x = 5'd0;
                goal_tile_y = 5'd0;
            end
            MODE_SPAWN: begin
                // Return to spawn location (safe area inside gate room, not on portal)
                goal_tile_x = 5'd13;
                goal_tile_y = 5'd15;
            end
            default: begin
                goal_tile_x = scatter_target_x;
                goal_tile_y = scatter_target_y;
            end
        endcase
    end
    
    // Calculate distance to goal for pathfinding
    logic [7:0] dist_to_goal_right, dist_to_goal_left, dist_to_goal_up, dist_to_goal_down;
    
    always_comb begin
        logic [4:0] dx, dy;
        
        // Right direction to goal
        dx = (right_x > goal_tile_x) ? (right_x - goal_tile_x) : (goal_tile_x - right_x);
        dy = (right_y > goal_tile_y) ? (right_y - goal_tile_y) : (goal_tile_y - right_y);
        dist_to_goal_right = {3'b0, dx} + {3'b0, dy};
        
        // Left direction to goal
        dx = (left_x > goal_tile_x) ? (left_x - goal_tile_x) : (goal_tile_x - left_x);
        dy = (left_y > goal_tile_y) ? (left_y - goal_tile_y) : (goal_tile_y - left_y);
        dist_to_goal_left = {3'b0, dx} + {3'b0, dy};
        
        // Up direction to goal
        dx = (up_x > goal_tile_x) ? (up_x - goal_tile_x) : (goal_tile_x - up_x);
        dy = (up_y > goal_tile_y) ? (up_y - goal_tile_y) : (goal_tile_y - up_y);
        dist_to_goal_up = {3'b0, dx} + {3'b0, dy};
        
        // Down direction to goal
        dx = (down_x > goal_tile_x) ? (down_x - goal_tile_x) : (goal_tile_x - down_x);
        dy = (down_y > goal_tile_y) ? (down_y - goal_tile_y) : (goal_tile_y - down_y);
        dist_to_goal_down = {3'b0, dx} + {3'b0, dy};
    end

    // Main state machine
    always_ff @(posedge clk or negedge rst_n) begin       
        if (!rst_n) begin
            // Reset all state variables
            state <= ST_IDLE;
            speed_cnt <= 0;
            just_exited_gate <= 1'b0;
            fully_exited_gate <= 1'b0;  //Reset fully_exited flag
            cleared_gate_area <= 1'b0;  //Reset cleared_gate_area flag
            turn_counter <= 0;
            eaten <= 1'b0;
            waiting_respawn <= 1'b0; 
            respawn_counter <= 32'd0;
            immunity_timer <= 32'd0;  // Reset immunity timer
            reached_center <= 1'b0;  // Reset center flag
            
            // Async reset must assign constants only (no color_in dependent logic)
            release_timer <= 32'd0;
            released <= 1'b1;
            
            // AI Mode system initialization
            ai_mode <= MODE_SCATTER;      // Start in SCATTER mode
            prev_mode <= MODE_SCATTER;
            mode_timer <= SCATTER_TIME;   // First scatter lasts 7 seconds
            
            // Async reset must assign constants only (no color_in dependent logic)
            curr_tile_x <= 5'd13;
            curr_tile_y <= 5'd11;
            x <= 13 * TILE_SIZE;
            y <= 11 * TILE_SIZE - V_SHIFT;
            ai_dir <= 2'b01;
            
            target_tile_x <= 0;
            target_tile_y <= 0;

        end else if (game_tick && !game_active) begin
            // Reset all state variables
            state <= ST_IDLE;
            speed_cnt <= 0;
            just_exited_gate <= 1'b0;
            fully_exited_gate <= 1'b0;  //Reset fully_exited flag
            cleared_gate_area <= 1'b0;  //Reset cleared_gate_area flag
            turn_counter <= 0;
            eaten <= 1'b0;
            waiting_respawn <= 1'b0; 
            respawn_counter <= 32'd0;
            immunity_timer <= 32'd0;  // Reset immunity timer
            reached_center <= 1'b0;  // Reset center flag
            
            // Initialize release timer based on ghost color
            case(color_in)
                3'b100: begin  // RED: immediate release
                    release_timer <= 32'd0;
                    released <= 1'b1;
                end
                3'b101: begin  // PINK: immediate release
                    release_timer <= 32'd0;
                    released <= 1'b1;
                end
                3'b011: begin  // CYAN: 1 second delay
                    release_timer <= RELEASE_DELAY_1SEC;
                    released <= 1'b0;
                end
                3'b110: begin  // YELLOW: 2 seconds delay
                    release_timer <= RELEASE_DELAY_2SEC;
                    released <= 1'b0;
                end
                default: begin
                    release_timer <= 32'd0;
                    released <= 1'b1;
                end
            endcase
            
            // AI Mode system initialization
            ai_mode <= MODE_SCATTER;      // Start in SCATTER mode
            prev_mode <= MODE_SCATTER;
            mode_timer <= SCATTER_TIME;   // First scatter lasts 7 seconds
            
            // Set initial positions based on ghost color
            case(color_in)
                3'b100: begin  // RED: above gate, column 14, row 11, starts moving LEFT
                    curr_tile_x <= 5'd13; 
                    curr_tile_y <= 5'd11;
                    x <= 13 * TILE_SIZE; 
                    y <= 11 * TILE_SIZE - V_SHIFT;
                    ai_dir <= 2'b01;  // LEFT
                end
                3'b101: begin  // PINK: behind gate (center), column 14, row 14, starts moving UP
                    curr_tile_x <= 5'd13; 
                    curr_tile_y <= 5'd14;
                    x <= 13 * TILE_SIZE; 
                    y <= 14 * TILE_SIZE - V_SHIFT;
                    ai_dir <= 2'b10;  // UP (moves up to gate first)
                end
                3'b011: begin  // CYAN: behind gate (left), column 13, row 14, starts moving UP
                    curr_tile_x <= 5'd11; 
                    curr_tile_y <= 5'd14;
                    x <= 11 * TILE_SIZE; 
                    y <= 14 * TILE_SIZE - V_SHIFT;
                    ai_dir <= 2'b10;  // UP (moves up to gate first)
                end
                3'b110: begin  // YELLOW: behind gate (right), column 15, row 14, starts moving UP
                    curr_tile_x <= 5'd15; 
                    curr_tile_y <= 5'd14;
                    x <= 15 * TILE_SIZE; 
                    y <= 14 * TILE_SIZE - V_SHIFT;
                    ai_dir <= 2'b10;  // UP (moves up to gate first)
                end
                default: begin
                    curr_tile_x <= 5'd13; 
                    curr_tile_y <= 5'd11;
                    x <= 13 * TILE_SIZE; 
                    y <= 11 * TILE_SIZE - V_SHIFT;
                    ai_dir <= 2'b01;
                end
            endcase
            
            target_tile_x <= 0;
            target_tile_y <= 0;

        // Handle ghost being eaten (separate from rst_n)
        end else if (game_tick && eat_signal && !eaten) begin
            eaten <= 1'b1;
            ai_mode <= MODE_SPAWN;          // Switch to spawn mode immediately
            waiting_respawn <= 1'b1;
            respawn_counter <= RESPAWN_DELAY;

        end else if (game_tick) begin
            
            // Release timer management (for delayed ghost exit)
            if (!released && release_timer > 32'd0) begin
                release_timer <= release_timer - 32'd1;
            end else if (!released && release_timer == 32'd0) begin
                released <= 1'b1;
            end
            
            // Immunity timer management (prevents frightened mode after respawn)
            if (immunity_timer > 32'd0) begin
                immunity_timer <= immunity_timer - 32'd1;
            end
            
            // AI Mode management (independent of speed counter)
            
            // Handle frightened mode (Power Pellet eaten)
            // Ghost cannot become frightened during immunity period or in SPAWN mode
            if (frightened_mode && ai_mode != MODE_FRIGHTENED && ai_mode != MODE_SPAWN && immunity_timer == 32'd0) begin
                prev_mode <= ai_mode;           // Save current mode
                ai_mode <= MODE_FRIGHTENED;     // Switch to frightened
            end else if (!frightened_mode && ai_mode == MODE_FRIGHTENED) begin
                ai_mode <= prev_mode;           // Restore previous mode (SCATTER or CHASE)
            end
            
            // SCATTER/CHASE mode switching (only when not in FRIGHTENED or SPAWN)
            if (ai_mode == MODE_SCATTER || ai_mode == MODE_CHASE) begin
                if (mode_timer > 32'd0) begin
                    mode_timer <= mode_timer - 32'd1;
                end else begin
                    // Timer expired, switch modes
                    if (ai_mode == MODE_SCATTER) begin
                        ai_mode <= MODE_CHASE;
                        mode_timer <= CHASE_TIME;  // Chase for 20 seconds
                    end else begin
                        ai_mode <= MODE_SCATTER;
                        mode_timer <= SCATTER_TIME; // Scatter for 7 seconds
                    end
                end
            end

            if (waiting_respawn) begin
                if (respawn_counter > 32'd0) begin
                    respawn_counter <= respawn_counter - 32'd1;
                end else begin
                    // Respawn complete - reset to starting position
                    waiting_respawn <= 1'b0;
                    eaten <= 1'b0;
                    immunity_timer <= frightened_timer;  // Immunity = remaining frightened time
                    state <= ST_IDLE;
                    just_exited_gate <= 1'b0;
                    fully_exited_gate <= 1'b0;
                    cleared_gate_area <= 1'b0;
                    reached_center <= 1'b0;  // Reset center flag
                    
                    // Reset release timer based on ghost color
                    case(color_in)
                        3'b100: begin  // RED: immediate release
                            release_timer <= 32'd0;
                            released <= 1'b1;
                        end
                        3'b101: begin  // PINK: immediate release
                            release_timer <= 32'd0;
                            released <= 1'b1;
                        end
                        3'b011: begin  // CYAN: 1 second delay
                            release_timer <= RELEASE_DELAY_1SEC;
                            released <= 1'b0;
                        end
                        3'b110: begin  // YELLOW: 2 seconds delay
                            release_timer <= RELEASE_DELAY_2SEC;
                            released <= 1'b0;
                        end
                        default: begin
                            release_timer <= 32'd0;
                            released <= 1'b1;
                        end
                    endcase
                    
                    // Reset AI mode to SCATTER after respawn
                    ai_mode <= MODE_SCATTER;
                    prev_mode <= MODE_SCATTER;
                    mode_timer <= SCATTER_TIME;
                    
                    case(color_in)
                        3'b100: begin  // RED: above gate
                            curr_tile_x <= 5'd14; 
                            curr_tile_y <= 5'd11;
                            x <= 14 * TILE_SIZE; 
                            y <= 11 * TILE_SIZE - V_SHIFT;
                            ai_dir <= 2'b01;  // LEFT
                        end
                        3'b101: begin  // PINK: center
                            curr_tile_x <= 5'd14; 
                            curr_tile_y <= 5'd14;
                            x <= 14 * TILE_SIZE; 
                            y <= 14 * TILE_SIZE - V_SHIFT;
                            ai_dir <= 2'b10;  // UP
                        end
                        3'b011: begin  // CYAN: left
                            curr_tile_x <= 5'd13; 
                            curr_tile_y <= 5'd14;
                            x <= 13 * TILE_SIZE; 
                            y <= 14 * TILE_SIZE - V_SHIFT;
                            ai_dir <= 2'b10;  // UP
                        end
                        3'b110: begin  // YELLOW: right
                            curr_tile_x <= 5'd15; 
                            curr_tile_y <= 5'd14;
                            x <= 15 * TILE_SIZE; 
                            y <= 14 * TILE_SIZE - V_SHIFT;
                            ai_dir <= 2'b10;  // UP
                        end
                        default: begin
                            curr_tile_x <= 5'd13; 
                            curr_tile_y <= 5'd11;
                            x <= 13 * TILE_SIZE; 
                            y <= 11 * TILE_SIZE - V_SHIFT;
                            ai_dir <= 2'b01;
                        end
                    endcase
                end
            end else begin
            // Speed control counter
            speed_cnt <= (speed_cnt >= current_speed_limit) ? 0 : speed_cnt + 1;

            if (speed_cnt == current_speed_limit) begin
                case (state)
                    ST_IDLE: begin
                        state <= ST_DECIDE;
                    end

                    ST_DECIDE: begin
                        turn_counter <= turn_counter + 1;                

                        // If any ghost accidentally enters gate area, force them to exit UP
                        if (current_tile_type == GATE && fully_exited_gate) begin
                            // Ghost is in gate area but should have already exited - force exit UP
                            if (can_go_up) begin
                                ai_dir <= 2'b10;  // FORCE UP
                                target_tile_x <= up_x;
                                target_tile_y <= up_y;
                                state <= ST_MOVE;
                            end else begin
                                state <= ST_DECIDE;
                            end
                        end
                        // CYAN and YELLOW: first move to center (13,14) before exiting
                        else if ((color_in == 3'b011 || color_in == 3'b110) && !reached_center) begin
                            if (released) begin
                                // Move towards center position (13, 14)
                                if (curr_tile_x < 5'd13 && can_go_right) begin
                                    ai_dir <= 2'b00;  // RIGHT to center
                                    target_tile_x <= right_x;
                                    target_tile_y <= right_y;
                                    state <= ST_MOVE;
                                end else if (curr_tile_x > 5'd13 && can_go_left) begin
                                    ai_dir <= 2'b01;  // LEFT to center
                                    target_tile_x <= left_x;
                                    target_tile_y <= left_y;
                                    state <= ST_MOVE;
                                end else if (curr_tile_x == 5'd13 && curr_tile_y == 5'd14) begin
                                    // Reached center, now can proceed with normal gate logic
                                    reached_center <= 1'b1;
                                    state <= ST_DECIDE;
                                end else begin
                                    state <= ST_DECIDE;
                                end
                            end else begin
                                // Not yet released, stay in place
                                state <= ST_DECIDE;
                            end
                        end
                        // Gate ghosts need to move UP to reach the gate first
                        else if (is_gate_ghost && !just_exited_gate && current_tile_type != GATE) begin
                            // Check if ghost is released (delay expired)
                            if (released) begin
                                // Still behind gate, move UP to reach it
                                if (can_go_up) begin
                                    ai_dir <= 2'b10;  // UP
                                    target_tile_x <= up_x;
                                    target_tile_y <= up_y;
                                    state <= ST_MOVE;
                                end else begin
                                    state <= ST_DECIDE;
                                end
                            end else begin
                                // Not yet released, stay in place
                                state <= ST_DECIDE;
                            end
                        end
                        // Now on gate tile, exit horizontally in preferred direction
                        else if (is_gate_ghost && current_tile_type == GATE && !just_exited_gate) begin
                            just_exited_gate <= 1'b1;
                            fully_exited_gate <= 1'b1;  // Prevent re-entry to gate immediately
                            
                            case(preferred_dir)
                                2'b00: begin  // Prefer to exit RIGHT
                                    if (can_go_right) begin
                                        ai_dir <= 2'b00;
                                        target_tile_x <= right_x;
                                        target_tile_y <= right_y;
                                        state <= ST_MOVE;
                                    end else if (can_go_left) begin  // Fallback to LEFT if RIGHT blocked
                                        ai_dir <= 2'b01;
                                        target_tile_x <= left_x;
                                        target_tile_y <= left_y;
                                        state <= ST_MOVE;
                                    end else begin
                                        state <= ST_DECIDE;
                                    end
                                end
                                2'b01: begin  // Prefer to exit LEFT
                                    if (can_go_left) begin
                                        ai_dir <= 2'b01;
                                        target_tile_x <= left_x;
                                        target_tile_y <= left_y;
                                        state <= ST_MOVE;
                                    end else if (can_go_right) begin  // Fallback to RIGHT if LEFT blocked
                                        ai_dir <= 2'b00;
                                        target_tile_x <= right_x;
                                        target_tile_y <= right_y;
                                        state <= ST_MOVE;
                                    end else begin
                                        state <= ST_DECIDE;
                                    end
                                end
                                default: begin
                                    state <= ST_DECIDE;
                                end
                            endcase
                        end
                        // After exiting gate, force UP movement until hitting a wall
                        else if (is_gate_ghost && just_exited_gate && current_tile_type != GATE && !cleared_gate_area) begin
                            if (can_go_up) begin
                                ai_dir <= 2'b10;  // FORCE UP direction until can't go up anymore
                                target_tile_x <= up_x;
                                target_tile_y <= up_y;
                                state <= ST_MOVE;
                            end else begin
                                // Can't go up anymore - hit a wall, now enable normal AI
                                cleared_gate_area <= 1'b1;
                                state <= ST_DECIDE;  // Re-decide with AI logic
                            end
                        end
                        // AI behavior based on current mode (after clearing gate area)
                        else if (cleared_gate_area || !is_gate_ghost) begin
                            // FRIGHTENED mode: random movement
                            if (ai_mode == MODE_FRIGHTENED) begin
                                // Random turns at intersections
                                if (is_intersection && (turn_counter[3:0] == 4'b1111)) begin
                                    case(ai_dir)
                                        2'b00, 2'b01: begin  // Moving horizontally
                                            // Try to turn up or down based on counter bit
                                            if (can_go_up && (turn_counter[4] == 1'b0)) begin
                                                ai_dir <= 2'b10;
                                                target_tile_x <= up_x;
                                                target_tile_y <= up_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_down && (turn_counter[4] == 1'b1)) begin
                                                ai_dir <= 2'b11;
                                                target_tile_x <= down_x;
                                                target_tile_y <= down_y;
                                                state <= ST_MOVE;
                                            end else begin
                                                state <= ST_DECIDE;
                                            end
                                        end
                                        2'b10, 2'b11: begin  // Moving vertically
                                            // Try to turn left or right based on counter bit
                                            if (can_go_right && (turn_counter[4] == 1'b0)) begin
                                                ai_dir <= 2'b00;
                                                target_tile_x <= right_x;
                                                target_tile_y <= right_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_left && (turn_counter[4] == 1'b1)) begin
                                                ai_dir <= 2'b01;
                                                target_tile_x <= left_x;
                                                target_tile_y <= left_y;
                                                state <= ST_MOVE;
                                            end else begin
                                                state <= ST_DECIDE;
                                            end
                                        end
                                    endcase
                                end
                                // Normal random movement (continue or turn when hit wall)
                                else begin
                                    case(ai_dir)
                                        2'b00: begin  // Moving RIGHT
                                            if (can_go_right) begin
                                                target_tile_x <= right_x;
                                                target_tile_y <= right_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_up) begin
                                                ai_dir <= 2'b10;
                                                target_tile_x <= up_x;
                                                target_tile_y <= up_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_down) begin
                                                ai_dir <= 2'b11;
                                                target_tile_x <= down_x;
                                                target_tile_y <= down_y;
                                                state <= ST_MOVE;
                                            end else begin
                                                ai_dir <= 2'b01;  // Reverse
                                                state <= ST_DECIDE;
                                            end
                                        end
                                        2'b01: begin  // Moving LEFT
                                            if (can_go_left) begin
                                                target_tile_x <= left_x;
                                                target_tile_y <= left_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_up) begin
                                                ai_dir <= 2'b10;
                                                target_tile_x <= up_x;
                                                target_tile_y <= up_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_down) begin
                                                ai_dir <= 2'b11;
                                                target_tile_x <= down_x;
                                                target_tile_y <= down_y;
                                                state <= ST_MOVE;
                                            end else begin
                                                ai_dir <= 2'b00;  // Reverse
                                                state <= ST_DECIDE;
                                            end
                                        end
                                        2'b10: begin  // Moving UP
                                            if (can_go_up) begin
                                                target_tile_x <= up_x;
                                                target_tile_y <= up_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_right) begin
                                                ai_dir <= 2'b00;
                                                target_tile_x <= right_x;
                                                target_tile_y <= right_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_left) begin
                                                ai_dir <= 2'b01;
                                                target_tile_x <= left_x;
                                                target_tile_y <= left_y;
                                                state <= ST_MOVE;
                                            end else begin
                                                ai_dir <= 2'b11;  // Reverse
                                                state <= ST_DECIDE;
                                            end
                                        end
                                        2'b11: begin  // Moving DOWN
                                            if (can_go_down) begin
                                                target_tile_x <= down_x;
                                                target_tile_y <= down_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_right) begin
                                                ai_dir <= 2'b00;
                                                target_tile_x <= right_x;
                                                target_tile_y <= right_y;
                                                state <= ST_MOVE;
                                            end else if (can_go_left) begin
                                                ai_dir <= 2'b01;
                                                target_tile_x <= left_x;
                                                target_tile_y <= left_y;
                                                state <= ST_MOVE;
                                            end else begin
                                                ai_dir <= 2'b10;  // Reverse
                                                state <= ST_DECIDE;
                                            end
                                        end
                                    endcase
                                end
                            end
                            // SCATTER, CHASE, SPAWN modes: pathfinding to goal
                            else begin
                                // Find direction with minimum distance to goal
                                logic [1:0] best_dir;
                                logic [7:0] min_dist;
                                
                                // Initialize with invalid high value
                                min_dist = 8'hFF;
                                best_dir = ai_dir;  // Default: keep current direction
                                
                                // Check all valid directions and pick closest to goal
                                // NEVER reverse direction (don't go opposite to current direction)
                                if (can_go_right && ai_dir != 2'b01 && dist_to_goal_right < min_dist) begin
                                    min_dist = dist_to_goal_right;
                                    best_dir = 2'b00;  // RIGHT
                                end
                                if (can_go_left && ai_dir != 2'b00 && dist_to_goal_left < min_dist) begin
                                    min_dist = dist_to_goal_left;
                                    best_dir = 2'b01;  // LEFT
                                end
                                if (can_go_up && ai_dir != 2'b11 && dist_to_goal_up < min_dist) begin
                                    min_dist = dist_to_goal_up;
                                    best_dir = 2'b10;  // UP
                                end
                                if (can_go_down && ai_dir != 2'b10 && dist_to_goal_down < min_dist) begin
                                    min_dist = dist_to_goal_down;
                                    best_dir = 2'b11;  // DOWN
                                end
                                
                                // Move in the best direction
                                ai_dir <= best_dir;
                                case(best_dir)
                                    2'b00: begin target_tile_x <= right_x; target_tile_y <= right_y; end
                                    2'b01: begin target_tile_x <= left_x; target_tile_y <= left_y; end
                                    2'b10: begin target_tile_x <= up_x; target_tile_y <= up_y; end
                                    2'b11: begin target_tile_x <= down_x; target_tile_y <= down_y; end
                                endcase
                                state <= ST_MOVE;
                            end
                        end
                    end

                    ST_MOVE: begin
                        // Move towards target tile (1 pixel per frame)
                        if (x < target_tile_x * TILE_SIZE) 
                            x <= x + 10'd1;
                        else if (x > target_tile_x * TILE_SIZE) 
                            x <= x - 10'd1;
                        
                        if (y < target_tile_y * TILE_SIZE - V_SHIFT) 
                            y <= y + 10'd1;
                        else if (y > target_tile_y * TILE_SIZE - V_SHIFT) 
                            y <= y - 10'd1;

                        // Handle tunnel wraparound (left edge <-> right edge)
                        if ((x == 0 && target_tile_x == 27) || (x == 27*TILE_SIZE && target_tile_x == 0))
                            x <= target_tile_x * TILE_SIZE;

                        // Check if reached target tile
                        if (x == target_tile_x * TILE_SIZE && y == target_tile_y * TILE_SIZE - V_SHIFT) begin
                            curr_tile_x <= target_tile_x;
                            curr_tile_y <= target_tile_y;
                            state <= ST_DECIDE;  // Decide next move
                        end
                    end
                    
                    default: begin
                        state <= ST_IDLE;
                    end
                endcase
            end
        end
    end
    end

endmodule