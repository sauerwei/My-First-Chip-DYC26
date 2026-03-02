module matrix_mem (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [5:0]  index,
    input  wire        input_done,
    input  wire        write_en,
    output reg  [63:0] arr_out, 
    output reg         start_game
);

    reg [63:0] mem;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem        <= 64'd0;
            arr_out    <= 64'd0;
            start_game <= 1'd0;
        end else begin
            if (input_done) begin
                arr_out    <= mem;
                start_game <= 1'd1;
                mem        <= 64'd0;
            end
            else if (write_en) begin 
                start_game <= 1'd0;
                mem <= mem | (64'd1 << index);
            end
        end
    end
endmodule