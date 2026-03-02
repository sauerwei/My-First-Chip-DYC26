module game_ctrl (
    input  logic        game_tick,
    input  logic        clk,
    input  logic        rst_n,
    input  logic        round_reset, // vom game_state_controller
    input  logic        game_active,
    input  logic        eat_ghost1,
    input  logic        eat_ghost2,
    input  logic        eat_ghost3,
    input  logic        eat_ghost4,
    
    // Current pacman tile position
    input  logic [4:0]  pac_tile_x,
    input  logic [4:0]  pac_tile_y,
    
    // Current tile type from maze
    input  logic [5:0]  current_tile_type,
    input  logic        fruit_visible,
    
    // Check if current tile is already eaten
    input  logic        current_tile_eaten,
    
    // Outputs to RAM control
    output logic [4:0]  eat_x,
    output logic [4:0]  eat_y,
    output logic        eat_valid,
    output logic [1:0]  eat_kind,
    output logic        fruit_eaten,    // Pulse when fruit is eaten
    output logic        pill_eaten 
);
    localparam EAT_DOT   = 2'd0;
    localparam EAT_PILL  = 2'd1;
    localparam EAT_FRUIT = 2'd2;
    localparam EAT_GHOST = 2'd3;

    localparam DOT   = 6'd43;
    localparam PILL  = 6'd44;
    localparam FRUIT = 6'd45;

    logic [4:0] prev_tile_x, prev_tile_y;
    logic       collision_detected;
    logic       prev_any_ghost_eaten;
    logic       ghost_event_pending;
    logic       tile_event;
    logic       ghost_event;

    wire any_ghost_eaten = eat_ghost1 | eat_ghost2 | eat_ghost3 | eat_ghost4;
    wire ghost_eaten_pulse = any_ghost_eaten && !prev_any_ghost_eaten;

    // Detect when pacman enters a new tile
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_tile_x <= 5'd13;
            prev_tile_y <= 5'd23;
            collision_detected <= 1'b0;
            prev_any_ghost_eaten <= 1'b0;
            ghost_event_pending <= 1'b0;
        end else if (game_tick) begin
            if (round_reset) begin
                prev_tile_x <= 5'd13;
                prev_tile_y <= 5'd23;
                collision_detected <= 1'b0;
                prev_any_ghost_eaten <= 1'b0;
                ghost_event_pending <= 1'b0;
            end else begin      
                prev_tile_x <= pac_tile_x;
                prev_tile_y <= pac_tile_y;
                prev_any_ghost_eaten <= any_ghost_eaten;
                
                // Detect tile change
                if (pac_tile_x != prev_tile_x || pac_tile_y != prev_tile_y) begin
                    collision_detected <= 1'b1;
                end else begin
                    collision_detected <= 1'b0;
                end

                if (game_active && ghost_eaten_pulse && tile_event) begin
                    ghost_event_pending <= 1'b1;
                end else if (game_active && ghost_event) begin
                    ghost_event_pending <= 1'b0;
                end
            end
        end
    end 

    // Combinational logic for eating
    always_comb begin
        tile_event = 1'b0;
        ghost_event = 1'b0;

        eat_x = pac_tile_x;
        eat_y = pac_tile_y;
        eat_valid = 1'b0;
        eat_kind = EAT_DOT;
        fruit_eaten = 1'b0;
        pill_eaten = 1'b0;

        // Tile events (DOT/PILL/FRUIT)
        if (game_active && collision_detected && !current_tile_eaten) begin
            case (current_tile_type)
                DOT: begin
                    tile_event = 1'b1;
                    eat_kind = EAT_DOT;
                end
                PILL: begin
                    tile_event = 1'b1;
                    eat_kind = EAT_PILL;
                end
                FRUIT: begin
                    if (fruit_visible) begin
                        tile_event = 1'b1;
                        eat_kind = EAT_FRUIT;
                    end
                end
                default: begin
                    // Nothing to eat
                end
            endcase
        end

        // Ghost events (edge-detected, optionally deferred by one cycle)
        if (game_active && (ghost_event_pending || ghost_eaten_pulse)) begin
            ghost_event = 1'b1;
        end

        // One event per cycle: tile has priority, ghost can be deferred.
        if (tile_event) begin
            eat_valid = 1'b1;

            if (eat_kind == EAT_PILL)
                pill_eaten = 1'b1;
            else if (eat_kind == EAT_FRUIT)
                fruit_eaten = 1'b1;
        end else if (ghost_event) begin
            eat_valid = 1'b1;
            eat_kind = EAT_GHOST;
        end
    end

endmodule
