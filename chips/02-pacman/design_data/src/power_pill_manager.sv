module power_pill_manager (
    input  logic        game_tick,
    input  logic        clk,
    input  logic        rst_n,
    input  logic        game_active,
    input  logic        pill_eaten,          // Pulse when power pill is eaten
    output logic        frightened_mode,     
    output logic        fright_blink_white,  // Blink white in last 1.5 seconds
    output logic [31:0] frightened_timer     // Remaining frightened time
);
    // 8 seconds
    localparam FRIGHT_DURATION = 32'd420*2;      // ~7 seconds / Dauer sollte sein: (sek/lvl)- 6/1, 5/2, 4/3, 3/4, 2/5, 7-18/1, 19+/0 
    localparam BLINK_THRESHOLD = 32'd90*2;       // Last ~1.5 seconds
    localparam BLINK_RATE = 20'd10*2;            // Blink every ~0.012 seconds
    
    logic [31:0] fright_counter;
    logic        fright_active;
    logic [19:0] blink_counter;
    logic        blink_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fright_counter <= 0;
            fright_active <= 1'b0;
            blink_counter <= 0;
            blink_state <= 1'b0;
        end else if(game_tick) begin
            if (!game_active) begin
                fright_counter <= 0;
                fright_active <= 1'b0;
                blink_counter <= 0;
                blink_state <= 1'b0;
            end else if (pill_eaten) begin
                // (Re)start frightened mode on every power pill
                fright_active <= 1'b1;
                fright_counter <= FRIGHT_DURATION;
                blink_counter <= 0;
                blink_state <= 1'b0;
            end else if (fright_active) begin
                if (fright_counter > 0) begin
                    fright_counter <= fright_counter - 1;
                    
                    // Blinking logic in last 1.5 seconds
                    if (fright_counter <= BLINK_THRESHOLD) begin
                        if (blink_counter >= BLINK_RATE) begin
                            blink_counter <= 0;
                            blink_state <= ~blink_state;
                        end else begin
                            blink_counter <= blink_counter + 1;
                        end
                    end else begin
                        blink_counter <= 0;
                        blink_state <= 1'b0;
                    end
                end else begin
                    // Timer expired
                    fright_active <= 1'b0;
                    blink_counter <= 0;
                    blink_state <= 1'b0;
                end
            end
        end
    end

    // Active when counter > 0
    assign frightened_mode = (fright_counter > 32'd0);
    assign fright_blink_white = (fright_counter > 32'd0) && (fright_counter <= BLINK_THRESHOLD) && blink_state;
    assign frightened_timer = fright_counter;

endmodule