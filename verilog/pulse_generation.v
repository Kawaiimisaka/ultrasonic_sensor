//根据设置的发送次数和脉冲数来控制IO1、IO2,采用IO_MODE1
module pulse_generation(
input gclk,
input burst_en,
input rstn,
input burst_rstn,
output reg io1,
output reg io2,
output reg burst_finish);

//时钟分频
reg [7:0]IO2_CNT;
reg [7:0]IO2_FLAG='d45;
//脉冲控制
reg BURST_DIS;
//记录当前发出的脉冲数
reg [4:0]pulse_num;
//脉冲数
`define PULSE_NUM 5'b00100

//io2使能失能控制位
always @(posedge gclk or negedge rstn or negedge burst_rstn)
begin
	if(~rstn||~burst_rstn)
		io1<='b1;
		//两个if不能调换位置，放前面的优先级高，dis放前面可以覆盖掉en的信号，此时io1为1
	else if(BURST_DIS)
		io1<='b1;
	else if(burst_en)
		io1<='b0;	
end

//产生指定脉冲数300khz的io2，gclk=27Mhz
always @(posedge gclk or negedge rstn or negedge burst_rstn)
begin
	if(~rstn||~burst_rstn)
		IO2_CNT<=0;
	else if(IO2_CNT==IO2_FLAG)
		IO2_CNT<='d0;
	else if(~io1)
		IO2_CNT<=IO2_CNT+'d1;	
end

always @(posedge gclk or negedge rstn or negedge burst_rstn)
begin
	if(~rstn||~burst_rstn)
		io2<='b1;
	else if(pulse_num==(`PULSE_NUM)+'b1)//发出指定脉冲数后，io2拉高,end of burst
		io2<='b1;
	else if(IO2_CNT==IO2_FLAG)
		io2<=~io2;
end



//当前脉冲数,下降沿计数
always @(negedge io2 or negedge rstn or negedge burst_rstn)
begin
	if(~rstn||~burst_rstn)
		pulse_num<='b0;
	else if(burst_en&&~BURST_DIS)//只有在产生脉冲时才对下降沿计数
		pulse_num<=pulse_num+'b1;
		
end

//停止计数
always @(negedge io2 or negedge rstn or negedge burst_rstn)
begin
	if(~rstn||~burst_rstn)
		BURST_DIS<='b0;
	else if (pulse_num==(`PULSE_NUM))
		BURST_DIS<='b1;
	else
		BURST_DIS<='b0;

end

//脉冲停止标志位，发给main作为检测触发信号
always @(posedge gclk or negedge rstn or negedge burst_rstn)
begin
	if(~rstn||~burst_rstn)
		burst_finish<='b0;
	else if(BURST_DIS)
		burst_finish<='b1;
	else
		burst_finish<='b0;
end




endmodule