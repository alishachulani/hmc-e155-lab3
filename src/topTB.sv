
// Testbench module to test top module
module topTB();

        logic reset;
        logic [3:0] rows;
        logic [3:0] cols;
        logic [6:0] segments;
        logic power1;
        logic power2;


        top2 dut (reset, rows, cols, segments, power1, power2);

        initial begin
                rows <= 4'b1111;
                reset <= 0; #1000
                reset <= 1;
                #1000000;
                rows <= 4'b1110; #60000000;
                rows <= 4'b1111; #60000000;
                rows <= 4'b1011; #60000000;
                rows <= 4'b1111; #80000000;
                rows <= 4'b0111; #60000000;
                rows <= 4'b1111; #60000000;
                rows <= 4'b0111; #60000000;
                rows <= 4'b1111; #60000000;
                rows <= 4'b1101; #60000000;
                rows <= 4'b1111; #60000000;
                rows <= 4'b1011; #60000000;
                rows <= 4'b1111; #60000000;
                rows <= 4'b1011; #60000000;
                rows <= 4'b1111; #60000000;
                $stop;
        end
endmodule
