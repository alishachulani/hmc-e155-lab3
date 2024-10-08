// Module to combine keypad and multiplexedSevenSeg modules to display the 2 most recent buttons pressed on 2 7 segment displays
module top (
        input logic reset,
        input logic [3:0] rows,

        output logic [3:0] cols,
        output logic [6:0] segments,
        output logic power1,
        output logic power2
);

        logic int_osc;
    LSOSC #()
         lf_osc (.CLKLFPU(1'b1), .CLKLFEN(1'b1), .CLKLF(int_osc));

        logic [3:0] val1;
        logic [3:0] val2;
        logic [3:0] sync_rows;
        sync sdut (int_osc, rows, sync_rows);
        fsm inst1 (int_osc, reset, sync_rows, cols, val1, val2);
        multiplexer inst2 (val2, val1, int_osc, reset, segments, power2, power1);

endmodule

module fsm(
        input logic clk,
        input logic reset,
        input logic [3:0] rows,

        output logic [3:0] cols,
        output logic [3:0] val1,
        output logic [3:0] val2
);


        logic [4:0] state, nextState;

        // Define states
        parameter S0 = 5'b00000;
        parameter S1 = 5'b00001;
        parameter S2 = 5'b00010;
        parameter S3 = 5'b00011;
        parameter S4 = 5'b00100;
        parameter S5 = 5'b00101;
        parameter S6 = 5'b00110;
        parameter S7 = 5'b00111;
        parameter S8 = 5'b01000;
        parameter S9 = 5'b01001;
        parameter S10 = 5'b01010;
        parameter S11 = 5'b01011;
        parameter S12 = 5'b01100;
        parameter S13 = 5'b01101;
        parameter S14 = 5'b01110;
        parameter S15 = 5'b01111;
		parameter S16 = 5'b10000;
		parameter S17 = 5'b10001;
		parameter S18 = 5'b10010;
		parameter S19 = 5'b10011;
		parameter S20 = 5'b10100;
		
		
		
        // Will use these as helpers when we enter debouncing stage
        logic [3:0] initialRows;
        logic [3:0] initialCols;
        logic [8:0] counterOn;
        logic [8:0] counterOff;
        logic valid;



        // State register
        always_ff @(posedge clk)
                if (reset == 0) begin
                        state <= S0;
                end else state <= nextState;

        // State transition logic
        always_comb
                case (state)
                        S0: nextState <= S12;
						S12: nextState <= S16;
                        S16: nextState <= S1;
                        S1: if (rows == 4'b1111) nextState <= S2;
                                else nextState <= S8;
                        S2: nextState <= S17;
						S17: nextState <= S13;
                        S13: nextState <= S3;
                        S3: if (rows == 4'b1111) nextState <= S4;
                                else nextState <= S8;
                        S4: nextState <= S18;
						S18: nextState <= S14;
                        S14: nextState <= S5;
                        S5: if (rows == 4'b1111) nextState <= S6;
                                else nextState <= S8;
                        S6: nextState <= S19;
						S19: nextState <= S15;
                        S15: nextState <= S7;
                        S7: if (rows == 4'b1111) nextState <= S0;
                                else nextState <= S8;
                        S8: if (rows == 4'b1110 || rows == 4'b1101 || rows == 4'b1011 || rows == 4'b0111) nextState <= S11;
                                else nextState <= S0;
                        S11: nextState <= S20;
						S20: nextState <= S9;
                        S9: if (counterOff == 9'b111111111 && valid) nextState <= S10;
                                else if (counterOff == 9'b111111111 && !valid) nextState <= S0;
                                else nextState <= S9;
                        S10: nextState <= S0;
                        default: nextState <= S0;
                endcase

         // Output logic
        always_ff @(posedge clk)
                case (state)
                        S0: cols <= 4'b1110;
                        S2: cols <= 4'b1101;
                        S4: cols <= 4'b1011;
                        S6: cols <= 4'b0111;
                        S8: begin
                                counterOn <= 0;
                                counterOff <= 0;
                                initialRows <= rows;
                                initialCols <= cols;
                                valid <= 0;
								cols <= 4'b0000;
                        end
                        // Debounce the input
                        S9: begin
                                if (rows == initialRows) begin // Realistically cols can't change at this point, but check anyways to be safe
                                        counterOff <= 0;
                                        if (counterOn == 9'b111111111) begin
                                                if (!valid) begin
                                                        valid <= 1;
                                                end
                                                counterOn <= counterOn;
                                        end else counterOn <= counterOn + 1;
                                end else begin
                                        if (counterOff < 9'b111111111 && rows == 4'b1111) counterOff <= counterOff + 1;
                                        else counterOff <= 0;
                                end
                        end
                        // Use S10 to assign new values
                        S10: begin
                                val1 <= val2;
                                case ({initialRows, initialCols})
                                        8'b11101110: val2 <= 1;
                                        8'b11101101: val2 <= 2;
                                        8'b11101011: val2 <= 3;
                                        8'b11100111: val2 <= 10;

                                        8'b11011110: val2 <= 4;
                                        8'b11011101: val2 <= 5;
                                        8'b11011011: val2 <= 6;
                                        8'b11010111: val2 <= 11;

                                        8'b10111110: val2 <= 7;
                                        8'b10111101: val2 <= 8;
                                        8'b10111011: val2 <= 9;
                                        8'b10110111: val2 <= 12;

                                        8'b01111110: val2 <= 14;
                                        8'b01111101: val2 <= 0;
                                        8'b01111011: val2 <= 15;
                                        8'b01110111: val2 <= 13;
                                        default: val2 <= val2;
                                endcase
                        end
                endcase
endmodule

module sync (
        input logic clk,
        input logic [3:0] rows,
        output logic [3:0] synch_rows
);
        logic [3:0] n1;

      always_ff @(posedge clk)
        begin
		 n1 <= rows;
		 synch_rows <= n1;
       end
endmodule

module sevenSeg (
        input logic [3:0] switch,
        output logic [6:0] seg
);
        always_comb begin
                case (switch)
                        4'b0000: seg = 7'b0000001;
						4'b0001: seg = 7'b1001111;
						4'b0010: seg = 7'b0010010;
						4'b0011: seg = 7'b0000110;
						4'b0100: seg = 7'b1001100;
						4'b0101: seg = 7'b0100100;
						4'b0110: seg = 7'b0100000;
						4'b0111: seg = 7'b0001111;
						4'b1000: seg = 7'b0000000;
						4'b1001: seg = 7'b0000100;
						4'b1010: seg = 7'b0001000;
						4'b1011: seg = 7'b1100000;
						4'b1100: seg = 7'b0110001;
						4'b1101: seg = 7'b1000010;
						4'b1110: seg = 7'b0110000;
						4'b1111: seg = 7'b0111000;
                endcase
        end
endmodule

// Module to multiplex 2 7-segment displays using the sevenSeg module above
module multiplexer(
    input logic [3:0] S1,
    input logic [3:0] S2,
    input logic int_osc,
    input logic reset,
    output logic [6:0] segments,
    output logic power1,
    output logic power2
);

		logic [12:0] counter;

        logic [3:0] S;

		sevenSeg seg (S, segments);

    always_ff @(posedge int_osc) begin
        if (reset == 0)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    // Set the power and output depending on the state of counter[6] (essentially a slower clock signal)
    always_ff @(posedge int_osc) begin
        if (counter[6] == 0) begin
            power1 <= 1;
            power2 <= 0;
            S <= S1;
        end
        else begin
            power1 <= 0;
            power2 <= 1;
            S <= S2;
        end
    end
endmodule
