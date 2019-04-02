function run_all_tagging_algs(filename,info,algstorun)
nalgs = 21;
if isempty(algstorun)
    algstorun = ones(nalgs,1);
end
if isempty(info)
    info=getfileinfo(filename);
end

isfirst = [];
firstindex = find(algstorun,1);

% This isn't initializing the results file values in any way - it is just
% filling a place in the initial run of the algorithm
result_name = [];
result_data = [];
result_tags = [];
result_tagcolumns = [];
result_tagtitle = [];
result_qrs = [];

for i=1:length(algstorun)
    if algstorun(i)
        if isempty(isfirst)
            isfirst = firstindex==i;
        end
        [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs,isfirst] = runalg(filename,info,i,isfirst,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
    end
end

% Find the Result Filename
if contains(filename,'.hdf5')
    resultfilename = strrep(filename,'.hdf5','_results.mat');
elseif contains(filename,'.dat')
    resultfilename = strrep(filename,'.dat','_results.mat');
elseif contains(filename,'.mat')
    resultfilename = strrep(filename,'.mat','_results.mat');
end

% Save the Results
msgbox('Saving the results','Tagging','modal');
info = rmfield(info,'alldata');
save(resultfilename,'result_data','result_name','result_tags','result_tagcolumns','result_tagtitle','result_data','result_qrs','info');

msgbox('Tagging Algorithms Complete','Tagging','modal');
end

function [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs,isfirst] = runalg(filename,info,algnum,isfirst,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs)
    algdispname = {...
        'QRS Detection: ECG I',1;...
        'QRS Detection: ECG II',1;...
        'QRS Detection: ECG III',1;...
        'CU Artifact',1;...
        'WUSTL Artifact',1;...
        'Brady Detection',1;...
        'Desat Detection',1;...
        'Apnea Detection with ECG Lead I',1;...
        'Apnea Detection with ECG Lead II',1;...
        'Apnea Detection with ECG Lead III',1;...
        'Apnea Detection with No ECG Lead',1;...
        'Periodic Breathing with ECG Lead I',1;...
        'Periodic Breathing with ECG Lead II',1;...
        'Periodic Breathing with ECG Lead III',1;...
        'Periodic Breathing with No ECG Lead',1;...
        'Brady Detection Pete',1;...
        'Desat Detection Pete',1;...
        'Brady Desat',1;...
        'Brady Desat Pete',1;...
        'ABD Pete No ECG',1;...
        'Save HR in Results',1;...
        'Data Available: Pulse',1;...
        'Data Available: HR',1;...
        'Data Available: SPO2_pct',1;...
        'Data Available: Resp',1;...
        'Data Available: ECG I',1;...
        'Data Available: ECG II',1;...
        'Data Available: ECG III',1};
    
    resultname = {'/Results/CUartifact',1;...
        '/Results/WUSTLartifact',1;...
        '/Results/Brady<100',1;...
        '/Results/Desat<80',1;...
        '/Results/Apnea-I',1;...
        '/Results/Apnea-II',1;...
        '/Results/Apnea-III',1;...
        '/Results/Apnea-NoECG',1;...
        '/Results/PeriodicBreathing-I',1;...
        '/Results/PeriodicBreathing-II',1;...
        '/Results/PeriodicBreathing-III',1;...
        '/Results/PeriodicBreathing-NoECG',1;...
        '/Results/Brady<100-Pete',1;...
        '/Results/Desat<80-Pete',1;...
        '/Results/BradyDesat',1;...
        '/Results/BradyDesatPete',1;...
        '/Results/ABDPete-NoECG',1;...
        '/Results/HR',1};
    
    % Find out if this algorithm has already been run. If it has, but this is the first alg on the list, load in the data that the program expects
    shouldrun = shouldrunalgorithm(filename,algnum,resultname,algdispname,result_tagtitle,result_qrs);
    if ~shouldrun
        return
    end
    
    pmin = 1; % minimum number of points below threshold (default one) - only applies to tags!!
    tmin = 0; % time gap between crossings to join (default zero) - only applies to tags!!
    msgboxtitle = 'Tagging';

    msgbox(['Running algorithm ' num2str(algnum) ' of ' num2str(size(algdispname,1)) ': ' algdispname{algnum,1} ' v' num2str(algdispname{algnum,2})],msgboxtitle,'modal');
    try
        switch algnum
            case 1
                % QRS Detection with ECGI
                qrs = qrsdetector(info,1,algdispname(algnum,2));
            case 2
                % QRS Detection with ECGII
                qrs = qrsdetector(info,2,algdispname(algnum,2));
            case 3
                % QRS Detection with ECGIII
                qrs = qrsdetector(info,3,algdispname(algnum,2));
            case 4
                % Run and plot Columbia artifact removal, which works by comparing HR vs SPO2-R. Removes data which has a discrepancy between sensors.
                [result,t_temp,tag,tagcol] = cu_artifact_removal(info,pmin,tmin);
            case 5
                % Run and plot WashU artifact removal, which works by removing low or missing SPO2-% data, then removing big jumps (of >3%)
                [result,t_temp,tag,tagcol] = wustl_artifact_removal(info,50,pmin,tmin); % 50 is the threshold for spo2 values to determine if they are non-physiologic. Any spo2 value below this level is determined to be "missing" data. Amanda made this up because we don't have an exact value from WashU
            case 6
                % Run a bradycardia detection algorithm which identifies any and all drops <= the threshold
                [result,t_temp,tag,tagcol] = bradydetector(info,99.99,pmin,tmin);
            case 7
                % Run a desaturation detection algorithm which identifies any and all drops <= the threshold
                [result,t_temp,tag,tagcol] = desatdetector(info,79.99,pmin,tmin);
            case 8 
                % Apnea detection algorithm using lead I
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,1,result_qrs);
            case 9
                % Apnea detection algorithm using lead II
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,2,result_qrs);
            case 10
                % Apnea detection algorithm using lead III
                [result,t_temp,tag,tagcol,qrs] = apneadetector(info,3,result_qrs);
            case 11
                % Apnea detection algorithm using no EKG lead
                [result,t_temp,tag,tagcol] = apneadetector(info,0,result_qrs);
            case 12
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with ecg lead I
                [result,t_temp,tag,tagcol] = periodicbreathing(info,1,result_name,result_data);
            case 13
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with ecg lead II
                [result,t_temp,tag,tagcol] = periodicbreathing(info,2,result_name,result_data);
            case 14
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with ecg lead III
                [result,t_temp,tag,tagcol] = periodicbreathing(info,3,result_name,result_data);
            case 15
                % Mary Mohr's periodic breathing algorithm run on results from apnea detector with no ecg lead
                [result,t_temp,tag,tagcol] = periodicbreathing(info,0,result_name,result_data);
            case 16
                % Pete's bradycardia detection algorithm: Bradys are <100 for ECG HR for at least 4 seconds. Joining rule for bradys is 4 seconds
                [result,t_temp,tag,tagcol] = bradydetector(info,99.99,4,4000);
            case 17
                % Pete's Desat detection algorithm: <80% for at least 10 seconds if two of those events happen within 10 seconds of eachother, join them together as one event
                [result,t_temp,tag,tagcol] = desatdetector(info,79.99,10,10000);
            case 18
                % Brady Desat Algorithm with a 30 second threshold. Any brady within 30 seconds of any desat (in either direction) will count
                [result,t_temp,tag,tagcol] = bradydesat(info,30000,result_tags,result_tagcolumns,result_tagtitle);
            case 19
                % Brady Desat Algorithm with a 30 second threshold. Any brady within 30 seconds of any desat (in either direction) will count
                [result,t_temp,tag,tagcol] = bradydesatpete(info,30000,result_tags,result_tagcolumns,result_tagtitle);
            case 20
                % ABD Algorithm with a 30 second threshold. Used Pete's B and D tags along with Apnea-NoECG
                [result,t_temp,tag,tagcol] = abd(info,30000,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
            case 21
                % Store HR Vital Sign
                [result,t_temp,tag,tagcol] = pullHRdata(info);
            case 22
                % Determine when a pulse signal exists
                [~,~,tag,tagcol] = dataavailable(info,pmin,tmin,'Pulse',1);
            case 23
                % Determine when a hr signal exists
                [~,~,tag,tagcol] = dataavailable(info,pmin,tmin,'HR',1);
            case 24
                % Determine when a spo2% signal exists
                [~,~,tag,tagcol] = dataavailable(info,pmin,tmin,'SPO2_pct',1);
            case 25 
                % Determine when a resp signal exists
                [~,~,tag,tagcol] = dataavailable(info,pmin,tmin,'Resp',0);
            case 26
                % Determine when an ECGI signal exists
                [~,~,tag,tagcol] = dataavailable(info,pmin,tmin,'ECGI',0);
            case 27
                % Determine when an ECGII signal exists
                [~,~,tag,tagcol] = dataavailable(info,pmin,tmin,'ECGII',0);
            case 28
                % Determine when an ECGIII signal exists
                [~,~,tag,tagcol] = dataavailable(info,pmin,tmin,'ECGIII',0);

        end
        if exist('result')
            if isfirst
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresultsfile(filename,resultname(algnum-3,:),result,t_temp,tag,tagcol,[]);
                isfirst = 0;
            else
                if ~isempty(result)
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(resultname(algnum-3,:),result,t_temp,tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs); % Must subtract 3 for resultname because qrs detection doesn't have a resultname
                end
            end
        elseif exist('tagcol') % For dataavailable results
            if isfirst
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresultsfile(filename,algdispname(algnum,:),[],[],tag,tagcol,[]);
                isfirst = 0;
            else
                if ~isempty(tagcol)
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(algdispname(algnum,:),[],[],tag,tagcol,[],result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
                end
            end
        end
        if exist('qrs')
            if isfirst
                [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = loadresultsfile(filename,algdispname(algnum,:),[],[],[],[],qrs);
                isfirst = 0;
            else
                if ~isempty(qrs)
                    [result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs] = addtoresultsfile3(algdispname(algnum,:),[],[],[],[],qrs,result_name,result_data,result_tags,result_tagcolumns,result_tagtitle,result_qrs);
                end
            end
        end
    catch
        msgbox(['Failure running algorithm ' num2str(algnum) ' of ' num2str(size(algdispname,1)) ': ' algdispname{algnum,1} '. Continuing running tagging algorithms.'],msgboxtitle,'modal');
        pause(1)
    end

end