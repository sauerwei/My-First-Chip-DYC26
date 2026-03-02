// Zentrale Spielzustandsmaschine (FSM)
//
// Aufgabe:
// - steuert alle Spielphasen (Start, Ready, Play, Death, Win, Game Over)
// - erzeugt kurze Reset-Pulse für Subsysteme
// - aktiviert/deaktiviert Gameplay-Logik (Kollisionen, Consumables)
// - liefert einfache Render-Flags für Bildschirmzustände
module game_state_controller #(
    // Startanzahl Leben pro neuem Spiel
    parameter logic [3:0] INITIAL_LIVES = 4'd3,

    // Dauer der jeweiligen Zustände in Frames (game_tick-basiert)
    parameter logic [9:0] READY_FRAMES = 10'd30*2,
    parameter logic [9:0] DEATH_ANIMATION_FRAMES = 10'd30*2,
    parameter logic [9:0] WIN_FLASH_FRAMES = 10'd100*2,
    parameter logic [9:0] GAME_OVER_FRAMES = 10'd40*2
)(
    // game_tick wird als takt für die Zustandsmaschine genutzt
    input  logic       game_tick,
    input  logic       clk,
    input  logic       rst_n,

    // Startsignal (z. B. irgendeine Richtungstaste gedrückt)
    input  logic       start_pressed, // gamepad

    // Ereignisse aus anderer Logik
    input  logic       pacman_died_pulse, // game_reset_controller
    input  logic       level_cleared, // dot_pill_ram
    input  logic [21:0] score, // dot_pill_ram

    // Globales Gameplay-Gating
    output logic       game_active,

    // Render-/Overlay-Hinweise pro Zustand
    output logic       show_start,
    output logic       show_ready,
    output logic       show_death_animation,
    output logic       show_win_flash,
    output logic       show_game_over,

    // Aktuelle Leben
    output logic [3:0] lives, // renderer kann aktuell max. 5 anzeigen // aktuell gibt es aber nur max 4 Leben (3 Start + 1 extra Leben ab 10000 Punkten)
    output logic [9:0] level,

    // Ein-Frame-Pulse für Subsystem-Resets
    output logic       game_reset_pulse,  // game_reset_pulse: komplettes neues Spiel (Score/Map/etc.)
    output logic       level_reset_pulse,     // level_reset_pulse: nur neues Level (Map neu, Score bleibt)
    output logic       round_reset_pulse      // round_reset_pulse: nur Runde/Positionen neu (nach Tod oder Start)
);

    // Zustandskodierung
    localparam logic [2:0] S_START            = 3'd0;
    localparam logic [2:0] S_READY            = 3'd1;
    localparam logic [2:0] S_PLAY             = 3'd2;
    localparam logic [2:0] S_DEATH_ANIMATION  = 3'd3;
    localparam logic [2:0] S_WIN_FLASH        = 3'd4;
    localparam logic [2:0] S_GAME_OVER        = 3'd5;
    localparam logic [21:0] EXTRA_LIFE_SCORE  = 22'd10000;

    logic [2:0] state; // state: aktueller FSM-Zustand
    logic [9:0] state_timer; // state_timer: Countdown für zeitgesteuerte Zustände
    logic       death_to_game_over; // death_to_game_over: merkt beim Tod, ob danach GAME_OVER statt READY folgt
    logic       extra_life_awarded; // extra_life_awarded: verhindert mehrfaches Bonusleben bei 10.000 Punkten

    // Sequentielle FSM (läuft auf Frame-Basis)
    always_ff @(posedge clk or negedge rst_n) begin
        // Asynchroner Hardware-Reset: alles in definierten Startzustand
        if (!rst_n) begin
            state                 <= S_START;
            state_timer           <= 10'd0;
            lives                 <= INITIAL_LIVES;
            level                 <= 10'd1;
            death_to_game_over    <= 1'b0;
            extra_life_awarded    <= 1'b0;
            game_reset_pulse      <= 1'b0;
            level_reset_pulse     <= 1'b0;
            round_reset_pulse     <= 1'b0;
        end else if (game_tick) begin

            // Pulse standardmäßig jede Frame wieder löschen
            // (werden nur im jeweiligen Übergang 1 Frame lang gesetzt)
            game_reset_pulse    <= 1'b0; // nach game_over
            level_reset_pulse    <= 1'b0; // nach win
            round_reset_pulse    <= 1'b0; // nach Death (ohne game_over)

            case (state)
                // START:
                // wartet auf Startsignal, initialisiert bei Übergang das Spiel neu
                S_START: begin
                    if  (start_pressed) begin
                        // Neues Spiel starten
                        game_reset_pulse    <= 1'b1;
                        level_reset_pulse   <= 1'b1;
                        round_reset_pulse   <= 1'b1;
                        lives               <= INITIAL_LIVES;
                        level               <= 10'd1;
                        death_to_game_over  <= 1'b0;
                        extra_life_awarded  <= 1'b0;
                        state               <= S_READY;
                        state_timer         <= READY_FRAMES;
                    end
                end

                // READY:
                // kurze Wartephase vor PLAY (z. B. "READY!"-Moment)
                S_READY: begin
                    if (state_timer > 0) begin
                        state_timer <= state_timer - 10'd1;
                    end else begin
                        round_reset_pulse   <= 1'b1;
                        state <= S_PLAY;
                    end
                end

                // PLAY:
                // normales Gameplay; reagiert auf Tod oder Levelende
                S_PLAY: begin
                    if (pacman_died_pulse) begin
                        // Leben reduzieren (unter 0 wird vermieden)
                        if (lives > 4'd0) begin
                            lives <= lives - 4'd1;
                        end
                        // Entscheidung für Zielzustand nach Death-Phase vormerken
                        // lives<=1 bedeutet: aktueller Tod verbraucht letztes Leben
                        death_to_game_over <= (lives <= 4'd1);
                        state             <= S_DEATH_ANIMATION;
                        state_timer       <= DEATH_ANIMATION_FRAMES;
                    end else if (level_cleared) begin
                        // Bei Levelende erst kurze Win-Phase
                        state       <= S_WIN_FLASH;
                        state_timer <= WIN_FLASH_FRAMES;
                    end else if (!extra_life_awarded && (score >= EXTRA_LIFE_SCORE)) begin
                        extra_life_awarded <= 1'b1;
                        lives <= lives + 4'd1;
                    end
                end

                // DEATH_ANIMATION:
                // Nach Ablauf entweder GAME_OVER oder zurück zu READY
                S_DEATH_ANIMATION: begin
                    if (state_timer > 0) begin
                        state_timer <= state_timer - 10'd1;
                    end else if (death_to_game_over) begin
                        state       <= S_GAME_OVER;
                        state_timer <= GAME_OVER_FRAMES;
                    end else begin
                        // Neue Runde im gleichen Level
                        round_reset_pulse <= 1'b1;
                        state             <= S_READY;
                        state_timer       <= READY_FRAMES;
                    end
                end

                // WIN_FLASH:
                // Kurze Siegphase, dann neues Level vorbereiten
                S_WIN_FLASH: begin
                    if (state_timer > 0) begin
                        state_timer <= state_timer - 10'd1;
                    end else begin
                        // Neues Level + neue Runde
                        level_reset_pulse <= 1'b1;
                        round_reset_pulse <= 1'b1;
                        if (level < 10'd1023)
                            level <= level + 10'd1;
                        state             <= S_READY;
                        state_timer       <= READY_FRAMES;
                    end
                end

                // GAME_OVER:
                // Nach Timer zurück auf Startbildschirm
                S_GAME_OVER: begin
                    if (state_timer > 0) begin
                        state_timer <= state_timer - 10'd1;
                    end else begin
                        state               <= S_START;
                        game_reset_pulse    <= 1'b1;
                        level_reset_pulse   <= 1'b1;
                        round_reset_pulse   <= 1'b1;
                    end
                end

                // Fallback bei unerwartetem Zustand
                default: begin
                    state <= S_START;
                end
            endcase
        end
    end

    // Kombinatorische Ausgabe-Logik je Zustand
    always_comb begin
        // Sichere Defaults
        game_active           = 1'b0;
        show_start            = 1'b0;
        show_ready            = 1'b0;
        show_death_animation  = 1'b0;
        show_win_flash        = 1'b0;
        show_game_over        = 1'b0;

        case (state)
            S_START: begin
                // Nur Overlay, kein Gameplay
                show_start = 1'b1;
            end

            S_PLAY: begin
                // Nur hier sind Bewegung/Kollision/Consume aktiv
                game_active = 1'b1;
            end

            S_READY: begin
                show_ready = 1'b1;
            end

            S_DEATH_ANIMATION: begin
                show_death_animation = 1'b1;
            end

            S_WIN_FLASH: begin
                show_win_flash = 1'b1;
            end

            S_GAME_OVER: begin
                show_game_over = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule

// Auswirkungen LvL-Up (außer Früchte - sind bereit implementiert):

//Hier ist genau, was sich beim Level-Up im Original-Automaten verändert:
// 1. Die Geschwindigkeiten (Speed Tiers)

// Weder Pac-Man noch die Geister bewegen sich immer gleich schnell. Das Spiel ist in feste Geschwindigkeits-Stufen eingeteilt.

//     Level 1: Pac-Man bewegt sich mit 80% seiner Maximalgeschwindigkeit, die Geister mit 75%.

//     Level 2 bis 4: Pac-Man beschleunigt auf 90%, die Geister auf 85%.

//     Level 5 bis 20: Pac-Man erreicht seine absolute Höchstgeschwindigkeit von 100%, die Geister sind dicht auf den Fersen mit 95%.

//     Das böse Erwachen ab Level 21: Pac-Man wird plötzlich wieder auf 90% gedrosselt, aber die Geister bleiben auf ihren rasanten 95%. Ab jetzt sind die Geister also dauerhaft schneller als du!

// Wichtiges Detail: Wenn Pac-Man kleine Punkte (Dots) isst, bleibt er pro Punkt für exakt einen Frame stehen. Das macht ihn beim Essen effektiv um etwa 10% langsamer. Auf hohen Leveln holen dich die Geister in Punktereihen also gnadenlos ein.
// 2. Die Power-Pellets (Frightened Mode)

// Die Zeit, in der die Geister nach dem Essen eines dicken Punktes blau werden (Frightened Mode) und gefressen werden können, nimmt rapide ab.

//     Level 1: Du hast üppige 6 Sekunden Zeit.

//     Level 2 bis 5: Die Zeit sinkt schrittweise von 5 auf nur noch 2 Sekunden.

//     Level 17, sowie alles ab Level 19: Die Zeit beträgt 0 Sekunden. Die Geister werden überhaupt nicht mehr blau und können dementsprechend nicht mehr gefressen werden. Das Power-Pellet bewirkt hier nur noch, dass die Geister sofort ihre aktuelle Richtung wechseln (180-Grad-Wende).

// 3. "Cruise Elroy" (Blinkys Wut-Modus)

// Der rote Geist (Blinky) hat eine versteckte Mechanik: Er beschleunigt zweimal pro Level abhängig davon, wie viele kleine Punkte noch im Labyrinth übrig sind. Dieser Zustand wird im Code "Cruise Elroy" genannt.

//     Sobald Elroy Stufe 2 erreicht (bei nur noch 10 verbleibenden Punkten im Level), ist er nochmals spürbar schneller als Pac-Man.

//     Der Level-Effekt: Mit steigendem Level wird Blinky immer früher wütend. In Level 1 zündet der Turbo erst bei 20 restlichen Punkten. In hohen Leveln wird Blinky schon bei viel mehr verbleibenden Punkten zum rasenden Elroy. Zu allem Überfluss jagt er Pac-Man im vollen Elroy-Modus auch in den Scatter-Phasen dauerhaft weiter, anstatt sein reguläres Zielfeld aufzusuchen.

// 4. Die Scatter- & Chase-Timer

// Geister haben zwei Verhaltensmuster: "Chase" (Pac-Man angreifen) und "Scatter" (sich in ihre 4 festgelegten Bildschirmecken zurückziehen).

//     Diese Phasen wechseln sich automatisch nach festen Timern während des Gameplays ab.

//     Der Level-Effekt: Je höher das Level, desto kürzer werden deine Verschnaufpausen. Die Scatter-Phasen schrumpfen zusammen, während die Chase-Phasen, in denen dich die Geister aktiv jagen, immer länger werden.