// Gal Eshel & Tal Leron - DCS 2020 - Final Project - Barcode 39
module BUFFER(
output [7:0] data_bus,
input  [7:0] data_in,
input DACK
);
 assign  data_bus = (DACK) ? data_in : 8'bzzzzzzzz ;  // Buffer
endmodule