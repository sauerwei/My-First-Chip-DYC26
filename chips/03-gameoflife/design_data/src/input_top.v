module input_top(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] x_in,
    input  wire [2:0] y_in,
    input  wire       forw_coord,
    input  wire       input_done, 

    output wire [63:0] arr_out, 
    output wire        start_game
);

    wire [5:0] index;
    reg        mem_write_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            mem_write_en <= 0;
        else        
            mem_write_en <= forw_coord;
    end

    encoder u_encoder(
        .clk(clk),
        .rst_n(rst_n),
        .x_in(x_in),
        .y_in(y_in),
        .forw_coord(forw_coord),
        .index(index)
    );

    matrix_mem u_matrix_mem(
        .clk(clk),
        .rst_n(rst_n),
        .input_done(input_done),
        .index(index),
        .write_en(mem_write_en),
        .arr_out(arr_out),
        .start_game(start_game)
    );

endmodule