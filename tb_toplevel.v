// Gal Eshel & Tal Leron - DCS 2020 - Final Project - Barcode 39
`timescale 1ns/10ps
module tb_toplevel();

integer in,out; // file pointers
integer i;

wire wALE;
wire wINT,wEOP; // interrupt wires.
wire wDREQ,wMEMR,wBHE; // cpu and timer wires.
wire wDACK,bhe_dma_wire,wMEMW,wHOLD,wHLDA; // dma wires.
wire [7:0] data_timer_wire;
wire [9:0] wAD_BUS;
wire [9:0] wAddressBus;

// Registers.
reg [9:0] AD_bus;
reg MEMR,BHE,ALE;
reg clk,rst;
reg scanner_bit;
reg [7:0] code39_table [0:43]; // ascii_value

// conversion variables.
reg [7:0] div;
reg [9:0] temp_encoded; 
 
// cpu registers.
reg SRTSCAN,INTA;

initial begin
  `include "code39_table.v"
  clk = 0;
  rst = 0;
  scanner_bit = 1;
  in  = $fopen("Scanner.txt","rb");
end
// Create 20Mhz clock
always #25 clk = ~clk;
// DUT input driver code
initial begin
    #clk 
    rst = 0;
    repeat(5) @ (posedge clk);
    rst = ~rst;
    while (!$feof(in)) begin @ (posedge clk);
      /// Read character
      MEMR = 0;
      ALE = 0;
      repeat (3) @ (posedge clk);
      scanner_bit = $fgetc(in);
      SRTSCAN = 1; 
    end // closing while
    
SRTSCAN = 0; // finished scanner reading
    repeat (5) @ (posedge clk);
    $fclose(in);
    in = 32'bz;

/**************************************************/
// START receiving barcode data from memory units.
/**************************************************/


out = $fopen("Barcode.txt","w");
div = 100 ;
temp_encoded = 0;
for ( i = 0 ; i < 99 ; i = i + 1) // Encoding 11 Barcodes to Keys
  begin 
    AD_bus = i; // Address
    ALE = 1; // Demuxes address from AD bus
    BHE = AD_bus[0];
    #50
    ALE = 0; // Finished Demuxing from AD bus
    MEMR = 1; // Reads from Memory
    #50
    MEMR = 0; // Finished reading from Memory
    if( wAD_BUS == 8) // Encoding Barcode to Key
      begin
        temp_encoded = temp_encoded + (i%9)*div;
        div=div/10;
      end
    if(i%9 == 8) 
      begin
        div=100;
        $fwrite(out,"%c",code39_table[encoded_index(temp_encoded)]); // Key to ASCII and writes to Barcode.txt
        temp_encoded = 0; 
      end
  end 
  $fclose(out); // Finished encoding
  #100;  
end


assign wMEMR = MEMR;
assign wBHE = (wMEMW) ? bhe_dma_wire : (wMEMR)? BHE:bhe_dma_wire;
assign wAD_BUS = (ALE) ? AD_bus : (wMEMW || wMEMR) ? {2'b0,wAD_BUS[7:0]} : 10'bz;
assign start_wire = SRTSCAN;
assign wHLDA  = (wHOLD) ? 1 : 0;
assign wINTA = wINT;
assign wALE = ALE;
  
/***********************************************************/
// Input encoded number and get the right index in encoded_table
/***********************************************************/
  function integer encoded_index;
    input [9:0] encoded_number; 
    // Local Variables
    reg [9:0] encoded_table [0:43]; // max 678 value
    //reg [5:0] i;
    integer i;
    begin
     `include "encoded_table.v"
     for( i=0 ; i < 44 ; i = i+1)
     begin
        if( encoded_table[i] - encoded_number == 0) // Finds index 
         encoded_index = i; // Returns index
     end
    end
  endfunction

// DUT modules.
INTEL_8254 Timer(
.clk(clk),
.rst(rst),
.CS(start_wire),
.data(data_timer_wire),
.OUT0(wDREQ),
.GATE0(scanner_bit));

/* Timer buffer */
BUFFER Timer_Buffer(
.data_bus(wAD_BUS[7:0]),
.data_in(data_timer_wire),
.DACK(wDACK));

INTEL_8237 DMA_Unit(
.clk(clk),
.rst(rst),
.Address(wAddressBus),
.DACK(wDACK),
.HOLD(wHOLD),
.HLDA(wHLDA),
.MEMW(wMEMW),
.DREQ(wDREQ),
.CS(!wMEMR),
.EOP(wEOP),
.BHE(bhe_dma_wire));

// EVEN memory (BLE)
RAM EVEN(
.clk(clk),
.rst(rst),
.MEMW(wMEMW),
.MEMR(wMEMR),
.Address(wAddressBus/8'b00000010),
.data(wAD_BUS[7:0]),
.CS( !wBHE && wAddressBus[0] == 1'b0)
);
// ODD memory (BHE)
RAM ODD(
.clk(clk),
.rst(rst),
.MEMW(wMEMW),
.MEMR(wMEMR),
.Address((wAddressBus-8'b00000001)/8'b00000010),
.data(wAD_BUS[7:0]),
.CS(wBHE && wAddressBus[0] == 1'b1)
);

INTEL_8259 PIC(
.IR0(wEOP),
.INT(wINT),
.INTA(wINTA)
);

ALatch Bus_Demux(
.rst(rst),
.ALE(wALE),
.AD(wAD_BUS),
.Address(wAddressBus)
);

endmodule