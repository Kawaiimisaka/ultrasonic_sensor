module main(
input gclk,
input rstn,
input tuss_ready,
input ct1,
input out_3,
input out_4,
input burst_finish,
output reg burst_en,
output reg burst_rstn,//发射脉冲次数
output wire ct,
output wire ct2
);



//芯片状态位
reg [1:0] DEV_STATE;
//三个错误标志位
reg PULSE_NUM_FLT,DRV_PULSE_FLT,EE_CRC_FLT;

//检测计数
reg [5:0]DETECTED_NUM;
//out_4信号会持续，但只需发出一个脉宽的DETECTED
reg [7:0]DETECTED_CNT;

//检测物体
reg DETECTED;
reg DETECT_EN;
reg DETECTED_STATE;
//记录脉冲波发送次数
reg [7:0]i;
//检测模式保持时间
reg [19:0] DELAY_CNT;
`define DELAY_TIME 'd43000//每次发射脉冲的间隔，一定要大于发波时间+反射时间
//发送脉冲次数
`define PUSE_GENERATION_TIMES 'd10

//检测次数的阈值
`define DETECTED_NUM_THRESHOLD 'd3
//状态
reg [1:0]state;
parameter BURST_STATE = 'b0;
parameter LISTEN_STATE ='b1;

	
//发出脉冲与检测策略
//状态机
always @(posedge gclk or negedge rstn)
begin
	if (~rstn)
	begin
		DETECT_EN<='b0;
		state<=LISTEN_STATE;
		burst_en<='b0;
	end		
	else if (tuss_ready)
	begin
		case(state)
			BURST_STATE:
			begin
				burst_en<='b1;
				state<=LISTEN_STATE;
			end
			
			LISTEN_STATE:
			begin
				if(burst_finish)
					burst_en<='b0;
				//延时300us，等待脉冲发射完成,在10cm临界点后进行检测。可设置最短检测距离
				if(DELAY_CNT=='d17000)
				begin
					DETECT_EN<='b1;
				end
				//延时1300us转换状态
				if(DELAY_CNT==`DELAY_TIME)
				begin
					state<=BURST_STATE;
					DETECT_EN<='b0;
				end
			end	
		endcase
	end
end

//周期计数
always @(posedge gclk or negedge rstn)
if (~rstn)
	i<='d0;
else if(i==`PUSE_GENERATION_TIMES)
	i<='d0;
else if(burst_finish)
	i<=i+'d1;



//产生检测计时位
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DELAY_CNT<='b0;
	else if (DELAY_CNT==`DELAY_TIME)
		DELAY_CNT<='d0;
	else if(state==LISTEN_STATE)
		DELAY_CNT<=DELAY_CNT+'d1;

end	



//脉冲程序复位，等待下一次burst_en
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		burst_rstn<='b1;
	else if (burst_finish)
		burst_rstn<='b0;
	else  	
		burst_rstn<='b1;
end	
	
	

//out_4触发计数	
////对本次返回的脉冲进行检测,一次波只能加一次
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DETECTED_CNT<='b0;
	//检测使能且检测到物体	
	else if (DETECT_EN&&out_4)
		DETECTED_CNT<=DETECTED_CNT+'b1;
	else
		DETECTED_CNT<='b0;

end

always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DETECTED<='b0;
	else if(DETECTED_CNT=='b1)
		DETECTED<='b1;
	else
		DETECTED<='b0;
end

//
////检测计数
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DETECTED_NUM<='b0;
	else if(i==`PUSE_GENERATION_TIMES)//一次检测周期后置0
		DETECTED_NUM<='b0;
	else if(DETECTED)
		DETECTED_NUM<=DETECTED_NUM+'b1;

end

//检测完成后根据状态亮灯
//状态转移
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DETECTED_STATE<='b0;
	else if(i==`PUSE_GENERATION_TIMES&&DETECTED_NUM>=`DETECTED_NUM_THRESHOLD)
		DETECTED_STATE<='b1;
	else if(i==`PUSE_GENERATION_TIMES&&DETECTED_NUM<`DETECTED_NUM_THRESHOLD)
		DETECTED_STATE<='b0;

end

//芯片配置指示灯,100pin
assign ct2=tuss_ready;
//检测到位指示灯,98pin
assign ct=DETECTED_STATE;
endmodule

//芯片配置
	//从SPI模块收发数据        								ps：每帧数据发送前tx_en都要先拉低再拉高；弄清各个寄存器的配置值，SPI各位的值
	//根据从SPI模块返回的信息判断芯片是否准备就绪 		ps：VDRV电压以及芯片的模式


//物体检测
	//在芯片准备就绪后io1/io2控制产生脉冲 					ps:通过SPI的2、3、4位检测错误，如果检测到错误则重新发送
	//根据out_4,out_4返回的信息判断本次是否检测到物体  	ps:out_4作用在于增加稳定性
	//确认检测到物体后，通过ct控制LED灯亮					ps:检测逻辑 
	//亮灯反馈信号ct1进行计数