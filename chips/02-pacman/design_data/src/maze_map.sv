// 28 x 31 Tiles (16x16 Pixel) = 448 x 496 Pixel

module maze_map(
    input  logic [4:0] x_tile, // tile-coordinates
    input  logic [4:0] y_tile, // tile-coordinates
    output logic [5:0] tile_type  
);
    // Logik
    
    // Definition der Tile-Typen
    localparam DHT = 6'd0; // double wall horizontal top
    localparam DHB = 6'd1; // double wall horizontal bottom
    localparam DVL = 6'd2; // double wall vertical left
    localparam DVR = 6'd3; // double wall vertical right
    localparam DLG = 6'd4; // double wall left of gate
    localparam DRG = 6'd5; // double wall right of gate
    localparam DSA = 6'd6; // double wall square corner NO
    localparam DSB = 6'd9; // double wall square corner SO
    localparam DSC = 6'd10; // double wall square corner NW
    localparam DSD = 6'd11; // double wall square corner SW
    localparam DTA = 6'd12; // double wall round corner top NO
    localparam DTB = 6'd13; // double wall round corner top SO
    localparam DTC = 6'd14; // double wall round corner top NW
    localparam DTD = 6'd15; // double wall round corner top SW
    localparam DBA = 6'd16; // double wall round corner bottom NO
    localparam DBB = 6'd17; // double wall round corner bottom SO
    localparam DBC = 6'd18; // double wall round corner bottom NW
    localparam DBD = 6'd19; // double wall round corner bottom SW
    localparam SWT = 6'd20; // single wall top
    localparam SWB = 6'd21; // single wall bottom
    localparam SWL = 6'd22; // single wall left
    localparam SWR = 6'd23; // single wall right
    localparam STA = 6'd24; // single wall corner top NO
    localparam STB = 6'd25; // single wall corner top SO
    localparam STC = 6'd26; // single wall corner top NW
    localparam STD = 6'd27; // single wall corner top SW
    localparam SBA = 6'd28; // single wall corner bottom NO
    localparam SBB = 6'd29; // single wall corner bottom SO
    localparam SBC = 6'd30; // single wall corner bottom NW
    localparam SBD = 6'd31; // single wall corner bottom SW
    localparam TWA = 6'd32; // T-Wall top left
    localparam TWB = 6'd33; // T-Wall top right
    localparam TWC = 6'd34; // T-Wall right top
    localparam TWD = 6'd35; // T-Wall left top
    localparam TWE = 6'd36; // T-Wall left bottom
    localparam TWF = 6'd37; // T-Wall right bottom

    localparam WWW = 6'd40; // invisible Wall 
    localparam GAT = 6'd41; // G = Gate
    localparam EMP = 6'd42; // E = Empty 
    localparam DOT = 6'd43; // D = Dot 
    localparam PIL = 6'd44; // P = Power Pill
    localparam FRU = 6'd45; // F = Fruit 

    // 2D Array ROM for fastest access
    logic [31:0][27:0][5:0] maze_rom;

    initial begin
        // Row 0
        maze_rom[0] = {DBC,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,TWA,TWB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DHB,DBA};
        // Row 1
        maze_rom[1] = {DVR,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,SWL,SWR,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DVL};
        // Row 2
        maze_rom[2] = {DVR,DOT,STC,SWT,SWT,STA,DOT,STC,SWT,SWT,SWT,STA,DOT,SWL,SWR,DOT,STC,SWT,SWT,SWT,STA,DOT,STC,SWT,SWT,STA,DOT,DVL};
        // Row 3
        maze_rom[3] = {DVR,PIL,SWL,WWW,WWW,SWR,DOT,SWL,WWW,WWW,WWW,SWR,DOT,SWL,SWR,DOT,SWL,WWW,WWW,WWW,SWR,DOT,SWL,WWW,WWW,SWR,PIL,DVL};
        // Row 4
        maze_rom[4] = {DVR,DOT,SBD,SWB,SWB,SBB,DOT,SBD,SWB,SWB,SWB,SBB,DOT,SBD,SBB,DOT,SBD,SWB,SWB,SWB,SBB,DOT,SBD,SWB,SWB,SBB,DOT,DVL};
        // Row 5
        maze_rom[5] = {DVR,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DVL};
        // Row 6
        maze_rom[6] = {DVR,DOT,STC,SWT,SWT,STA,DOT,STC,STA,DOT,STC,SWT,SWT,SWT,SWT,SWT,SWT,STA,DOT,STC,STA,DOT,STC,SWT,SWT,STA,DOT,DVL};
        // Row 7
        maze_rom[7] = {DVR,DOT,SBD,SWB,SWB,SBB,DOT,SWL,SWR,DOT,SBD,SWB,SWB,SBA,SBC,SWB,SWB,SBB,DOT,SWL,SWR,DOT,SBD,SWB,SWB,SBB,DOT,DVL};
        // Row 8
        maze_rom[8] = {DVR,DOT,DOT,DOT,DOT,DOT,DOT,SWL,SWR,DOT,DOT,DOT,DOT,SWL,SWR,DOT,DOT,DOT,DOT,SWL,SWR,DOT,DOT,DOT,DOT,DOT,DOT,DVL};
        // Row 9
        maze_rom[9] = {DTD,DHT,DHT,DHT,DHT,DTA,DOT,SWL,STD,SWT,SWT,STA,EMP,SWL,SWR,EMP,STC,SWT,SWT,STB,SWR,DOT,DTC,DHT,DHT,DHT,DHT,DTB};
        // Row 10
        maze_rom[10] = {WWW,WWW,WWW,WWW,WWW,DVR,DOT,SWL,SBC,SWB,SWB,SBB,EMP,SBD,SBB,EMP,SBD,SWB,SWB,SBA,SWR,DOT,DVL,WWW,WWW,WWW,WWW,WWW};
        // Row 11
        maze_rom[11] = {WWW,WWW,WWW,WWW,WWW,DVR,DOT,SWL,SWR,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,SWL,SWR,DOT,DVL,WWW,WWW,WWW,WWW,WWW};
        // Row 12
        maze_rom[12] = {WWW,WWW,WWW,WWW,WWW,DVR,DOT,SWL,SWR,EMP,DSC,DHT,DLG,GAT,GAT,DRG,DHT,DSA,EMP,SWL,SWR,DOT,DVL,WWW,WWW,WWW,WWW,WWW};
        // Row 13
        maze_rom[13] = {DHB,DHB,DHB,DHB,DHB,DBB,DOT,SBD,SBB,EMP,DVL,EMP,EMP,EMP,EMP,EMP,EMP,DVR,EMP,SBD,SBB,DOT,DBD,DHB,DHB,DHB,DHB,DHB};
        // Row 14 - TUNNEL
        maze_rom[14] = {EMP,EMP,EMP,EMP,EMP,EMP,DOT,EMP,EMP,EMP,DVL,EMP,EMP,EMP,EMP,EMP,EMP,DVR,EMP,EMP,EMP,DOT,EMP,EMP,EMP,EMP,EMP,EMP};
        // Row 15
        maze_rom[15] = {DHT,DHT,DHT,DHT,DHT,DTA,DOT,STC,STA,EMP,DVL,EMP,EMP,EMP,EMP,EMP,EMP,DVR,EMP,STC,STA,DOT,DTC,DHT,DHT,DHT,DHT,DHT};
        // Row 16
        maze_rom[16] = {WWW,WWW,WWW,WWW,WWW,DVR,DOT,SWL,SWR,EMP,DSD,DHB,DHB,DHB,DHB,DHB,DHB,DSB,EMP,SWL,SWR,DOT,DVL,WWW,WWW,WWW,WWW,WWW};
        // Row 17 - fruits at [17,13] and [17,14]
        maze_rom[17] = {WWW,WWW,WWW,WWW,WWW,DVR,DOT,SWL,SWR,EMP,EMP,EMP,EMP,FRU,FRU,EMP,EMP,EMP,EMP,SWL,SWR,DOT,DVL,WWW,WWW,WWW,WWW,WWW};
        // Row 18
        maze_rom[18] = {WWW,WWW,WWW,WWW,WWW,DVR,DOT,SWL,SWR,EMP,STC,SWT,SWT,SWT,SWT,SWT,SWT,STA,EMP,SWL,SWR,DOT,DVL,WWW,WWW,WWW,WWW,WWW};
        // Row 19
        maze_rom[19] = {DBC,DHB,DHB,DHB,DHB,DBB,DOT,SBD,SBB,EMP,SBD,SWB,SWB,SBA,SBC,SWB,SWB,SBB,EMP,SBD,SBB,DOT,DBD,DHB,DHB,DHB,DHB,DBA};
        // Row 20
        maze_rom[20] = {DVR,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,SWL,SWR,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DVL};
        // Row 21
        maze_rom[21] = {DVR,DOT,STC,SWT,SWT,STA,DOT,STC,SWT,SWT,SWT,STA,DOT,SWL,SWR,DOT,STC,SWT,SWT,SWT,STA,DOT,STC,SWT,SWT,STA,DOT,DVL};
        // Row 22
        maze_rom[22] = {DVR,DOT,SBD,SWB,SBA,SWR,DOT,SBD,SWB,SWB,SWB,SBB,DOT,SBD,SBB,DOT,SBD,SWB,SWB,SWB,SBB,DOT,SWL,SBC,SWB,SBB,DOT,DVL};
        // Row 23 - Pacman start position between [23,13] and [23,14]
        maze_rom[23] = {DVR,PIL,DOT,DOT,SWL,SWR,DOT,DOT,DOT,DOT,DOT,DOT,DOT,EMP,EMP,DOT,DOT,DOT,DOT,DOT,DOT,DOT,SWL,SWR,DOT,DOT,PIL,DVL};
        // Row 24
        maze_rom[24] = {TWD,SWT,STA,DOT,SWL,SWR,DOT,STC,STA,DOT,STC,SWT,SWT,SWT,SWT,SWT,SWT,STA,DOT,STC,STA,DOT,SWL,SWR,DOT,STC,SWT,TWC};
        // Row 25
        maze_rom[25] = {TWE,SWB,SBB,DOT,SBD,SBB,DOT,SWL,SWR,DOT,SBD,SWB,SWB,SBA,SBC,SWB,SWB,SBB,DOT,SWL,SWR,DOT,SBD,SBB,DOT,SBD,SWB,TWF};
        // Row 26
        maze_rom[26] = {DVR,DOT,DOT,DOT,DOT,DOT,DOT,SWL,SWR,DOT,DOT,DOT,DOT,SWL,SWR,DOT,DOT,DOT,DOT,SWL,SWR,DOT,DOT,DOT,DOT,DOT,DOT,DVL};
        // Row 27
        maze_rom[27] = {DVR,DOT,STC,SWT,SWT,SWT,SWT,STB,STD,SWT,SWT,STA,DOT,SWL,SWR,DOT,STC,SWT,SWT,STB,STD,SWT,SWT,SWT,SWT,STA,DOT,DVL};
        // Row 28
        maze_rom[28] = {DVR,DOT,SBD,SWB,SWB,SWB,SWB,SWB,SWB,SWB,SWB,SBB,DOT,SBD,SBB,DOT,SBD,SWB,SWB,SWB,SWB,SWB,SWB,SWB,SWB,SBB,DOT,DVL};
        // Row 29
        maze_rom[29] = {DVR,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DOT,DVL};
        // Row 30
        maze_rom[30] = {DTD,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DHT,DTB};
        // Row 31 (unused/padding)
        maze_rom[31] = {EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP,EMP};
    end

    // output - direct ROM access (fast)
    assign tile_type = (y_tile < 31) ? maze_rom[y_tile][x_tile] : EMP;

    endmodule