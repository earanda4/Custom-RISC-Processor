// CSE141L revised 2025.07.23 for 1111... case fix
// CSE141L revised 2025.07.22 for sign-and-magnitdue fixed point
// CSE141L   revised 2025.05.24
// testbench for fixed(8.8) to float(16) conversion
// bench computes theoretical result
// bench holds your DUT and my dummy DUT
// (ideally, all three should agree :) )
// keyword bit is same as logic, except it self-initializes
//  to 0 and cannot take on x or z value
module new_int2flt_tb();
  bit       clk       , 
            reset = '1,
            req;
  wire      ack,			 // your DUT's done flag
            ack0;			 // my dummy done flag
  bit  [15:0] int_in; 	     // incoming operand
  logic[15:0] int_out0;      // reconstructed integer from my reference
  logic[15:0] int_out;       // reconstructed integer from your floating point output
  logic[15:0] int_outM;      // reconstructed integer from mathetmical floating point conversion
  bit  [ 3:0] shift;         // for incoming data sizing
  logic[15:0] flt_out0,		 // my design final result
			  flt_out,		 // your design final result
              flt_outM;	     // mathematical final result
  int         scoreM,        // your DUT vs. theory 
              score0,	     // your DUT vs. mine
			  count = 0;     // number of trials

  TopLevel f1(				 // your DUT to generate right answer
    .clk  (clk),
	.start(req),
    .reset(reset),
    .done (ack));	         // your ack is the one that counts
  TopLevel0 f0(				 // reference DUT goes here
    .clk  (clk),			 // 
    .start(req),			 //  
	.reset(reset),			 //  
    .done (ack0));           

  always begin               // clock 
    #5ns clk = '1;			 
	#5ns clk = '0;
  end

  initial begin				 // test sequence
//    $monitor("data_mem.core1,0 = %b  %b %t",f0.data_mem1.mem_core[1],f1.data_mem1.mem_core[0],$time);

    //#20ns reset = '0;
	disp2(int_in);
	int_in = 16'h8000;       // negative 0
	disp2(int_in);			 // subroutine call
	int_in = 16'h0001;		 // minimum nonzero positive = 1/128
	disp2(int_in);
	int_in = 16'h8001;       // minimum mag negative -1/128
	disp2(int_in);
	int_in = 16'h0002; 		 // start w/ contrived tests   1/64
	disp2(int_in);
    int_in = 16'h8002;		 // -1/64
	disp2(int_in);
	int_in = 16'h0003;		 // 						  3/128
	disp2(int_in);
    int_in = 16'h8003;
	disp2(int_in);
	int_in = 16'h000c;		 // 						  3/32
	disp2(int_in);
	int_in = 16'h0030;		 // 					  3/8
	disp2(int_in);
	int_in = 16'h1fff;       // qtr maximum positive   31 + 255/256
	disp2(int_in);
	int_in = 16'h3fff;      // half maximum positive  63 + 255/256
	disp2(int_in);
	int_in = 16'h7fff;      // maximum positive	 = 127 + 255/256
	disp2(int_in);
	int_in = 16'hffff;		 // maximum magnitude negative = -(127 + 255/256)
//	disp2(int_in);
//	int_in = 16'hfffe;		 // -(127+254/256)
//	disp2(int_in);
//	int_in = 16'hfffd; 		 // -(127+253/256)
//	disp2(int_in);
//	int_in = 16'hfff4;		 // -3/32
//	disp2(int_in);
//	int_in = 16'hffd0;		 // -3/8
	disp2(int_in);
	int_in = 16'hc000;      // half maximum magnitude negative
	disp2(int_in);
	int_in = 16'h4000;     // half maximum magnitude positive
	disp2(int_in);
	forever begin			 // random tests
	  int_in = $random;
	  disp2(int_in);
	  if(count>19) begin
	  	#20ns $display("scores = %d %d out of %d",score0,scoreM,count); 
        $stop;
	  end
	end
  end

task automatic disp2(input logic [15:0] int_in);
	// locals
  logic         sign;	                      // bit[15] float or fix
  real          v, mag;
  logic [4:0]   exp	;
  logic [9:0]   mant;
  logic [14:0]  half;
  logic [15:0]  float_M;

  sign = int_in[15];
  half = int_in;

  exp = 21;
  if (!int_in[14:0]) float_M = int_in; // zero trap
  else begin
    while (!half[14]) begin
      half <<= 1'b1;
	  exp--;
	end
  mant = half[13:4];
  float_M = {sign,exp,mant};
  end
    $display();
//	$display("This test case %b \n", int_in);
	reset = 1;
	#10ns;
	reset = 0;

	f1.data_mem1.mem_core[1] = int_in[15:8];   // load operands into your memory
	f1.data_mem1.mem_core[0] = int_in[ 7:0];
	f0.data_mem0.mem_core[1] = int_in[15:8];   // load operands into my memory
	f0.data_mem0.mem_core[0] = int_in[ 7:0];
    //flt_out_M[15]     = sgn_M;                 // sign is a passthrough
	#10ns req = 1;
	#10ns req = 0;
	wait(ack);
	wait(ack0);
	#10ns;
  	flt_out  = {f1.data_mem1.mem_core[3],f1.data_mem1.mem_core[2]};	 // results from your memory
    flt_out0 = {f0.data_mem0.mem_core[3],f0.data_mem0.mem_core[2]};	 // results from my dummy DUT
    $display("what's feeding the case %b",int_in);
	flt_outM = float_M;

	$display("IN=0x%h,  DUT=0x%h, REF=0x%h, MATH=0x%h",
			int_in, flt_out, flt_out0, flt_outM);
	// Compare DUT vs. reference DUT
    if (flt_out === flt_out0) 
      score0++;
    else 
      $display("Mismatch DUT vs REF: DUT=0x%h REF=0x%h", flt_out, flt_out0);

    // Compare DUT vs. math model
    if (flt_out === flt_outM) 
      scoreM++;
    else 
      $display("Mismatch DUT vs MATH: DUT=0x%h MATH=0x%h", flt_out, flt_outM);

    count++;
    $display("Scores so far: vs REF=%0d, vs MATH=%0d, tests=%0d",
			score0, scoreM, count);
  endtask
endmodule
