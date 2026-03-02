module gate_bitmap(
    input  logic [3:0] y_offset,    // row in map (0-15)
    input  logic [3:0] x_offset,    // pixel in row (0-15)
    output logic       is_gate      // 1 = on, 0 = off
);
    // logic
    logic [15:0] row_data;          // one row (16 Bit), Little Endian --> [0] = right
    // dot-ROM
    always_comb begin
        case (y_offset)
            4'd10:  row_data = 16'b1111111111111111; 
            4'd11:  row_data = 16'b1111111111111111;
            4'd12:  row_data = 16'b1111111111111111;
            4'd13:  row_data = 16'b1111111111111111;
            default: row_data = 16'b0;
        endcase
    end
    // output
    assign is_gate = row_data[x_offset];

endmodule