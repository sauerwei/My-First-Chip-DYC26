`default_nettype none

module tt_um_vga_example(
    input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    wire w_sys_rst_n  = rst_n && ~ui_in[0]; // Reset
    wire w_user_start = ui_in[1];           // Start game
    
    wire [3:0] w_in_x = ui_in[4:2]; // X-Coordinate
    wire [3:0] w_in_y = ui_in[7:5]; // Y-Coordinate
    
    wire w_forw_coord = uio_in[0];           // Pixel done (must be pressed for all pixel on and off)
    wire w_input_done = uio_in[1];           // Press when all inputs are done

    wire [3:0] w_vga_r, w_vga_g, w_vga_b;
    wire       w_vga_hs, w_vga_vs;
    
    wire        w_trigger;      
    wire        w_done;         
    wire [63:0] w_next_grid;    
    
    wire [63:0] w_grid_from_input; 
    wire        w_input_valid; 

    reg [63:0] r_current_grid;
    reg grid_loaded; 

    always @(posedge clk or negedge w_sys_rst_n) begin
        if (!w_sys_rst_n) begin
            r_current_grid <= 0; 
            grid_loaded    <= 0;
        end else begin
            if (w_input_valid && !grid_loaded) begin
                r_current_grid <= w_grid_from_input;
                grid_loaded <= 1; 
            end
            else if (w_trigger && w_done) begin
                 r_current_grid <= w_next_grid;
            end
        end
    end

    input_top u_input_top(
      .clk(clk),
      .rst_n(w_sys_rst_n),
      .x_in(w_in_x),
      .y_in(w_in_y),
      .forw_coord(w_forw_coord), 
      .input_done(w_input_done), 
      .arr_out(w_grid_from_input),    
      .start_game(w_input_valid) 
    );

    top_vga_handshake my_decoder (
        .CLK100MHZ   (clk),
        .CPU_RESETN  (w_sys_rst_n), 
        .game_grid_in(r_current_grid), 
        .game_done   (w_done),      
        .game_enable (w_trigger),
        .game_start  (w_user_start),   
        .VGA_HS(w_vga_hs), .VGA_VS(w_vga_vs),
        .VGA_R (w_vga_r),  .VGA_G (w_vga_g),  .VGA_B (w_vga_b)
    );

    gol my_game_engine (
        .clk        (clk),
        .reset      (!w_sys_rst_n), 
        .start      (w_user_start), 
        .game_enable(w_trigger),   
        .grid       (r_current_grid), 
        .next       (w_next_grid),    
        .done       (w_done)
    );

    assign uo_out = {w_vga_hs, w_vga_b[2], w_vga_g[2], w_vga_r[2], w_vga_vs, w_vga_b[3], w_vga_g[3], w_vga_r[3]};
    assign uio_out = 0;
    assign uio_oe  = 0;

endmodule