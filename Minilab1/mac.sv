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

reg [DATA_WIDTH*3-1:0] mult;
reg en_latch;

always_ff @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    Cout <= '0;
    mult <= '0;
  end
  else if (Clr) begin
    Cout <= '0;
    mult <= '0;
  end
  else begin
    en_latch <= En;
    if (En) begin
      mult <= (Ain * Bin);   
    end
    if (en_latch) begin
      Cout <= Cout + mult;
    end
  end
end

endmodule