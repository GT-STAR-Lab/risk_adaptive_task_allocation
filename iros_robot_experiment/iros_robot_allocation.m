clc; clear all;

% Global variables used in optimization functions
global Q_mu Q_sig Y_s M S T N_species

% Size declarations
n_traits_target = 2;
n_tasks = 2;
n_species = 2;
S = n_species;
T = n_traits_target;
M = n_tasks;

trials =1;

gs = GlobalSearch('Display', 'off');

strata_sols = zeros(n_tasks, n_species, trials);
probbased_sols = zeros(n_tasks, n_species, trials);

% Define objective function and nonlinear constraints
min_match_objective = @(X) -min_match_maxmin_prob(X);
strata_min_match_objective = @(X) strata_min_match_obj_novar(X);
nonlincon = @(X) round_nonlincon(X);


params = [];


params.N_species = [6 9];

params.mu_rand_mult  = 1; % 2
params.mu_dom_mult   = 1; % 1
params.sig_rand_mult = 1;
params.sig_dom_mult  = .5;


%Q_mu = ( params.mu_dom_mult *eye(n_species) + params.mu_rand_mult * rand(n_species));
Q_mu = [2 1; 1 2];
Q_sig = eye(n_traits_target).*ones(n_traits_target, n_traits_target, n_species);
% Q_sig =  Q_sig .* rand(n_traits_target,n_traits_target, n_species) * params.sig_rand_mult;
% for j = 1:n_traits_target
%     Q_sig(j,j,j) = rand(1)*params.sig_dom_mult;
% end



params.Q_mu = Q_mu;
params.Q_sig = Q_sig;
%
total_res = sum(generate_X_rand(params.N_species, n_tasks)*params.Q_mu,1);
resource_dist = rand(n_tasks, n_species);
resource_dist = resource_dist./sum(resource_dist,1) .* total_res;
params.Y_s = max(eye(n_traits_target).*total_res - 10,0);


%% Perform STRATA Optimization


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
b = [params.N_species zeros(1,n_tasks*n_species)];
beq = params.N_species;
lb = zeros(n_tasks, n_species);
ub = zeros(n_tasks, n_species)+params.N_species;

% Make local parameters global
N_species = params.N_species;
Q_mu = params.Q_mu;
Q_sig = params.Q_sig;
Y_s = params.Y_s;


% Optimization parameters needed to complete opt. A max of 10000
% iterations seems to work fine.
options = optimset('MaxFunEvals',10000, 'Display', 'off', 'algorithm','sqp');

X_init = generate_X_rand(params.N_species, n_tasks);

% Solve STRATA optimization
problem =  createOptimProblem('fmincon', 'x0', X_init, 'objective',  @(X) strata_min_match_obj(X),'Aineq', A,...
    'bineq', b,'lb', lb, 'ub', ub,  'options', options);


% X_sol_temp = run(gs,problem);
% X_strata_sol = round(X_sol_temp)
% [P_strata, task_P_strata] = min_match_prob(X_strata_sol);
% params.strata_sol = X_strata_sol;

X_sol_temp = run(gs,problem);
 [P, task_P] = min_match_prob(X_sol_temp);
X_strata_sol = round_X(X_sol_temp, N_species, P)
[P_strata, task_P_strata] = min_match_prob(X_strata_sol);
params.strata_sol = X_strata_sol;

% Do the NOVAR solution

options = optimset('MaxFunEvals',10000, 'Display', 'off', 'algorithm','sqp');

X_init = generate_X_rand(params.N_species, n_tasks);

% Solve STRATA optimization
problem =  createOptimProblem('fmincon', 'x0', X_init, 'objective',  @(X) strata_min_match_obj_novar(X),'Aineq', A,...
    'bineq', b,'lb', lb, 'ub', ub,  'options', options);


% X_sol_temp = run(gs,problem);
% X_strata_novar_sol = round(X_sol_temp)
% [P_strata, task_P_strata] = min_match_prob(X_strata_novar_sol);
% params.strata_novar_sol = X_strata_novar_sol;

X_sol_temp = run(gs,problem);
 [P, task_P] = min_match_prob(X_sol_temp);
X_strata_novar_sol = round_X(X_sol_temp, N_species, P)
[P_strata, task_P_strata] = min_match_prob(X_strata_novar_sol);
params.strata_novar_sol = X_strata_novar_sol;

%% Perform Prob-based Optimization

A = zeros(n_species, n_tasks*n_species);
task_num = 1:n_species;
task_idx = ones(n_tasks, 1);
task_idx = task_idx*task_num;
idx = sub2ind(size(A),task_idx(:),(1:(n_tasks*n_species))');
A(idx) = 1;
Aeq = A;
A = [A; -eye(n_tasks*n_species)];
b = [params.N_species zeros(1,n_tasks*n_species)];
beq = params.N_species;
lb = zeros(n_tasks, n_species);
ub = zeros(n_tasks, n_species)+params.N_species;


% Optimization parameters needed to complete opt. A max of 10000
% iterations seems to work fine.
options = optimset('MaxFunEvals',10000, 'Display', 'off','algorithm','sqp');

X_init = X_strata_sol;


% Solve Prob-based Method optimization
problem =  createOptimProblem('fmincon', 'x0', X_init, 'objective', min_match_objective,'Aineq', A,...
    'bineq', b, 'options', options);


X_sol_temp = run(gs,problem);
 [P, task_P] = min_match_prob(X_sol_temp);
X_sol = round_X(X_sol_temp, N_species, P)

% X_sol = round(X_sol_temp)

params.probbased_sol = X_sol;
[P_pbased, task_P_pbased] = min_match_prob(X_sol);

save('/Users/maxrudolph/Documents/research/rail/stratapp/algo/matlab/iros_robot_experiment/params.mat', 'params')

