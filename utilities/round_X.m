function [X_out] = round_X(X,N_species, P)
X = round(X);
over_spec = find(sum(X,1) > N_species);
[sorted sorted_prob_idx] = sort(P, 'descend');
for spec = over_spec 
    for prob_idx = sorted_prob_idx
       if sum(X(:, spec)) > N_species(spec) & X(prob_idx,spec) > 0
           X(prob_idx, spec) = X(prob_idx,spec) - 1;
       end
    end    
end
% under_spec = find(sum(X,1) < N_species);
% for spec = under_spec 
%     for prob_idx = sorted_prob_idx(end:-1:1)
%        if sum(X(:, spec)) < N_species(spec) & X(prob_idx,spec) > 0
%            X(prob_idx, spec) = X(prob_idx,spec) + 1;
%        end
%     end    
% end

X_out = X;
end