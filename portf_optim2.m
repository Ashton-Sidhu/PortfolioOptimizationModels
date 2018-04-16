clc;
clear all;
format long

global bPrice;

% Input files
input_file_prices  = 'C:\Users\ashto\OneDrive\Documents\MIE1622\MIE1622H_Assign1_data\Daily_closing_prices.csv';


% Read daily prices
if(exist(input_file_prices,'file'))
  fprintf('\nReading daily prices datafile - %s\n', input_file_prices)
  fid = fopen(input_file_prices);
     % Read instrument tickers
     hheader  = textscan(fid, '%s', 1, 'delimiter', '\n');
     headers = textscan(char(hheader{:}), '%q', 'delimiter', ',');
     tickers = headers{1}(2:end);
     % Read time periods
     vheader = textscan(fid, '%[^,]%*[^\n]');
     dates = vheader{1}(1:end);
  fclose(fid);
  data_prices = dlmread(input_file_prices, ',', 1, 1);
else
  error('Daily prices datafile does not exist')
end

% Convert dates into array [year month day]
format_date = 'mm/dd/yyyy';
dates_array = datevec(dates, format_date);
dates_array = dates_array(:,1:3);

% Find the number of trading days in Nov-Dec 2014/2007 and
% compute expected return and covariance matrix for period 1
day_ind_start0 = 1;
%day_ind_end0 = length(find(dates_array(:,1)==2007));
day_ind_end0 = length(find(dates_array(:,1)==2014));
cur_returns0 = data_prices(day_ind_start0+1:day_ind_end0,:) ./ data_prices(day_ind_start0:day_ind_end0-1,:) - 1;
mu = mean(cur_returns0)';
Q = cov(cur_returns0);

% Remove datapoints for year 2014/2007
data_prices = data_prices(day_ind_end0+1:end,:);
dates_array = dates_array(day_ind_end0+1:end,:);
dates = dates(day_ind_end0+1:end,:);

% Initial positions in the portfolio
init_positions = [5000 950 2000 0 0 0 0 2000 3000 1500 0 0 0 0 0 0 1001 0 0 0]';


% Initial value of the portfolio
init_value = data_prices(1,:) * init_positions;
fprintf('\nInitial portfolio value = $ %10.2f\n\n', init_value);


% Initial portfolio weights
w_init = (data_prices(1,:) .* init_positions')' / init_value;

% Number of periods, assets, trading days
N_periods = 6*length(unique(dates_array(:,1))); % 6 periods per year
N = length(tickers);
N_days = length(dates);

% Annual risk-free rate for years 2015-2016 is 2.5%
r_rf = 0.025;
% Annual risk-free rate for years 2008-2009 is 4.5%
r_rf2008_2009 = 0.045;

% Number of strategies
strategy_functions = {'strat_buy_and_hold' 'strat_equally_weighted' 'strat_min_variance' 'strat_max_Sharpe' 'strat_equal_risk_contr' 'strat_lever_equal_risk_contr' 'strat_robust_optim'};
strategy_names     = {'Buy and Hold' 'Equally Weighted Portfolio' 'Minimum Variance Portfolio' 'Maximum Sharpe Ratio Portfolio' 'Equal Risk Contributions Portfolio' 'Leveraged Equal Risk Contributions Portfolio' 'Robust Optimization Portfolio'};
%N_strat = 7; % comment this in your code
N_strat = length(strategy_functions); % uncomment this in your code
fh_array = cellfun(@str2func, strategy_functions, 'UniformOutput', false);

bValue = [];
eValue = [];
minValue = [];
maxValue = [];
eRisk = [];
levERisk = [];
robOpt = [];
bWeights = [];
eWeights = [];
minWeights = [];
maxWeights = [];
eRiskWeights = [];
levEWeights = [];
robOptWeights = [];

for (period = 1:N_periods)
   % Compute current year and month, first and last day of the period
   if(dates_array(1,1)==15)
       %cur_year  = 08 + floor(period/7);
       cur_year  = 15 + floor(period/7);
   else
       %cur_year  = 2008 + floor(period/7);
       cur_year  = 2015 + floor(period/7);
   end
   cur_month = 2*rem(period-1,6) + 1;
   day_ind_start = find(dates_array(:,1)==cur_year & dates_array(:,2)==cur_month, 1, 'first');
   day_ind_end = find(dates_array(:,1)==cur_year & dates_array(:,2)==(cur_month+1), 1, 'last');
   fprintf('\nPeriod %d: start date %s, end date %s\n', period, char(dates(day_ind_start)), char(dates(day_ind_end)));

   % Prices for the current day
   cur_prices = data_prices(day_ind_start,:);

   % Execute portfolio selection strategies
   for(strategy = 1:N_strat)

      % Get current portfolio positions
      if(period==1)
         curr_positions = init_positions;
         curr_cash = 0;
         portf_value{strategy} = zeros(N_days,1);
      else
         curr_positions = x{strategy,period-1};
         curr_cash = cash{strategy,period-1};
      end
      
      if(strategy == 6)
          if(period == 1)
              bPrice = data_prices(day_ind_start,:) * curr_positions;
              curr_positions = 2 * curr_positions;              
          else
              bPrice = (data_prices(day_ind_start,:) * x{strategy, period - 1})/2;              
          end         
          [x{strategy,period} cash{strategy,period} weights{strategy,period}] = fh_array{strategy}(curr_positions, curr_cash, mu, Q, cur_prices);      
          % Compute portfolio value
          portf_value{strategy}(day_ind_start:day_ind_end) = (data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period}) - (bPrice * (1+r_rf/6));
            
      else   
       % Compute strategy
          [x{strategy,period} cash{strategy,period} weights{strategy,period}] = fh_array{strategy}(curr_positions, curr_cash, mu, Q, cur_prices);
          % Compute portfolio value
          portf_value{strategy}(day_ind_start:day_ind_end) = data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period};
      end
      
      % Verify that strategy is feasible (you have enough budget to re-balance portfolio)
      % Check that cash account is >= 0
      % Check that we can buy new portfolio subject to transaction costs

      %%%%%%%%%%% Insert your code here %%%%%%%%%%%%
      if(strategy == 1)
          bWeights = [bWeights weights{1, period}];
          bValue = [bValue; portf_value{1}(day_ind_start:day_ind_end)];
      
      end
             
      if(strategy == 2)          
          eWeights = [eWeights weights{2, period}];
          eValue = [eValue; portf_value{2}(day_ind_start:day_ind_end)];
      end
      if(strategy == 3)
          minWeights = [minWeights weights{3, period}];
          minValue = [minValue; portf_value{3}(day_ind_start:day_ind_end)];
      end
      if(strategy == 4)
          maxWeights = [maxWeights weights{4, period}];
          maxValue = [maxValue; portf_value{4}(day_ind_start:day_ind_end)];
      end
      if(strategy == 5)
          eRiskWeights = [eRiskWeights weights{5, period}];
          eRisk = [eRisk; portf_value{5}(day_ind_start:day_ind_end)];
      end
      if(strategy == 6)
          levEWeights = [levEWeights weights{6, period}];
          levERisk = [levERisk; portf_value{6}(day_ind_start: day_ind_end)];       
      end
      if(strategy == 7)
          robOptWeights = [robOptWeights weights{7, period}];
          robOpt = [robOpt; portf_value{7}(day_ind_start:day_ind_end)];
      end
      fprintf('   Strategy "%s", value begin = $ %10.2f, value end = $ %10.2f\n', char(strategy_names{strategy}), portf_value{strategy}(day_ind_start), portf_value{strategy}(day_ind_end));

   end
      
   % Compute expected returns and covariances for the next period
   cur_returns = data_prices(day_ind_start+1:day_ind_end,:) ./ data_prices(day_ind_start:day_ind_end-1,:) - 1;
   mu = mean(cur_returns)';
   Q = cov(cur_returns);
   
end

% Plot results
% figure(1);
%%%%%%%%%%% Insert your code here %%%%%%%%%%%%
xAxisPeriod = linspace(1,N_periods);
xAxisDates = [1:length(dates)];
stocks = ["MSFT", "F",	"CRAY",	"GOOG",	"HPQ",	"YHOO",	"HOG",	"VZ",	"AAPL",	"IBM",	"T", "CSCO", "BAC",	"INTC",	"AMD",	"SNE",	"NVDA",	"AMZN",	"MS","BK"];
% 
% figure(1)
% area(minWeights')
% axis([1,12,0,1])
% legend(stocks);
% legend("Location", "northeastoutside");
% title("Min Variance Area Weight per Stock Per Period");
% xlabel("Period");
% ylabel("Weight");
% 
% figure(4)
% plot(minWeights')
% axis([1,12,0,1])
% legend(stocks);
% legend("Location", "northeastoutside");
% title("Min Variance Weight Graph per Stock Per Period");
% xlabel("Period");
% ylabel("Weight");
% 
% figure(2)
% area(maxWeights')
% axis([1,12,0,1])
% legend(stocks);
% legend("Location", "northeastoutside");
% title("Max Sharpe Ratio Area Weight Graph per Stock Per Period");
% xlabel("Period");
% ylabel("Weight");
% 
% figure(5)
% plot(maxWeights')
% axis([1,12,0,1])
% legend(stocks);
% legend("Location", "northeastoutside");
% title("Max Sharpe Portfolio Weight Graph per Stock Per Period");
% xlabel("Period");
% ylabel("Weight");

figure(6)
plot(robOptWeights')
axis([1,12,0,1])
legend(stocks);
legend("Location", "northeastoutside");
title("Robust Optimization Graph per Stock Per Period");
xlabel("Period");
ylabel("Weight");


figure(3)
plot(xAxisDates, bValue) 
hold on
plot(xAxisDates, eValue)
hold on
plot(xAxisDates, minValue)
hold on
plot(xAxisDates, maxValue)
hold on
plot(xAxisDates, eRisk)
hold on
plot(xAxisDates, levERisk)
hold on
plot(xAxisDates, robOpt)
legend('Buy and Hold', 'Equally Weighted', 'Minimum Variance', 'MaxSharpe Ratio', 'Equal Risk', 'Leveraged Equal Risk', 'Robust Optimization');
legend("Location", "northwest");
title("Portfolio Value Per Day Over 2 Years");
xlabel("Day");
ylabel("Portfolio Value");
hold off
