module fruit_bitmap(
    input  logic [4:0] y_offset,    // row in map (0-23)
    input  logic [4:0] x_offset,    // pixel in row (0-23)
    input  logic [2:0] item_id,
    output logic [2:0] pixel_color
);

    logic [35:0] row_data;
    logic [3:0]  x_new;
    logic [3:0]  y_new;
    logic [35:0] fruit_rom [0:7][0:11];

    // FARBPALETTE:
    // 0=Transparent, 1=Rot, 2=Grün, 3=Weiß, 4=Orange, 5=Gelb, 6=Braun, 7=Hellblau

    initial begin
        integer i;
        integer j;
        for (i = 0; i < 8; i = i + 1)
            for (j = 0; j < 12; j = j + 1)
                fruit_rom[i][j] = 36'o0;

        // 3'd0: KIRSCHE
        fruit_rom[0][0]  = 36'o000000000066;
        fruit_rom[0][1]  = 36'o000000006666;
        fruit_rom[0][2]  = 36'o000000660600;
        fruit_rom[0][3]  = 36'o000006000600;
        fruit_rom[0][4]  = 36'o011160006000;
        fruit_rom[0][5]  = 36'o111611060000;
        fruit_rom[0][6]  = 36'o111110161100;
        fruit_rom[0][7]  = 36'o131101161110;
        fruit_rom[0][8]  = 36'o113101111110;
        fruit_rom[0][9]  = 36'o011101311110;
        fruit_rom[0][10] = 36'o000001131110;
        fruit_rom[0][11] = 36'o000000111100;

        // 3'd1: ERDBEERE
        fruit_rom[1][0]  = 36'o000003000000;
        fruit_rom[1][1]  = 36'o002223222000;
        fruit_rom[1][2]  = 36'o011222221100;
        fruit_rom[1][3]  = 36'o111112111310;
        fruit_rom[1][4]  = 36'o131111131110;
        fruit_rom[1][5]  = 36'o111313111110;
        fruit_rom[1][6]  = 36'o111111113110;
        fruit_rom[1][7]  = 36'o013113111100;
        fruit_rom[1][8]  = 36'o011111111100;
        fruit_rom[1][9]  = 36'o001131130000;
        fruit_rom[1][10] = 36'o000111110000;
        fruit_rom[1][11] = 36'o000001000000;

        // 3'd2: ORANGE
        fruit_rom[2][0]  = 36'o000000022000;
        fruit_rom[2][1]  = 36'o000006222220;
        fruit_rom[2][2]  = 36'o000006022200;
        fruit_rom[2][3]  = 36'o004466644400;
        fruit_rom[2][4]  = 36'o044446444440;
        fruit_rom[2][5]  = 36'o444444444444;
        fruit_rom[2][6]  = 36'o444444444444;
        fruit_rom[2][7]  = 36'o444444444444;
        fruit_rom[2][8]  = 36'o444444444444;
        fruit_rom[2][9]  = 36'o044444444440;
        fruit_rom[2][10] = 36'o044444444440;
        fruit_rom[2][11] = 36'o000444444000;

        // 3'd3: APFEL
        fruit_rom[3][0]  = 36'o000000600000;
        fruit_rom[3][1]  = 36'o011106011100;
        fruit_rom[3][2]  = 36'o111116111110;
        fruit_rom[3][3]  = 36'o111111111111;
        fruit_rom[3][4]  = 36'o111111111111;
        fruit_rom[3][5]  = 36'o111111111111;
        fruit_rom[3][6]  = 36'o111111111311;
        fruit_rom[3][7]  = 36'o111111111311;
        fruit_rom[3][8]  = 36'o011111113110;
        fruit_rom[3][9]  = 36'o011111111110;
        fruit_rom[3][10] = 36'o001111111100;
        fruit_rom[3][11] = 36'o000110111000;

        // 3'd4: MELONE
        fruit_rom[4][0]  = 36'o000777770000;
        fruit_rom[4][1]  = 36'o000007000000;
        fruit_rom[4][2]  = 36'o000223220000;
        fruit_rom[4][3]  = 36'o022227222200;
        fruit_rom[4][4]  = 36'o027372227200;
        fruit_rom[4][5]  = 36'o222722372220;
        fruit_rom[4][6]  = 36'o237222727220;
        fruit_rom[4][7]  = 36'o272237223720;
        fruit_rom[4][8]  = 36'o037222722200;
        fruit_rom[4][9]  = 36'o022737372200;
        fruit_rom[4][10] = 36'o002272227000;
        fruit_rom[4][11] = 36'o000022200000;

        // 3'd5: GALAXIAN BOSS
        fruit_rom[5][0]  = 36'o000001000000;
        fruit_rom[5][1]  = 36'o700011100070;
        fruit_rom[5][2]  = 36'o700111110070;
        fruit_rom[5][3]  = 36'o751151511570;
        fruit_rom[5][4]  = 36'o755551555570;
        fruit_rom[5][5]  = 36'o775555555770;
        fruit_rom[5][6]  = 36'o077505057700;
        fruit_rom[5][7]  = 36'o007705077000;
        fruit_rom[5][8]  = 36'o000705070000;
        fruit_rom[5][9]  = 36'o000005000000;
        fruit_rom[5][10] = 36'o000005000000;
        fruit_rom[5][11] = 36'o000005000000;

        // 3'd6: GLOCKE
        fruit_rom[6][0]  = 36'o000005500000;
        fruit_rom[6][1]  = 36'o000550055000;
        fruit_rom[6][2]  = 36'o005555555500;
        fruit_rom[6][3]  = 36'o005505555500;
        fruit_rom[6][4]  = 36'o005055555500;
        fruit_rom[6][5]  = 36'o055055555550;
        fruit_rom[6][6]  = 36'o055555555550;
        fruit_rom[6][7]  = 36'o550555555555;
        fruit_rom[6][8]  = 36'o550555555555;
        fruit_rom[6][9]  = 36'o555555555555;
        fruit_rom[6][10] = 36'o577777337775;
        fruit_rom[6][11] = 36'o077777337770;

        // 3'd7: SCHLÜSSEL
        fruit_rom[7][0]  = 36'o000077700000;
        fruit_rom[7][1]  = 36'o007700077000;
        fruit_rom[7][2]  = 36'o007777777000;
        fruit_rom[7][3]  = 36'o007777777000;
        fruit_rom[7][4]  = 36'o000030300000;
        fruit_rom[7][5]  = 36'o000030330000;
        fruit_rom[7][6]  = 36'o000030300000;
        fruit_rom[7][7]  = 36'o000030000000;
        fruit_rom[7][8]  = 36'o000030300000;
        fruit_rom[7][9]  = 36'o000030330000;
        fruit_rom[7][10] = 36'o000030300000;
        fruit_rom[7][11] = 36'o000003000000;
    end

    always_comb begin
        x_new = x_offset[4:1];
        y_new = y_offset[4:1];
        row_data = (y_new < 4'd12) ? fruit_rom[item_id][y_new] : 36'o0;
    end

    // 12x12 Basis-Pixel auslesen (links->rechts)
    always_comb begin
        if (x_new < 4'd12 && y_new < 4'd12)
            pixel_color = row_data[((4'd11 - x_new) * 3) +: 3];
        else
            pixel_color = 3'd0;
    end

endmodule



// Welche Frucht gibt wie viele Punkte?
// Der Wert der Früchte steigt mit den höheren Leveln rapide an:
// Level	Bonus-Item	    Punkte
// 1	    Kirsche (Cherry)	100
// 2	    Erdbeere (Strawberry)	300
// 3 & 4	Orange/Pfirsich (Orange)	500
// 5 & 6	Apfel (Apple)	700
// 7 & 8	Ananas/Melone (Pineapple)	1.000
// 9 & 10	Galaxian-Raumschiff	2.000
// 11 & 12	Glocke (Bell)	3.000
// Ab 13	Schlüssel (Key)	5.000