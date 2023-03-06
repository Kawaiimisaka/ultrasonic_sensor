//检测到物体后，发出脉宽为1的detected信号
module detection(
input gclk,
input rstn,
input detect_en,
input out_3,
input out_4,
output reg detected
);

//out_3,out_4信号会持续，但只需发出一个脉宽的detected
reg [5:0]DETECTED_CNT;


always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DETECTED_CNT<='b0;
	else if (detect_en&&out_3)
		DETECTED_CNT<=DETECTED_CNT+'b1;
	else
		DETECTED_CNT<='b0;

end

always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		detected<='b0;
	else if(DETECTED_CNT=='b1)
		detected<='b1;
	else
		detected<='b0;
end

endmodule