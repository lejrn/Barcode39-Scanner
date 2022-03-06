module RAM(
input clk,
input rst,
input wire MEMW,
input wire MEMR,
input [9:0] Address,
inout [7:0] data,
input CS
);

// Memory of 1024 lines - 8K
parameter size = 8192,
          word = 16;
integer i;
reg [word/2-1:0]Mem[0:size-1]; 

always @ ( posedge clk or negedge rst )
begin
 if ( !rst )
   // Initialize memory block.
   for ( i =0 ; i<size ; i = i + 1)
   begin
     Mem[i] <= 0;
   end
 else
 begin
  if ( MEMW == 1 && CS)
    Mem[Address] <= data;
 end 
end

// Transfer data out of memory unit.
assign data = (MEMR && CS) ? Mem[Address]: 8'bz;
endmodule

