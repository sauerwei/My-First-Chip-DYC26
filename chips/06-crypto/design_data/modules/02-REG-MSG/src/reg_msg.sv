module reg_msg(
    input logic [511:0] data_in,
    input logic [9:0] bits_in,
    input logic set_p,
    output logic [511:0] data_out,
    output logic [9:0] bits_out
);

always_ff @(posedge set_p) begin
    data_out <= data_in;
    bits_out <= bits_in;
end

endmodule
