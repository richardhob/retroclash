`default_nettype none

module SevenSegment(input wire CLK,
                    input wire RST,
                    input wire EN,
                    input wire [7:0] DATA,
                    output reg [6:0] SEGMENTS,
                    output reg SEL);

    // Number of clocks between display swap
    parameter THRESHOLD = 100;

    reg [15:0] iCOUNTER;
    initial iCOUNTER = 0;

    // Down Counter 
    always @(posedge CLK)
        if (RST) 
            iCOUNTER <= THRESHOLD;
        else if (EN)
            if (iCOUNTER > 0)
                iCOUNTER <= iCOUNTER - 1;
            else // iCOUNTER == 0
                iCOUNTER <= THRESHOLD;

    // SEL
    always @(posedge CLK)
        if (RST)
            SEL <= 0;
        else if (EN)
            if (iCOUNTER == 0)
                SEL <= ~SEL;

    reg [3:0] iDATA = 0;
    initial iDATA = 0;

    // DATA -> iDATA
    always @(posedge CLK)
        if (RST)
            iDATA <= 0;
        else if (EN)
            if (SEL)
                iDATA <= DATA[7:4];
            else
                iDATA <= DATA[3:0];

    // iDATA -> SEGMENTS
    always @(posedge CLK)
        begin
            if (RST)
                SEGMENTS <= 7'b0000000;
            else if (EN)
                case (iDATA)
                    4'h0: SEGMENTS <= 7'b0111111;
                    4'h1: SEGMENTS <= 7'b0000110;
                    4'h2: SEGMENTS <= 7'b1011011;
                    4'h3: SEGMENTS <= 7'b1001111;
                    4'h4: SEGMENTS <= 7'b1100110;
                    4'h5: SEGMENTS <= 7'b1101101;
                    4'h6: SEGMENTS <= 7'b1011111;
                    4'h7: SEGMENTS <= 7'b0000111;
                    4'h8: SEGMENTS <= 7'b1111111;
                    4'h9: SEGMENTS <= 7'b1111011;
                    4'hA: SEGMENTS <= 7'b1110111;
                    4'hB: SEGMENTS <= 7'b1111100;
                    4'hC: SEGMENTS <= 7'b0111001;
                    4'hD: SEGMENTS <= 7'b1011110;
                    4'hE: SEGMENTS <= 7'b1111001;
                    4'hF: SEGMENTS <= 7'b1110001;
                endcase
        end

endmodule
