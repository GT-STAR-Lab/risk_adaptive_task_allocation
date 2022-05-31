function [X] = generate_X_rand(N_species, M)
%GENERATE_X_rand generates a random X assignment matrix X according to the
%number of agents in each species as defined by the N_species vector. M is
%the number of tasks.
% OUTPUTS
% - X: random X assignment

X = ones(M, numel(N_species)).*N_species;
for n = 1:numel(N_species)
    while sum(X(:, n)) > N_species(n)
        pos = randi([1 M], 1);
        X(pos, n) = max(X(pos, n) -1, 0);
    end
    % Non iterative way...
    %     X(:, n) = randi(N_species(n), [1, M]);
    %     X(:, n) = X(:, n) - round((sum(X(:, n)) - N_species(n))/M) -1;
    %     X(X(:, n) < 0, n) = 0;
    %     X
    %     sup = [ones(N_species(n)-sum(X(:,n)), 1); ...
    %         zeros(M - (N_species(n)-sum(X(:,n))), 1)]
    %     X(:, n) = X(:, n) + sup(randperm(length(sup)))
end
end

