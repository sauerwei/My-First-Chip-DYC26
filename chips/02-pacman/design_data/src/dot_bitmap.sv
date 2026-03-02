module dot_bitmap(
    input  logic [3:0] y_offset,    // row in map (0-15)
    input  logic [3:0] x_offset,    // pixel in row (0-15)
    output logic       is_dot     // 1 = on, 0 = off
);
    // logic
    logic [15:0] row_data;          // one row (16 Bit), Little Endian --> [0] = right
    // dot-ROM
    always_comb begin
        case (y_offset)
            4'd6:  row_data = 16'b000001111000000;
            4'd7:  row_data = 16'b000001111000000;
            4'd8:  row_data = 16'b000001111000000;
            4'd9:  row_data = 16'b000001111000000;
            default: row_data = 16'b0;
        endcase
    end
    // output
    assign is_dot = row_data[x_offset];

endmodule