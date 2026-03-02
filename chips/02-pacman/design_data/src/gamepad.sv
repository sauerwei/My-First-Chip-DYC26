module gamepad #(
    parameter integer DEBOUNCE_TIME = 1
)(
    input  logic clk,
    input  logic rst_n,
    input  logic round_reset, // vom game_state_controller
    // Pmod Gamepad Pins
    input  logic pmod_data,
    input  logic pmod_clk,
    input  logic pmod_latch,
    
    output logic [3:0] sw_out //
);

    // --- 1. Gamepad Schnittstelle & Synchronisation ---
    logic [1:0] sync_data, sync_clk, sync_latch;
    logic pmod_clk_prev, pmod_latch_prev;
    logic [11:0] shift_reg;
    
    // Roh-Signale nach dem Entpacken
    logic [3:0] gamepad_raw; // [3]=Right, [2]=Left, [1]=Down, [0]=Up

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n | round_reset) begin
            sync_data  <= 2'b0;
            sync_clk   <= 2'b0;
            sync_latch <= 2'b0;
            shift_reg  <= 12'hFFF;
            pmod_clk_prev <= 1'b0;
            pmod_latch_prev <= 1'b0;
            gamepad_raw <= 4'b0;
        end else begin
            // Synchronisation
            sync_data  <= {sync_data[0],  pmod_data};
            sync_clk   <= {sync_clk[0],   pmod_clk};
            sync_latch <= {sync_latch[0], pmod_latch};
            
            pmod_clk_prev   <= sync_clk[1];
            pmod_latch_prev <= sync_latch[1];

            // Daten einlesen bei steigender Taktflanke des Gamepads
            if (sync_clk[1] && !pmod_clk_prev) begin
                shift_reg <= {shift_reg[10:0], sync_data[1]};
            end

            // Extraktion bei Latch-Signal (Daten sind nun stabil)
            if (sync_latch[1] && !pmod_latch_prev) begin
                gamepad_raw[0] <= shift_reg[7]; // Up
                gamepad_raw[1] <= shift_reg[6]; // Down
                gamepad_raw[2] <= shift_reg[5]; // Left
                gamepad_raw[3] <= shift_reg[4]; // Right
            end
        end
    end

    // --- 2. Debouncing ---
    logic [3:0] clean_keys, keys_prev;
    localparam W_DB = $clog2(DEBOUNCE_TIME + 1);
    logic [W_DB-1:0] count [3:0];

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : debounce_gen
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    clean_keys[i] <= 1'b0;
                    count[i] <= 0;
                end else if (gamepad_raw[i] != clean_keys[i]) begin
                    if (count[i] >= W_DB'(DEBOUNCE_TIME)) begin
                        clean_keys[i] <= gamepad_raw[i];
                        count[i] <= 0;
                    end else begin
                        count[i] <= count[i] + 1'b1;
                    end
                end else begin
                    count[i] <= 0;
                end
            end
        end
    endgenerate

    // --- 3. Flankenerkennung & Prioritäts-Logik ---
    logic [3:0] fresh_pulse;
    assign fresh_pulse = clean_keys & ~keys_prev;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || round_reset) begin
            keys_prev <= 4'b0;
            sw_out    <= 4'b0;
        end else begin
            keys_prev <= clean_keys;
            
            if (|fresh_pulse) begin
                // Prioritäts-Kette: Up (0) > Down (1) > Left (2) > Right (3)
                casez (fresh_pulse)
                    4'b???1: sw_out <= 4'b0001;
                    4'b??10: sw_out <= 4'b0010;
                    4'b?100: sw_out <= 4'b0100;
                    4'b1000: sw_out <= 4'b1000;
                    default: sw_out <= sw_out;
                endcase
            end
        end
    end
endmodule