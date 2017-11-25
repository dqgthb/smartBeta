topPercent = .1
stratNo = 1



% this section is just formatting the data. Evan is showing us his work.
% Evan is great!

%crsp=readtable('crspTest.csv');

% %Create testData.csv
% crsp=readtable('crspCompustatMerged_2010_2014_dailyReturns.csv');
% permnoList=unique(crsp.PERMNO);
% permnoList=randsample(permnoList,100);
% crsp=crsp(ismember(crsp.PERMNO,permnoList),:);
% writetable(crsp,'crspTest.csv');

% ff3=readtable('ff3.csv');
% ff3.datenum=datenum(num2str(ff3.date),'yyyymmdd');
% ff3{:,{'mrp','hml','smb'}}=ff3{:,{'mrp','hml','smb'}}/100;
% writetable(ff3(2010<=year(ff3.datenum)&year(ff3.datenum)<=2014,:),'ff3_20102014.csv')

%% Load ff3 data
ff3=readtable('csvFolder/ff3_20102014.csv');

%%
% crsp=readtable('crspTest.csv');
% % crsp=readtable('crspCompustatMerged_2010_2014_dailyReturns.csv');
% 
% crsp.datenum=datenum(num2str(crsp.DATE),'yyyymmdd');
% 
% disp("datenum added");
% %% Calculate momentum size and value
% 
% crsp=addLags({'ME','BE'},2,crsp);
% 
% % this means market size, not height/width.
% crsp.size=crsp.lag2ME;
% crsp.value=crsp.lag2BE./crsp.lag2ME;
% disp("lag added");
% 
% %Calculate momentum
% crsp=addLags({'adjustedPrice'},21,crsp); %this means a month
% crsp=addLags({'adjustedPrice'},252,crsp);
% crsp.momentum=crsp.lag21adjustedPrice./crsp.lag252adjustedPrice;
% 
% crsp=addRank({'size','value','momentum'},crsp);
% disp("rank added");
% crsp = addLags({'RET'}, 2, crsp); % add lag2RET column
% crsp = addEWMA('lag2RET', 42, crsp);
% crsp = addEWMA('lag2RET', 252, crsp);
% save('matFolder/crsp.mat');

st = load('matFolder/crsp.mat');
crsp = st.crsp;



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STRATEGY#1: VALUE TOP 10% AND MOMENTUM

dateList=unique(crsp.datenum);

%Track strategy positions
% create table with variable name being datenum for first column. 
thisStrategy=table(dateList,'VariableNames',{'datenum'});

%Create empty column of cells for investment weight tables
thisStrategy{:,'portfolio'}={NaN};


%Create empty column of NaNs for ret
thisStrategy{:,'ret'}=NaN;
thisStrategy{:,'turnover'}=NaN;


%Run first iteration separately since there's no turnover to calculate
i = 1;
    
thisDate=thisStrategy.datenum(i);

if stratNo == 0 % baseline
    thisPortfolio=tradeLongMomentum(thisDate,crsp); 
elseif stratNo == 1
%% strat 1
    thisPortfolio = tradeValueMomentum(thisDate, crsp, topPercent);
elseif stratNo == 2
    disp("no strat?")
else
    disp("no strat?")
end




thisStrategy.portfolio(i)={thisPortfolio}; %Bubble wrap the table of investment weights and store in thisStrategy

if (sum(~isnan(thisPortfolio.w))>0)
    %Calculate returns if there's at least one valid position
    thisStrategy.ret(i)=nansum(thisPortfolio.RET.*thisPortfolio.w);


    changePortfolio=outerjoin(thisPortfolio(:,{'PERMNO','w'}),lastPortfolio(:,{'PERMNO','w'}),'Keys','PERMNO');
    %Fill missing positions with zeros
    changePortfolio=fillmissing( changePortfolio,'constant',0);
    thisStrategy.turnover(i)=nansum(abs(changePortfolio.w_left-changePortfolio.w_right))/2;

end
    
disp("start iteration..");
for i = 2:size(thisStrategy,1)

    thisDate=thisStrategy.datenum(i);
    lastPortfolio=thisPortfolio;
   
    
    if stratNo == 0 % baseline
        thisPortfolio=tradeLongMomentum(thisDate,crsp); 
    elseif stratNo == 1
    %% strat 1
        thisPortfolio = tradeValueMomentum(thisDate, crsp, topPercent);
    elseif stratNo == 2
        disp("no strat?")
    else
        disp("no strat?")
    end
    
    thisStrategy.portfolio(i)={thisPortfolio}; %Bubble wrap the table of investment weights and store in thisStrategy
    
    if (sum(~isnan(thisPortfolio.w))>0)
        %Calculate returns if there's at least one valid position
        thisStrategy.ret(i)=nansum(thisPortfolio.RET.*thisPortfolio.w);
        
        
        changePortfolio=outerjoin(thisPortfolio(:,{'PERMNO','w'}),lastPortfolio(:,{'PERMNO','w'}),'Keys','PERMNO');
        %Fill missing positions with zeros
        changePortfolio=fillmissing( changePortfolio,'constant',0);
        thisStrategy.turnover(i)=nansum(abs(changePortfolio.w_left-changePortfolio.w_right))/2;

    end 
    
end


thisPerformance=evaluateStrategy(thisStrategy,ff3);

save('sampleStrat');

%Plot cumulative returns with dateticks
%plot(thisPerformance.thisStrategy.datenum,thisPerformance.thisStrategy.cumLogRet);
%datetick('x','yyyy-mm', 'keepticks', 'keeplimits')
