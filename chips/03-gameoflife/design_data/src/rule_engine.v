module rule_engine(
    input  wire       center,
    input  wire [3:0] count, // wv nachbarn hat center (0-8)
    output reg        next_cell
);

    always @(*) begin 
        next_cell = (center && (count == 2 || count == 3)) || (!center && count == 3);
    end

endmodule