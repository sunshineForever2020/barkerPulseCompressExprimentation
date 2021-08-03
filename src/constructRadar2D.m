function rdata2 = constructRadar2D(echoWaveTables)

% 提取快时间、慢时间构造雷达接收二维平面矩阵
% 行维是快时间维， 即一列一个接收区间
% 列维是慢时间维， 即不同列是不同的接收区间

rdata2 = echoWaveTables.ComplexIQ;
rdata2 = cell2mat(struct2cell(rdata2));
