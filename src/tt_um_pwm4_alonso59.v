module tt_um_pwm4_alonso59 (
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
    
pwm DUT(
	.clk(clk),
	.resetn(rst_n),
	.duty_cycle(ui_in[3:0]),
	.pwm_out(uo_out)
);

endmodule

module pwm(
	input clk,
	input resetn,
	input [3:0] duty_cycle,
	output pwm_out
);

reg [3:0]count;

always@(posedge clk or negedge resetn)
begin
	if (!resetn) count <= 4'b0000;
	else if (count <=4'hf) count <= count + 1'b1;
	else count <= 4'b0000;
end

assign pwm_out = (count <= duty_cycle) ? 1:0;

endmodule 
