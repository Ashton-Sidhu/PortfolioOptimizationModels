function  [x_optimal, cash_optimal, w_Optimal] = strat_equally_weighted(x_init, cash_init, mu, Q, cur_prices)
    
    wOptimal = 1/length(x_init);
    totalCash = cash_init + (cur_prices * x_init);
    cash = cash_init;
    
    %Calculate optimal shares
    for (i = 1:length(x_init))
        x_optimal(i) = floor((wOptimal * totalCash) / cur_prices(i));
        diffUnit(i) = x_init(i) - x_optimal(i);
        
    end
    
    %Sell stocks first so there are funds to buy the optimal amount of
    %stocks
    sellInd = find(diffUnit > 0);    
    for(i = sellInd)
        cash_pre = diffUnit(i) * cur_prices(i);
        cash = cash + ( cash_pre * 0.995);
    end
        
    buyInd = find(diffUnit < 0);
    for(i = buyInd)
        cash = cash - (0.005 * cur_prices(i) * abs(diffUnit(i))) - (cur_prices(i) * abs(diffUnit(i)));        
    end
    
    %Ensure cash is not negative and if so substract the negative amount from the total cash allotted.    
    while(cash < 0)        
        totalCash = totalCash - abs(cash);
        cash = cash_init;
        for (i = 1:length(x_init))
            x_optimal(i) = floor((wOptimal * totalCash) / cur_prices(i));
            diffUnit(i) = x_init(i) - x_optimal(i);            
        end
        sellInd = find(diffUnit > 0);    
        for(i = sellInd)
            cash_pre = diffUnit(i) * cur_prices(i);
            cash = cash + ( cash_pre * 0.995);
        end

        buyInd = find(diffUnit < 0);
        for(i = buyInd)
            cash = cash - (0.005 * cur_prices(i) * abs(diffUnit(i))) - (cur_prices(i) * abs(diffUnit(i)));        
        end        
    end
    
    x_optimal = x_optimal';
    cash_optimal = cash;
    w_Optimal = wOptimal;
    
    
      
        
    
    
        
        
        