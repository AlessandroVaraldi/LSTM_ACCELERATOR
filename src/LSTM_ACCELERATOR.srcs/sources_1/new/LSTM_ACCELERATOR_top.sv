module LSTM_ACCELERATOR_top (
    input  logic clk,               // Porta per il clock
    input  logic rst,               // Porta per il reset
    input  logic start,             // Segnale di start
    input  logic [4:0] data_x[31:0], // Array di input
    output logic [31:0] outp,        // Array di output
    output logic ready               // Segnale di stato pronto
);

    // Istanza del modulo LSTM_ACCELERATOR
    LSTM_ACCELERATOR #(
        .inputs(5), 
        .cells(3), 
        .n(5), 
        .p(24)
    ) uut (
        .clk(clk), 
        .rst(rst), 
        .start(start), 
        .data_x(data_x), 
        .ready(ready),
        .outp(outp)
    );

endmodule
