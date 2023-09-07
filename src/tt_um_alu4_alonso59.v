module tt_um_alu4_alonso59 (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches for clk_selector and pattern_sel
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 LEDs
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled, not used circuit can be turned off when pattern_sel = 0
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
assign uio_out = 0;
assign uio_oe = 0;
assign uo_out[7:5] = 0;
    
pwm DUT(
	.clk(clk),
	.resetn(rst_n),
	.duty_cycle(ui_in[3:0]),
	.pwm_out(uo_out[0])
);

	ALU_4bit alu1(.Out(uo_out[4:1]), .Z(out_out[5]), .C(ui_in[6]), .A(ui_in[7:4]), .B(ui_in[7:4]), .Opcode(ui_in[3:0]));
endmodule

module Shifter(shift_out, A, B, Opcode);

	output [3:0] shift_out;
	input [3:0] A, B, Opcode;
	wire [3:0] left_shift, right_shift;
	
	assign left_shift = B << A[1:0];
	assign right_shift = B >> A[1:0];
	
	assign shift_out = (Opcode == 4'b0000) ? left_shift 
							:(Opcode == 4'b0001) ? left_shift
							:(Opcode == 4'b0010) ? right_shift
							:(Opcode == 4'b0011) ? ({B[3], right_shift[2:0]})
							: 4'b0000;

endmodule

module ALU_4bit(Out, Z, C, A, B, Opcode);

	input [3:0] A, B, Opcode;
	output Z, C, V, P;
	output [3:0] Out;
	wire temp_C, temp_V;
	wire [3:0] shift_out, arith_out, comp_out, logical_out;

	Shifter s(shift_out, A, B, Opcode);
	Arithmetic a(arith_out, temp_C, temp_V, A, B, Opcode);
	Comparator c(comp_out, A, B, Opcode);
	Logical l(logical_out, A, B, Opcode);
	
	MUX m(Out, shift_out, arith_out, logical_out, comp_out, Opcode);
	
	assign C = (Opcode > 3 && Opcode < 8) ? temp_C
				: 1'b0;
	
	assign Z = (Out[3] == 0) & (Out[2] == 0) & (Out[1] == 0) & (Out[0] == 0);
	
endmodule

module Comparator(comp_out, A, B, Opcode);

	input [3:0] A, B, Opcode;
	output [3:0] comp_out;
	wire AeB, AnB, AgB, AlB;
	
	assign AeB = (A == B);
	assign AnB = (A != B);
	
	assign comp_out = (Opcode == 4'b1100) ? {3'b000, AeB}
						 : (Opcode == 4'b1101) ? {3'b000, AnB}
						 : (Opcode == 4'b1110) ? {3'b000, ($signed(A) > $signed(B))}
						 : (Opcode == 4'b1111) ? {3'b000, ($signed(A) < $signed(B))}
						 : 4'b0000;
	
endmodule

module Logical(logical_out, A, B, Opcode);

	output [3:0] logical_out;
	input [3:0] A, B, Opcode;

	assign logical_out = (Opcode == 4'b1000) ? (A & B)
							 : (Opcode == 4'b1001) ? (A | B)
							 : (Opcode == 4'b1010) ? (A ^ B)
							 : (Opcode == 4'b1011) ? ~(A | B)
							 : 4'b0000;

endmodule

module Arithmetic(arith_out, C, V, A, B, Opcode);

	input [3:0] A, B, Opcode;
	output [3:0] arith_out;
	output C, V;
	wire [3:0] sum1, sum2, sum3, sum4, temp_C, temp_V;
	
	add_sub_4bit a1(sum1, temp_C[0], temp_V[0], A, B, 1'b0);
	add_sub_4bit a2(sum2, temp_C[1], temp_V[1], A, 4'b0001, 1'b0);
	add_sub_4bit a3(sum3, temp_C[2], temp_V[2], A, B, 1'b1);
	add_sub_4bit a4(sum4, temp_C[3], temp_V[3], A, 4'b0001, 1'b1);

	assign arith_out = (Opcode == 4'b0100) ? sum1
						  : (Opcode == 4'b0101) ? sum2
						  : (Opcode == 4'b0110) ? sum3
						  : (Opcode == 4'b0111) ? sum4
						  : 4'b0000;
						  
	assign C = (Opcode == 4'b0100) ? temp_C[0]
						  : (Opcode == 4'b0101) ? temp_C[1]
						  : (Opcode == 4'b0110) ? temp_C[2]
						  : (Opcode == 4'b0111) ? temp_C[3]
						  : 1'b0;
						  
	assign V = (Opcode == 4'b0100) ? temp_V[0]
						  : (Opcode == 4'b0101) ? temp_V[1]
						  : (Opcode == 4'b0110) ? temp_V[2]
						  : (Opcode == 4'b0111) ? temp_V[3]
						  : 1'b0;

endmodule

module add_sub_4bit(Sum, Cout, V, A, B, Operator);

	input [3:0] A, B;
	input Operator;
	output [3:0] Sum;
	output Cout, V;
	
	wire effective_B[3:0], carry_temp[2:0];
	
	assign effective_B[0] = B[0] ^ Operator;
	assign effective_B[1] = B[1] ^ Operator;
	assign effective_B[2] = B[2] ^ Operator;
	assign effective_B[3] = B[3] ^ Operator;

	full_adder fa1(Sum[0], carry_temp[0], A[0], effective_B[0], Operator);
	full_adder fa2(Sum[1], carry_temp[1], A[1], effective_B[1], carry_temp[0]);
	full_adder fa3(Sum[2], carry_temp[2], A[2], effective_B[2], carry_temp[1]);
	full_adder fa4(Sum[3], Cout, A[3], effective_B[3], carry_temp[2]);

	assign V = carry_temp[2] ^ Cout;

endmodule

module full_adder(Sum, Cout, A, B, Cin);

	input A, B, Cin;
	output Sum, Cout;

	assign {Cout, Sum} = A + B + Cin;

endmodule

module pwm(
	input wire clk,
	input wire resetn,
	input wire [3:0] duty_cycle,
	output reg pwm_out
);

	reg [3:0] count;

always@(posedge clk or negedge resetn)
begin
	if (!resetn) count <= 4'b0000;
	else if (count <=4'hf) count <= count + 1'b1;
	else count <= 4'b0000;
end

assign pwm_out = (count <= duty_cycle) ? 1:0;

endmodule 
