function rangegates = readRangeLimits(echoWaveTables)

% 读波门前沿、宽度、并计算距离门范围
% 距离范围自其实至结束， 共接收回波宽度个采样点
c = physconst("lightspeed");
us2s = 1e-6;
toMhz = 1e6;

fs = echoWaveTables(1, "SampleRate").SampleRate * toMhz; 
wavef = echoWaveTables(1, "WaveGateFront").WaveGateFront * us2s;
wavew = echoWaveTables(1, "WaveGateWidth").WaveGateWidth; 
waveb = (wavef + (wavew-1)/fs);

rangemin = wavef * c / 2; 
rangemax = waveb * c / 2;
% 测绘带距离门范围， 单位米
rangegates = linspace(rangemin, rangemax, wavew);