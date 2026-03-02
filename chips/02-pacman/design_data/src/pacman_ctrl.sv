module pacman_ctrl (
    input  logic        game_tick,
    input  logic        clk,
    input  logic        rst_n,
    input  logic        game_active, // vom game_state_controller
    input  logic [3:0]  move_dir, // sw_out vom gamepad
    output logic [9:0]  pac_x,
    output logic [9:0]  pac_y,
    output logic [3:0]  active_dir,
    output logic [3:0]  requested_dir,
    output logic [4:0]  pac_tile_x,
    output logic [4:0]  pac_tile_y,
    output logic [1:0]  pac_state
);

    localparam TILE_SIZE   = 5'd16;
    localparam WALL_END    = 6'd41; // 40 = letzte mauer, 41 = gate
    localparam SPEED_LIMIT = 20'd0;
    localparam MOUTH_PIXELS_PER_STEP = 4'd8; // Mundbewegung alle 8 Pixel und von Bewegung abhängig, nicht von clk

    typedef enum logic [1:0] {
        ST_IDLE   = 2'b00,
        ST_DECIDE = 2'b01,
        ST_MOVE   = 2'b10
    } state_t;

    state_t state;
    
    logic [4:0] curr_tile_x, curr_tile_y;
    logic [4:0] target_tile_x, target_tile_y;
    logic [19:0] speed_cnt;
    
    // Mouth animation
    logic [3:0]  mouth_step_pixels;
    logic [1:0]  mouth_state;
    logic        mouth_opening;

    // --- NEU: Wir brauchen zwei Checks gleichzeitig oder nacheinander ---
    // Um es kompakt zu halten, nutzen wir zwei kleine Instanzen der Map-Logik
    // oder fragen einfach beide Richtungen ab.
    
    logic [4:0] req_x, req_y, act_x, act_y;
    logic [5:0] req_tile_type, act_tile_type;

    // Wohin würde requested_dir führen?
    always_comb begin
        req_x = curr_tile_x; req_y = curr_tile_y;
        case (requested_dir)
            4'b0001: req_y = curr_tile_y - 5'd1;
            4'b0010: req_y = curr_tile_y + 5'd1;
            4'b0100: req_x = (curr_tile_x == 5'd0)  ? 5'd27 : curr_tile_x - 5'd1; //Pacman-Tunnel
            4'b1000: req_x = (curr_tile_x == 5'd27) ? 5'd0  : curr_tile_x + 5'd1; //Pacman-Tunnel
            default: ;
        endcase
    end

    // Wohin würde active_dir (geradeaus) führen?
    always_comb begin
        act_x = curr_tile_x; act_y = curr_tile_y;
        case (active_dir)
            4'b0001: act_y = curr_tile_y - 5'd1;
            4'b0010: act_y = curr_tile_y + 5'd1;
            4'b0100: act_x = (curr_tile_x == 5'd0)  ? 5'd27 : curr_tile_x - 5'd1; //Pacman-Tunnel
            4'b1000: act_x = (curr_tile_x == 5'd27) ? 5'd0  : curr_tile_x + 5'd1; //Pacman-Tunnel
            default: ;
        endcase
    end

    // Zwei Abfragen an die Map (Hardware-Ressourcen sind hier meist unkritisch)
    maze_map map_req (.x_tile(req_x), .y_tile(req_y), .tile_type(req_tile_type));
    maze_map map_act (.x_tile(act_x), .y_tile(act_y), .tile_type(act_tile_type));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            curr_tile_x <= 5'd13; curr_tile_y <= 5'd23;
            pac_x <= 10'd216; pac_y <= 23 * TILE_SIZE;
            {active_dir, speed_cnt, target_tile_x, target_tile_y} <= '0;
            requested_dir <= 4'b0100;
            pac_tile_x <= 5'd13;
            pac_tile_y <= 5'd23;
        end else if (game_tick) begin
            if (!game_active) begin
                state <= ST_IDLE;
                curr_tile_x <= 5'd13; curr_tile_y <= 5'd23;
                pac_x <= 10'd216; pac_y <= 23 * TILE_SIZE;
                {active_dir, speed_cnt, target_tile_x, target_tile_y} <= '0;
                requested_dir <= 4'b0100;
                pac_tile_x <= 5'd13;
                pac_tile_y <= 5'd23;
            end else if (game_active) begin
                if (move_dir != 4'b0000) begin
                    requested_dir <= move_dir;
                end
                speed_cnt <= (speed_cnt >= SPEED_LIMIT) ? 0 : speed_cnt + 1;
                if (speed_cnt == SPEED_LIMIT) begin
                    case (state)
                        ST_IDLE: begin
                            if (requested_dir != 4'b0000) state <= ST_DECIDE;
                        end
                        ST_DECIDE: begin
                            // 1. Priorität: Kann ich in die Wunsch-Richtung (requested_dir) abbiegen?
                            if (requested_dir != 4'b0000 && req_tile_type > WALL_END) begin
                                target_tile_x <= req_x;
                                target_tile_y <= req_y;
                                active_dir    <= requested_dir; // Wunsch wird zur aktiven Richtung
                                state         <= ST_MOVE;
                            end 
                            // 2. Priorität: Ist der Weg in der bisherigen Richtung (active_dir) weiterhin frei?
                            else if (active_dir != 4'b0000 && act_tile_type > WALL_END) begin
                                target_tile_x <= act_x;
                                target_tile_y <= act_y;
                                // active_dir bleibt gleich
                                state         <= ST_MOVE;
                            end 
                            // 3. Priorität: Sackgasse / Wand vorne -> Anhalten
                            else begin
                                state      <= ST_IDLE;
                            end
                        end

                        ST_MOVE: begin
                            // Pixel-Bewegung
                            if (pac_x < target_tile_x * TILE_SIZE) pac_x <= pac_x + 1'd1;
                            else if (pac_x > target_tile_x * TILE_SIZE) pac_x <= pac_x - 1'd1;
                            
                            if (pac_y < target_tile_y * TILE_SIZE) pac_y <= pac_y + 1'd1;
                            else if (pac_y > target_tile_y * TILE_SIZE) pac_y <= pac_y - 1'd1;

                            // Tunnel
                            if ((pac_x == 0 && target_tile_x == 27) || (pac_x == 27*TILE_SIZE && target_tile_x == 0))
                                pac_x <= target_tile_x * TILE_SIZE;

                            // Ankunft
                            if (pac_x == target_tile_x * TILE_SIZE && pac_y == target_tile_y * TILE_SIZE) begin
                                curr_tile_x <= target_tile_x;
                                curr_tile_y <= target_tile_y;
                                pac_tile_x <= target_tile_x;
                                pac_tile_y <= target_tile_y;
                                state       <= ST_DECIDE; 
                            end
                        end
                        
                        default: begin
                            state <= ST_IDLE;
                        end
                    endcase
                end
            end else begin
                speed_cnt <= speed_cnt;
            end
        end    
    end
    
    // Mouth animation: 0 -> 1 -> 2 -> 1, synchronisiert mit Bewegungs-Pixeln
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mouth_step_pixels <= 4'd0;
            mouth_state <= 2'd0;
            mouth_opening <= 1'b1;
        end
        else if (game_tick) begin
            if (!game_active) begin
                mouth_step_pixels <= 4'd0;
                mouth_state <= 2'd0;
                mouth_opening <= 1'b1;
            end else if ((state == ST_MOVE) && (speed_cnt == SPEED_LIMIT)) begin
                if (mouth_step_pixels == (MOUTH_PIXELS_PER_STEP - 4'd1)) begin
                    mouth_step_pixels <= 4'd0;
                    if (mouth_opening) begin
                        if (mouth_state == 2'd2) begin
                            mouth_state <= 2'd1;
                            mouth_opening <= 1'b0;
                        end else begin
                            mouth_state <= mouth_state + 2'd1;
                            mouth_opening <= 1'b1;
                        end
                    end else begin
                        if (mouth_state == 2'd0) begin
                            mouth_state <= 2'd1;
                            mouth_opening <= 1'b1;
                        end else begin
                            mouth_state <= mouth_state - 2'd1;
                            mouth_opening <= 1'b0;
                        end
                    end
                end else begin
                    mouth_step_pixels <= mouth_step_pixels + 4'd1;
                    mouth_opening <= mouth_opening;
                end
            end else begin
                mouth_step_pixels <= mouth_step_pixels;
                mouth_state <= mouth_state;
                mouth_opening <= mouth_opening;
            end
        end
    end
    
    assign pac_state = mouth_state;
    
endmodule