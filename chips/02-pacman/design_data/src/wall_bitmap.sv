module wall_bitmap(
    input  logic [5:0] wall_type,
    input  logic [3:0] y_offset,    // row in map (0-15)
    input  logic [3:0] x_offset,    // pixel in row (0-15)
    output logic       is_wall      // 1 = on, 0 = off
);
    // logic
    // wall-Types
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

    logic [15:0] row_data; // one row (16 Bit), Little Endian --> [0] = right

    // wall-ROM
    always_comb begin
        case (wall_type)
            // double wall horizontal top
            DHT: begin 
                case (y_offset)
                    4'd8:  row_data = 16'b1111111111111111;
                    4'd9:  row_data = 16'b1111111111111111; 
                    4'd14: row_data = 16'b1111111111111111; 
                    4'd15: row_data = 16'b1111111111111111; 
                    default: row_data = 16'b0; 
                endcase
            end
            // double wall horizontal bottom
            DHB: begin 
                case (y_offset)
                    4'd0: row_data = 16'b1111111111111111;
                    4'd1: row_data = 16'b1111111111111111; 
                    4'd6: row_data = 16'b1111111111111111; 
                    4'd7: row_data = 16'b1111111111111111; 
                    default: row_data = 16'b0; 
                endcase
            end
            // double wall vertical left
            DVL: begin
                row_data = 16'b0000000011000011;
            end
            // double wall vertical right
            DVR: begin
                row_data = 16'b1100001100000000;
            end
            // double wall left of gate
            DLG: begin 
                case (y_offset)
                    4'd8:  row_data = 16'b1111111111111111;
                    4'd9:  row_data = 16'b1111111111111111; 
                    4'd10: row_data = 16'b0000000000000011; 
                    4'd11: row_data = 16'b0000000000000011;
                    4'd12: row_data = 16'b0000000000000011;
                    4'd13: row_data = 16'b0000000000000011;
                    4'd14: row_data = 16'b1111111111111111; 
                    4'd15: row_data = 16'b1111111111111111; 
                    default: row_data = 16'b0; 
                endcase
            end
            // double wall right of gate
            DRG: begin 
                case (y_offset)
                    4'd8:  row_data = 16'b1111111111111111;
                    4'd9:  row_data = 16'b1111111111111111; 
                    4'd10: row_data = 16'b1100000000000000; 
                    4'd11: row_data = 16'b1100000000000000;
                    4'd12: row_data = 16'b1100000000000000;
                    4'd13: row_data = 16'b1100000000000000;
                    4'd14: row_data = 16'b1111111111111111; 
                    4'd15: row_data = 16'b1111111111111111; 
                    default: row_data = 16'b0; 
                endcase
            end
            // double wall square corner 1- 4
            DSA: begin
                case (y_offset)
                    4'd8:  row_data = 16'b1111111100000000;
                    4'd9:  row_data = 16'b1111111100000000;
                    4'd10: row_data = 16'b0000001100000000; 
                    4'd11: row_data = 16'b0000001100000000;
                    4'd12: row_data = 16'b0000001100000000;
                    4'd13: row_data = 16'b0000001100000000;
                    4'd14: row_data = 16'b1100001100000000;
                    4'd15: row_data = 16'b1100001100000000;
                    default: row_data = 16'b0;
                endcase
            end
            DSB: begin
                case (y_offset)
                    4'd0: row_data = 16'b1100001100000000;
                    4'd1: row_data = 16'b1100001100000000;
                    4'd2: row_data = 16'b0000001100000000; 
                    4'd3: row_data = 16'b0000001100000000;
                    4'd4: row_data = 16'b0000001100000000;
                    4'd5: row_data = 16'b0000001100000000;
                    4'd6: row_data = 16'b1111111100000000;
                    4'd7: row_data = 16'b1111111100000000;
                    default: row_data = 16'b0;
                endcase
            end
            DSC: begin
                case (y_offset)
                    4'd8:  row_data = 16'b0000000011111111;
                    4'd9:  row_data = 16'b0000000011111111;
                    4'd10: row_data = 16'b0000000011000000; 
                    4'd11: row_data = 16'b0000000011000000;
                    4'd12: row_data = 16'b0000000011000000;
                    4'd13: row_data = 16'b0000000011000000;
                    4'd14: row_data = 16'b0000000011000011;
                    4'd15: row_data = 16'b0000000011000011;
                    default: row_data = 16'b0;
                endcase
            end
            DSD: begin
                case (y_offset)
                    4'd0: row_data = 16'b0000000011000011;
                    4'd1: row_data = 16'b0000000011000011;
                    4'd2: row_data = 16'b0000000011000000; 
                    4'd3: row_data = 16'b0000000011000000;
                    4'd4: row_data = 16'b0000000011000000;
                    4'd5: row_data = 16'b0000000011000000;
                    4'd6: row_data = 16'b0000000011111111;
                    4'd7: row_data = 16'b0000000011111111;
                    default: row_data = 16'b0;
                endcase
            end
            // double wall round corner top 1- 4
            DTA: begin
                case (y_offset)
                    4'd8:  row_data = 16'b1111000000000000;
                    4'd9:  row_data = 16'b1111000000000000;
                    4'd10: row_data = 16'b0000110000000000; 
                    4'd11: row_data = 16'b0000110000000000;
                    4'd12: row_data = 16'b0000001100000000;
                    4'd13: row_data = 16'b0000001100000000;
                    4'd14: row_data = 16'b0000001100000000;
                    4'd15: row_data = 16'b0000001100000000;
                    default: row_data = 16'b0;
                endcase
            end
            DTB: begin
                case (y_offset)
                    4'd8:  row_data = 16'b1111111100000011;
                    4'd9:  row_data = 16'b1111111100000011;
                    4'd10: row_data = 16'b0000000000000011; 
                    4'd11: row_data = 16'b0000000000000011;
                    4'd12: row_data = 16'b0000000000001100;
                    4'd13: row_data = 16'b0000000000001100;
                    4'd14: row_data = 16'b1111111111110000;
                    4'd15: row_data = 16'b1111111111110000;
                    default: row_data = 16'b0000000011000011;
                endcase
            end
            DTC: begin
                case (y_offset)
                    4'd8:  row_data = 16'b0000000000001111;
                    4'd9:  row_data = 16'b0000000000001111;
                    4'd10: row_data = 16'b0000000000110000; 
                    4'd11: row_data = 16'b0000000000110000;
                    4'd12: row_data = 16'b0000000011000000;
                    4'd13: row_data = 16'b0000000011000000;
                    4'd14: row_data = 16'b0000000011000000;
                    4'd15: row_data = 16'b0000000011000000;
                    default: row_data = 16'b0;
                endcase
            end
            DTD: begin
                case (y_offset)
                    4'd8:  row_data = 16'b1100000011111111;
                    4'd9:  row_data = 16'b1100000011111111;
                    4'd10: row_data = 16'b1100000000000000; 
                    4'd11: row_data = 16'b1100000000000000;
                    4'd12: row_data = 16'b0011000000000000;
                    4'd13: row_data = 16'b0011000000000000;
                    4'd14: row_data = 16'b0000111111111111;
                    4'd15: row_data = 16'b0000111111111111;
                    default: row_data = 16'b1100001100000000;
                endcase
            end
            // double wall round corner bottom 1- 4
            DBA: begin
                case (y_offset)
                    4'd0: row_data = 16'b1111111111110000;
                    4'd1: row_data = 16'b1111111111110000;
                    4'd2: row_data = 16'b0000000000001100; 
                    4'd3: row_data = 16'b0000000000001100;
                    4'd4: row_data = 16'b0000000000000011;
                    4'd5: row_data = 16'b0000000000000011;
                    4'd6: row_data = 16'b1111111100000011;
                    4'd7: row_data = 16'b1111111100000011;
                    default: row_data = 16'b0000000011000011;
                endcase
            end
            DBB: begin
                case (y_offset)
                    4'd0: row_data = 16'b0000001100000000;
                    4'd1: row_data = 16'b0000001100000000;
                    4'd2: row_data = 16'b0000001100000000; 
                    4'd3: row_data = 16'b0000001100000000;
                    4'd4: row_data = 16'b0000110000000000;
                    4'd5: row_data = 16'b0000110000000000;
                    4'd6: row_data = 16'b1111000000000000;
                    4'd7: row_data = 16'b1111000000000000;
                    default: row_data = 16'b0;
                endcase
            end
            DBC: begin
                case (y_offset)
                    4'd0: row_data = 16'b0000111111111111;
                    4'd1: row_data = 16'b0000111111111111;
                    4'd2: row_data = 16'b0011000000000000; 
                    4'd3: row_data = 16'b0011000000000000;
                    4'd4: row_data = 16'b1100000000000000;
                    4'd5: row_data = 16'b1100000000000000;
                    4'd6: row_data = 16'b1100000011111111;
                    4'd7: row_data = 16'b1100000011111111;
                    default: row_data = 16'b1100001100000000;
                endcase
            end
            DBD: begin
                case (y_offset)
                    4'd0: row_data = 16'b0000000011000000;
                    4'd1: row_data = 16'b0000000011000000;
                    4'd2: row_data = 16'b0000000011000000; 
                    4'd3: row_data = 16'b0000000011000000;
                    4'd4: row_data = 16'b0000000000110000;
                    4'd5: row_data = 16'b0000000000110000;
                    4'd6: row_data = 16'b0000000000001111;
                    4'd7: row_data = 16'b0000000000001111;
                    default: row_data = 16'b0;
                endcase
            end
            // single wall top
            SWT: begin
                case (y_offset)
                    4'd8:  row_data = 16'b1111111111111111;
                    4'd9:  row_data = 16'b1111111111111111;
                    default: row_data = 16'b0;
                endcase
            end
            // single wall bottom
            SWB: begin
                case (y_offset)
                    4'd6:  row_data = 16'b1111111111111111;
                    4'd7:  row_data = 16'b1111111111111111;
                    default: row_data = 16'b0;
                endcase
            end
            // single wall left
            SWL: begin
                row_data = 16'b0000000011000000;
            end
            // single wall right
            SWR: begin
                row_data = 16'b0000001100000000;
            end
            // single wall corner top 1-4
            STA: begin
                case (y_offset)
                    4'd8:  row_data = 16'b1111000000000000;
                    4'd9:  row_data = 16'b1111000000000000;
                    4'd10: row_data = 16'b0000110000000000;
                    4'd11: row_data = 16'b0000110000000000;
                    4'd12: row_data = 16'b0000001100000000;
                    4'd13: row_data = 16'b0000001100000000;
                    4'd14: row_data = 16'b0000001100000000;
                    4'd15: row_data = 16'b0000001100000000;
                    default: row_data = 16'b0;
                endcase
            end
            STB: begin
                case (y_offset)
                    4'd0:  row_data = 16'b0000000011000000;
                    4'd1:  row_data = 16'b0000000011000000;
                    4'd2:  row_data = 16'b0000000011000000;
                    4'd3:  row_data = 16'b0000000011000000;
                    4'd4:  row_data = 16'b0000000011000000;
                    4'd5:  row_data = 16'b0000000011000000;
                    4'd6:  row_data = 16'b0000001100000000; 
                    4'd7:  row_data = 16'b0000001100000000;
                    4'd8:  row_data = 16'b1111110000000000;
                    4'd9:  row_data = 16'b1111110000000000;
                    default: row_data = 16'b0;
                endcase
            end
            STC: begin
                case (y_offset)
                    4'd8:  row_data = 16'b0000000000001111;
                    4'd9:  row_data = 16'b0000000000001111;
                    4'd10: row_data = 16'b0000000000110000;
                    4'd11: row_data = 16'b0000000000110000;
                    4'd12: row_data = 16'b0000000011000000;
                    4'd13: row_data = 16'b0000000011000000;
                    4'd14: row_data = 16'b0000000011000000;
                    4'd15: row_data = 16'b0000000011000000;
                    default: row_data = 16'b0;
                endcase
            end
            STD: begin
                case (y_offset)
                    4'd0:  row_data = 16'b0000001100000000;
                    4'd1:  row_data = 16'b0000001100000000;
                    4'd2:  row_data = 16'b0000001100000000;
                    4'd3:  row_data = 16'b0000001100000000;
                    4'd4:  row_data = 16'b0000001100000000;
                    4'd5:  row_data = 16'b0000001100000000;
                    4'd6:  row_data = 16'b0000000011000000; 
                    4'd7:  row_data = 16'b0000000011000000;
                    4'd8:  row_data = 16'b0000000000111111;
                    4'd9:  row_data = 16'b0000000000111111;
                    default: row_data = 16'b0;
                endcase
            end
            // single wall corner bottom 1-4
            SBA: begin
                case (y_offset)
                    4'd6:  row_data = 16'b1111110000000000; 
                    4'd7:  row_data = 16'b1111110000000000;
                    4'd8:  row_data = 16'b0000001100000000;
                    4'd9:  row_data = 16'b0000001100000000;
                    4'd10: row_data = 16'b0000000011000000;
                    4'd11: row_data = 16'b0000000011000000;
                    4'd12: row_data = 16'b0000000011000000;
                    4'd13: row_data = 16'b0000000011000000;
                    4'd14: row_data = 16'b0000000011000000;
                    4'd15: row_data = 16'b0000000011000000;
                    default: row_data = 16'b0;
                endcase
            end
            SBB: begin
                case (y_offset)
                    4'd0:  row_data = 16'b0000001100000000;
                    4'd1:  row_data = 16'b0000001100000000;
                    4'd2:  row_data = 16'b0000001100000000;
                    4'd3:  row_data = 16'b0000001100000000;
                    4'd4:  row_data = 16'b0000110000000000;
                    4'd5:  row_data = 16'b0000110000000000;
                    4'd6:  row_data = 16'b1111000000000000; 
                    4'd7:  row_data = 16'b1111000000000000;
                    default: row_data = 16'b0;
                endcase
            end
            SBC: begin
                case (y_offset)
                    4'd6:  row_data = 16'b0000000000111111; 
                    4'd7:  row_data = 16'b0000000000111111;
                    4'd8:  row_data = 16'b0000000011000000;
                    4'd9:  row_data = 16'b0000000011000000;
                    4'd10: row_data = 16'b0000001100000000;
                    4'd11: row_data = 16'b0000001100000000;
                    4'd12: row_data = 16'b0000001100000000;
                    4'd13: row_data = 16'b0000001100000000;
                    4'd14: row_data = 16'b0000001100000000;
                    4'd15: row_data = 16'b0000001100000000;
                    default: row_data = 16'b0;
                endcase
            end
            SBD: begin
                case (y_offset)
                    4'd0:  row_data = 16'b0000000011000000;
                    4'd1:  row_data = 16'b0000000011000000;
                    4'd2:  row_data = 16'b0000000011000000;
                    4'd3:  row_data = 16'b0000000011000000;
                    4'd4:  row_data = 16'b0000000000110000;
                    4'd5:  row_data = 16'b0000000000110000;
                    4'd6:  row_data = 16'b0000000000001111; 
                    4'd7:  row_data = 16'b0000000000001111;
                    default: row_data = 16'b0;
                endcase
            end
            // T-wall 1-6
            TWA: begin
                case (y_offset)
                    4'd0: row_data = 16'b1111111111111111;
                    4'd1: row_data = 16'b1111111111111111; 
                    4'd2: row_data = 16'b0000000000000000;
                    4'd3: row_data = 16'b0000000000000000;
                    4'd4: row_data = 16'b0000000000000000;
                    4'd5: row_data = 16'b0000000000000000;
                    4'd6: row_data = 16'b1111110000000000; 
                    4'd7: row_data = 16'b1111110000000000;
                    4'd8: row_data = 16'b0000001100000000;
                    4'd9: row_data = 16'b0000001100000000;
                    default: row_data = 16'b0000000011000000;
                endcase
            end
            TWB: begin
                case (y_offset)
                    4'd0: row_data = 16'b1111111111111111;
                    4'd1: row_data = 16'b1111111111111111; 
                    4'd2: row_data = 16'b0000000000000000;
                    4'd3: row_data = 16'b0000000000000000;
                    4'd4: row_data = 16'b0000000000000000;
                    4'd5: row_data = 16'b0000000000000000;
                    4'd6: row_data = 16'b0000000000111111; 
                    4'd7: row_data = 16'b0000000000111111;
                    4'd8: row_data = 16'b0000000011000000;
                    4'd9: row_data = 16'b0000000011000000;
                    default: row_data = 16'b0000001100000000;
                endcase
            end 
            TWC: begin
                case (y_offset)
                    4'd6:  row_data = 16'b0000001100000011; 
                    4'd7:  row_data = 16'b0000001100000011;
                    4'd8:  row_data = 16'b1111110000000011;
                    4'd9:  row_data = 16'b1111110000000011;
                    4'd10: row_data = 16'b0000000000000011; 
                    4'd11: row_data = 16'b0000000000000011;
                    4'd12: row_data = 16'b0000000000000011;
                    4'd13: row_data = 16'b0000000000000011;
                    4'd14: row_data = 16'b0000000000000011;
                    4'd15: row_data = 16'b0000000000000011;
                    default: row_data = 16'b0000000011000011;
                endcase
            end
            TWD: begin
                case (y_offset) 
                    4'd6:  row_data = 16'b1100000011000000; 
                    4'd7:  row_data = 16'b1100000011000000;
                    4'd8:  row_data = 16'b1100000000111111;
                    4'd9:  row_data = 16'b1100000000111111;
                    4'd10: row_data = 16'b1100000000000000; 
                    4'd11: row_data = 16'b1100000000000000;
                    4'd12: row_data = 16'b1100000000000000;
                    4'd13: row_data = 16'b1100000000000000;
                    4'd14: row_data = 16'b1100000000000000;
                    4'd15: row_data = 16'b1100000000000000;
                    default: row_data = 16'b1100001100000000;
                endcase
            end
            TWE: begin
                case (y_offset)
                    4'd0:  row_data = 16'b1100000000000000;
                    4'd1:  row_data = 16'b1100000000000000;
                    4'd2:  row_data = 16'b1100000000000000;
                    4'd3:  row_data = 16'b1100000000000000;
                    4'd4:  row_data = 16'b1100000000000000;
                    4'd5:  row_data = 16'b1100000000000000; 
                    4'd6:  row_data = 16'b1100000000111111; 
                    4'd7:  row_data = 16'b1100000000111111;
                    4'd8:  row_data = 16'b1100000011000000;
                    4'd9:  row_data = 16'b1100000011000000;
                    default: row_data = 16'b1100001100000000;
                endcase
            end
            TWF: begin
                case (y_offset)
                    4'd0:  row_data = 16'b0000000000000011;
                    4'd1:  row_data = 16'b0000000000000011;
                    4'd2:  row_data = 16'b0000000000000011;
                    4'd3:  row_data = 16'b0000000000000011;
                    4'd4:  row_data = 16'b0000000000000011;
                    4'd5:  row_data = 16'b0000000000000011; 
                    4'd6:  row_data = 16'b1111110000000011; 
                    4'd7:  row_data = 16'b1111110000000011;
                    4'd8:  row_data = 16'b0000001100000011;
                    4'd9:  row_data = 16'b0000001100000011;
                    default: row_data = 16'b0000000011000011;
                endcase
            end
            default: row_data = 16'b0; 
        endcase
    end

    // output
    assign is_wall = row_data[x_offset];

endmodule
