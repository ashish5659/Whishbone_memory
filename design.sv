`timescale 1ns / 1ps

interface wb_if;
    logic clk;
    logic we;
    logic strb;
    logic rst;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic  ack;
endinterface


module mem_wb(
    input clk, we, strb, rst, 
    input [7:0] addr,
    input [7:0] wdata,
    output reg [7:0] rdata,
    output reg ack 
    );

reg [7:0] mem[0:255];
reg [7:0] temp;

typedef enum bit [1:0] {idle = 0, check_mode = 1, write = 2, read = 3} state_type; 
state_type state, next_state;

//////////////////////reset decoder    
always_ff @(posedge clk) begin  
    if (rst) begin
        state <= idle;
        for (int i = 0; i < 256; i++) begin
            mem[i] <= 8'h11;
        end
    end else begin
        state <= next_state;

        if (state == write) begin
            mem[addr] <= wdata;
        end else if (state == read) begin
            temp <= mem[addr];
        end
    end
end

///////////next state and output decoder
always_comb begin
    ack = 1'b0;
    rdata = 8'h00;
    next_state = state; // Default to avoid latch

    case(state)
        idle: begin
            ack = 1'b0;
            rdata = 8'h00;
            next_state = check_mode; 
        end  

        check_mode: begin
            if (strb && we) begin
                next_state = write;
            end else if (strb && !we) begin
                next_state = read;
            end else begin
                next_state = check_mode;
            end
        end  

        write: begin
            ack = 1'b1;
            next_state = idle;
        end

        read: begin
            rdata = temp;
            ack = 1'b1;
            next_state = idle; 
        end

        default: next_state = idle;
    endcase
end 

endmodule
