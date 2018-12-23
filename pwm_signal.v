module pwm_signal(
clk,
pulse_request,
pwm_out,
new_data_ready,
data_recieved,
tap
);

//-------------- inputs ----------------
input           clk                       ;// Clock
input     [31:0]pulse_request             ;// PWM request signal
input           new_data_ready            ;// Signal to set new Values

//-------------- outputs ---------------
output reg      pwm_out                   ;// PWM Output
output reg      data_recieved             ;// AKN for data recieved
output reg      [7:0]tap                  ;
//-------------- Local Variables -------
reg       [31:0]pulse_length              ;// 
reg       [31:0]_time                     ;// cycle timer
//                            1.1ms                        1.95ms               22ms
//parameter MIN_PULSE_LENGTH = 32'hEA60, MAX_PULSE_LENGTH = 32'h17318,  FRAME = 32'h10C8E0; 

parameter MIN_PULSE_LENGTH = 32'HD0FC, MAX_PULSE_LENGTH = 32'h17CDC,  FRAME = 32'h10C8E0; 

//-------------- Initialize ------------
initial begin
  // cycles = time_ms * 50 * 10^3
  pulse_length      <= MIN_PULSE_LENGTH    ;
  pwm_out           <= 1'b0                ;// output from the module
  _time             <= 32'h0               ;// The timer
  data_recieved     <= 1'b0                ;
  tap               <= MIN_PULSE_LENGTH    ;
end


//-------------- Algorithm ------------

always@(posedge clk)begin
  if(new_data_ready)begin
    if(pulse_request >= MAX_PULSE_LENGTH) begin
      pulse_length <= MAX_PULSE_LENGTH;	
    end else if(pulse_request < MIN_PULSE_LENGTH) begin
      pulse_length <= MIN_PULSE_LENGTH;	
    end else begin
      pulse_length <= pulse_request;	
    end
    data_recieved  <= 1'b1;
	 tap            <= pulse_length[7:0];
  end else begin
    data_recieved  <= 1'b0; 
  end
end

always@(posedge clk)begin
  _time = _time + 1'b1;
  if(_time >= FRAME)begin
    _time    <= 31'h0;
    pwm_out  <= 1'b1;
  end else if(_time >= pulse_length) begin
     pwm_out <= 1'b0;
  end
end

// Get new data;
endmodule 