function [result,t_temp,tag,tagcol] = abd(info,thresh,result_tags,result_tagcolumns,result_tagtitle,result_qrs,ECG)
% Set ECG to 0 to use Apnea-NoECG. Set ECG to 1 to use Apnea with all ECG
% leads.

t_temp = info.times+info.timezero;
result = zeros(length(t_temp),1);
tag = [];
tagcol = {'Start';'Stop';'Duration'};

if isempty(result_tagtitle)
    if ~isempty(info.resultfile)
        result_tags = load(info.resultfile,'result_tags');
        if isfield(result_tags,'result_tags')
            result_tags = result_tags.result_tags;
        end
        result_tagcolumns = load(info.resultfile,'result_tagcolumns');
        if isfield(result_tagcolumns,'result_tagcolumns')
            result_tagcolumns = result_tagcolumns.result_tagcolumns;
        end
        result_tagtitle = load(info.resultfile,'result_tagtitle');
        if isfield(result_tagtitle,'result_tagtitle')
            result_tagtitle = result_tagtitle.result_tagtitle;
        end
    end
end

% Get apnea results
if ECG == 0
    idx = findresultindex('/Results/Apnea-NoECG',1,result_tagtitle);
    if sum(idx)
        apneatags = result_tags(idx);
        apneatagcolumns = result_tagcolumns(idx);
    else
        % Run apnea algorithm
        [~,~,at,a] = apneadetector(info,0,result_qrs);
        apneatags(1).tagtable = at;
        apneatagcolumns(1).tagname = a;
    end
elseif ECG == 1
    idx = findresultindex('/Results/Apnea',1,result_tagtitle);
    if sum(idx)
        apneatags = result_tags(idx);
        apneatagcolumns = result_tagcolumns(idx);
    else
        % Run apnea algorithm
        [~,~,at,a] = apneadetector(info,[],result_qrs);
        apneatags(1).tagtable = at;
        apneatagcolumns(1).tagname = a;
    end
end

if isempty(apneatags)
    result = [];
    t_temp = [];
    tagcol = [];
    return
end

% Get brady results
idx = findresultindex('/Results/Brady<100-Pete',3,result_tagtitle);
if sum(idx)
    bradytags = result_tags(idx);
    bradytagcolumns = result_tagcolumns(idx);
else
    % Run brady algorithm
    [~,~,bt,b] = bradydetector(info,100,4,4000);
    bradytags(1).tagtable = bt;
    bradytagcolumns(1).tagname = b;
end

if isempty(bradytags)
    return
end

% Get desat results
idx = findresultindex('/Results/Desat<80-Pete',3,result_tagtitle);
if sum(idx)
    desattags = result_tags(idx);
    desattagcolumns = result_tagcolumns(idx);
else
    % Run desat algorithm
    [~,~,dt,d] = desatdetector(info,80,10,10000);
    desattags(1).tagtable = dt;
    desattagcolumns(1).tagname = d;
end

if isempty(desattags)
    return
end

% Find the ABD overlap
[result,t_temp,tag,tagcol] = tripletagmerge(apneatagcolumns,bradytagcolumns,desattagcolumns,apneatags,bradytags,desattags,thresh,info);
result = [];
t_temp = [];
end
