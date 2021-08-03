# 电离层巴克码信号处理流程
## 对接收信号做脉压，本程序使用了三种方式

- phased.MatchedFilter 函数构造匹配滤波器
- matlab函数xcorr 直接做互相关
- 相关的fft实现， 手写实现的matchedFilter函数

## 解析报文方式修改

增加的函数如下

- [codew, pulsew, prt, fs] = readTxParameters(echoWaveTables)

  解析完报文之后直接读取码宽、脉宽、PRT和采样率等参数

- rangegates = readRangeLimits(echoWaveTables)

  利用波门前沿、宽度、采样率等直接计算距离门范围

- rdata2 = constructRadar2D(echoWaveTables)

  直接构建雷达快慢时间二维矩阵

  
