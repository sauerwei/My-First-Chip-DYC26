module gamepad_final #(
    //DEBOUNCE_TIME = Taktfrequenz des Chips(Hz)*Entprellzeit(Sekunden) - das gilt für HW-Tests.
    //Für SW-Tests sollen kürzere Zeiten reichen.
    parameter integer DEBOUNCE_TIME = 2
)(
    input  logic clk,
    input  logic rst_n,     // Hardware-Reset (Active-Low)
    input  logic btn_up, btn_down, btn_left, btn_right,
    input  logic round_reset,
    output logic [3:0] sw_out
);

    // Interne Signale
    logic [3:0] raw_sync_0, raw_sync_1; // Synchronisations-Stufen
    logic [3:0] clean_keys, keys_prev;
    logic [3:0] fresh_pulse;

    // Breite des Entprell-Zählers berechnen
    localparam W_DB = $clog2(DEBOUNCE_TIME + 1); //Damit Array exakt zur Größe vom count passt. clog - celling log2
    logic [W_DB-1:0] count [3:0];

   // --- 1. Synchronisierung ---
    // Verhindert Metastabilität, da Tasten asynchron zum Takt sind
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            raw_sync_0 <= 4'b0;
            raw_sync_1 <= 4'b0;
        end else begin
            if (round_reset) begin
                raw_sync_0 <= 4'b0;
                raw_sync_1 <= 4'b0;
            end else begin
                raw_sync_0 <= {btn_right, btn_left, btn_down, btn_up};
                raw_sync_1 <= raw_sync_0;
            end
        end
    end

    // 2. Debouncing 
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : debounce_gen
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin // wenn reset - alles auf 0
                    clean_keys[i] <= 1'b0;
                    count[i] <= 0;
                end else if (raw_sync_1[i] != clean_keys[i]) begin //wenn kein reset und raw und clean_keys nicht übereinstinnem
                    if (count[i] >= W_DB'(DEBOUNCE_TIME)) begin //entweder raw_sync in die clean_keys schreiben
                        clean_keys[i] <= raw_sync_1[i];
                        count[i] <= 0;
                    end else begin //oder debouncing_Zeit abwarten
                        count[i] <= count[i] + 1'b1;
                    end
                end else begin //wenn alles übereinstimmt, dann Zeit-counter wieder auf 0 setzen
                    count[i] <= 0;
                end
            end
        end
    endgenerate

    // --- 3. Flankenerkennung (Rising Edge) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            keys_prev <= 4'b0;
        end else begin
            keys_prev <= clean_keys;
        end
    end

    assign fresh_pulse = clean_keys & ~keys_prev;

   // --- 4. Entscheidungs-Logik (Priorität) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_out <= 4'b0;
        end else if (round_reset) begin
            sw_out <= 4'b0; // Alle Richtungen zurücksetzen
        end else if (|fresh_pulse) begin
            // Prioritäts-Kette: Up > Down > Left > Right
            if      (fresh_pulse[0]) sw_out <= 4'b0001; // Up
            else if (fresh_pulse[1]) sw_out <= 4'b0010; // Down
            else if (fresh_pulse[2]) sw_out <= 4'b0100; // Left
            else if (fresh_pulse[3]) sw_out <= 4'b1000; // Right
        end
    end
endmodule
