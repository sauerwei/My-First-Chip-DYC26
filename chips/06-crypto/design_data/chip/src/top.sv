module top(
    `ifdef USE_POWER_PINS
    inout wire IOVDD,
    inout wire IOVSS,
    inout wire VDD,
    inout wire VSS,
    `endif

    inout clk_PAD,
    inout rst_n_PAD,

    inout spi_out_PAD,
    inout spi_in_PAD,
    inout spi_clk_PAD
);

logic clk;
logic rst_n;
logic spi_out;
logic spi_in;
logic spi_clk;
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
//spi_in input PAD instance
sg13g2_IOPadIn spi_in_pad (
    `ifdef USE_POWER_PINS
    .iovdd  (IOVDD),
    .iovss  (IOVSS),
    .vdd    (VDD),
    .vss    (VSS),
    `endif
    .p2c    (spi_in),
    .pad    (spi_in_PAD)
);
//spi_out output PAD instance
sg13g2_IOPadOut30mA spi_out_pad (
    `ifdef USE_POWER_PINS
    .vss    (VSS),
    .vdd    (VDD),
    .iovss  (IOVSS),
    .iovdd  (IOVDD),
    `endif
    .c2p (spi_out),
    .pad (spi_out_PAD)
);
//spi_clk input PAD instance
sg13g2_IOPadIn spi_clk_pad (
    `ifdef USE_POWER_PINS
    .iovdd  (IOVDD),
    .iovss  (IOVSS),
    .vdd    (VDD),
    .vss    (VSS),
    `endif
    .p2c    (spi_clk),
    .pad    (spi_clk_PAD)
);
chip u_chip (
    .clk(clk),
    .rst_n(rst_n),
    .spi_in(spi_in),
    .spi_out(spi_out),
    .spi_clk(spi_clk)
);

endmodule
