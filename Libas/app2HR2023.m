function [Rwavecorrect, BPMmat]  = app2HR2023(filemat, plotflag) 

% first define useful stuff: 
[B,A] = butter(6,.05, 'high'); 

% secbins are the 1 second segments that are being considereed
secbins = 0:10;

for fileindex = 1:size(filemat,1)
   
    BPM_mat = [];

    % read  file and check how many trials 
    [dummy,Version,LHeader,ScaleBins,NChan,NPoints,NTrials,SampRate,AvgRefStatus,File,Path,FilePath,EegMegStatus,NChanExtra,AppFileFormatVal]=...
	ReadAppData(deblank(filemat(fileindex,:)));

    time = 0:1000/SampRate:size(dummy,2).*1000/SampRate-1000/SampRate; 

    Rwavecorrect = zeros(1, size(dummy,2));


 for trial = 1: NTrials 
    % read, calculate and plot   
    [a]=ReadAppData(deblank(filemat(fileindex,:)), trial);
    % ECG =filtfilt(B, A, a(121,:) - a(228,:)); 
    ECG =filtfilt(B, A, a(73,:) - a(121,:)); 
    ECGsquare = ((ECG.^2)); 

    if plotflag
    figure(1)    
    subplot(2,1,1)
    plot(time, ECG), title('raw')
    subplot(2,1,2)
    plot(time, ECGsquare), title('square')   
    hold on
    end
    
    % find and plot R-peaks
    stdECG = std(ECGsquare); 
    threshold = 4*stdECG; 
    Rchange=  find(ECGsquare > threshold);
    Rstamps = [Rchange(find(diff(Rchange)>10)) Rchange(end)];
   
    if plotflag
    subplot(2,1,2)
    plot(time(Rstamps), 1000, 'r*')
    hold off
    pause(1)
    end
 

    % convert to IBIs
    Rwavestamps = time(Rstamps)./500; 
    IBIvec = diff(Rwavestamps);
                

    % artifact handling
   [IBIvecClean, IBIvecClean1, correctedflag] = HR_artifact(IBIvec);

   while sum(correctedflag)> 0
       [IBIvecClean, IBIvecClean1, correctedflag] = HR_artifact(IBIvecClean);
   end
      
   stamps = round(cumsum(IBIvecClean)); 

   Rwavecorrect(trial, stamps) = 1; 
  
   BPMmat(trial,:)  = IBI2HRchange_halfsec(IBIvecClean, 11); 

   
   
 end %trial

eval(['save ' deblank(filemat(fileindex,:)) 'HR.mat BPMmat -mat'])

fclose('all'); 
end % fileindex


