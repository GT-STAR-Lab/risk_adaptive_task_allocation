function [mismatch] = compute_trait_mismatch(Y_mu,Y_s)
%TRAIT_MISMATCH Summary of this function goes here
%   Detailed explanation goes here

mismatch.over = sum(max(Y_mu - Y_s, 0), 'all');
mismatch.under = sum(max(Y_s - Y_mu, 0), 'all');
mismatch.total = sum(Y_mu - Y_s, 'all');
mismatch.mat = Y_mu - Y_s;
end

