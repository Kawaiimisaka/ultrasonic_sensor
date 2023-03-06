module ultrasonic_sensor3_1
//修改端口后记得例化！！！
(
input out_3,
input out_4,
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
.burst_en (burst_en),
.burst_rstn(burst_rstn),
.burst_finish(burst_finish),
.tuss_ready(tuss_ready),
.out_3(out_3),
.out_4(oout_4),
//.detect_en(detect_en),
//.detected(detected),
.ct (ct),
.ct1 (ct1)

);

spi m2(
.gclk (gclk),
.rstn (rstn),
.tuss_ready(tuss_ready),
.mosi (mosi),
.miso (miso),
.sclk (sclk),
.nss (nss)
);



pulse_generation m3(
.gclk (gclk),
.rstn (rstn),
.burst_en (burst_en),
.burst_finish(burst_finish),
.burst_rstn(burst_rstn),
.io1 (io1),
.io2 (io2)
);



//detection m4(
//.gclk(gclk),
//.rstn(rstn),
//.out_3(out_3),
//.out_4(out_4),
//.detect_en(detect_en),
//.detected(detected)
//);




//芯片配置
	//从SPI模块收发数据        								ps：每帧数据发送前nss都要先拉低再拉高；弄清各个寄存器的配置值，SPI各位的值
	//根据从SPI模块返回的信息判断芯片是否准备就绪 		ps：VDRV电压以及芯片的模式


//物体检测
	//在芯片准备就绪后io1/io2控制产生脉冲 					ps:通过SPI的2、3、4位检测错误，如果检测到错误则重新发送
	//根据out_3,out_4返回的信息判断本次是否检测到物体  	ps:out_3作用在于增加稳定性
	//确认检测到物体后，通过CT控制LED灯亮					ps:检测逻辑 
	//亮灯反馈信号CT1进行计数

endmodule