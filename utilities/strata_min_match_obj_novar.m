function [P] = strata_min_match_obj_novar(X)
% min_match_prob  Calcs probability of P(Y > Y*) from an assigment X.
global Q_mu Y_s Q_sig M S

X = reshape(X, M, S);
Y_mu = X*Q_mu;

sig = [];
sig_cost = 0;
for task = 1:M
    % Calculate trait covariance matrix for each task
    task_sig = Q_sig(:,:,1)*0;
    for spec = 1:S
        task_sig = task_sig + X(task, spec).^2 * Q_sig(:, :, spec);
    end
    
    sig = [sig task_sig];
    sig_cost = sig_cost + norm(task_sig, 'fro')^2;
end

P = norm(max(Y_s - Y_mu, 0),'fro')^2 ;

end