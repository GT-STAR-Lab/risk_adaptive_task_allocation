clc; clear all;

% Global variables used in optimization functions
global Q_mu Q_sig Y_s M S T N_species

% Size declarations
n_traits_target = 3;
n_tasks = 3;
n_species = 3;
S = n_species;
T = n_traits_target;
M = n_tasks;

trials = 100;

gs = GlobalSearch;

strata_sols = zeros(n_tasks, n_species, trials);
probbased_sols = zeros(n_tasks, n_species, trials);
strata_novar_sols = zeros(n_tasks, n_species, trials);

% Define objective function and nonlinear constraints
min_match_objective = @(X) -min_match_maxmin_prob(X);
strata_min_match_objective = @(X) strata_min_match_obj(X);
strata_min_match_objective_novar = @(X) strata_min_match_obj_novar(X);


params = [];
for i = 1:trials
    params(i).N_species = randi([5 15], 1, n_species);
    %params(i).N_species = randi([15 25], 1, n_species);
    
    
    % [1 4 0.15 0.1], over resourcing [2 12] <- good for making var and no var similar r
    % [1 4 1 0.5]over resourcing [2 12] <- Good for general use (novar is better than var)
    params(i).mu_rand_mult  = 1; % 1
    params(i).mu_dom_mult   = 4; % 4
    params(i).sig_rand_mult = 1; % 1
    params(i).sig_dom_mult  = 0.5; % 0.5
    
    params(i).range = [6 12];
    
    Q_mu = ( params(i).mu_dom_mult *eye(n_species) + params(i).mu_rand_mult * rand(n_species));
    Q_sig = eye(n_traits_target).*ones(n_traits_target, n_traits_target, n_species);
    Q_sig =  Q_sig .* rand(n_traits_target,n_traits_target, n_species) * params(i).sig_rand_mult;
    for j = 1:n_traits_target
        Q_sig(j,j,j) = rand(1)*params(i).sig_dom_mult;
    end
    for j = 1:n_traits_target
        Q_sig(j,j,:) = Q_sig(j,j,:) + 0.01;
    end
    
    
    params(i).Q_mu = Q_mu;
    params(i).Q_sig = Q_sig;
    %
    total_res = sum(generate_X_rand(params(i).N_species, n_tasks)*params(i).Q_mu,1);
    resource_dist = rand(n_tasks, n_species);
    resource_dist = resource_dist./sum(resource_dist,1) .* total_res;

    params(i).Y_s = max(resource_dist + (rand(n_tasks, n_species)*(params(i).range(2) - params(i).range(1)) - params(i).range(2)), 0);
    
end

min_match_under_data.params = params;

%% Perform STRATA Optimization
strata_time = 0;
strata_novar_time = 0;
prob_time = 0;
X_sols = [];
X_exacts = [];
random_task_min_probs = [];
random_task_probs = [];
trait_mm_strata = [];
task_sols = [];
task_sols_novar = [];

for i = 1:trials
    
    % Build linear constraints forcing agent assignment to be
    % nonnegative and forcing a maximum number of agents per species
    
    A = zeros(n_species, n_tasks*n_species);
    task_num = 1:n_species;
    task_idx = ones(n_tasks, 1);
    task_idx = task_idx*task_num;
    idx = sub2ind(size(A),task_idx(:),(1:(n_tasks*n_species))');
    A(idx) = 1;
    Aeq = A;
    A = [A; -eye(n_tasks*n_species)];
    b = [params(i).N_species zeros(1,n_tasks*n_species)];
    beq = params(i).N_species;
    lb = zeros(n_tasks, n_species);
    ub = zeros(n_tasks, n_species)+params(i).N_species;
    
    % Make local parameters global
    N_species = params(i).N_species;
    Q_mu = params(i).Q_mu;
    Q_sig = params(i).Q_sig;
    Y_s = params(i).Y_s;
    
    
    % Optimization parameters needed to complete opt. A max of 10000
    % iterations seems to work fine.
    options = optimset('MaxFunEvals',10000, 'Display', 'off', 'algorithm','sqp');
    
    X_init = generate_X_rand(params(i).N_species, n_tasks);
    
    tic
    problem = createOptimProblem('fmincon', 'x0', X_init, 'objective', strata_min_match_objective_novar,'Aineq', A,...
        'bineq', b,'lb', lb, 'ub', ub, 'options', options);
    X_sol_temp_novar = run(gs, problem);
    [P, task_P] = min_match_prob(X_sol_temp_novar);
    X_sol_temp_novar = round_X(X_sol_temp_novar, N_species, task_P);
    strata_novar_sols(:,:,i) = X_sol_temp_novar;
    strata_novar_time = strata_novar_time + toc;
    tic
    % Solve STRATA optimization
    problem = createOptimProblem('fmincon', 'x0', X_init, 'objective', strata_min_match_objective,'Aineq', A,...
        'bineq', b,'lb', lb, 'ub', ub, 'options', options);
    
    X_sol_temp = run(gs,problem);
    [P, task_P] = min_match_prob(X_sol_temp);
    X_sol_temp = round_X(X_sol_temp, N_species, task_P);
    strata_sols(:,:,i) = X_sol_temp;
    
    strata_time = strata_time + toc;
%     
%     [cur_val, vals] = min_match_prob(round(X_sol_temp));
%     [cur_val_novar, vals_novar] = min_match_prob(round(X_sol_temp_novar));
    
    X_sol = round(X_sol_temp);
%     strata_novar_sols(:,:,i) = X_sol;
    
    % Calc performance with optimied X.
    [P, task_P] =  min_match_prob(X_sol_temp);
    [P_novar, task_P_novar] = min_match_prob(round(X_sol_temp_novar));
    
    X_sols = [X_sols min(task_P)];
    task_sols = [task_sols task_P];
    task_sols_novar = [task_sols_novar, task_P_novar];
    
    
    [random_P, random_task_P] =  min_match_prob(generate_X_rand(N_species, n_tasks));
    
    random_task_min_probs = [random_task_min_probs min(random_task_P)];
    random_task_probs = [random_task_probs random_task_P];
    
    trait_mm_strata = [trait_mm_strata compute_trait_mismatch(X_sol*Q_mu, Y_s);];
    
    
    prog = i/trials;
    display(['Progress is: ' num2str(prog*100) '%'])
    
end



min_match_under_data.strata_task_sols = task_sols';
min_match_under_data.strata_sol_probs = X_sols;
min_match_under_data.strata_mismatch = trait_mm_strata;
min_match_under_data.random_task_probs = random_task_probs;
min_match_under_data.random_task_min_probs = random_task_min_probs;
min_match_under_data.strata_novar_task_sols = task_sols_novar';

min_match_under_data.strata_sols = strata_sols;

%% Perform Prob-based Optimization

X_sols = [];
trait_mm_probbased = [];
task_sols = [];

for i = 1:trials
    
    % Build linear constraints forcing agent assignment to be
    % nonnegative and forcing a maximum number of agents per species
    A = zeros(n_species, n_tasks*n_species);
    task_num = 1:n_species;
    task_idx = ones(n_tasks, 1);
    task_idx = task_idx*task_num;
    idx = sub2ind(size(A),task_idx(:),(1:(n_tasks*n_species))');
    A(idx) = 1;
    Aeq = A;
    A = [A; -eye(n_tasks*n_species)];
    b = [params(i).N_species zeros(1,n_tasks*n_species)];
    beq = params(i).N_species;
    lb = zeros(n_tasks, n_species);
    ub = zeros(n_tasks, n_species)+params(i).N_species;
    
    % Make local parameters global
    N_species = params(i).N_species;
    Q_mu = params(i).Q_mu;
    Q_sig = params(i).Q_sig;
    Y_s = params(i).Y_s;

    
    % Optimization parameters needed to complete opt. A max of 10000
    % iterations seems to work fine.
    options = optimset('MaxFunEvals',10000, 'Display', 'off','algorithm','sqp');
    
    X_init = min_match_under_data.strata_sols(:,:,i);
    
    
    % Solve Prob-based Method optimization
    tic
    problem =  createOptimProblem('fmincon', 'x0', X_init, 'objective', min_match_objective,'Aineq', A,...
        'bineq', b, 'options', options);
    
    X_sol_temp = run(gs,problem);
    [P, task_P] = min_match_prob(X_sol_temp);
    X_sol_temp_novar = round_X(X_sol_temp, N_species, task_P);
    prob_time = prob_time + toc;
    %X_sol_temp = fmincon(min_match_objective, X_init, A,b , ...
    %    Aeq, beq, lb, ub, nonlincon, options);
    
    X_sol = round(X_sol_temp);
    probbased_sols(:,:,i) = X_sol;
    
    % Calc performance with optimied X.
    [P, task_P] =  min_match_prob(X_sol);
    [P_strata, task_P_strata] = min_match_prob(strata_sols(:,:,i));
    [P_strata_novar, task_P_strata_novar] = min_match_prob(strata_novar_sols(:,:,i));
    
    
    if (min(task_P) >= min(task_P_strata)) & (min(task_P) >= min(task_P_strata_novar))
        X_sols = [X_sols min(task_P)];
        task_sols = [task_sols task_P];
    else
        if min(task_P_strata) >= min(task_P_strata_novar)
            X_sols = [X_sols min(task_P_strata)];
            task_sols = [task_sols task_P_strata];
            probbased_sols(:,:,i) = strata_sols(:,:,i);
        else
            X_sols = [X_sols min(task_P_strata_novar)];
            task_sols = [task_sols task_P_strata_novar];
            probbased_sols(:,:,i) = strata_novar_sols(:,:,i);
        end
        
    end
    
    trait_mm_probbased = [trait_mm_probbased compute_trait_mismatch(X_sol*Q_mu, Y_s);];
    
    
    prog = i/trials;
    display(['Progress is: ' num2str(prog*100) '%'])
    
end



min_match_under_data.probbased_task_sols = task_sols';
min_match_under_data.probbased_sol_probs = X_sols;
min_match_under_data.probbased_mismatch = trait_mm_strata;
min_match_under_data.probbased_sols = probbased_sols;


%% Save Data
min_match_under_data.strata_time = strata_time/trials;
min_match_under_data.strata_novar_time = strata_novar_time/trials;
min_match_under_data.prob_time = prob_time/trials;
c = clock;
id = num2str(c(3)*24*60 + c(4)*60 + c(5));
path = which('monte_carlo_sim.m');
save([path(1:end-34) 'data/min_match_under_' id '.mat'], 'min_match_under_data')

