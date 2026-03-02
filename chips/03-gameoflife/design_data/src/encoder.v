module encoder(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] x_in,
    input  wire [2:0] y_in,
    input  wire       forw_coord,
    output reg  [5:0] index
);

    wire [5:0] next_index;

    assign next_index = (y_in * 8) + x_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            index <= 6'd0;
        end else if (forw_coord) begin
            index <= next_index;   
        end
    end

endmodule