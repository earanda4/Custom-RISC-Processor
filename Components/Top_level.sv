// revised 2025.07.23 for 111 ... 111 case
// revised 2025.07.22 for sign-and-magnitude fixed point
// revised 2025.05.11 for no_round required	   PROGRAM 1
// behavioral model for fix(8.8) to float(16) conversion
// CSE141L  dummy DUT for int_to_float
// goes alongside yours in the Program 1 testbench 
module TopLevel (
  input        clk, 
               reset, 				    // master reset -- start at beginning 
               start,                   // request -- start next conversion
  output logic done);				    // your acknowledge back to the testbench --ready for next operation
  logic        nil;					    // zero trap
  logic        max_neg;                 // 16'h8000 trap
  logic[ 7:0]  ctr;					    // clock cycle downcounter
  logic[ 4:0]  exp;					    // floating point exponent
  logic[14:0]  int1;				    // input value
  logic        sgn; 				    // floating point sign
  logic        trap;                    // max neg or 0 input
  bit  [ 1:0]  pgm;                     // counts 1, 2, 3 program
// port connections to dummy data_mem
  bit     [7:0]  DataAddress;		    // pointer
  bit            ReadMem = 1'b1;		// can leave enabled	
  bit            WriteMem;				// write enable
  bit     [7:0]  DataIn;				// data input port 
  wire    [7:0]  DataOut;				// data output port
  data_mem       data_mem1(.*);	  		// dummy data_memory for compatibility

  always @(posedge clk) begin
	if(reset) begin 
	end	                                // do nothing else
    else if(start) begin
	  {sgn,int1}    = {data_mem1.mem_core[1],data_mem1.mem_core[0]};
	  trap    = !int1;                  // trap 0 or 16'h8000) 
      exp     = 6'd21;			   	    // biased exponent starting value = 6 + 15
	  done    = 1'b0;
    end
	else if(!done) begin	   		
      if(trap) begin
	    exp  = '0;			            // +/-0  
      end
      else begin
// normalization -- start w/ biased exponent = 14+15, count down as needed
        for(int ct=0;ct<15;ct++) begin
          if(int1[14]==1'b0) begin   // priority coder
            int1 = int1<<1'b1;	// looks for position of leading one
	        exp--;				        // decrement exponent every time we double mant.
//			$display("exp = %d, int1 = %b",exp,int1);
          end
		  else break; 
        end
      end
      #10ns {data_mem1.mem_core[3],data_mem1.mem_core[2]} = {sgn,exp[4:0],int1[13:4]};
	  #20000ns done = '1;                   // adjust as needed for your design
    end	 
  end

endmodule