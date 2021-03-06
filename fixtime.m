function [data,t,dt]=fixtime(data,dt)
%function [data,t,dt]=fixtime(data,dt)
%
% data      structure with time stamps for each signal
% dt        intended time between timestamps
%
% data      sequence added and correced time stamps signal
% t         time matrix with corrected/original in first/second column

%Find original time sequence

if ~exist('dt','var'),dt=NaN;end

% Find unique timestamps and signal/sequence number for each data block
[t,s,seq]=timeseq(data);
t0=t;

if isnan(dt)
    dt=median(diff(t));
end

n=length(data);

%Fix jitter of global timestamps to make increasing and multiple of dt

t=fixjitter(t0,dt);

%Put original times in second column
t(:,2)=t0;

%Replae timestamps with sequence number index in data structure
for i=1:n
    j=seq(s==i);
%Remove timestamps and find blocks of consecutive data to put in index
    data(i).t=[];
    j1=min(j);
    j2=max(j);    
    k=find(diff(j)>1);
    if ~isempty(k)       
        j2=[j(k);j2];
        j1=[j1;j(k+1)];
    end
    index=[j1 j2-j1+1];
    data(i).index=index;
%Put corrected timestamps back into data structure    
%    data(i).t=t(ind,1);
%    data(i).seq=ind;    
end

end

function [t,s,seq,tnum,T,Tnum,D]=timeseq(data)
%function [t,s,seq,tnum,T,Tnum,D]=timeseq(data)
%
% data = structure with time stamps for each signal
%
% t         all unique timestamps
% s         signal number for all timestamps
% seq       sequence number for all timestamps
% tnum      unique timestamps duplicate numbers 
% T         all timestamps
% Tnum      all timestamps duplicate numbers 

t=[];
tnum=[];
T=[];
Tnum=[];
s=[];
seq=[];
D=[];
n=length(data);
if n==0,return,end
for i=1:n
    tt=double(data(i).t);    
    nt=length(tt);
    if nt==0,continue,end
    tn=ones(nt,1);
    dup=[0;diff(tt)==0];
    j=find(dup);
    for k=1:length(j)
        jj=j(k);
        tn(jj)=tn(jj-1)+1;
    end
    T=[T;tt];
    s=[s;i*ones(nt,1)];
    Tnum=[Tnum;tn];
end

maxnum=max(Tnum);
D=10.^ceil(log10(maxnum));

%Find all unique times
[Dt,~,seq]=unique(D*T+Tnum);
t=floor(Dt/D);
tnum=Dt-D*t;

end

function [t,td,d,st,t0]=fixjitter(t,dt)
%function [t,td,d,st]=fixjitter(t,dt)
%
%t      original time stamps in seconds
%dt     target time between samples (default 2 seconds)
%
%t      corrected times
%td     amount corrected
%d      cumulative jitter
%st     ideal times without jitter
%t0     anchor time point

if ~exist('dt','var'),dt=1;end

%Find ideal samples
t0=t(1);
nt=length(t);
st=t0+(0:(nt-1))'*dt;

%Find cumulative minimum drift of actual vs ideal
ds=t-st;
d=cummin(ds,'reverse');

%Correction
td=d-ds;
t=t+td;

if dt==1,return,end

%Find original time point with smallest correction as anchor

j0=find(abs(td)==min(abs(td)),1);
t0=t(j0);

%Force times to be multiple of dt
if dt>1      
    t=t0+dt*ceil((t-t0)/dt);
end

end