module top(
    `ifdef USE_POWER_PINS
    inout wire IOVDD,
    inout wire IOVSS,
    inout wire VDD,
    inout wire VSS,
    `endif

    inout clk_PAD,
    inout rst_n_PAD,
    inout button_up_PAD,
    inout button_down_PAD,
    inout button_left_PAD,
    inout button_right_PAD,

    output [7:0] uo_out_PADs
);

logic clk;
logic rst_n;
logic button_up;
logic button_down;
logic button_left;
logic button_right;
logic [7:0] uo_out;
// Power/ground pad instances
generate
for (genvar i=0; i<1; i++) begin : iovdd_pads
    (* keep *)
    sg13g2_IOPadIOVdd iovdd_pad  (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS)
        `endif
    );
end
for (genvar i=0; i<1; i++) begin : iovss_pads
    (* keep *)
    sg13g2_IOPadIOVss iovss_pad  (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS)
        `endif
    );
end
for (genvar i=0; i<1; i++) begin : vdd_pads
    (* keep *)
    sg13g2_IOPadVdd vdd_pad  (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS)
        `endif
    );
end
for (genvar i=0; i<1; i++) begin : vss_pads
    (* keep *)
    sg13g2_IOPadVss vss_pad  (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS)
        `endif
    );
end
endgenerate
// clk PAD instance
sg13g2_IOPadIn clk_pad (
    `ifdef USE_POWER_PINS
    .iovdd  (IOVDD),
    .iovss  (IOVSS),
    .vdd    (VDD),
    .vss    (VSS),
    `endif
    .p2c    (clk),
    .pad    (clk_PAD)
);
//reset PAD instance
sg13g2_IOPadIn rst_n_pad (
    `ifdef USE_POWER_PINS
    .iovdd  (IOVDD),
    .iovss  (IOVSS),
    .vdd    (VDD),
    .vss    (VSS),
    `endif
    .p2c    (rst_n),
    .pad    (rst_n_PAD)
);
//Button up PAD instance
sg13g2_IOPadIn button_up_pad (
    `ifdef USE_POWER_PINS
    .iovdd  (IOVDD),
    .iovss  (IOVSS),
    .vdd    (VDD),
    .vss    (VSS),
    `endif
    .p2c    (button_up),
    .pad    (button_up_PAD)
);
//Button down PAD instance
sg13g2_IOPadIn button_down_pad (
    `ifdef USE_POWER_PINS
    .iovdd  (IOVDD),
    .iovss  (IOVSS),
    .vdd    (VDD),
    .vss    (VSS),
    `endif
    .p2c (button_down),
    .pad (button_down_PAD)
);
//Button left PAD instance
sg13g2_IOPadIn button_left_pad (
    `ifdef USE_POWER_PINS
    .iovdd  (IOVDD),
    .iovss  (IOVSS),
    .vdd    (VDD),
    .vss    (VSS),
    `endif
    .p2c    (button_left),
    .pad    (button_left_PAD)
);
//Button right PAD instance
sg13g2_IOPadIn button_right_pad (
    `ifdef USE_POWER_PINS
    .iovdd  (IOVDD),
    .iovss  (IOVSS),
    .vdd    (VDD),
    .vss    (VSS),
    `endif
    .p2c    (button_right),
    .pad    (button_right_PAD)
);

// Output PAD instances
generate
for (genvar i=0; i<8; i++) begin : uo_out_pads
    sg13g2_IOPadOut30mA uo_out_pad (
        `ifdef USE_POWER_PINS
        .vss    (VSS),
        .vdd    (VDD),
        .iovss  (IOVSS),
        .iovdd  (IOVDD),
        `endif
        .c2p (uo_out[i]),
        .pad (uo_out_PADs[i])
    );
end
endgenerate

project_final u_project (
    .clk(clk),
    .rst_n(rst_n),
    .btn_up(button_up),
    .btn_down(button_down),
    .btn_left(button_left),
    .btn_right(button_right),

    .uo_out(uo_out)
);

endmodule