module MAC #
(
parameter DATA_WIDTH = 8
)
(
input clk,
input rst_n,
input En,
input Clr,
input [DATA_WIDTH-1:0] Ain,
input [DATA_WIDTH-1:0] Bin,
output reg [DATA_WIDTH*3-1:0] Cout
);

logic [DATA_WIDTH*3-1:0] mult;

// multiply
always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    mult <= '0;
  end
  else if (Clr) begin
    mult <= '0;
  end
  else if (En) begin
    mult <= (Ain * Bin);
  end
end

// add 
always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    Cout <= '0;
  end
  else if (Clr) begin
    Cout <= '0;
  end
  else if (En) begin
    Cout <= Cout + mult;
  end
end

endmodule


// always_ff @(posedge clk or negedge rst_n) begin
//   if (~rst_n) begin
//     Cout <= '0;
//   end
//   else if (Clr) begin
//     Cout <= '0;
//   end
//   else if (En) begin
//     Cout <= Cout + (Ain * Bin);
//   end
// end
