module main(
input gclk,
input rstn,
input [15:0]spi_data_out,
input done,
input ct1,
input out3,
input out4,
output reg burst_en,//发射脉冲次数
output reg ct);



//芯片状态位
reg [15:0] DATA_FROM_SPI;
reg [1:0] DEV_STATE;
reg TUSS_READY;

//三个错误标志位
reg PULSE_NUM_FLT,DRV_PULSE_FLT,EE_CRC_FLT;
////检测物体标志位
reg FINISH;




//判断接收到的信息
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DATA_FROM_SPI<='b0;
	else
		DATA_FROM_SPI<=spi_data_out;
end


always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		TUSS_READY<='b0;
//	else if((DATA_FROM_SPI[14]=='b1)&&DATA_FROM_SPI[10:9]=='b11)
	else if(1)
		TUSS_READY<='b1;
end
	
	
//检测逻辑
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		burst_en<='b0;
	else if(TUSS_READY)
		burst_en<='b1;
	else
		burst_en<='b0;
		
end



	
endmodule
//芯片配置
	//从SPI模块收发数据        								ps：每帧数据发送前tx_en都要先拉低再拉高；弄清各个寄存器的配置值，SPI各位的值
	//根据从SPI模块返回的信息判断芯片是否准备就绪 		ps：VDRV电压以及芯片的模式


//物体检测
	//在芯片准备就绪后io1/io2控制产生脉冲 					ps:通过SPI的2、3、4位检测错误，如果检测到错误则重新发送
	//根据OUT3,OUT4返回的信息判断本次是否检测到物体  	ps:OUT3作用在于增加稳定性
	//确认检测到物体后，通过CT控制LED灯亮					ps:检测逻辑 
	//亮灯反馈信号CT1进行计数

