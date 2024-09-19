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
        //sync sdut (int_osc, rows, sync_rows);
        //keypad inst1 (int_osc, reset, sync_rows, cols, val1, val2);
		 keypad inst1 (int_osc, reset, rows, cols, val1, val2);
        multiplexedSevenSeg inst2 (val2, val1, int_osc, reset, segments, power2, power1);

endmodule

module keypad (
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
        parameter S11 = 5'b11111;

        // Will use these as helpers when we enter debouncing stage
        logic [3:0] initialRows;
        logic [3:0] initialCols;
        logic [8:0] counter;
        logic [8:0] noKeyCounter;
        logic valid;


        // State register
        always_ff @(posedge clk)
                if (reset == 0) begin
                        state <= S0;
                end else state <= nextState;

        // State transition logic
        always_comb
                case (state)
                        S0: nextState <= S1;
                        S1: if (rows == 4'b1111) nextState <= S2;
                                else nextState <= S8;
                        S2: nextState <= S3;
                        S3: if (rows == 4'b1111) nextState <= S4;
                                else nextState <= S8;
                        S4: nextState <= S5;
                        S5: if (rows == 4'b1111) nextState <= S6;
                                else nextState <= S8;
                        S6: nextState <= S7;
                        S7: if (rows == 4'b1111) nextState <= S0;
                                else nextState <= S8;
                        S8: if (rows == 4'b1110 || rows == 4'b1101 || rows == 4'b1011 || rows == 4'b0111) nextState <= S11;
                                else nextState <= S0;
                        S11: nextState <= S9;
                        S9: if (noKeyCounter == 9'b111111111 && valid) nextState <= S10;
                                else if (noKeyCounter == 9'b111111111 && !valid) nextState <= S0;
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
                        // Use S8 to initialize debouncing helper values
                        S8: begin
                                counter <= 0;
                                noKeyCounter <= 0;
                                initialRows <= rows;
                                initialCols <= cols;
                                valid <= 0;
                        end
                        // Debounce the input
                        S9: begin
                                if (rows == initialRows && cols == initialCols) begin // Realistically cols can't change at this point, but check anyways to be safe
                                        noKeyCounter <= 0;
                                        if (counter == 9'b111111111) begin
                                                if (!valid) begin
                                                        valid <= 1;
                                                end
                                                counter <= counter;
                                        end else counter <= counter + 1;
                                end else begin
                                        if (noKeyCounter < 9'b111111111 && rows == 4'b1111) noKeyCounter <= noKeyCounter + 1;
                                        else noKeyCounter <= 0;
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

//module sync (
//        input logic clk,
  //      input logic [3:0] rows,
     //   output logic [3:0] synch_rows
//);
//        logic [3:0] n1;

//      always_ff @(posedge clk)
//        begin
         //n1 <= rows;
         //synch_rows <= n1;
//		 synch_rows <= rows;
  //      end
//endmodule

module sevenSeg (
        input logic [3:0] S,
        output logic [6:0] segments
);
        always_comb begin
                case (S)
                        4'b0000: segments = 7'b0000001;
						4'b0001: segments = 7'b1001111;
						4'b0010: segments = 7'b0010010;
						4'b0011: segments = 7'b0000110;
						4'b0100: segments = 7'b1001100;
						4'b0101: segments = 7'b0100100;
						4'b0110: segments = 7'b0100000;
						4'b0111: segments = 7'b0001111;
						4'b1000: segments = 7'b0000000;
						4'b1001: segments = 7'b0000100;
						4'b1010: segments = 7'b0001000;
						4'b1011: segments = 7'b1100000;
						4'b1100: segments = 7'b0110001;
						4'b1101: segments = 7'b1000010;
						4'b1110: segments = 7'b0110000;
						4'b1111: segments = 7'b0111000;
                endcase
        end
endmodule

// Module to multiplex 2 7-segment displays using the sevenSeg module above
module multiplexedSevenSeg (
    input logic [3:0] S1,
    input logic [3:0] S2,
        input logic int_osc,

    input logic reset,

    output logic [6:0] segments,

    output logic power1,
    output logic power2
);

        // Use LSOSC help switch power back and forth between the 2 displays
		logic [12:0] counter;

        logic [3:0] S;

    sevenSeg seg1 (S, segments); // Instantiate seg1

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