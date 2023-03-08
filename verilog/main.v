`timescale 1 ns/ 1 ns
module main(
input gclk,
input rstn,
input tuss_ready,
input ct1,
input out_3,
input out_4,
input burst_finish,
//input detected,
//output reg detect_en,
output reg burst_en,
output reg burst_rstn,//发射脉冲次数
output reg ct
);



//芯片状态位
reg [1:0] DEV_STATE;
//三个错误标志位
reg PULSE_NUM_FLT,DRV_PULSE_FLT,EE_CRC_FLT;

//确保延时时间大于发波回波时间
`define DELAY_TIME 50000;
//检测计数
reg [6:0]DETECTED_NUM;
//out_3,out_4信号会持续，但只需发出一个脉宽的detected
reg [5:0]DETECTED_CNT;

//检测到物体
reg detected;
reg detect_en;
	
//发出脉冲与检测策略
//等待初始化完成
initial 
begin
	detect_en='b0;
	#10000;//等待TUSS就绪
	if(tuss_ready)
	begin
		repeat(250)
		begin
			detect_en='b0;
			burst_en='b1;
			#`DELAY_TIME//根据检测距离来调整延时，确保在这段延时内能完成发波回波
			detect_en='b1;
			#100;
		end
	end
end


//脉冲程序复位，等待下一次burst_en
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		burst_en<='b0;
	else if(burst_finish)
		burst_en<='b0;
end

always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		burst_rstn<='b1;
	else if (burst_finish)
		burst_rstn<='b0;
	else  	
		burst_rstn<='b1;
end	
	
	
//
////对本次返回的脉冲进行检测	
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

//
////检测计数
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DETECTED_NUM<='b0;
	else if(detected)
		DETECTED_NUM<=DETECTED_NUM+'b1;
	else if(DETECTED_NUM==5)//连续检测到五次后复位
		DETECTED_NUM<='b0;
end

//检测完成后亮灯
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		ct<='b1;
	else if(DETECTED_NUM==5)
		ct<='b0;
end
	
endmodule
//芯片配置
	//从SPI模块收发数据        								ps：每帧数据发送前tx_en都要先拉低再拉高；弄清各个寄存器的配置值，SPI各位的值
	//根据从SPI模块返回的信息判断芯片是否准备就绪 		ps：VDRV电压以及芯片的模式


//物体检测
	//在芯片准备就绪后io1/io2控制产生脉冲 					ps:通过SPI的2、3、4位检测错误，如果检测到错误则重新发送
	//根据out_3,out_4返回的信息判断本次是否检测到物体  	ps:out_3作用在于增加稳定性
	//确认检测到物体后，通过ct控制LED灯亮					ps:检测逻辑 
	//亮灯反馈信号ct1进行计数

