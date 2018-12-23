


module bit_scaler(
clk,
rdy_in,
akn_out,
rdy_out,
akn_in,
request,
time_output
);

//-------- Input ----------------
input       clk               ;
input       rdy_in            ;
input       akn_in            ;
input       [7:0]request      ;//requested pulse width

//-------- Outputs --------------
output reg  rdy_out           ;
output reg  akn_out           ;
output reg  [31:0]time_output ;// calculated time for the requested pulse width

//-------- Local Variables ------
reg         [1:0] state       ;// state for state machine
reg         [31:0]data        ;

localparam WAIT = 2'b00, SAVE = 2'b01, MULTIPLY = 2'b10, SEND = 2'b11;

parameter NUMERATOR = 32'HABE0, DENOMINATOR = 32'hFF, OFFSET = 32'HD0FC;


//-------- Initialize ---------
initial begin
  state = WAIT               ;
  data <= 32'b0              ;
  rdy_out <= 1'b0            ;
  akn_out <= 1'b0            ;
  time_output <= 32'b0       ;
end

always@(posedge clk)begin
  case(state)
    WAIT: begin
      if(rdy_in)begin
        data[7:0] <= request;
        state <= SAVE;
        time_output <= 32'b0;
        akn_out <= 1'b1; 
      end
    end

    SAVE: begin
       akn_out <= 1'b1;
      if(~rdy_in)begin
        akn_out <= 1'b0;
        state <= MULTIPLY;
      end
    end

    MULTIPLY: begin
      // Y = M * X + B
      time_output <= NUMERATOR * data / DENOMINATOR  + OFFSET;
      state <= SEND;
    end

    SEND: begin
      rdy_out <= 1'b1;
      if(akn_in)begin
        rdy_out <= 1'b0;
        state <= WAIT;
      end
    end

    default begin
      state <= WAIT;
    end

  endcase

end

endmodule 