function [start,stop]=threshcross(x,T,pmin,negthresh)
%function [start,stop]=threshcross(x,T,pmin)
%
% x = input signal
% T = threshold for event
% pmin = minimum number of points below threshold (default none)
%
% start = starting indice for threshold crossing
% stop = stopping indice for threshold crossing
% negthresh = 1 if you want to identify events that drop below a threshold
% negthresh = 0 if you want to identify events above a threshold

if ~exist('pmin','var'),pmin=1;end
if ~exist('negthresh','var'),negthresh=1;end

start=[];
stop=[];
%Find all data below threshold
if negthresh
    c=find(x<=T);
else
    c=find(x>=T);
end
if length(c)<pmin,return,end
start=c;
stop=c;
nc=length(c);
if nc==1,return,end

%Find events of non-consecutive points below threshold
dc=diff(c);
e=find(dc>1);
start=[c(1);c(e+1)];
stop=[c(e);c(nc)];
np=stop-start+1;
if pmin>1
    j=find(np<pmin);
    start(j)=[];
    stop(j)=[];
    np(j)=[];
end    
% nt=length(start);
% if nt<2,return,end
% if gmin<1,return,end
% j1=(1:nt)';
% j2=j1;
% gap=start(2:nt)-stop(1:(nt-1));
% j1=1;
% j2=nt;
% j=find(gap>gmin);
% if ~isempty(j)
%     j1=[1;(j+1)];
%     j2=[j;nt];
% end
% start=start(j1);
% stop=stop(j2);
