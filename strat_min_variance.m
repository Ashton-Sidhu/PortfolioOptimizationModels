function  [x_optimal, cash_optimal, w_Optimal] = strat_min_variance(x_init, cash_init, mu, Q, cur_prices)

    n = length(x_init);
    lb = zeros(n,1);
    ub = inf*ones(n,1);
    A = ones(1,n);
    b = 1;
    

    %Calculate MVP    
    cplexMVP = Cplex('min_Variance');
    cplexMVP.addCols(zeros(n,1), [], lb, ub);
    cplexMVP.addRows(b, A, b);
    cplexMVP.Model.Q = 2*Q;
    cplexMVP.Param.qpmethod.Cur = 6;
    cplexMVP.Param.barrier.crossover.Cur = 1;
    cplexMVP.DisplayFunc = [];
    cplexMVP.solve();
    
    wOptimal = cplexMVP.Solution.x;
    var_minVar = wOptimal' * Q * wOptimal;
    ret_minVar = mu' * wOptimal;
    
    totalCash = cash_init + (cur_prices * x_init);
    cash = cash_init;
    %Calculate optimal shares
    for (i = 1:length(x_init))
        x_optimal(i) = floor((wOptimal(i) * totalCash) / cur_prices(i));
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
            x_optimal(i) = floor((wOptimal(i) * totalCash) / cur_prices(i));
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
    
    w_Optimal = wOptimal;
    x_optimal = x_optimal';
    cash_optimal = cash;
    
end

