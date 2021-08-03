function DataFileTable = readDataFromRawEcho(RadarFileName)
% 这个位置是写文档用的
% ref https://ww2.mathworks.cn/matlabcentral/answers/385608-how-to-process-a-large-binary-file-with-set-skipping-patterns
% 打开文件为读, 获取文件指针
% 2021/7/15 修改结束标志， 直接按照波门宽度采样，少一个点也没问题
FileHandleId = fopen(RadarFileName, 'rb', 'ieee-le');
if (FileHandleId == -1)
    error(['Error opening', RadarFileName, 'for input.']);
end

%% 获取每帧帧头位置和总帧数
radarFileUint = fread(FileHandleId, inf, '*uint')';
% 帧起始、结束标志，uint int类型， 二进制文件是小字节序5555AAAA->AAAA5555
FrameHeadFlagUint = 0xAAAA5555;
FrameHeadFlagInt = typecast(FrameHeadFlagUint, 'int32');
FrameEndFlagUint = 0xAA5555AA;
FrameHeadLoc = strfind(radarFileUint, FrameHeadFlagUint);
% 将 uint 转化为 uint8， 32->8
FrameHeadLoc = (FrameHeadLoc-1)*4;
TotalFrames = length(FrameHeadLoc);
% 文件指针回到开始处
fseek(FileHandleId, 0, 'bof');

%% 解析帧头信息以及IQ数据
% 数据结构初始化，日期数、方位、俯仰、探测模式、波形类型、码宽、脉宽
% 脉冲重复周期、波门前沿、波门宽度、带宽、采样率
DateNumV = zeros(TotalFrames, 1);
AziV = zeros(TotalFrames, 1); 
EleV = zeros(TotalFrames, 1); 
DetectModeV = string(zeros(TotalFrames, 1));
WaveTypeV = string(zeros(TotalFrames, 1)); 
CodeWidthV = zeros(TotalFrames, 1);
PulseWidthV = zeros(TotalFrames, 1); 
PRTV = zeros(TotalFrames, 1); 
WaveGateFrontV = zeros(TotalFrames, 1);
WaveGateWidthV = zeros(TotalFrames, 1);
BandWidthV = zeros(TotalFrames, 1);
SampleRateV = zeros(TotalFrames, 1);
BigCode = zeros(TotalFrames, 1);
LittleCode = zeros(TotalFrames, 1);
% 信息数据结构下标
index = 1;
for FrameHeadLocInd = FrameHeadLoc
    % 跳转至每帧帧头位置
    fseek(FileHandleId, FrameHeadLocInd, 'bof');
    %% 跳转至每帧日期位置, 相对6word
    fseek(FileHandleId, 6*2, 'cof');
    % 读日期
    month = fread(FileHandleId, 1, 'uint8');
    year = fread(FileHandleId, 1, 'uint8');
    hour = fread(FileHandleId, 1, 'uint8');
    day = fread(FileHandleId, 1, 'uint8');
    second = fread(FileHandleId, 1, 'uint8');
    minute = fread(FileHandleId, 1, 'uint8');
    fracOfSecond = fread(FileHandleId, 1, 'uint16') * 25e-6;
    % 可以直接用datenum转换时间, 之前fracOfSecond*1e3计算错误了,单位是秒
    DateNumV(index) = datenum(year+2000, month, day, hour, minute,...
        second+fracOfSecond);          
    
    %% 解析信号带宽、采样率、信号形式、探测模式
        % 解析采样率， Mhz
        fseek(FileHandleId, (18-10)*2, 'cof');
        SampleRateCode = fread(FileHandleId, 1, 'ubit4');
        SampleRateTemp = 0;
        if SampleRateCode == 0x0
            SampleRateTemp = 4;
        elseif SampleRateCode == 0x1
            SampleRateTemp = 0.1;
        elseif SampleRateCode == 0x2
            SampleRateTemp = 0.2;
        elseif SampleRateCode == 0x3
            SampleRateTemp = 0.4;
        else
            SampleRateTemp = 0;
        end
        
        SampleRateV(index) = SampleRateTemp;
        
        % 解析波形类型，巴克码之类等
        WaveTypeTemp = fread(FileHandleId, 1, 'ubit4');
        WaveTypeNameTemp = '';
        if WaveTypeTemp == 0x0
            WaveTypeNameTemp = '线性调频';
        elseif WaveTypeTemp == 0x1
            WaveTypeNameTemp = '互补码';
        elseif WaveTypeTemp == 0x2
            WaveTypeNameTemp = '巴克码';
        elseif WaveTypeTemp == 0x3
            WaveTypeNameTemp = '交替码';
        elseif WaveTypeTemp == 0x4
            WaveTypeNameTemp = '长脉冲';
        elseif WaveTypeTemp == 0x7
            WaveTypeNameTemp = '单载频';
        end 
        WaveTypeV(index) = WaveTypeNameTemp;
        
        % 跳4bits
        fread(FileHandleId, 1, 'ubit4');
        
        % 读带宽， MHz
        BandWidthC = fread(FileHandleId, 1, 'ubit4');
        BandWidthTemp  = 0;
        if BandWidthC == 0x0
            BandWidthTemp = 0.05;
        elseif BandWidthC == 0x1
            BandWidthTemp = 4;
        elseif BandWidthC == 0x2
            BandWidthTemp = 0.1;
        elseif BandWidthC == 0x3
            BandWidthTemp = 0.3;
        elseif BandWidthC == 0x10
            BandWidthTemp = 1;
        end
        BandWidthV(index) = BandWidthTemp;
        
        % 跳16bits
        fread(FileHandleId, 1, 'uint16');
        % 读电离层灵活探测模式
        ModeOfDetect = fread(FileHandleId, 1, 'uint16');
        DetectModeTemp = '';
        switch ModeOfDetect
            case 0
                DetectModeTemp = '天顶探测';
            case 1
                DetectModeTemp = '子午面广域探测';
            case 2
                DetectModeTemp = '东西向精细扫描探测';
            case 3
                DetectModeTemp = '全天空探测';
            otherwise
                DetectModeTemp = '其他';
        end
        DetectModeV(index) = DetectModeTemp;
        
        %% 读码宽、读DBF输出波束数、波门起始、波门宽度
        fseek(FileHandleId, (334-21)*2, 'cof');
        CodeWidthTemp = fread(FileHandleId, 1, 'uint16');
        CodeWidthV(index) = CodeWidthTemp;
      
        % 读DBF输出波束数、波门起始、波门宽度
        fseek(FileHandleId, (382-335)*2, 'cof');
        DBFNumberOfOutput = fread(FileHandleId, 1, 'ubit8');
        
        if DBFNumberOfOutput~= 1 
            error('输出波束数为4，该程序暂不支持！');
        end
        
        % 跳8位
        fseek(FileHandleId, 1, 'cof');
        WaveGateFrontTemp = fread(FileHandleId, 1, 'uint16'); %us
        WaveGateFrontV(index) = WaveGateFrontTemp;
        
        WaveGateWidthTemp = fread(FileHandleId, 1, 'uint32');
        WaveGateWidthV(index) = WaveGateWidthTemp;
        
        %% 读天线方位、俯仰
        fseek(FileHandleId, (428-386)*2, 'cof');
        AziTemp = fread(FileHandleId, 1, 'uint16');
        AziTemp = AziTemp * 0.005493164;
        AziV(index) = AziTemp;
        
        EleTemp = fread(FileHandleId, 1, 'uint16');
        EleTemp = EleTemp * 0.005493164;
        EleV(index) = EleTemp;
        %% 解码大小编码 
        fseek(FileHandleId, (468-430)*2, 'cof');
        BigCodeTemp = fread(FileHandleId, 1, 'uint16');
        BigCode(index) = BigCodeTemp;
        % 跳 2word
        fread(FileHandleId, 2, 'uint16');
        LittleCodeTemp = fread(FileHandleId, 1, 'uint16');
        LittleCode(index) = LittleCodeTemp;
        
        %% 读脉冲重复周期、脉宽、
        % 读脉冲重复周期
        fseek(FileHandleId, (490-472)*2, 'cof');   % 出问题了，应该用相对位置
        PRTTemp = fread(FileHandleId, 1, 'uint16');
        PRTV(index) = PRTTemp;
        % 跳3word
        fread(FileHandleId, 3, 'uint16');
        % 读脉宽
        PulseWidthTemp = fread(FileHandleId, 1, 'uint16');
        PulseWidthV(index) = PulseWidthTemp;
        % 读完帧头
        fread(FileHandleId, 15, 'uint16');
        endflag = fread(FileHandleId, 1, 'uint32');
        
        if (endflag ~= FrameEndFlagUint)
            error('dont read to end flag');
        end
        
        %% 读IQ数据到复数数组中   
        TotalIQ = (WaveGateWidthTemp) * 2; % I Q 两个 所以加倍                  % 这里为什么+1？去掉
        signalIQ = fread(FileHandleId, TotalIQ, 'int32'); 
        % signalIQ = reshape(signalIQ, [], 2);
        % ComplexIQTemp = complex(signalIQ(:,1), signalIQ(:,2)); 错误！！
        % IQ 应该是一个接一个， 但是我在一半的时候reshape了， 后面一半当成了Q
        ComplexIQTemp = complex(signalIQ(1:2:end), signalIQ(2:2:end));
        % 奇数位是 I， 偶数位是 Q 
        
        % 确保读完一帧，出错代表解析错误
        % 2021/7/15日修改，
%         while ~feof(FileHandleId)
%             tempIQ = fread(FileHandleId, 1, 'int32');
%             if tempIQ == FrameHeadFlagInt
%                 break;
%             else
%                 if feof(FileHandleId)
%                     error('读帧错误！');
%                 end
%             end
%         end
            
        % 放到Data数据结构体中
        Data(index).IQ = ComplexIQTemp;
        index = index + 1;
        
end
% 将所有数据读到一个table数据结构中
DataFileTable = table; 
DataFileTable.Time = DateNumV;
DataFileTable.Azi = AziV;
DataFileTable.Ele = EleV;
DataFileTable.ComplexIQ = Data';
DataFileTable.DetectMode = DetectModeV;
DataFileTable.WaveType = WaveTypeV;
DataFileTable.CodeWidth = CodeWidthV;
DataFileTable.PulseWidth = PulseWidthV;
DataFileTable.PRT = PRTV;
DataFileTable.WaveGateFront = WaveGateFrontV;
DataFileTable.WaveGateWidth = WaveGateWidthV;
DataFileTable.BandWidth = BandWidthV;
DataFileTable.SampleRate = SampleRateV;
DataFileTable.BigCode = BigCode;
DataFileTable.LittleCode = LittleCode;
fclose(FileHandleId);
    









