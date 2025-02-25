function [BPM_mat]  = app2HR(filemat); 

% first define useful stuff: 
[B,A] = butter(6,.05, 'high'); 

% secbins are the 1 second segments that are being considereed
secbins = [0:10];


for fileindex = 1:size(filemat,1); 
   
    BPM_mat = [];

% read  file and chekc how many trials 

[dummy,Version,LHeader,ScaleBins,NChan,NPoints,NTrials,SampRate,AvgRefStatus,File,Path,FilePath,EegMegStatus,NChanExtra,AppFileFormatVal]=...
	ReadAppData(deblank(filemat(fileindex,:)));
time = 0:1000/SampRate:size(dummy,2).*1000/SampRate-1000/SampRate; 

figure

for trial = 1: NTrials; 
    % read, calculate and plot
   
    [a]=ReadAppData(deblank(filemat(fileindex,:)), trial);
    % ECG =filtfilt(B, A, a(121,:) - a(228,:)); 
    ECG =filtfilt(B, A, a(73,:) - a(121,:)); 
    ECGsquare = ((ECG.^2)) 
    
    figure(1)
    
    subplot(3,1,1)
    plot(time, ECG), title('raw')
    subplot(3,1,2)
    plot(time, ECGsquare), title('square')   
    hold on
    
    % find and plot R-peaks
    stdECG = std(ECGsquare); 
    threshold = 4*stdECG; 
    Rchange=  find(ECGsquare > threshold);
    Rstamps = [Rchange(find(diff(Rchange)>10)) Rchange(end)];
    subplot(3,1,2)
    plot(time(Rstamps), 1000, 'r*')
    hold off
 
       
                 [artifactmode] = input('break for artifact correction?')
                 
                 if artifactmode == 1
                     figure(10), clf
                     subplot(3,1,1) %changed by VM
                     plot(time,ECG),title('raw') %added by VM
                     subplot(3,1,2) %changed by VM
                      plot(time, ECGsquare), title('square'), hold on
                     plot(time(Rstamps), 800, 'r*'), hold off
                     [x,y] = ginput
                      Rstamps = round(x./(1000/SampRate)) 
                      subplot(3,1,3) %changed by VM
                    plot(time, ECGsquare, 'b'), title('square'), hold on
                     plot(time(Rstamps), 800, 'b*'), hold off
                     pause
                 end
        
    % convert to IBIs
     Rwavestamps = time(Rstamps)./1000; 
    IBIvec = diff(Rwavestamps);
    leftfornext = 0; 
    BPMvec = zeros(1,length(secbins)-1);
    
    %%%% calculate HR change   
             for bin_index = 1:length(secbins)-1 % start counting timebins with first time bin until second to last, which has info about the last beat(s)

              %find cardiac events in and around this timebin and where they are
              %first find cardiac events that are located entirely in the time bin

              % ---- 
                    RindicesInBin1= find(Rwavestamps >= secbins(bin_index));
                    RindicesInBin2 = min(find(Rwavestamps > secbins(bin_index +1)));
                    RindicesInBin = min(RindicesInBin1) : RindicesInBin2 -1;

                    if ~isempty(RindicesInBin); 
                    maxbincurrent = max(RindicesInBin);
                    end

                    if length(RindicesInBin) == 2, % if there are two Rwaves in this segment, the basevalue is always 1 beat, and more may be added

                            basebeatnum = 1+leftfornext;

                             %  identify remaining time and determine proportion of next IBI that belongs to this
                             % segment
                              proportion =  (secbins(bin_index +1) - Rwavestamps(max(RindicesInBin)))./IBIvec(max(RindicesInBin));

                              leftfornext = 1-proportion;

                    elseif length(RindicesInBin) == 1,% if there is one Rwave in this segment, the basevalue is what remained from the previous beat, and more may be added

                            basebeatnum = leftfornext;

                             % then identify remaining time and determine proportion of next IBI that belongs to this
                             % segment
                               proportion =  (secbins(bin_index +1) - Rwavestamps(max(RindicesInBin)))./IBIvec(max(RindicesInBin));

                               leftfornext = 1-proportion;

                    else % if there is no beat in this segment

                        basebeatnum = leftfornext;

                        if length(IBIvec) >= maxbincurrent+1; 
                        proportion =  (secbins(bin_index +1) - Rwavestamps(maxbincurrent+1))./IBIvec(maxbincurrent+1);
                        else
                            proportion = 1; 
                        end

                         leftfornext = abs(proportion);

                    end

                 BPMvec(bin_index) = (basebeatnum+proportion) .* 60;
                 
             end % loop over bin indices
             IBIvec
               BPMvec(1) = 1./IBIvec(1).*60; 
                 BPMvec(end) = 1./IBIvec(end).*60;  
             
             figure(1)    
             subplot(3,1,3)
            plot(BPMvec); 
                 
                 BPM_mat = [BPM_mat; BPMvec];
             
   
end %trial

fclose('all'); 
end % fileindex


