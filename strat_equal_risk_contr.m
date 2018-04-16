function  [x_optimal, cash_optimal, w_Optimal] = strat_equal_risk_contr(x_init, cash_init, mu, Q, cur_prices)
    
    
    
    global Q A_ineq A_eq
    n = length(x_init);
    % Equality constraints
    A_eq = ones(1,n);
    b_eq = 1;
    
    
    % Inequality constraints
    A_ineq = [];
    b_ineql = [];
    b_inequ = [];
    weights_init = [];

    for i = 1:length(x_init)
        weights_init(i) = cur_prices(i) * x_init(i) / (cur_prices * x_init);
    end
        
    
    w0 = weights_init;
    w0 = w0';
    %w0 = repmat(1.0/n, n, 1);

    options.lb = zeros(1,n);       % lower bounds on variables
    options.lu = ones (1,n);       % upper bounds on variables
    options.cl = [b_eq' b_ineql']; % lower bounds on constraints
    options.cu = [b_eq' b_inequ']; % upper bounds on constraints

    % Set the IPOPT options
    options.ipopt.jac_c_constant        = 'yes';
    options.ipopt.hessian_approximation = 'limited-memory';
    options.ipopt.mu_strategy           = 'adaptive';
    options.ipopt.tol                   = 1e-300;
    options.ipopt.print_level           = 0;
    % The callback functions
    funcs.objective         = @computeObjERC;
    funcs.constraints       = @computeConstraints;
    funcs.gradient          = @computeGradERC;
    funcs.jacobian          = @computeJacobian;
    funcs.jacobianstructure = @computeJacobian;

    % !!!! Function "computeGradERC" is just the placeholder
    % !!!! You need to compute the gradient yourself

    %% Run IPOPT
    [wsol info] = ipopt(w0',funcs,options);

    % Make solution a column vector
    if(size(wsol,1)==1)
        w_erc = wsol';
    else
        w_erc = wsol;
    end

    % Compute return, variance and risk contribution for the ERC portfolio
    ret_ERC = dot(mu, w_erc);
    var_ERC = w_erc'*Q*w_erc;
     RC_ERC = (w_erc .* ( Q*w_erc )) / sqrt(w_erc'*Q*w_erc);
     
    totalCash = cash_init + (cur_prices * x_init);
    cash = cash_init;
    wOptimal = w_erc;
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
