module detected_count(
input rstn,
input gclk,
input ct1
);
reg [10:0]DETECTED_COUNT;
always  @(posedge ct1 or negedge rstn)
begin
	if(~rstn)
		DETECTED_COUNT<='d0;
	else if(ct1)
		DETECTED_COUNT<=DETECTED_COUNT+'d1;

end
endmodule