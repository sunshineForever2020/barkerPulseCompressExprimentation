function [codew, pulsew, prt, fs] = readTxParameters(echoWaveTables)

% 单位转换， 凡是遇到时间都将us都转换为s， 凡是关于频率都加上Mhz单位
us2s = 1e-6;
toMhz = 1e6;
% 读码宽、脉宽、prt、fs
codew = echoWaveTables(1, "CodeWidth").CodeWidth * us2s;
pulsew = echoWaveTables(1, "PulseWidth").PulseWidth * us2s;
prt = echoWaveTables(1, "PRT").PRT * us2s;
fs = echoWaveTables(1, "SampleRate").SampleRate * toMhz; 

