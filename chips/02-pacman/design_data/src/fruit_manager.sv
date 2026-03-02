module fruit_manager (
    input  logic       game_tick,
    input  logic       clk,
    input  logic       rst_n,
    input  logic       game_active,
    input  logic       game_reset,
    input  logic       level_reset,
    input  logic [9:0] level,
    input  logic [8:0] dots_eaten,
    input  logic       fruit_eaten_pulse, // Impuls vom game_ctrl
    output logic       fruit_display,      // Signal an den Renderer
    output logic [2:0] fruit_item_id,
    output logic [21:0] fruit_item_points
);

    localparam logic [8:0] DOTS_FIRST_FRUIT  = 9'd70;// 70
    localparam logic [8:0] DOTS_SECOND_FRUIT = 9'd180; // 180
    localparam logic [27:0] TIMER = 28'd600*2; // sollten 9-10 sekunden sein

    logic [27:0] fruit_timer;
    logic        fruit_visible;
    logic        first_spawn_done;
    logic        second_spawn_done;

    always_comb begin
        // Level -> Item/Punkte
        // 1: Cherry 100
        // 2: Strawberry 300
        // 3-4: Orange 500
        // 5-6: Apple 700
        // 7-8: Melon 1000
        // 9-10: Galaxian 2000
        // 11-12: Bell 3000
        // >=13: Key 5000
        if (level <= 10'd1) begin
            fruit_item_id     = 3'd0;
            fruit_item_points = 22'd100;
        end else if (level == 10'd2) begin
            fruit_item_id     = 3'd1;
            fruit_item_points = 22'd300;
        end else if (level <= 10'd4) begin
            fruit_item_id     = 3'd2;
            fruit_item_points = 22'd500;
        end else if (level <= 10'd6) begin
            fruit_item_id     = 3'd3;
            fruit_item_points = 22'd700;
        end else if (level <= 10'd8) begin
            fruit_item_id     = 3'd4;
            fruit_item_points = 22'd1000;
        end else if (level <= 10'd10) begin
            fruit_item_id     = 3'd5;
            fruit_item_points = 22'd2000;
        end else if (level <= 10'd12) begin
            fruit_item_id     = 3'd6;
            fruit_item_points = 22'd3000;
        end else begin
            fruit_item_id     = 3'd7;
            fruit_item_points = 22'd5000;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fruit_timer       <= 28'd0;
            fruit_visible     <= 1'b0;
            first_spawn_done  <= 1'b0;
            second_spawn_done <= 1'b0;
        end
        else if (game_tick) begin
            if (game_reset || level_reset) begin
                fruit_timer       <= 28'd0;
                fruit_visible     <= 1'b0;
                first_spawn_done  <= 1'b0;
                second_spawn_done <= 1'b0;
            end else begin
                if (fruit_visible) begin
                    if (fruit_eaten_pulse) begin
                        fruit_visible <= 1'b0;
                        fruit_timer   <= 28'd0;
                    end else if (fruit_timer > 28'd0) begin
                        fruit_timer <= fruit_timer - 28'd1;
                    end else begin
                        fruit_visible <= 1'b0;
                    end
                end else begin
                    if (!first_spawn_done && dots_eaten >= DOTS_FIRST_FRUIT) begin
                        first_spawn_done <= 1'b1;
                        fruit_visible    <= 1'b1;
                        fruit_timer      <= TIMER;
                    end else if (!second_spawn_done && dots_eaten >= DOTS_SECOND_FRUIT) begin
                        second_spawn_done <= 1'b1;
                        fruit_visible     <= 1'b1;
                        fruit_timer       <= TIMER;
                    end
                end
            end
        end
    end

    // Frucht nur im aktiven Spiel anzeigen
    always_comb begin
        fruit_display = fruit_visible && game_active;
    end

endmodule