clear; clc; clf; close all;
path = which('plot_results.m');
data_path = [path(1:end-31) 'data/'];

data_id = 8200;
load([data_path 'min_match_under_' num2str(data_id) '.mat'])

n_tasks = 3;
strata_probs = min_match_under_data.strata_sol_probs;
probbased_probs = min_match_under_data.probbased_sol_probs;
random_probs = min_match_under_data.random_task_min_probs;

task_probs_strata = reshape(min_match_under_data.strata_task_sols, n_tasks, numel(min_match_under_data.strata_task_sols)/n_tasks);
task_probs_strata_novar = reshape(min_match_under_data.strata_novar_task_sols, n_tasks, numel(min_match_under_data.strata_task_sols)/n_tasks);
task_probs_probbased = reshape(min_match_under_data.probbased_task_sols, n_tasks, numel(min_match_under_data.strata_task_sols)/n_tasks);
task_probs_random = reshape(min_match_under_data.random_task_probs, n_tasks, numel(min_match_under_data.strata_task_sols)/n_tasks);

strata_diffs = task_probs_strata-task_probs_probbased;
strata_novar_diffs = task_probs_strata_novar-task_probs_probbased;
random_diffs = task_probs_random-task_probs_probbased;


strata_probs = min(task_probs_strata, [], 1)';
probbased_probs = min(task_probs_probbased, [], 1)';
random_probs = min(task_probs_random, [], 1)';
strata_novar_probs = min(task_probs_strata_novar, [], 1)';

 strata_diffs = strata_probs-probbased_probs;
 strata_novar_diffs = strata_novar_probs-probbased_probs;
 random_diffs = random_probs-probbased_probs;

f = figure(1)
rand_label = {'Random'};
rnet_label = {'Risk-Neutral'};
rave_label = {'Risk-Averse'};
rawa_label = {'Risk-Adaptive (Ours)'};


min_probs = [random_probs(:); strata_novar_probs(:); strata_probs(:); probbased_probs(:) ];
labels = cell(1, length(min_probs));

labels(1:end/4) =rand_label;
labels(end/4+1:end/2) = rnet_label;
labels(end/2+1:3/4*end) = rave_label;
labels(end*3/4+1:end) = rawa_label;
grouporder = [rand_label, rnet_label, rave_label, rawa_label];
va = violinplot(min_probs, labels, 'GroupOrder', grouporder, 'ViolinColor', [.1 .5 .1])

grid on;
ylabel('min P(Success)', 'fontsize', 18)
set(gca, 'GridAlpha', .5)
% title('Minimum Probability Across Task', 'fontsize', 15)
x0=500;
y0=500;
width=750;
height=500
set(gcf,'position',[x0,y0,width,height])


figure(2)

task_probs = [ task_probs_random(:); task_probs_strata_novar(:); task_probs_strata(:); task_probs_probbased(:)];
labels = cell(1, length(task_probs));

labels(1:end/4) =rand_label;
labels(end/4+1:end/2) = rnet_label;
labels(end/2+1:3/4*end) = rave_label;
labels(end*3/4+1:end) = rawa_label;
grouporder = [rand_label, rnet_label, rave_label, rawa_label];
va = violinplot(task_probs, labels, 'GroupOrder', grouporder)
% title('Individual Task Probabilities', 'fontsize', 15)

set(gca, 'GridAlpha', .5)
ylabel('P(Success)', 'fontsize', 20)
grid on;
x0=500;
y0=500;
width=750;
height=500

set(gcf,'position',[x0,y0,width,height])


figure(3)

task_probs = [random_diffs(:); strata_novar_diffs(:); strata_diffs(:)];
labels = cell(1, length(task_probs));

labels(1:end/3) = rand_label;
labels(end/3+1:2*end/3) = rnet_label;
labels(2*end/3+1:end) = rave_label;

grouporder = [rand_label, rnet_label, rave_label];
va = violinplot(task_probs, labels, 'GroupOrder', grouporder)


set(gca, 'GridAlpha', .5)
ylabel('P(Success)', 'fontsize', 20)
grid on;
x0=500;
y0=500;
width=750;
height=500

set(gcf,'position',[x0,y0,width,height])
