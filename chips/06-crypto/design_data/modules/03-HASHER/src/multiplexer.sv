module multiplexer(
    input logic clk,
    input logic rst_n,

    input logic [511:0] message_1,
    input logic [511:0] message_2,
    input logic has_message_2,
    input logic msg_ready_p,
    input logic last_msg,

    output logic [511:0] message,
    output logic msg_ready_out_p,
    input logic next_p,
    output logic done,
    output logic msg_lock
);

enum {IDLE, ONE, TWO, DONE} state, next_state;

always_comb begin : control_logic
    next_state = state;

    msg_ready_out_p = 0;
    case (state)
        IDLE,
        DONE: begin
            if (msg_ready_p) begin
                msg_ready_out_p = 1;
                next_state = ONE;
            end
        end
        ONE: begin
            if (next_p) begin
                if (has_message_2) begin
                    msg_ready_out_p = 1;
                    next_state = TWO;
                end else begin
                    next_state = DONE;
                end
            end
        end
        TWO: begin
            if (next_p) begin
                next_state = DONE;
            end
        end
    endcase

    done = 0;
    if (next_state == DONE && last_msg) begin
        done = 1;
    end

    case (next_state)
        ONE: message = message_1;
        TWO: message = message_2;
        default: message = 'x;
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        msg_lock <= 0;
    end else begin
        if ((next_state == DONE || state == DONE) && !msg_ready_out_p) begin
            msg_lock <= 0;
        end
        state <= next_state;
        if (next_state != IDLE && next_state != DONE) begin
            msg_lock <= 1;
        end
    end
end

endmodule
