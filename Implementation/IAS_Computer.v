module main(clk, endit);
	input clk;
	//Reg
	reg signed [0:11] PC = -1;
	reg signed [0:11] MAR;
	reg signed [0:19] IBR;
	reg signed [0:7] IR;
	reg signed [0:39] MBR;
	reg signed [0:39] AC;
	reg signed [0:39] MQ;
	//Memory reg
	reg signed [0:39] memory [0:999];
	//Temporary reg to store the result of multiplication.
	reg signed [0:79] mul;
	//Control signals
	reg fetch1 = 0;
	reg decode = 0;
	reg left = 0;
	reg execute = 0;
	reg rightleft = 0;
	reg jumpright = 0;
	reg incrementpc = 1;
	
	output endit;
	reg endit = 0;
	
	initial begin
  		$readmemb("memory.dat", memory);
	end
	
always@(negedge clk) begin	//Control signals handler
	if(fetch1 == 1) begin
		fetch1 = 0;
		decode = 1;
	end
	
	else if(decode == 1) begin
		decode = 0;
		execute = 1;
	end
	
	else if(execute == 1) begin
		execute = 0;
		if(left == 0) begin
			incrementpc = 1;
		end
		else begin
			left = 0;
			rightleft = 1;
		end
	end
	
	else if(incrementpc == 1) begin
		incrementpc = 0;
		PC = PC + 1;
		fetch1 = 1;
	end
	
	else if(rightleft == 1) begin
		rightleft = 0;
		execute = 1;
	end	
end 
		
always@(posedge clk) begin		//Fetch, decode and execute
	
	if(rightleft == 1) begin
		IR[0:7] = IBR[0:7];
		MAR[0:11] = IBR[8:19];
	end
	
	else if(fetch1 == 1)	begin		//Fetch
		MAR[0:11] = PC[0:11];
		MBR[0:39] = memory[MAR];
	end
	
	else if(decode == 1) begin		//Decode
		if(jumpright == 1) begin	//For right jump instructions
			MBR[0:19] = 20'b0;
			jumpright = 0;
		end
		
		if(MBR[0:19] == 20'b0) begin	//If no left instruction
			left = 0;
			IR = MBR[20:27];
			MAR = MBR[28:39];
		end
		else begin		//If left instruction is present
			left = 1;
			IBR = MBR[20:39];
			IR = MBR[0:7];
			MAR = MBR[8:19];
		end		
	end

	else if(execute == 1) begin		//Execute
		if(IR[0:7] == 8'b11111111) begin //HALT
			$writememb("Memory_out.dat", memory);
			endit = 1;
		end
			
		else if(IR[0:7] == 8'b00000001) begin //LOAD M(X)
			MBR[0:39] = memory[MAR];
			AC[0:39] = MBR[0:39];
		end
		
		else if(IR[0:7] == 8'b00000101) begin //ADD M(X)
			MBR[0:39] = memory[MAR];
			AC[0:39] = AC[0:39] + MBR[0:39];
		end
		
		else if(IR[0:7] == 8'b00100001) begin //STORE M(X)
			MBR[0:39] = AC[0:39];
			memory[MAR] = MBR[0:39];
		end	
		
		else if(IR[0:7] == 8'b00001010) begin //LOAD MQ
			AC[0:39] = MQ[0:39];
		end
		
		else if(IR[0:7] == 8'b00001001) begin //LOAD MQ, M(X)
			MBR[0:39] = memory[MAR];
			MQ[0:39] = MBR[0:39];
		end
		
		else if(IR[0:7] == 8'b00010100) begin //LSH
			AC = 2 * AC;
		end
		
		else if(IR[0:7] == 8'b00010101) begin //RSH
			AC = AC / 2;	
		end
		
		else if(IR[0:7] == 8'b00000010) begin // LOAD -M(X)
			MBR[0:39] = memory[MAR];
			AC[0:39] = MBR[0:39];
			AC[0:39] = -AC[0:39];
		end
		
		else if(IR[0:7] == 8'b00000110) begin //SUB M(X)
			MBR[0:39] = memory[MAR];
			AC = AC - MBR;
		end
		
		else if(IR[0:7] == 8'b00010010) begin //STORE M(X,8:19)
			MBR = AC[28:39];
			memory[MAR][8:19] = MBR;
		end
		
		else if(IR[0:7] == 8'b00010011) begin //STORE M(X,28:39)
			MBR = AC[28:39];
			memory[MAR][28:39] = MBR;
		end
		
		else if(IR[0:7] == 8'b00000011) begin //LOAD |M(X)|
			MBR[0:39] = memory[MAR];
			if(MBR[0] == 0)
				AC[0:39] = MBR[0:39];
			else
				AC[0:39] = -MBR[0:39];
		end
	
		else if(IR[0:7] == 8'b00000100) begin //LOAD -|M(X)|
			MBR[0:39] = memory[MAR];
			if(MBR[0] == 0)
				AC[0:39] = -MBR[0:39];
			else
				AC[0:39] = MBR[0:39];
		end
		
		else if(IR[0:7] == 8'b00000111) begin //ADD |M(X)|
			MBR[0:39] = memory[MAR];
			if(MBR[0] == 0)
				AC = AC	+ MBR;
			else 
				AC = AC - MBR;
		end
		
		else if(IR[0:7] == 8'b00001000) begin //SUB |M(X)|
			MBR[0:39] = memory[MAR];
			if(MBR[0] == 0)
				AC = AC - MBR;
			else
				AC = AC + MBR;
		end
		
		else if(IR[0:7] == 8'b00001011) begin // MUL M(X)
			MBR[0:39] = memory[MAR];
			mul[0:79] = MBR * MQ;
			AC[0:39] = mul[0:39];
			MQ[0:39] = mul[40:79];
		end 
		
		else if(IR[0:7] == 8'b00001100) begin // DIV M(X)
			MBR[0:39] = memory[MAR];
			MQ[0:39] = AC[0:39] / MBR[0:39];
			AC[0:39] = AC[0:39] % MBR[0:39];
		end 
		
		else if (IR[0:7] == 8'b00001101) begin //JUMP M(X,0:19)
			left = 0;
			PC = MAR - 1;
		end
		
		else if(IR[0:7] == 8'b00001110) begin //JUMP M(X,20:39)
			left = 0;
			PC = MAR - 1;
			jumpright = 1;
		end
		
		else if(IR[0:7] == 8'b00001111) begin //JUMP + M(X, 0:19)
			if(AC[0] == 0) begin
				left = 0;
				PC = MAR - 1;
			end
		end
		
		else if(IR[0:7] == 8'b00010000) begin //Jump + M(X, 20:39)
			if(AC[0] == 0) begin
				left = 0;
				PC = MAR - 1;
				jumpright = 1;
			end
		end		
	end
end

endmodule


`timescale 1ns/1ps

module test;			//Testbench

	reg clk;
	wire endit;
	
	main Implementation(clk, endit);
	
	initial begin
	
	$dumpfile("Output.vcd");
	$dumpvars(0, test);
		
	clk = 1; 
	
	end
	
	always begin
		#5 clk = ~clk;	
		if(endit == 1)
			$finish;	
	end
	
endmodule
