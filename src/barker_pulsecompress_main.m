%% 读取巴克码数据
% 构建数据所在路径
datadir = "../data/";
filename = "2021_07_31_19_32_13.dat1-1-0";
filepath = fullfile(datadir, filename);
% 读取数据
rawdatatables = readDataFromRawEcho(filepath);

%% 择取发射信息， 
% 择取码宽、脉宽、prt和fs, 单位是s 和 Mhz
[codew, pulsew, prt, fs] = readTxParameters(rawdatatables);
% 计算回波距离门范围， 单位是米
rangegates = readRangeLimits(rawdatatables);
% 构建二维雷达回波数据
rdata2 = constructRadar2D(rawdatatables);

%% 构造发射13位巴克码， 
% 采样率是fs， 码宽是codew的整us数, PRF构建为脉宽的倒数
barkercodew = pulsew/13;
barkerprf = 1 / pulsew;
barker13waveform = phased.PhaseCodedWaveform('Code','Barker',...
     'ChipWidth',barkercodew,'NumChips',13,...
     'OutputFormat','Pulses','NumPulses',1,...
     'SampleRate', fs, 'PRF', barkerprf);
barker13 = barker13waveform(); 


%% 对接收信号的快时间做匹配滤波

[rows, cols] = size(rdata2);
% 利用相控阵雷达工具箱的匹配滤波实现
bkmf = phased.MatchedFilter( ...
    'Coefficients',getMatchedFilter(barker13waveform));
rdata2pc = zeros(size(rdata2));
for i = 1:cols 
    rdata2pc(:, i) = bkmf(rdata2(:, i));
end

% 利用matlab 自带 xcorr互相关实现 
rdata2cc = zeros(size(rdata2));
for i = 1:cols 
     [m, lags] = xcorr(rdata2(:, i), barker13);
     m = m(lags>=0);
     rdata2cc(:, i) = m;
end

% 自己的fft实现
rdata2fft = zeros(size(rdata2));
for i = 1:cols 
     rdata2fft(:, i) = matchedFilter(rdata2(:, i), barker13);
end

%% 画功率剖面图, 未经过脉压
nint = 2000; % 积分时间， 慢时间脉冲数
powerprofiled = pulse_int(rdata2(:, 1:nint));
figure()
plot_powerProfile(powerprofiled, rangegates/1e3)

%% 画 RTI 图, matlab工具箱实现匹配滤波
nrti = floor(cols/nint);  % 可以积累的慢时间组数
rti2 = zeros(rows, nrti); % 用于存放经过积累的rti矩阵数据
for i = 1:nrti 
    rti2(:, i) = pulse_int(rdata2pc(:, ((i-1)*nint + 1):i*nint));
    % 积分时间是 nint
end
figure()
h = newplot;
imagesc(rti2, [0.9e7 1.8e7]);
h.YDir = 'normal';
ytickk = 0:460/7:460;
h.YTick = ytickk;
h.YTickLabel = 100:100:800;

%% 画 RTI 图, 互相关实现
nrti = floor(cols/nint);
rti2 = zeros(rows, nrti);
for i = 1:nrti 
    rti2(:, i) = pulse_int(rdata2cc(:, ((i-1)*nint + 1):i*nint));
end
figure()
h = newplot;
imagesc(rti2, [0.9e7 1.8e7]);
h.YDir = 'normal';
ytickk = 0:460/7:460;
h.YTick = ytickk;
h.YTickLabel = 100:100:800;

%% 比较脉压和未脉压的功率剖面图
figure()
plot_powerProfile(powerprofiled, rangegates/1e3)
hold on 
plot_powerProfile(rti2(:, 1)/100, rangegates/1e3)

%% 画 RTI 图, 未脉压前
nrti = floor(cols/nint);
rti2 = zeros(rows, nrti);
for i = 1:nrti 
    rti2(:, i) = pulse_int(rdata2(:, ((i-1)*nint + 1):i*nint));
end
figure()
h = newplot;
imagesc(rti2, [1.3e5 2.4e5]);
h.YDir = 'normal';
ytickk = 0:460/7:460;
h.YTick = ytickk;
h.YTickLabel = 100:100:800;

%% 画 RTI 图, 利用fft
nrti = floor(cols/nint);
rti2 = zeros(rows, nrti);
for i = 1:nrti 
    rti2(:, i) = pulse_int(rdata2fft(:, ((i-1)*nint + 1):i*nint));
end
figure()
h = newplot;
imagesc(rti2, [0.9e7 1.8e7]);
h.YDir = 'normal';
ytickk = 0:460/7:460;
h.YTick = ytickk;
h.YTickLabel = 100:100:800;


 