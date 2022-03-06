// Gal Eshel & Tal Leron - DCS 2020 - Final Project - Barcode 39
module ALatch(
input rst,
input [9:0] AD,
input ALE,
output reg [9:0] Address);

always @ (posedge ALE or negedge rst) // Demuxing Bus
begin
  if (!rst)
    Address <= 10'bz;
  else 
    Address <= AD;
end
endmodule