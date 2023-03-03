module spi(
input gclk,
input rstn,
input miso,
output reg sclk,
output reg nss,
output reg mosi,
output reg spi_data_out);


//生成时钟
reg [4:0] SCLK_CNT;
reg [4:0] SCLK_FLAG=5'b100; 
//线性序列机
reg done;
reg [5:0] CNT;
reg WORK;
	//发送数据缓存
reg [15:0]DATA_BUF;
	//发送帧数标志位
reg [5:0]SPI_CNT;
	//移位寄存器
reg [15:0] DATA_SHIFT;
//用于将done复位,根据时钟来调整DONG_CNT位数，CNT到达19前，DONG_CNT不能溢出
reg [4:0]DONE_CNT;


//芯片配置数据
reg [15:0]DATA_TO_TUSS;
//脉冲数
`define PULSE_NUM 5'b01010
	//向TUSS发送接收信息
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		DATA_BUF=16'b0;
	case(SPI_CNT)
		0:begin
			DATA_BUF<=16'b1_010000_0_00100101;//0x10,0x25;
			end
		1:begin
			DATA_BUF<=16'b1_010001_1_00000000;//0x11,0x00
			end
	
		2:begin
			DATA_BUF<=16'b1_010010_0_10110011;//0x12,0xB3
			end

		3:begin
			DATA_BUF<=16'b1_010011_1_00000010;//0x13,0x02
			end

		4:begin
			DATA_BUF<=16'b1_010100_1_00000001;//0x14,0x01，设置为IO_MODE1
			end
		5:begin
			DATA_BUF<=16'b1_010110_0_00001111;//0x16,0x0F
			end
		6:begin
			DATA_BUF<=16'b1_010111_1_00011000;//0x17,0x18
			end
		7:begin
			DATA_BUF<=16'b1_011000_1_11010100;//0x18,0xD4
			end
		8:begin
			DATA_BUF<={11'b1_011010_1_000,`PULSE_NUM};//0x1A,0x08,前五位为脉冲数
			end
		9:begin
			DATA_BUF<=16'b1_011011_1_00000000;//0x1B,0x00,进入listen模式
			end
	default:begin
		DATA_BUF<=16'b0;end
	endcase
end


//发送接收信息标志位
always @(posedge gclk or negedge rstn)
begin
	if(~rstn)
		SPI_CNT<='b0;
	else if(done)
		SPI_CNT<=SPI_CNT+1'b1;
		
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
		
always@(posedge gclk or negedge rstn)
begin
  if(~rstn)	
		done<='b0;
	else if (DONE_CNT==1)
		done<='b1;
	else if (DONE_CNT==2)
		done<='b0;
	else
		done<='b0;

end

//done复位程序
always@(posedge gclk or negedge rstn)
begin
  if(~rstn)	
		DONE_CNT<='b0;
		//根据时钟来调整DONG_CNT位数，CNT到达19前，DONG_CNT不能溢出
	else if (CNT==18)
		DONE_CNT<=DONE_CNT+'b1;
	else
		DONE_CNT<='b0;

end



//WORK控制程序		
always@(posedge gclk or negedge rstn)
begin
  if(~rstn)	
		WORK<='b0;
	else if (CNT==18)
		WORK<='b0;
	else 
		WORK<='b1;

end		
	
	
//上升沿发送数据,下降沿接收数据
always@(posedge sclk or negedge rstn)begin
  if(~rstn)begin
    DATA_SHIFT <= 'b0;
	 spi_data_out<='b0;
	 mosi <= 'bz;
	end

  else if(WORK&&~done) 
  begin
    case(CNT)
		0:begin 
		  DATA_SHIFT <= DATA_BUF; 
		  spi_data_out<='b0;
		  mosi <= 'bz;end
      1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16:begin 
		  mosi <= DATA_SHIFT[15];
		  DATA_SHIFT<={DATA_SHIFT[14:0],miso};end
		17:begin
		  mosi <= 'bz;
		  spi_data_out<=DATA_SHIFT;end
      default : begin
	     DATA_SHIFT <= 'b0;
        mosi <= 'bz;end 
	   endcase
	end
end




endmodule