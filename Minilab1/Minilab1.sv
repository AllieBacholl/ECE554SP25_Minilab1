
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module Minilab1(

	//////////// CLOCK //////////
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,
	input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SEG7 //////////
	output	reg	     [6:0]		HEX0,
	output	reg	     [6:0]		HEX1,
	output	reg	     [6:0]		HEX2,
	output	reg	     [6:0]		HEX3,
	output	reg	     [6:0]		HEX4,
	output	reg	     [6:0]		HEX5,
	
	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		     [9:0]		SW

);

localparam DATA_WIDTH = 8;
localparam DEPTH = 8;

localparam ENTER = 3'd0;
localparam FILLM = 3'd1;
localparam DONEM = 3'd2;
localparam MACMATH = 3'd3;
localparam DONE = 3'd4;

parameter HEX_0 = 7'b1000000;		// zero
parameter HEX_1 = 7'b1111001;		// one
parameter HEX_2 = 7'b0100100;		// two
parameter HEX_3 = 7'b0110000;		// three
parameter HEX_4 = 7'b0011001;		// four
parameter HEX_5 = 7'b0010010;		// five
parameter HEX_6 = 7'b0000010;		// six
parameter HEX_7 = 7'b1111000;		// seven
parameter HEX_8 = 7'b0000000;		// eight
parameter HEX_9 = 7'b0011000;		// nine
parameter HEX_10 = 7'b0001000;		// ten
parameter HEX_11 = 7'b0000011;		// eleven
parameter HEX_12 = 7'b1000110;		// twelve
parameter HEX_13 = 7'b0100001;		// thirteen
parameter HEX_14 = 7'b0000110;		// fourteen
parameter HEX_15 = 7'b0001110;		// fifteen
parameter OFF   = 7'b1111111;		// all off

//=======================================================
//  REG/WIRE declarations
//=======================================================

//reg [1:0] state;
reg [2:0] mem_state;

reg [DATA_WIDTH-1:0] datain [0:8];
reg [DATA_WIDTH-1:0] dataout [0:8];
wire rst_n;
logic [8:0] wren, full, empty;
logic rden;
reg [7:0] [DATA_WIDTH*3-1:0] macout;
logic mac_en;

logic [31:0] address;
logic read, readdatavalid, waitrequest;
logic [63:0] readdata;

logic [3:0] mem_count, count_fifo;

integer j, k, l;
logic [6:0] bound;

//=======================================================
//  Module instantiation
//=======================================================

genvar i;

// Fifo 0 or B, Fifos 1-8 for A 
generate
  for (i=0; i<9; i=i+1) begin : fifo_gen
    FIFO
    #(
    .DEPTH(DEPTH),
    .DATA_WIDTH(DATA_WIDTH)
    ) input_fifo
    (
    .clk(CLOCK_50),
    .rst_n(rst_n),
    .rden(rden),
    .wren(wren[i]),
    .i_data(datain[i]),
    .o_data(dataout[i]),
    .full(full[i]),
    .empty(empty[i])
    );
  end
endgenerate

logic [DATA_WIDTH-1:0] dataout_int [0:8];
logic [7:0] [DATA_WIDTH*3-1:0] macout_int;

always @(posedge CLOCK_50) begin
		dataout_int <= dataout;
	end 

// 8 MACs
generate
  for (i=0; i<8; i=i+1) begin : mac_gen
	MAC
	#(
	.DATA_WIDTH(DATA_WIDTH)
	) mac
	(
	.clk(CLOCK_50),
	.rst_n(rst_n),
	.En(mac_en),
	.Clr(1'b0),
	.Ain(dataout_int[i+1]),
	.Bin(dataout_int[0]),
	.Cout(macout_int[i])
	);
  end
endgenerate


always @(posedge CLOCK_50) begin
	macout <= macout_int;
end 

mem_wrapper mem_module (
	.clk(CLOCK_50),
	.reset_n(rst_n),
	.address(address),
	.read(read),
	.readdata(readdata),
	.readdatavalid(readdatavalid),
	.waitrequest(waitrequest)
);

//=======================================================
//  Structural coding
//=======================================================

assign rst_n = KEY[0];
assign bound = 7'd63-(count_fifo*7'd8);
logic [3:0] mac_count;

always @(posedge CLOCK_50 or negedge rst_n) begin

  if (~rst_n) begin
    mem_state <= ENTER;
    read <= 1'b0;
    address <= 32'b0;
    mem_count <= 4'h0;
    count_fifo <= 4'b0000; 
	mac_count <= 4'b0;
	wren <= 9'b0; 
	rden <= 1'b0;
  end 

  else begin

    case (mem_state)
      ENTER: begin
        if (full[8]) begin
          mem_state <= DONEM;  
		end else if (readdatavalid) begin
		  // when one line is read, reset count_fifo and
		  // move to FILLM to move data to the fifo
          count_fifo <= 4'b0000;
          mem_state <= FILLM;  
        end else if (!waitrequest) begin
		  // read from memory
          read <= 1'b1; 
        end
      end

      FILLM: begin
        if (count_fifo >= 4'b1001) begin
          address <= address + 32'd1;  
          mem_count <= mem_count + 1'b1;
		  wren[mem_count-1] <= 1'b0;
		  datain[mem_count-1] <= 8'b0;
          mem_state <= ENTER; 
        end else begin
          datain[mem_count-1] <= readdata[bound-:8];
		  wren[mem_count-1] <= 1'b1;  
          count_fifo <= count_fifo + 1'b1; 
        end
      end

      DONEM: begin
		// stop reading (no mroe memory-fifo interfacing)
        read <= 1'b0;  
        mac_en <= 1'b0;
        mem_state <= MACMATH;
      end

      MACMATH: begin
		// until all 8 values of C are written out, keep calculating
        if (mac_count <= 4'b1010) begin
            rden <= 1'b1;
            mac_en <= 1'b1;
            mac_count <= mac_count + 1;
        end else begin
            // rden <=1'b0;
            mac_en <= 1'b0;
			mem_state <= DONE;
        end 
      end

	  DONE: begin
        rden <= 1'b0;
    	//mac_en <= 1'b0;
      end

    endcase
  end
end

logic [2:0] sel;

always @(*) begin
    case(SW[3:1])
        3'b000: sel = 3'd0;
        3'b001: sel = 3'd1;
        3'b010: sel = 3'd2;
        3'b011: sel = 3'd3;
		3'b100: sel = 3'd4;
		3'b101: sel = 3'd5;
		3'b110: sel = 3'd6;
		3'b111: sel = 3'd7;    
    endcase
end

always @(*) begin
  if (mem_state == DONE & SW[0]) begin
	case(macout[sel][3:0])
    //case(macout[SW[3:1]][3:0])
		4'd0: HEX0 = HEX_0;
		4'd1: HEX0 = HEX_1;
		4'd2: HEX0 = HEX_2;
		4'd3: HEX0 = HEX_3;
		4'd4: HEX0 = HEX_4;
		4'd5: HEX0 = HEX_5;
		4'd6: HEX0 = HEX_6;
		4'd7: HEX0 = HEX_7;
		4'd8: HEX0 = HEX_8;
		4'd9: HEX0 = HEX_9;
		4'd10: HEX0 = HEX_10;
		4'd11: HEX0 = HEX_11;
		4'd12: HEX0 = HEX_12;
		4'd13: HEX0 = HEX_13;
		4'd14: HEX0 = HEX_14;
		4'd15: HEX0 = HEX_15;
    endcase
  end
  else begin
    HEX0 = OFF;
  end
end

always @(*) begin
  if (mem_state == DONE & SW[0]) begin
    case(macout[sel][7:4])
    	4'd0: HEX1 = HEX_0;
		4'd1: HEX1 = HEX_1;
		4'd2: HEX1 = HEX_2;
		4'd3: HEX1 = HEX_3;
		4'd4: HEX1 = HEX_4;
		4'd5: HEX1 = HEX_5;
		4'd6: HEX1 = HEX_6;
		4'd7: HEX1 = HEX_7;
		4'd8: HEX1 = HEX_8;
		4'd9: HEX1 = HEX_9;
		4'd10: HEX1 = HEX_10;
		4'd11: HEX1 = HEX_11;
		4'd12: HEX1 = HEX_12;
		4'd13: HEX1 = HEX_13;
		4'd14: HEX1 = HEX_14;
		4'd15: HEX1 = HEX_15;
    endcase
  end
  else begin
    HEX1 = OFF;
  end
end

always @(*) begin
  if (mem_state == DONE & SW[0]) begin
    case(macout[sel][11:8])
    	4'd0: HEX2 = HEX_0;
		4'd1: HEX2 = HEX_1;
		4'd2: HEX2 = HEX_2;
		4'd3: HEX2 = HEX_3;
		4'd4: HEX2 = HEX_4;
		4'd5: HEX2 = HEX_5;
		4'd6: HEX2 = HEX_6;
		4'd7: HEX2 = HEX_7;
		4'd8: HEX2 = HEX_8;
		4'd9: HEX2 = HEX_9;
		4'd10: HEX2 = HEX_10;
		4'd11: HEX2 = HEX_11;
		4'd12: HEX2 = HEX_12;
		4'd13: HEX2 = HEX_13;
		4'd14: HEX2 = HEX_14;
		4'd15: HEX2 = HEX_15;
    endcase
  end
  else begin
    HEX2 = OFF;
  end
end

always @(*) begin
  if (mem_state == DONE & SW[0]) begin
    case(macout[sel][15:12])
    	4'd0: HEX3 = HEX_0;
		4'd1: HEX3 = HEX_1;
		4'd2: HEX3 = HEX_2;
		4'd3: HEX3 = HEX_3;
		4'd4: HEX3 = HEX_4;
		4'd5: HEX3 = HEX_5;
		4'd6: HEX3 = HEX_6;
		4'd7: HEX3 = HEX_7;
		4'd8: HEX3 = HEX_8;
		4'd9: HEX3 = HEX_9;
		4'd10: HEX3 = HEX_10;
		4'd11: HEX3 = HEX_11;
		4'd12: HEX3 = HEX_12;
		4'd13: HEX3 = HEX_13;
		4'd14: HEX3 = HEX_14;
		4'd15: HEX3 = HEX_15;
    endcase
  end
  else begin
    HEX3 = OFF;
  end
end

always @(*) begin
  if (mem_state == DONE & SW[0]) begin
    case(macout[sel][19:16])
    	4'd0: HEX4 = HEX_0;
		4'd1: HEX4 = HEX_1;
		4'd2: HEX4 = HEX_2;
		4'd3: HEX4 = HEX_3;
		4'd4: HEX4 = HEX_4;
		4'd5: HEX4 = HEX_5;
		4'd6: HEX4 = HEX_6;
		4'd7: HEX4 = HEX_7;
		4'd8: HEX4 = HEX_8;
		4'd9: HEX4 = HEX_9;
		4'd10: HEX4 = HEX_10;
		4'd11: HEX4 = HEX_11;
		4'd12: HEX4 = HEX_12;
		4'd13: HEX4 = HEX_13;
		4'd14: HEX4 = HEX_14;
		4'd15: HEX4 = HEX_15;
    endcase
  end
  else begin
    HEX4 = OFF;
  end
end

always @(*) begin
  if (mem_state == DONE & SW[0]) begin
    case(macout[sel][23:20])
    	4'd0: HEX5 = HEX_0;
		4'd1: HEX5 = HEX_1;
		4'd2: HEX5 = HEX_2;
		4'd3: HEX5 = HEX_3;
		4'd4: HEX5 = HEX_4;
		4'd5: HEX5 = HEX_5;
		4'd6: HEX5 = HEX_6;
		4'd7: HEX5 = HEX_7;
		4'd8: HEX5 = HEX_8;
		4'd9: HEX5 = HEX_9;
		4'd10: HEX5 = HEX_10;
		4'd11: HEX5 = HEX_11;
		4'd12: HEX5 = HEX_12;
		4'd13: HEX5 = HEX_13;
		4'd14: HEX5 = HEX_14;
		4'd15: HEX5 = HEX_15;
    endcase
  end
  else begin
    HEX5 = OFF;
  end
end

assign LEDR = {{8{1'b0}}, mem_state};

endmodule

