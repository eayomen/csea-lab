
function [EEG] = C1P1eeglab_pipeline(EEGfilepath)

EEG = pop_readegi(EEGfilepath, [],[],'auto');

EEG = eeg_checkset( EEG );

% filter the data
temp = EEG.data'; 

[fila,filb] = butter(4, 0.08); 

temp2 = filtfilt(fila, filb, double(temp)); 

[filaH,filbH] = butter(2, 0.002, 'high');

temp3 =  filtfilt(filaH, filbH, temp2)'; 

EEG.data = single(temp3);

EEG = eeg_checkset( EEG );
%EEG=pop_chanedit(EEG, 'load',{'/Users/cseauf/Documents/Arash/BOP_experiment/GSN-HydroCel-128.sfp' 'filetype' 'autodetect'});

EEG=pop_chanedit(EEG, 'load',{'GSN-HydroCel-257.sfp' 'filetype' 'autodetect'},'changefield',{132 'datachan' 0},'setref',{'132' 'Cz'});

EEG = eeg_checkset( EEG );

%% now the trigger issue, har har 
for index1 = 1:length(EEG.event)
temptrigs(index1) = EEG.event(index1).latency;
end

newtrigvec = []; 
indiceswithtrigs = find(diff(temptrigs) > 9); 
newtrigvec_temp = temptrigs(indiceswithtrigs+1);
newtrigvec = [temptrigs(1); newtrigvec_temp']; 

% replace trigger structures in EEG structure with actual triggers
EEG.event = []; 
EEG.urevent = []; 

for index2 = 1:length(newtrigvec)
    EEG.event(index2).type = 'DIN3';
    EEG.event(index2).latency = newtrigvec(index2);
    EEG.event(index2).urevent = index2;
    EEG.urevent(index2).type = 'DIN3';
    EEG.urevent(index2).latency = newtrigvec(index2);
end



EEG = pop_epoch( EEG, {  'DIN3'  }, [-.2  .3], 'newname', 'test epochs', 'epochinfo', 'yes');
EEG = eeg_checkset( EEG );
EEG = pop_rmbase( EEG, [-100     0]);


% take care of bad channels
 [outmat3d, interpsensvec] = scadsAK_3dchan(EEG.data, EEG.chanlocs);
 EEG.data = single(outmat3d); 


% run the ICA and save  output
 EEG = pop_runica(EEG,  'icatype', 'sobi');
 EEG = eeg_checkset( EEG );
 EEG = pop_saveset( EEG, 'filename',[EEGfilepath '.EEG.set'],'filepath',pwd);
 EEG = eeg_checkset( EEG );
% 
% 
 warning('off');
 pop_topoplot(EEG,0, [1:64] ,'component topographies',[8 8] ,0,'electrodes','off');
 warning('on');


