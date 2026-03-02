module hasher(
    input logic clk,
    input logic rst_n,

    input logic [511:0] message,
    input logic [9:0] bits_read,
    input logic chunk_ready_p,

    output logic msg_lock,
    output logic hash_ready,
    output logic [255:0] hash
);

logic [511:0] message_1;
logic [511:0] message_2;
logic has_overflow;
logic msg_ready_p;
logic new_msg;
logic rst_p;

logic [511:0] padded_message;
logic msg_ready_out_p;
logic next_p;

logic msg_lock_1;
logic msg_lock_2;

always_comb begin
    msg_lock = msg_lock_1 | msg_lock_2;
end

pad_message u_pad_message (
    .clk(clk),
    .rst_n(rst_n),
    .chunk_ready_p(chunk_ready_p),
    .message(message),
    .bits_read(bits_read),
    .msg_lock(msg_lock_1),
    .message_1(message_1),
    .message_2(message_2),
    .has_overflow(has_overflow),
    .msg_ready_p(msg_ready_p),
    .new_msg(new_msg),
    .rst_p(rst_p)
);

multiplexer u_multiplexer (
    .clk(clk),
    .rst_n(rst_n),
    .message_1(message_1),
    .message_2(message_2),
    .has_message_2(has_overflow),
    .msg_ready_p(msg_ready_p),
    .last_msg(new_msg),
    .message(padded_message),
    .msg_ready_out_p(msg_ready_out_p),
    .next_p(next_p),
    .done(hash_ready),
    .msg_lock(msg_lock_2)
);

sha256 u_sha256 (
    .clk(clk),
    .rst_n(rst_n),
    .msg_ready_p(msg_ready_out_p),
    .message(padded_message),
    .finished_chunk_p(next_p),
    .hash(hash),
    .rst_p(rst_p)
);

endmodule
