%% 时域互相关

% 发射信号构建， 1s长脉冲，载波f0=10hz， 总时长15s， 采样率fs 1khz
fs = 1e3;
tmax = 15;
tt = 0:1/fs:tmax-1/fs;
f0 = 10;
T = 1;
t = 0:1/fs:T-1/fs;
pls = cos(2*pi*f0*t);

% 接收信号构建， 5s后碰到目标，每隔2s一个目标，反射系数是0.2， 随距离衰减
t0 = 5;
dt = 2*T;
lgs = t0:dt:tmax;
att = 1.1;
ref = 0.2;
rpls = pulstran(tt,[lgs;ref*att.^-(lgs-t0)]',pls,fs);
% 增加高斯白噪声， SNR 15db
SNR = 15;
r = randn(size(tt))*std(pls)/db2mag(SNR);
rplsnoise = r+rpls;

% 做互相关， 时域匹配滤波实现，只要正时延
[m,lg] = xcorr(rplsnoise, pls);
m = m(lg>=0);
tm = lg(lg>=0)/fs;

subplot(2,1,1)
plot(tt,rplsnoise,t,pls,tt,rpls)
xticks(lgs)
legend('Noisy Received','Initial Pulse','Noiseless Received')
title('Transmitted/Received Signals')
ylabel('Magnitude (L.U.)')

subplot(2,1,2)
plot(tm,abs(m))
xticks(lgs)
title('Matched Filter Output')
xlabel('Time (s)')
ylabel('Magnitude (L.U.)')

% 如果目标距离较近，引起距离模糊
dt = 1.5*T;
lgs = t0:dt:tmax;
rpls = pulstran(tt,[lgs;ref*att.^-(lgs-t0)]',pls,fs);
rplsnoise = r + rpls;
[m,lg] = xcorr(rplsnoise,pls);
m = m(lg>=0);
tm = lg(lg>=0)/fs;

subplot(2,1,1)
plot(tt,r,t,pls,tt,rpls)
xticks(lgs)
legend('Noisy Received','Initial Pulse','Noiseless Received')
title('Transmitted/Received Signals')
ylabel('Magnitude (L.U.)')

subplot(2,1,2)
plot(tm,abs(m))
xticks(lgs)
title('Matched Filter Output')
xlabel('Time (s)')
ylabel('Magnitude (L.U.)')

% 利用线性调频信号提高距离分辨， 旁瓣也更低
pls = chirp(t,0,T,f0,'complex');
rpls = pulstran(tt,[lgs;ref*att.^-(lgs-t0)]',pls,fs);
r = randn(size(tt))*std(pls)/db2mag(SNR);
rplsnoise = r + rpls;

[m,lg] = xcorr(rplsnoise,pls);
m = m(lg>=0);
tm = lg(lg>=0)/fs;

subplot(2,1,1)
plot(tt,real(r),t,real(pls),tt,real(rpls))
xticks(lgs)
legend('Noisy Received','Initial Pulse','Noiseless Received')
title('Transmitted/Received Signals')
ylabel('Magnitude (L.U.)')

subplot(2,1,2)
plot(tm,abs(m))
xticks(lgs)
title('Matched Filter Output')
xlabel('Time (s)')
ylabel('Magnitude (L.U.)')

%% 匹配滤波的频域实现， 更快， 数字域才叫匹配滤波
% 发射脉冲取反转共轭，并与补齐与接收长度一致， 时域卷积=频域相乘
% 最大值延迟脉冲T时间
pls_rev = [fliplr(pls) zeros(1, length(r) - length(pls))];
PLS = fft(conj(pls_rev));
R = fft(rplsnoise);
fft_conv = PLS.*R;
faxis = linspace(-fs/2,fs/2,length(PLS));

clf
subplot(3,1,1)
plot(faxis,abs(fftshift(PLS)))
title('FFT of Time-Reversed Transmitted Pulse')
xlim([-100 100])
ylabel('Magnitude (L.U)')

subplot(3,1,2)
plot(faxis,abs(fftshift(R)))
title('FFT of Noisy Signal')
xlim([-100 100])
ylabel('Magnitude (L.U)')

subplot(3,1,3)
plot(faxis,abs(fftshift(fft_conv)))
title("FFT of Multiplied Signals")
xlabel('Frequency (Hz)')
xlim([-100 100])
ylabel('Magnitude (L.U)')

pls_prod = ifft(fft_conv);

clf
plot((0:length(pls_prod)-1)/fs,abs(pls_prod))
xticks(lgs+T)
xlabel('Time (s)')
ylabel('Magnitude (L.U.)')
title('Matched Filter Output')

% 加窗降低旁瓣 
n = fftfilt(fliplr(conj(pls)),rplsnoise);
n_win = fftfilt(fliplr(conj(pls).*taylorwin(length(pls), 30)'),rplsnoise);

clf
plot(tt,abs(n),tt,abs(n_win))
xticks(lgs+T)
xlabel('Time (s)')
ylabel('Magnitude (L.U.)')
legend('No Window', 'Hamming Window')
title('Matched Filter Output')
