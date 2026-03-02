module sha256(
    input logic clk,
    input logic rst_n,

    input logic msg_ready_p,
    input logic [511:0] message,
    output logic finished_chunk_p,

    output logic [255:0] hash,

    input logic rst_p
);

localparam logic [2047:0] K = 2048'hc67178f2bef9a3f7a4506ceb90befffa8cc7020884c8781478a5636f748f82ee682e6ff35b9cca4f4ed8aa4a391c0cb334b0bcb52748774c1e376c0819a4c116106aa070f40e3585d6990624d192e819c76c51a3c24b8b70a81a664ba2bfe8a192722c8581c2c92e766a0abb650a735453380d134d2c6dfc2e1b213827b70a851429296706ca6351d5a79147c6e00bf3bf597fc7b00327c8a831c66d983e515276f988da5cb0a9dc4a7484aa2de92c6f240ca1cc0fc19dc6efbe4786e49b69c1c19bf1749bdc06a780deb1fe72be5d74550c7dc3243185be12835b01d807aa98ab1c5ed5923f82a459f111f13956c25be9b5dba5b5c0fbcf71374491428a2f98;
localparam logic [255:0] INITh = 'h6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19;

enum {IDLE, COMPUTING, FINISH} state;
logic [5:0] loops;
logic [2047:0] w;

logic [31:0] temp1;
logic [31:0] temp2;

logic [31:0] a;
logic [31:0] b;
logic [31:0] c;
logic [31:0] d;
logic [31:0] e;
logic [31:0] f;
logic [31:0] g;
logic [31:0] h;

function automatic logic [31:0] right_rotate(input logic [31:0] operand, input logic [31:0] amount);
    right_rotate = (operand >> amount) | (operand << (32 - amount));
endfunction

always_comb begin : control_logic
    w[511:0] = message;
    for (integer i = 17; i <= 64; i = i + 1) begin
        /* verilator lint_off ALWCOMBORDER */
        w[i*32-1-:32] = w[(i-16)*32-1-:32]
            + (right_rotate(w[(i-15)*32-1-:32], 7) // right rotate 7
                ^ right_rotate(w[(i-15)*32-1-:32], 18) // right rotate 18
                ^ (w[(i-15)*32-1-:32] >> 3)) // right shift 3
            + w[(i-7)*32-1-:32]
            + (right_rotate(w[(i-2)*32-1-:32], 17) // right rotate 17
                ^ right_rotate(w[(i-2)*32-1-:32], 19) // right rotate 19
                ^ (w[(i-2)*32-1-:32] >> 10)); // right shit 10
        /* verilator lint_on ALWCOMBORDER */
    end
    temp2 = (right_rotate(a, 2)
            ^ right_rotate(a, 13)
            ^ right_rotate(a, 22))
        + ((a & b) ^ (a & c) ^ (b & c));
    temp1 = h
        + (right_rotate(e, 6)
            ^ right_rotate(e, 11)
            ^ right_rotate(e, 25))
        + ((e & f) ^ ((~e) & g))
        + K[(32*(loops+1))-1-:32]
        + w[(32*(loops+1))-1-:32];
end

always_ff @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        state <= IDLE;
        finished_chunk_p <= 0;
        loops <= 0;
        hash <= INITh;
    end else if (msg_ready_p) begin
        state <= COMPUTING;
        loops <= 0;
        finished_chunk_p <= 0;
        {a, b, c, d, e, f, g, h} <= hash;
    end else if (rst_p) begin
        state <= IDLE;
        loops <= 0;
    end else if (state == COMPUTING) begin
        h <= g;
        g <= f;
        f <= e;
        e <= d + temp1;
        d <= c;
        c <= b;
        b <= a;
        a <= temp1 + temp2;
        loops <= loops + 1;
        if (loops == 63) begin
            state <= FINISH;
        end
    end else if (state == FINISH) begin
        state <= IDLE;
        hash[31:0] <= hash[31:0] + h;
        hash[63:32] <= hash[63:32] + g;
        hash[95:64] <= hash[95:64] + f;
        hash[127:96] <= hash[127:96] + e;
        hash[159:128] <= hash[159:128] + d;
        hash[191:160] <= hash[191:160] + c;
        hash[223:192] <= hash[223:192] + b;
        hash[255:224] <= hash[255:224] + a;
        finished_chunk_p <= 1;
    end else if (finished_chunk_p) finished_chunk_p <= 0;
end

endmodule
