module ultrasonic_sensor3_1

(
input out3,
input out4,
input ct1,
input gclk,
input rstn,
input miso,
output ct,
output mosi,
output sclk,
output nss,
output io1,
output io2);

main m1(
.gclk (gclk),
.rstn (rstn),
.spi_data_out (spi_data_out),
.burst_en (burst_en)
//.ct (ct),
//.ct1 (ct1),
//.out3 (out3),
//.out4 (out4)

);

spi m2(
.gclk (gclk),
.rstn (rstn),
.spi_data_out (spi_data_out),
.mosi (mosi),
.miso (miso),
.sclk (sclk),
.nss (nss)
);



pulse_generation m3(
.gclk (gclk),
.rstn (rstn),
.burst_en (burst_en),
.io1 (io1),
.io2 (io2)
);




//芯片配置
	//从SPI模块收发数据        								ps：每帧数据发送前nss都要先拉低再拉高；弄清各个寄存器的配置值，SPI各位的值
	//根据从SPI模块返回的信息判断芯片是否准备就绪 		ps：VDRV电压以及芯片的模式


//物体检测
	//在芯片准备就绪后io1/io2控制产生脉冲 					ps:通过SPI的2、3、4位检测错误，如果检测到错误则重新发送
	//根据OUT3,OUT4返回的信息判断本次是否检测到物体  	ps:OUT3作用在于增加稳定性
	//确认检测到物体后，通过CT控制LED灯亮					ps:检测逻辑 
	//亮灯反馈信号CT1进行计数

endmodule