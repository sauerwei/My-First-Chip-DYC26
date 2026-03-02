module vga_timing(
    input  wire       clk_25MHz,
    input  wire       rst_n,
    output wire       h_sync,
    output wire       v_sync,
    output reg  [9:0] px,         
    output reg  [9:0] py,         
    output wire       video_active,
    output wire       frame_tick
);

    // VGA 640x480 @ 60Hz
    localparam H_TOTAL = 800;
    localparam V_TOTAL = 525;
    
    // Counter
    always @(posedge clk_25MHz or negedge rst_n) begin
        if (!rst_n) begin
            px <= 0; py <= 0;
        end else begin
            if (px == H_TOTAL - 1) begin
                px <= 0;
                if (py == V_TOTAL - 1) py <= 0;
                else py <= py + 1;
            end else begin
                px <= px + 1;
            end
        end
    end

    // Sync Signals (Low Active) & Active Area
    assign h_sync = !(px >= 656 && px < 752); 
    assign v_sync = !(py >= 490 && py < 492);
    assign video_active = (px < 640) && (py < 480);
    assign frame_tick = (px == H_TOTAL - 1) && (py == V_TOTAL - 1);

endmodule