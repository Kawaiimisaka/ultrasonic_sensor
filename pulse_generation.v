//根据设置的发送次数和脉冲数来控制IO1、IO2,采用IO_MODE1
module pulse_generation(
input gclk,
input rstn,
input burst_en,
output reg io1,
output reg io2);


//时钟分频,//T1=80*T2
reg [5:0]IO2_CNT;
reg [5:0]IO2_FLAG='b101000;
//脉冲控制
reg BURST_DIS;
//记录当前发出的脉冲数
reg [4:0]pulse_num;
//脉冲数
`define PULSE_NUM 5'b01010

//io2使能失能控制位
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		io1<='b1;
		//两个if不能调换位置，放前面的优先级高，dis放前面可以覆盖掉en的信号，此时io1为1
	else if(BURST_DIS)
		io1<='b1;
	else if(burst_en)
		io1<='b0;
	
		
end

//产生指定脉冲数300khz的io2，gclk=24Mhz
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		IO2_CNT<=0;
	else if(~io1)
		IO2_CNT<=IO2_CNT+'b1;
	else if(IO2_CNT==IO2_FLAG)
		IO2_CNT<='b0;	
end

always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		io2<='b1;
	else if(IO2_CNT==IO2_FLAG)
		io2<=~io2;
	else if(pulse_num==(`PULSE_NUM+'b1))//发出指定脉冲数后，io2拉高,end of burst
		io2<='b1;
end



//当前脉冲数,下降沿计数
always @(negedge io2 or negedge rstn)
begin
	if(~rstn)
		pulse_num<='b0;
	else if(burst_en&&~BURST_DIS)//只有在产生脉冲时才对下降沿计数
		pulse_num<=pulse_num+'b1;
		
end

//停止计数
always @(posedge io2 or negedge rstn)
begin
	if(~rstn)
		BURST_DIS<='b0;
	else if (pulse_num==(`PULSE_NUM+'b1))
		BURST_DIS<='b1;
	else
		BURST_DIS<='b0;

end








endmodule