module spi(
input gclk,
input rstn,
input miso,
output reg sclk,
output reg nss,
output reg mosi,
output reg tuss_ready);

//生成时钟
reg [4:0] SCLK_CNT;
reg [4:0] SCLK_FLAG=5'b00010; 
//线性序列机
reg DONE;
reg [5:0] CNT;
reg WORK;
	//发送数据缓存
reg [14:0]DATA_IN_BUF;
	//接收数据缓存
reg [15:0]DATA_OUT_BUF;
	//发送帧数标志位
reg [4:0]SPI_CNT;
	//移位寄存器
reg [15:0] DATA_SHIFT;
//用于将DONE复位,根据时钟来调整DONG_CNT位数，CNT到达19前，DONG_CNT不能溢出
reg [4:0]DONE_CNT;

//芯片配置数据
reg [15:0]DATA_TO_TUSS;
////脉冲数
`define PULSE_NUM 5'b00100
//SPI读写模式，1为读，0为写
`define MODE 'b0

	//向TUSS发送接收信息
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DATA_IN_BUF=15'b0;
	case(SPI_CNT)
		0:begin
			DATA_IN_BUF<=15'b010000_1_00100101;//0x10,0x25;BPF_HPF_FREQ配置为300khz
			end
		1:begin
			DATA_IN_BUF<=15'b010001_1_00000000;//0x11,0x00;BPF_Q_SEL，BPF_FC_TRIM
			end
	
		2:begin
			DATA_IN_BUF<=15'b010010_1_1_100_0000;//0x12,配置LOGAMP_SLOPE_ADJ=0x4,LOGAMP_INT_ADJ=0x0
			end

		3:begin
			DATA_IN_BUF<=15'b010011_1_00000001;//0x13,0x01;设置VOUT_SCALE_SEL=0;LNA Gain增益为10V；LOGAMP_DIS_FIRST；LOGAMP_DIS_LAST														
			end
		4:begin
			DATA_IN_BUF<=15'b010100_1_00000011;//0x14,0x03，设置为IO_MODE1
			end
		5:begin
			DATA_IN_BUF<=15'b010110_0_00000110;//0x15,0x06,设置vdrv—ready的电压值为6+5=11v
			end
		6:begin
			DATA_IN_BUF<=15'b010111_1_00011011;//0x17,，ECHO_INT_THR_SEL设置VOUT阈值为0.04*11+0.4=0.84V
			end
		7:begin
			DATA_IN_BUF<=15'b011000_1_11010100;//0x18,0xD4
			end
		8:begin
			DATA_IN_BUF<={10'b011010_1_000,`PULSE_NUM};//0x1A,0x08,前五位为脉冲数
			end
		9:begin
			DATA_IN_BUF<=15'b011011_1_00000000;//0x1B,0x00,进入listen模式
			end
		10:begin
			DATA_IN_BUF<=15'bzzzzzzzzzzzzzzz;end
	endcase
end
 
//发送接收信息标志位
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		SPI_CNT<='b0;
	else if(tuss_ready)
		SPI_CNT<='d10;
	//设置发送几次数据
	else if(DONE)
		SPI_CNT<=SPI_CNT+'d1;
end

//判断TUSS返回的信息
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		tuss_ready<='b0;
	else if(SPI_CNT=='d10)
		tuss_ready<='b1;
end

  
//生成时钟
//SCLK_CNT用于时钟分频
always@(posedge gclk or negedge rstn)
begin
  if(~rstn)
    SCLK_CNT <= 'b0;
  else if(SCLK_CNT == SCLK_FLAG)
    SCLK_CNT <= 'b0;
  else
    SCLK_CNT <= SCLK_CNT + 'b1; 
end
	 
always@(posedge gclk or negedge rstn)
begin
	if(~rstn)
		sclk<= 'b0;
//	else if(tuss_ready)
//		sclk<=1'bz;
	else if (SCLK_CNT == SCLK_FLAG) 
		sclk <= ~sclk;	
end
   	
//使能信号，在发送完每帧数据后拉高，开始发送先拉低,与WORK状态相反
always@(posedge gclk or negedge rstn)
   if(~rstn)
	 nss <= 'b1; 
	else if(WORK)
    nss <= 'b0;
	else
	 nss <= 'b1;
	 

	 
//线性序列机，根据时序发送、接收数据
//CNT+1说明完成一次发送接收
always@(posedge sclk or negedge rstn)
	if(~rstn)
		CNT <= 'b0;
	else if(WORK)
		CNT <= CNT + 'b1;
	else 
		CNT<='b0;
	
//发出一个脉宽的DONE信号	
always@(posedge gclk or negedge rstn)
begin
  if(~rstn)	
		DONE<='b0;
	else if (DONE_CNT==1)
		DONE<='b1;
	else if (DONE_CNT==2)
		DONE<='b0;
	else
		DONE<='b0;
end

//DONE复位程序，解决sclk与gclk之间的逻辑问题,DONE_CNT由gclk驱动，CNT由sclk驱动
always@(posedge gclk or negedge rstn)
begin
  if(~rstn)	
		DONE_CNT<='b0;
		//根据时钟来调整DONG_CNT位数，CNT到达19前，DONG_CNT不能溢出
	else if (CNT==17)
		DONE_CNT<=DONE_CNT+'b1;
	else
		DONE_CNT<='b0;

end

//WORK控制程序		
always@(posedge gclk or negedge rstn)
begin
  if(~rstn)	
		WORK<='b0;
	else if (CNT==17)
		WORK<='b0;
	else 
		WORK<='b1;

end			
	
//上升沿发送数据,下降沿接收数据
always@(posedge sclk or negedge rstn)begin
if(~rstn)begin
	DATA_SHIFT <= 'b0;
	DATA_OUT_BUF<='b0;
	mosi <= 'bz;
end
else if(WORK&&~DONE) 
begin
	case(CNT)
	0:begin 
		DATA_SHIFT <= DATA_IN_BUF; 
		DATA_OUT_BUF<='bz;
		//		  R/W选择
		if (tuss_ready)
			mosi<=1'bz;
		else
			mosi <= `MODE;
		end
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15:begin 
		mosi <= DATA_SHIFT[14];
		DATA_SHIFT<={DATA_SHIFT[13:0],miso};end
	16:begin
		mosi<=1'bz;
//		mosi<='b1;
		DATA_OUT_BUF<=DATA_SHIFT;end
	default : begin
		DATA_SHIFT <= 'b0;
		mosi <= 1'bz;
//		mosi <= 'b1;
		end 
	endcase
end
end
endmodule