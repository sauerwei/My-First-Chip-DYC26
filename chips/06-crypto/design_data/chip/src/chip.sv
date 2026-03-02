module chip(
    input logic clk,
    input logic rst_n,

    input logic spi_in,
    output logic spi_out,
    input logic spi_clk
);

logic [255:0] hash;

logic [511:0] reg_msg_data_in;
logic [9:0] reg_msg_bits_in;
logic reg_msg_set_p;
logic [511:0] reg_msg_data_out;
logic [9:0] reg_msg_bits_out;

logic hash_ready;
logic msg_lock;
logic msg_up_p;

reg_msg u_reg_msg(
    .data_in(reg_msg_data_in),
    .bits_in(reg_msg_bits_in),
    .set_p(reg_msg_set_p),
    .data_out(reg_msg_data_out),
    .bits_out(reg_msg_bits_out)
);

spi u_spi (
    .clk(clk),
    .rst_n(rst_n),
    .spi_clk(spi_clk),
    .spi_in(spi_in),
    .spi_out(spi_out),
    .hash_ready(hash_ready),
    .hash_in(hash),
    .data_out(reg_msg_data_in),
    .msg_lock(msg_lock),
    .msg_bits(reg_msg_bits_in),
    .msg_set_p(reg_msg_set_p),
    .msg_up_p(msg_up_p)
);

hasher u_hasher (
    .clk(clk),
    .rst_n(rst_n),
    .message(reg_msg_data_out),
    .bits_read(reg_msg_bits_out),
    .chunk_ready_p(msg_up_p),
    .msg_lock(msg_lock),
    .hash_ready(hash_ready),
    .hash(hash)
);

endmodule
