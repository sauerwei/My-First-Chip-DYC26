module pad_message(
    input logic clk,
    input logic rst_n,

    input logic chunk_ready_p,
    input logic [511:0] message,
    input logic [9:0] bits_read,

    output logic msg_lock,
    output logic [511:0] message_1,
    output logic [511:0] message_2,
    output logic has_overflow,
    output logic msg_ready_p,
    output logic new_msg,

    output logic rst_p
);

logic [63:0] length;

always_comb begin : mappings
    message_1 = 0;
    for (integer i = 0; i < 16; i = i +1) begin
        for (integer j = 0; j < 4; j = j + 1) begin
            for (integer z = 0; z < 8; z = z + 1) begin
                if (i*32+8*j+z < bits_read) begin
                    message_1[i*32+8*(3-j)+z] = message[i*32+8*j+z];
                end
            end
        end
    end
    message_2 = 'x;
    has_overflow = 0;
    if (bits_read != 512) begin
        message_1[bits_read[8:5] * 32 + (31 - bits_read[4:0])] = 1;
        if (512 - bits_read >= 64) begin
            message_1[511:480] = length[31:0];
            message_1[479:448] = length[63:32];
        end else begin // not enough place for length in padding
            message_2 = 0;
            message_2[511:480] = length[31:0];
            message_2[479:448] = length[63:32];
            has_overflow = 1;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    // for some reason the rst_p reset needs to be in every main branch
    if (!rst_n) begin
        length <= 0;
        new_msg <= 1;
        msg_lock <= 0;
        rst_p <= 0;
    end else if (chunk_ready_p) begin
        if (new_msg) begin
            rst_p <= 1;
            /* verilator lint_off WIDTHEXPAND */
            length <= bits_read;
            /* verilator lint_on WIDTHEXPAND */
            if (bits_read == 512) begin
                new_msg <= 0;
            end
        end else begin
            /* verilator lint_off WIDTHEXPAND */
            length <= length + bits_read;
            /* verilator lint_on WIDTHEXPAND */
            if (bits_read != 512) begin
                new_msg <= 1;
            end
        end
        msg_lock <= 1;
        msg_ready_p <= 1;
        if (rst_p) rst_p <= 0;
    end else if (msg_ready_p) begin
        msg_ready_p <= 0;
        msg_lock <= 0;
        if (rst_p) rst_p <= 0;
    end else begin
        if (rst_p) rst_p <= 0;
    end
end

endmodule
