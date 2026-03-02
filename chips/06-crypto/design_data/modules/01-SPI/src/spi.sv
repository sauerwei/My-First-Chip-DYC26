module spi(
    input logic clk,
    input logic rst_n,

    input logic spi_clk,
    input logic spi_in,
    output logic spi_out,

    input logic hash_ready,
    input logic [255:0] hash_in,

    output logic [511:0] data_out,

    input logic msg_lock,
    output logic [9:0]msg_bits,
    output logic msg_set_p,
    output logic msg_up_p
);

    logic spi_clk_d;

    typedef enum {IDLE, ADDR_READ, LEN_READ, PAD_IGNORE, LOCK_CHECK, SEND_ERR, SEND_HASH_OK, SEND_HASH, CACHE_PAYLOAD, SAVE_DATA, SEND_OK, IGNORE_PAYLOAD} state_t;
    state_t state, next_state;

    logic [1:0] addr_bits;
    logic [9:0] len_bits;
    logic [9:0] count_len_bits;
    logic [2:0] count_padding_ignore;
    logic [9:0] count_payload_ignore;
    logic [9:0] count_data_send;

    logic [1:0] next_addr_bits;
    logic [9:0] next_len_bits;
    logic [9:0] next_count_len_bits;
    logic [2:0] next_count_padding_ignore;
    logic [9:0] next_count_payload_ignore;
    logic [9:0] next_count_data_send;


    logic [511:0] msg_cache;
    logic [511:0] next_msg_cache;
    logic [9:0]   count_cached;
    logic [9:0]   next_count_cached;

    logic [1:0] pulse_set_for_empty_payload;

    logic spi_clk_edge;

    assign spi_clk_edge = (spi_clk_d == 0) & (spi_clk == 1);

    always_comb begin : spi_logic
        next_state = state;

        next_addr_bits = addr_bits;
        next_len_bits  = len_bits;
        next_count_len_bits = count_len_bits;
        next_count_padding_ignore = count_padding_ignore;
        next_count_payload_ignore = count_payload_ignore;
        next_count_data_send = count_data_send;

        next_count_cached = count_cached;
        next_msg_cache = msg_cache;


        spi_out = 0;

        case(state)
            IDLE: begin
                if (spi_clk_edge) begin
                    next_addr_bits = 0;
                    next_len_bits  = 0;
                    next_count_len_bits = 0;
                    next_count_padding_ignore = 0;
                    next_count_payload_ignore = 0;
                    next_count_data_send = 0;

                    next_addr_bits[1] = spi_in;
                    next_state = ADDR_READ;
                end
            end
            ADDR_READ: begin
                if (spi_clk_edge) begin
                    next_addr_bits[0] = spi_in;
                    next_state = LEN_READ;
                end
            end
            LEN_READ: begin
                if (spi_clk_edge) begin
                    next_len_bits[9 - count_len_bits] = spi_in;
                    next_count_len_bits = count_len_bits + 1;

                    if (count_len_bits == 9) begin
                        next_state = PAD_IGNORE;
                    end
                end
            end
            PAD_IGNORE: begin
                if (spi_clk_edge) begin
                    next_count_padding_ignore = count_padding_ignore + 1;

                    if (count_padding_ignore == 3) begin
                        next_state = LOCK_CHECK;
                    end
                end
            end
            LOCK_CHECK: begin
                if (next_addr_bits == 0) begin // MSG type
                    if (msg_lock == 1) begin
                        if (next_len_bits == 0) begin
                            next_state = SEND_ERR;
                        end else begin
                            next_state = IGNORE_PAYLOAD;
                        end
                    end else begin
                        if (next_len_bits == 0) begin
                            next_state = SEND_OK;
                        end else begin
                            next_state = CACHE_PAYLOAD;
                        end
                    end
                end
                if (next_addr_bits == 2) begin // HASH type
                    if (hash_ready == 1) begin
                        next_state = SEND_HASH_OK;
                    end else begin
                        next_state = SEND_ERR;
                    end
                end
            end
            IGNORE_PAYLOAD: begin
                if (spi_clk_edge) begin
                    next_count_payload_ignore = count_payload_ignore + 1;

                    if (count_payload_ignore == (next_len_bits - 1)) begin
                        next_state = SEND_ERR;
                    end
                end
            end
            SEND_ERR: begin
                if (spi_clk_edge) begin
                    spi_out = 1;

                    next_count_data_send = count_data_send + 1;

                    if (count_data_send == 7) begin
                        next_count_data_send = 0;
                        next_state = IDLE;
                    end
                end
            end
            SEND_HASH_OK: begin
                if (spi_clk_edge) begin
                    spi_out = ~count_data_send[0];  // 1,0,1,0,1,0,1,0  (0xAA MSB-first)

                    next_count_data_send = count_data_send + 1;

                    if (count_data_send == 7) begin
                        next_count_data_send = 0;
                        next_state = SEND_HASH;
                    end
                end
            end
            SEND_HASH: begin
                if (spi_clk_edge) begin
                    spi_out = hash_in[255 - count_data_send];

                    next_count_data_send = count_data_send + 1;

                    if (count_data_send == 255) begin
                        next_count_data_send = 0;
                        next_state = IDLE;
                    end
                end
            end
            CACHE_PAYLOAD: begin
                if (spi_clk_edge) begin
                    logic [8:0] idx;
                    /* verilator lint_off WIDTHTRUNC */
                    idx = (next_len_bits - 1) - count_cached;
                    /* verilator lint_on WIDTHTRUNC */

                    // MSG type
                    if (next_addr_bits == 0) begin
                        next_msg_cache[idx] = spi_in;
                    end


                    next_count_cached = count_cached + 1;

                    if (count_cached == (next_len_bits - 1)) begin
                        next_count_cached = 0;
                        next_state = SAVE_DATA;
                    end
                end
            end
            SAVE_DATA: begin
                next_state = SEND_OK;
            end
            SEND_OK: begin
                if (spi_clk_edge) begin
                    spi_out = ~count_data_send[0];  // 1,0,1,0,1,0,1,0  (0xAA MSB-first)

                    next_count_data_send = count_data_send + 1;

                    if (count_data_send == 7) begin
                        next_count_data_send = 0;
                        next_state = IDLE;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            spi_clk_d <= 0;
            addr_bits <= 0;
            len_bits <= 0;
            count_len_bits <= 0;
            count_padding_ignore <= 0;
            count_payload_ignore <= 0;
            count_data_send <= 0;

            pulse_set_for_empty_payload <= 0;

            msg_cache <= 0;
            count_cached <= 0;

            msg_bits <= 0;
            data_out <= 0;

            msg_set_p <= 1; // reset register msg

        end else begin
            state <= next_state;
            addr_bits <= next_addr_bits;
            len_bits <= next_len_bits;
            count_len_bits <= next_count_len_bits;
            count_padding_ignore <= next_count_padding_ignore;
            count_payload_ignore <= next_count_payload_ignore;
            count_data_send <= next_count_data_send;

            msg_cache <= next_msg_cache;
            count_cached <= next_count_cached;

            msg_set_p <= 0;
            msg_bits <= next_len_bits;
            msg_up_p <= 0;


            if (next_state == SAVE_DATA || (next_addr_bits == 0 && next_len_bits == 0 && next_state == SEND_OK && pulse_set_for_empty_payload == 0) ) begin
                pulse_set_for_empty_payload <= 1;

                if (next_addr_bits == 0) begin
                    data_out <= next_msg_cache;
                    msg_set_p <= 1;
                    msg_up_p <= 1;
                end
            end else if (next_state == IDLE) begin
                pulse_set_for_empty_payload <= 0;
            end

            spi_clk_d <= spi_clk;
        end
    end

endmodule
