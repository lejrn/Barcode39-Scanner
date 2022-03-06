// Gal Eshel & Tal Leron - DCS 2020 - Final Project - Barcode 39
module INTEL_8237(
input clk,
input rst,
inout [9:0] Address,
input wire HLDA, 
output reg HOLD,
output reg EOP,
output reg DACK,
output reg MEMW,
input  DREQ,
input  CS,
output reg BHE
);

reg [9:0] address;

always @ (DREQ,HLDA) // Asynchronic 
begin
  HOLD = (DREQ) ? 1:0; // Hold control - DMA asks CPU to control the bus
  MEMW = (DREQ) ? 1:0;  // MEMW control - Memory Write
  BHE  = (DREQ)? ((address % 2 == 0) ? 0:1):0;  // Byte High Enable control
  DACK = (HLDA) ? 1:0;  // DMA Acknowledge
end

always @ (posedge clk or negedge rst) // Synchronic
    begin
      if(!rst)
        begin
          address <= 0;
        end
      else if (DREQ == 1 && CS)
        begin
          address <= address + 1; // Updates the address
          EOP <= (address == 98) ? 1:0; // Checks if the reading process ended
        end 
    end

assign Address = (DREQ && CS) ? address : 10'bz; // Address bus drives only when is needed

endmodule
