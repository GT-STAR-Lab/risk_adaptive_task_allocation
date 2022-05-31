function [P, Pm] = min_match_prob(X)
% min_match_prob  Calcs probability of P(Y > Y*) from an assigment X.
global Q_mu Y_s Q_sig M S sig

Y_mu = X*Q_mu;
P = 0;
Pm = [];
for task = 1:M
    
    % Calculate trait covariance matrix for each task
    sig = Q_sig(:,:,1)*0;
    for spec = 1:S
        sig = sig + X(task, spec).^2 * Q_sig(:, :, spec);
    end
    
    % Calculate the objective function value according to equations found
    % in STRATA++. Ensure no errors incase det(sig) <= 0
    if det(sig) > 0
        val = (mvncdf(Y_s(task, :)',Y_s(task, :)'+Inf,  Y_mu(task, :)', sig))/M;
        P = P + val;
        Pm = [Pm val*M];
    else 
        Pm = [Pm 0];
    end
end

end