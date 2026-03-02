module gol(
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire        game_enable,
    input  wire [63:0] grid,
    output wire [63:0] next,
    output reg         done
);

    localparam IDLE = 2'b00;
    localparam RUN  = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0]  state;
    reg [63:0] grid_reg;
    reg [63:0] next_reg;
    reg [5:0]  addr;
    
    wire [3:0] count;
    wire       next_bit;

    neighbor_counter nc (
        .grid(grid_reg),
        .addr(addr),
        .count(count)
    );

    rule_engine re (
        .center(grid_reg[addr]),
        .count(count),
        .next_cell(next_bit)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            addr  <= 0;
            done  <= 0;
            grid_reg <= 0;
            next_reg <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    done <= 0;
                    if (start && game_enable) begin
                        grid_reg <= grid;
                        addr <= 0;
                        state <= RUN;
                    end
                end

                RUN: begin
                    next_reg[addr] <= next_bit;
                    addr <= addr + 1;
                    if (addr == 63)
                        state <= DONE;
                end

                DONE: begin
                    done <= 1;
                    
                    if (!game_enable)
                        state <= IDLE;
                end
                
                default: state <= IDLE;

            endcase
        end
    end

    assign next = next_reg;

endmodule