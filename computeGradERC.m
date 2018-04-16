function gval = computeGradERC (x)

global Q
  
  n = size(Q,1) ; 
  
%   std = sqrt(x * (Q*(x'))); 

  if(size(x,1)==1)
     x = x';
  end

  y = (Q*x) ; 
  
  gval = [] ; 
  for z = 1:n
      xij = 0;
      for i = 1:n        
        for j = i+1:n
          if i == z
              gradI = y(i) + Q(i, i) * x(i);
          else
              gradI = Q(i, z) * x(i);
          end             

          if j == z
              gradJ = y(j) + Q(j, j) * x(j);
          else
              gradJ = Q(j, z) * x(j);
          end
          
          xij  = xij + ((y(i) - y(j)) * (gradI - gradJ));           
        end 
      end
      gval(z) = xij;
  end

  gval = 8*gval;
  
%   for(i = 1:length(x))
%       grd = (x')*Q;
%       gval(i) = grd(i);
%   end   
   
   grad1 = zeros(n, 1);

    diff = 1e-6;

    for i = 1:n

        x_left = x;

        x_left(i) = x_left(i) - diff;

        x_right = x;

        x_right(i) = x_right(i) + diff;

        result = (computeObjERC(x_right) - computeObjERC(x_left)) / (2 * diff);

        

        grad1(i) = result;

    end

    %gval = grad;
end
