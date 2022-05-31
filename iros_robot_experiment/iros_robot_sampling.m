clear all; clc; close all;

data_path = which('iros_robot_experiment.m');
load([data_path(1:end-23) 'params.mat']);

N = 10000;
spec1_mu = params.Q_mu(:,1)';
spec2_mu = params.Q_mu(:,2)';

spec1_sig = params.Q_sig(:,:,1);
spec2_sig = params.Q_sig(:,:,2);

spec1_trait = mvnrnd(spec1_mu,spec1_sig, N*params.N_species(1));
spec2_trait = mvnrnd(spec2_mu,spec2_sig, N*params.N_species(2));

spec1_trait(spec1_trait < 0) = 0;
spec2_trait(spec2_trait < 0) = 0;

X_strata = params.strata_sol;
X_strata_novar = params.strata_novar_sol;
X_probbased = params.probbased_sol;
X_random = generate_X_rand(params.N_species, length(params.Q_mu));

Y_s = params.Y_s;
Y_probbased_tot = 0;
Y_strata_tot = 0;
strata_succ = 0;
probbased_succ = 0;
Q_tot = 0;

strata_succ_task1= 0;
strata_succ_task2= 0;
strata_novar_succ_task1= 0;
strata_novar_succ_task2= 0;
probbased_succ_task1= 0;
probbased_succ_task2= 0;
rand_succ_task1 = 0;
rand_succ_task2 = 0;

strata_succ_all = 0;
strata_novar_succ_all = 0;
probbased_succ_all = 0;
rand_succ_all  = 0;


Y_stratas = zeros(2,2, N);
Y_probbaseds = zeros(2,2,N);
for i = 1:N
    X_random = generate_X_rand(params.N_species, length(params.Q_mu));
    
    species1_task1_strata = spec1_trait(1:X_strata(1,1), :);
    species1_task2_strata = spec1_trait((X_strata(1,1)+1):params.N_species(1), :);
    
    species1_task1_probbased = spec1_trait(1:X_probbased(1,1), :);
    species1_task2_probbased = spec1_trait( (X_probbased(1,1)+1):params.N_species(1), :);
    
    species1_task1_rand = spec1_trait(1:X_random(1,1), :);
    species1_task2_rand = spec1_trait( (X_random(1,1)+1):params.N_species(1), :);
    
    species1_task1_strata_novar = spec1_trait(1:X_strata_novar(1,1), :);
    species1_task2_strata_novar = spec1_trait((X_strata_novar(1,1)+1):params.N_species(1), :);
    
    species2_task1_strata = spec2_trait(1:X_strata(1,2), :);
    species2_task2_strata = spec2_trait( (X_strata(1,2)+1):params.N_species(2), :);
    
    species2_task1_rand = spec2_trait(1:X_random(1,2), :);
    species2_task2_rand = spec2_trait( (X_random(1,2)+1):params.N_species(2), :);
    
    species2_task1_probbased = spec2_trait(1:X_probbased(1,2), :);
    species2_task2_probbased = spec2_trait( (X_probbased(1,2)+1):params.N_species(2), :);
    
    species2_task1_strata_novar = spec2_trait(1:X_strata_novar(1,2), :);
    species2_task2_strata_novar = spec2_trait( (X_strata_novar(1,2)+1):params.N_species(2), :);
    
    
    spec2_trait(1:params.N_species(2),:) = [];
    spec1_trait(1:params.N_species(1),:) = [];
    
    Y_strata = [sum([species1_task1_strata; species2_task1_strata],1); sum([species1_task2_strata; species2_task2_strata],1)];
    Y_probbased = [sum([species1_task1_probbased; species2_task1_probbased],1); sum([species1_task2_probbased; species2_task2_probbased],1)];
    Y_rand = [sum([species1_task1_rand; species2_task1_rand],1); sum([species1_task2_rand; species2_task2_rand],1)];
    Y_strata_novar = [sum([species1_task1_strata_novar; species2_task1_strata_novar],1); sum([species1_task2_strata_novar; species2_task2_strata_novar],1)];
    
    strata_satisfied = Y_strata >= Y_s;
    strata_novar_satisfied = Y_strata_novar >= Y_s;
    probbased_satisfied = Y_probbased >= Y_s;
    rand_satisfied = Y_rand >= Y_s;
    
    Q_tot = inv(X_probbased)*Y_probbased + Q_tot;
    
    Y_stratas(:,:,i) = Y_strata;
    Y_probbaseds(:,:,i) = Y_probbased;
    
    strata_succ = all(strata_satisfied, 2);
    probbased_succ = all(probbased_satisfied, 2);
    rand_succ = all(rand_satisfied, 2);
    strata_novar_succ = all(strata_novar_satisfied, 2);
    
    strata_succ_all = all(strata_satisfied, 'all')/(N) + strata_succ_all;
    strata_novar_succ_all = all(strata_novar_satisfied, 'all')/(N) + strata_novar_succ_all;
    probbased_succ_all = all(probbased_satisfied, 'all')/(N) + probbased_succ_all;
    rand_succ_all = all(rand_satisfied, 'all')/(N) + rand_succ_all;
    
    strata_succ_task1 = strata_succ(1)/N + strata_succ_task1;
    strata_succ_task2 = strata_succ(2)/N + strata_succ_task2;
    strata_novar_succ_task1 = strata_novar_succ(1)/N + strata_novar_succ_task1;
    strata_novar_succ_task2 = strata_novar_succ(2)/N + strata_novar_succ_task2;
    probbased_succ_task1 = probbased_succ(1)/N + probbased_succ_task1;
    probbased_succ_task2 = probbased_succ(2)/N + probbased_succ_task2;
    rand_succ_task1 = rand_succ(1)/N + rand_succ_task1;
    rand_succ_task2 = rand_succ(2)/N + rand_succ_task2;
end


task_probs = [strata_succ_task1;
    strata_succ_task2;
    strata_novar_succ_task1;
    strata_novar_succ_task2;
    probbased_succ_task1;
    probbased_succ_task2;
    rand_succ_task1;
    rand_succ_task2]';

ANDed_task_probs = [strata_succ_all,strata_novar_succ_all,probbased_succ_all,rand_succ_all];



        
bar_data = [rand_succ_task1 strata_novar_succ_task1 strata_succ_task1 probbased_succ_task1;
            rand_succ_task2 strata_novar_succ_task2 strata_succ_task2 probbased_succ_task2;
            rand_succ_all strata_novar_succ_all strata_succ_all probbased_succ_all];
 
 labels = categorical({'Task 1','Task 2','Task 1&2'});
 labels = reordercats(labels,{'Task 1','Task 2','Task 1&2'});

 ax = bar(labels, bar_data)

 grid minor;
 legend({'Random', 'Risk-Neutral', 'Risk-Averse','Risk-Adaptive (Ours)' })
 ylabel('P(Success)')
 ylim([0 1])
set(gca, 'fontsize', 30)

