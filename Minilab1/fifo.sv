module FIFO
#(
  parameter DEPTH      = 8,  // Number of entries in the FIFO
  parameter DATA_WIDTH = 8   // Data bus width
)
(
  input  wire                  clk,
  input  wire                  rst_n,
  input  wire                  rden,       // Read enable
  input  wire                  wren,       // Write enable
  input  wire [DATA_WIDTH-1:0] i_data,     // Data in
  output reg  [DATA_WIDTH-1:0] o_data,     // Data out
  output wire                  full,
  output wire                  empty
);

  // For an 8-deep FIFO, we need 3 bits for indexing (log2(8)=3).
  // More generally, we can write:
  // localparam PTR_WIDTH = $clog2(DEPTH);
  // but for more general or older tools, you can do integer math carefully.
  localparam PTR_WIDTH = $clog2(DEPTH);

  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];  // The FIFO storage

  // Pointers and count
  reg [PTR_WIDTH-1:0]  rd_ptr;  // Read pointer
  reg [PTR_WIDTH-1:0]  wr_ptr;  // Write pointer
  // Count must go up to DEPTH, so it needs PTR_WIDTH+1 bits
  reg [PTR_WIDTH:0]    count;

  // Combinational flags
  assign empty = (count == 0);
  assign full  = (count == DEPTH);

  // Synchronous logic
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rd_ptr <= {PTR_WIDTH{1'b0}};
      wr_ptr <= {PTR_WIDTH{1'b0}};
      count  <= {PTR_WIDTH+1{1'b0}};
      o_data <= {DATA_WIDTH{1'b0}};
    end
    else begin
      // READ operation
      if(rden && !empty) begin
        // Grab data from memory at rd_ptr
        o_data <= mem[rd_ptr];
        // Bump read pointer
        rd_ptr <= rd_ptr + 1'b1;
        // Decrease count
        count <= count - 1'b1;
      end

      // WRITE operation
      if(wren && !full) begin
        // Store data into memory at wr_ptr
        mem[wr_ptr] <= i_data;
        // Bump write pointer
        wr_ptr <= wr_ptr + 1'b1;
        // Increase count
        count <= count + 1'b1;
      end
    end
  end

endmodule