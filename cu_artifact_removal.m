 function [results,vt] = cu_artifact_removal(filename)
 % "HR is compared with PR and data are considered valid only if the
 % difference between HR and lagged PR is > 1 standard deviation from 1h
 % smoothed HR." - Joe Isler
 
 % I don't know what constitutes "smoothed HR," so I will just use raw HR
 % here
 
[vdata,vname,vt,~]=gethdf5vital(filename);
if sum(contains(vname,'/VitalSigns/SPO2-R'))
    dataindex = ismember(vname,'/VitalSigns/SPO2-R');
elseif sum(contains(vname,'/VitalSigns/PULSE'))
    dataindex = ismember(vname,'/VitalSigns/PULSE');
end
spo2rdata = vdata(:,dataindex);
dataindex = ismember(vname,'/VitalSigns/HR');
hrdata = vdata(:,dataindex);
numsamps = length(spo2rdata);
try
    fs = double(h5readatt(filename,'/VitalSigns/HR','Sample Frequency (Hz)'));
catch
    fs = 1/(double(h5readatt(filename,'/VitalSigns/HR','Sample Period (ms)'))/1000);
end
onehrsamples = 60*60*fs; % 60 min of samples
artifact = zeros(numsamps,1);

for n=1:numsamps
    if n>onehrsamples
        stdev = std(hrdata((n-onehrsamples):n));
        if abs(hrdata(n)-spo2rdata(n))>stdev
            artifact(n) = 1;
        end
    else
%         stdev = std(hrdata(1:n));
        artifact(n) = 1;
    end

end

% artifact = abs(hrdata-spo2rdata)>thresh;

% plot(spo2rdata,'Color',[0.5843 0.5157 0.9882])
% hold on
% plot(hrdata,'b')
% 
% for q=1:numsamps
%     if artifact(q)
%         fillbar(q)
%     end
% end

results = artifact;
end

function fillbar(e)
x1 = e-1;
x2 = e;
y2 = [0 250];
h = fill([x1 x1 x2 x2], [y2 fliplr(y2)], [0.5843 0.8157 0.9882],'EdgeColor','none');
alpha(h,0.5);
hold on
end
