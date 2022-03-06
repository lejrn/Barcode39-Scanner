// Gal Eshel & Tal Leron - DCS 2020 - Final Project - Barcode 39
module INTEL_8259(  // Interrupt Controller
input IR0, // IR0 interrupt port
input INTA, // Inerrupt Acknowledge
output reg INT); // Interrupt Request

always @ (*)
begin
	if ( IR0 ) // DMA done transfer IO to MEM
		INT = 1; // Interrupt Request
	else if ( INTA ) // Resets INT
		INT = 0;
end
endmodule