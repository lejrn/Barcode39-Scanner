// Gal Eshel & Tal Leron - DCS 2020 - Final Project - Barcode 39
module INTEL_8254(
    input clk,
    input rst,
    input CS,
    output wire [7:0] data,
    output reg OUT0,
    input wire GATE0
    );
    
    reg GATE0S, flag =0, FLAG; // flag - Sets at first toggle of scanner bit, FLAG is a delayed flag (Being sampled)
    reg [3:0] counter; // Counter register
    reg [3:0] capture = 0; // Captures counter every toggle
    reg [3:0] Toggles = -1; // Counts the number of toggles

    always @ (GATE0) // Asynchronous block
		  if(CS) begin
            capture = counter+8'b1; // Captures the counter (either 4 or 8)
            flag = 1; // flag to start counting
            if(Toggles < 10)
                Toggles = Toggles + 1; // Counts toggles up to 10, when there is a seperating bar '1'
            else
                if(FLAG) // For synchronising toggles counting
                    Toggles = 1; // Resets toggles number 
        end

    always @(posedge clk, negedge rst) // Synchronous block: Samples GATE0 every rising clock
        if(~rst) begin
            GATE0S <= 1;
            FLAG <= 0;
        end
        else if(CS) begin
            GATE0S <= GATE0; // "GATE0 Sampled" = "GATE0S" samples GATE0 for DREQ reasons
            FLAG <= flag; // Is needed to be sampled only once, but it still works very well
        end

    always @(posedge clk, negedge rst)
        if(~rst) begin
            OUT0 <= 0;
            counter <= 1;
        end
        else if(CS) 
            begin
                if(flag)
                    if(GATE0 & ~GATE0S || ~GATE0 & GATE0S) // Creates DREQ (=OUT0) only when either rising or falling edges, meaning when GATE0 toggles
                            begin
                                if(FLAG & ~(Toggles%10 == 0)) // For every 10th '1', which is a seperating bar in between characters, OUT0 is NOT raised up for DREQ && FLAG makes sure OUT0 only rises up at first count
                                    OUT0 <= 1; // Requests DMA to write to MEM
                                counter <= 1; // Resets counter for next counting
                            end
                        else
                            begin
                                OUT0 <= 0; // Resets OUT0
                                counter <= counter + 1; // Increaments counter
                            end
            end
assign data = (CS && flag) ? capture : 8'bzzzzzzzz ; // Data out

endmodule