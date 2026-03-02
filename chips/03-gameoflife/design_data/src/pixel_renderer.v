module pixel_renderer(
    input  wire [9:0]  px,
    input  wire [9:0]  py,
    input  wire        video_active,
    input  wire [63:0] grid_data,
    input  wire [127:0] age_data,
    output reg  [3:0]  r, g, b
);
    
    always @(*) begin
        r = 0; g = 0; b = 0;
        
        if (video_active && px < 480 && py < 480) begin
            if ((px % 60 == 0) || (py % 60 == 0)) begin
                r = 4'h2; g = 4'h2; b = 4'h2;
            end
            else begin
                if (grid_data[ (py/60)*8 + (px/60) ]) begin
                    
                    case ( age_data[ ((py/60)*8 + (px/60))*2 +: 2 ] )
                        
                        2'd0: begin r=0; g=4'hF; b=0; end    
                        
                        2'd1: begin r=4'hF; g=4'hF; b=0; end 
                        
                        2'd2: begin r=0; g=4'h8; b=4'hF; end 
                        
                        2'd3: begin r=4'hF; g=0; b=4'h4; end 
                        
                    endcase
                    
                end else begin
                    r=0; g=0; b=0;
                end
            end
        end
    end
endmodule