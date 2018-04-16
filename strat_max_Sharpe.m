function  [x_optimal, cash_optimal, wOptimal] = strat_max_Sharpe(x_init, cash_init, mu, Q, cur_prices)
    n=21;
    rf= 0.025/252;
    lb = zeros(n,1);
    ub = inf*ones(n,1);
    A = [mu'-(rf*ones(1,20)),0;ones(1,n-1),-1];
    b =[1;0];
    q =[Q,zeros(20,1);zeros(1,21)];

    %Calculate MSR    
    cplexMVP = Cplex('strat_max_Sharpe');
    cplexMVP.addCols(zeros(n,1), [], lb, ub);
    cplexMVP.addRows(b, A, b);
    cplexMVP.Model.Q = 2*q;
    cplexMVP.Param.qpmethod.Cur = 6;
    cplexMVP.Param.barrier.crossover.Cur = 1;
    cplexMVP.DisplayFunc = [];
    cplexMVP.solve();
    
    if(cplexMVP.Solution.status == 3)
        x_optimal = x_init;
        cash_optimal = cash_init;
        wOptimal = ((cur_prices .* (x_init'))') / (cur_prices * x_init);        
        return;
    end
    
    wPreOptimal = cplexMVP.Solution.x;   
    var_minVar = wPreOptimal' * q * wPreOptimal;    
    ret_minVar = [mu;0]' * wPreOptimal;
    wOptimal = wPreOptimal(1:20)/wPreOptimal(21);
    totalCash = cash_init + (cur_prices * x_init);
    cash = cash_init;
    
    %Calculate optimal number of stocks
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
    
    x_optimal = x_optimal';
    cash_optimal = cash;
    wOptimal = wOptimal;

end

