/* 
Service Drive is a top level module.

	servo_driver
		|----> bit_scaler
		|----> pwm_signal


sever_driver is a smaller part of a larger system.
sever_driver as a local_address parameter to specifically identify which servo to control.

pulse_request and addr should be ready at the input before asserting rdy_in.
Pulse request should be 0-255 (0x00-0xFF) which will set the pwm pulse width.
The PMW signal can be customized by setting the MIN_PULSE_LENGTH, MAX_PULSE_LENGTH and FRAME parameters.
These parameters are the number of clock cycles that will occur since the start of frame.

The bit_scaler modules takes the 8 bit pulse_request (0x00-0xFF) and converts it to a time boundary for pwm_signal module
which is basically the time at which the signal will transition from high to low.

*/



module servo_driver(
clk,
pulse_request,
pwm_out,
rdy_in,
akn_in_out,
addr,
tap
);

//-------------- inputs ----------------
input           clk                          ;// Clock
input      [7:0]pulse_request                ;// PWM request signal
input           rdy_in                       ;// Signal to set new Values
input      [7:0]addr                         ;
//-------------- outputs ---------------
output          pwm_out                      ;// PWM Output
inout           akn_in_out                   ;// AKN for data recieved
output     [7:0]tap                          ;
//-------------- Local Variables -------

reg               go                         ;
reg               bs_rdy                     ;
wire              bs_akn                     ;
reg          [1:0]state                      ;
reg               local_akn                  ;
wire              pwm_rdy                    ;
wire              pwm_akn                    ;
wire        [31:0]data                       ;

localparam WAIT = 2'H0, SEND_DATA = 2'H1, SEND_AKN = 2'H2;

parameter LOCAL_ADDR = 8'H1          ;
//	PWM Signal Parameters 


// 									Bases on a 50mHz clock signal (500000*ms)
//                            1.1ms                        1.95ms               22ms
parameter MIN_PULSE_LENGTH = 32'HD0FC, MAX_PULSE_LENGTH = 32'h17CDC,  FRAME = 32'h10C8E0;



//	Bit Scaler Parameters
// The input should be 0-255 (0x00-0xFF)
parameter NUMERATOR = (MAX_PULSE_LENGTH - MIN_PULSE_LENGTH), DENOMINATOR = 32'hFF, OFFSET = MIN_PULSE_LENGTH;
//-------------- Initialize ------------
initial begin
  local_akn      <= 1'B0                    ;
  bs_rdy         <= 1'B0                    ;
  state          <= WAIT;
end

assign akn_in_out = (local_akn) ? 1'B1 : 1'BZ;

bit_scaler #(.NUMERATOR(NUMERATOR),.DENOMINATOR(DENOMINATOR),.OFFSET(OFFSET)) bs (
clk,
bs_rdy, 	
bs_akn,	
pwm_rdy,        
pwm_akn,         
pulse_request,        
data    
);


pwm_signal #(.MIN_PULSE_LENGTH(MIN_PULSE_LENGTH), .MAX_PULSE_LENGTH(MAX_PULSE_LENGTH), .FRAME(FRAME)) PWM1(
clk,
data,  
pwm_out,        
pwm_rdy, 
pwm_akn,
tap  
);
//-------------- Algorithm ------------

always@(posedge clk)begin
  case(state)
    WAIT:begin
      if(rdy_in && (addr == LOCAL_ADDR))begin
        bs_rdy = 1'B1;
        state <= SEND_DATA;
      end
    end SEND_DATA: begin
      if(bs_akn && ~ local_akn)begin
        bs_rdy = 1'B0;
        local_akn <= 1'B1;
        state <= SEND_AKN;
      end
    end SEND_AKN: begin
      if(~rdy_in && local_akn)begin
        state <= WAIT;
        local_akn <= 1'B0;
      end
    end default begin
      state <= WAIT;
    end
  endcase
end


// Get new data;
endmodule 