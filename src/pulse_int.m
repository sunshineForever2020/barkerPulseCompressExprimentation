function res = pulse_int(data_2d)
% 计算二维雷达数据N个慢时间的非相干功率积累， 
% data_2d 一列一个快时间， 积累总列数次
res = mean(abs(data_2d).^2, 2);