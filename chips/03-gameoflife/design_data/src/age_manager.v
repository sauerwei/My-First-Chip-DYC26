module age_manager(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        update_en,
    input  wire [63:0] new_grid_data,
    input  wire [63:0] current_grid,
    output reg [127:0] age_grid
);
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            age_grid <= 0;
        end else begin
            if (update_en) begin
                for (i = 0; i < 64; i = i + 1) begin
                    if (new_grid_data[i]) begin
                        
                        if (current_grid[i]) begin
                            if (age_grid[i*2 +: 2] < 2'd3) 
                                age_grid[i*2 +: 2] <= age_grid[i*2 +: 2] + 1;
                        end 
                        else begin
                            age_grid[i*2 +: 2] <= 0;
                        end
                        
                    end else begin
                        age_grid[i*2 +: 2] <= 0;
                    end
                end
            end
        end
    end
endmodule