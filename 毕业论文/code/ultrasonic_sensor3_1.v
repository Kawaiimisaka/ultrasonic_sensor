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

detected_count m4(
.gclk (gclk),
.rstn (rstn),
.ct1(ct1)
);
endmodule