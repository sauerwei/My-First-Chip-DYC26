module neighbor_counter(
    input  wire [63:0] grid,
    input  wire [5:0]  addr,
    output reg  [3:0]  count
);

    reg [2:0] x;
    reg [2:0] y;

    integer dx, dy;
    integer nx, ny;
    integer naddr;

    always @(*) begin
        naddr = 0;
        count = 0;
        
        x = addr[2:0];
        y = addr[5:3];

        for (dy = -1; dy <= 1; dy = dy + 1) begin
            for (dx = -1; dx <= 1; dx = dx + 1) begin

                if (!(dx == 0 && dy == 0)) begin
                    
                    nx = x + dx;
                    ny = y + dy;

                    if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) begin
                        naddr = ny * 8 + nx;
                        
                        if (grid[naddr]) begin
                            count = count + 1;
                        end
                    end
                end
            end
        end
    end

endmodule