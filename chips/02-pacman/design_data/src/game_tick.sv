module game_tick #(
    parameter CLK_FREQ = 25_175_000,
    parameter TICK_RATE = 60
)
(
    input wire clk,
    input wire rst_n,
    output wire game_tick
);

localparam TICK_MAX = CLK_FREQ / TICK_RATE;

reg [$clog2(TICK_MAX)-1:0] tick_counter;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tick_counter <= 0;
    end else if (tick_counter == $bits(tick_counter)'(TICK_MAX - 1)) begin
        tick_counter <= 0;
    end else begin
        tick_counter <= tick_counter + 1;
    end
end

assign game_tick = (tick_counter == 0);

endmodule