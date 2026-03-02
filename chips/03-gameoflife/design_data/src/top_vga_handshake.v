module top_vga_handshake(
    input  wire        CLK100MHZ,   
    input  wire        CPU_RESETN,  

    input  wire [63:0] game_grid_in,  
    input  wire        game_done,
    input  wire        game_start,  
    output wire        game_enable,   
    
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B
);

    wire clk_25;
    wire [9:0] px, py;
    wire video_active, frame_tick;
    wire [127:0] w_age_grid;
    reg [63:0] display_buffer;
    reg [5:0] frame_counter;

    localparam STATE_WAIT_TIME = 2'b00;
    localparam STATE_REQUEST   = 2'b01;
    localparam STATE_SAVE      = 2'b10;
    reg [1:0] state;

    // --- CLOCK HANDLING ---
    
    // for vga-playground only
    // assign clk_25 = CLK100MHZ; 
    
    // for fpga (100 MHz -> 25 MHz)
    reg [1:0] clk_cnt;
    always @(posedge CLK100MHZ) clk_cnt <= clk_cnt + 1;
    assign clk_25 = clk_cnt[1]; 
    

    vga_timing timing_inst (
        .clk_25MHz(clk_25),
        .rst_n(CPU_RESETN),
        .h_sync(VGA_HS),
        .v_sync(VGA_VS),
        .px(px),
        .py(py),
        .video_active(video_active),
        .frame_tick(frame_tick)
    );

    age_manager age_inst (
        .clk(clk_25),
        .rst_n(CPU_RESETN),
        .update_en(state == STATE_SAVE),
        .new_grid_data(game_grid_in),
        .current_grid(display_buffer),
        .age_grid(w_age_grid)
    );

    pixel_renderer paint_inst (
        .px(px),
        .py(py),
        .video_active(video_active),
        .grid_data(display_buffer), 
        .age_data(w_age_grid),
        .r(VGA_R),
        .g(VGA_G),
        .b(VGA_B)
    );

    always @(posedge clk_25 or negedge CPU_RESETN) begin
        if (!CPU_RESETN) begin
            frame_counter  <= 0;
            display_buffer <= 64'h8142241818244281;
            state          <= STATE_WAIT_TIME;
        end else begin
            
            case (state)
                STATE_WAIT_TIME: begin
                    display_buffer <= game_grid_in; 

                    if (frame_tick) begin
                        if (frame_counter < 29) begin
                            frame_counter <= frame_counter + 1;
                        end else if (game_start) begin
                            frame_counter <= 0;
                            state <= STATE_REQUEST; 
                        end
                    end
                end

                STATE_REQUEST: begin
                    if (game_done == 1) begin
                        state <= STATE_SAVE;
                    end
                end

                STATE_SAVE: begin
                    display_buffer <= game_grid_in;
                    state <= STATE_WAIT_TIME;
                end
                
                default: state <= STATE_WAIT_TIME;
            endcase
        end
    end

    assign game_enable = (state == STATE_REQUEST);

endmodule