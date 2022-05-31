%% Experiment Constants
close all; clear; clc;
%Run the simulation for a specific number of iterations
iterations = 1500;
N = 15;

data_path = which('iros_robot_experiment.m');
load([data_path(1:end-23) 'params.mat']);
STRATA = true;
videoFlag = true;
if STRATA
    X = params.strata_sol;
else
    X = params.probbased_sol;
end

% Task 2 is FIRE needs cap 2. Task 1 is Payload needs cap 1
species.task1 = sum(X(1,:));
species.task2 = sum(X(2,:));

species(1).strength = params.Q_mu(1,1);
species(1).water_cap = params.Q_mu(1,2);
species(2).strength = params.Q_mu(2,1);
species(2).water_cap = params.Q_mu(2,2);
species(1).N = params.N_species(1);
species(2).N =  params.N_species(2);

species1_idx = 1:species(1).N ;
species2_idx = (species(1).N +1):sum(params.N_species);

task1_agents = [1:X(1,1) (species(1).N +1):(species(1).N +X(1,2))];
task2_agents = [(X(1,1) + 1):(X(1,1) + X(2,1)) (task1_agents(end)+1):N];

% Generate agent capabilities
ensure_over = 1;
capabilities = [mvnrnd(params.Q_mu(1,:)'/ensure_over, params.Q_sig(:,:,1), species(1).N); ...
    mvnrnd(params.Q_mu(2,:)'/ensure_over, params.Q_sig(:,:,2), species(2).N)];
capabilities(capabilities <= 0) = .001;
cap0 = capabilities;
task1_satisfied = sum(capabilities(task1_agents,1)) >= params.Y_s(1,1);
task2_satisfied = sum(capabilities(task2_agents,2)) >= params.Y_s(2,2);
task1_carry_cap = sum(capabilities(task1_agents,1))
task2_water_cap = sum(capabilities(task2_agents,2))

task1_pos = [-1;-1];
task2_pos = [1;1];
connection_distance = 3;
death_distance = 0.1;


%% Set up the Robotarium object


initial_positions = generate_initial_conditions(N, 'Width', 1, 'Height', 1, 'Spacing', 0.2);

task1_init_pos = generate_initial_conditions(length(task1_agents), 'Width', 1, 'Height', 0.5, 'Spacing', 0.2);
task2_init_pos = generate_initial_conditions(length(task2_agents), 'Width', 1, 'Height', 1, 'Spacing', 0.2);

initial_positions(:, task1_agents) = task1_init_pos + [-1; -0.5; 0];
initial_positions(:, task2_agents) = task2_init_pos + [1; 0.5; 0];

% initial_positions(1:2, task2_agents) = .3*rand(2, lfength(task2_agents)) - 1;
r = Robotarium('NumberOfRobots', N, 'ShowFigure', true, 'InitialConditions', initial_positions);
set(gca,'Color','none')
crs = [r.boundaries(1), r.boundaries(3);
    r.boundaries(1), r.boundaries(4);
    r.boundaries(2), r.boundaries(4);
    r.boundaries(2), r.boundaries(3)];
%Initialize velocity vector
dxi = zeros(2, N);


%% Grab tools we need to convert from single-integrator to unicycle dynamics

% Single-integrator -> unicycle dynamics mapping
si_to_uni_dyn = create_si_to_uni_dynamics('LinearVelocityGain', 0.8);
% Single-integrator barrier certificates
uni_barrier_cert = create_uni_barrier_certificate_with_boundary('SafetyRadius', .1);
% Single-integrator position controller
pos_controller = create_si_position_controller('XVelocityGain', 0.8, 'YVelocityGain', 0.8, 'VelocityMagnitudeLimit', 0.08);


%% Plotting Setup
tic

% Color Vector for Plotting
% Note the Robotarium MATLAB instance runs in a docker container which will
% produce the same rng value every time unless seeded by the user.

% Import and scale the GT logo appropriately.
[gt_img, map, alphamap] = imread('fire.png'); % Original input image file

% Display the image with an associated spatial referencing object.
x_img = linspace(0, 0.1, size(gt_img,2));
y_img = linspace(0, -0.1, size(gt_img,1)); %Note the 1 to -1 here due to the (1,1) pixel being in the top left corner.

fire_pos = [-1; 0.5];
fire_size = eye(2)*0.02;
fire_units = params.Y_s(2,2)*10;


fires = mvnrnd(fire_pos, fire_size, fire_units);
fires(fires(:, 1) < -1.6, 1)  = -1.6;
fires(fires(:, 2) > 1, 2)  = 1;

for i = 1:fire_units
    %fire_handle(i) = plot(fires(i, 1), fires(i, 2),'.', 'color', [1 0 0],'markersize', 15);
    fire_handle(i) = image(x_img + fires(i,1), y_img + fires(i,2), gt_img,'CDataMapping','scaled','AlphaData', alphamap);
    
end

fire_out = false(fire_units,1);

payload_pos = [[-1.5; -0.5], [1.5 ;-0]];

%Marker, font, and line sizes
marker_size_goal = determine_marker_size(r, 0.20);
font_size = determine_font_size(r, 0.05);
line_width = 5;

for i = 1:N
    if i <= species(1).N
        species_tag(i) = plot(0,0,'.', 'markersize', 100, 'color', [1 .5 .5]);
        species_line(i) = line([0,0], [0,0], 'linewidth', 1, 'color', 'k');
    else
        species_tag(i) =  plot(0,0,'.', 'markersize', 100, 'color', [0.5 0.5 1]);
        species_line(i) = line([0,0], [0,0], 'linewidth', 1, 'Color', 'k');
    end
    
end


for i = 1:N
    if i <= species(1).N
        water_cap(i) = line([0,0], [0,0], 'linewidth', 3, 'color', 'k');
        carry_cap(i) = line([0,0], [0,0], 'linewidth', 3, 'color', 'c');
    else
        water_cap(i) = line([0,0], [0,0], 'linewidth', 3, 'color', 'k');
        carry_cap(i) = line([0,0], [0,0], 'linewidth', 3, 'color', 'c');
    end
end



g = plot(payload_pos(1,1), payload_pos(2,1),'s', ...
    'MarkerSize',marker_size_goal,'LineWidth',line_width,'Color','k', 'MarkerFaceColor',0*[1 .6 .6]);
% g = image(x_img_rock + payload_pos(1,1), y_img_rock + payload_pos(2,1), rock_img,'CDataMapping','scaled');

if videoFlag
    vid = VideoWriter(['/Users/maxrudolph/Documents/research/github_repos/risk_adaptive_task_allocation'...
        '/iros_robot_experiment/iros_risk_adaptive_robotarium.mp4'], 'MPEG-4');
    vid.Quality = 100;
    vid.FrameRate = 72;
    open(vid);
    writeVideo(vid, getframe(gcf));
end

toc
tic
%%
% Plot graph connections
%Need location of robots
x=r.get_poses();
payload_init_dis = norm( payload_pos(:, 1) - mean(x(1:2, task1_agents),2));


r.step();

for t = 1:iterations
    if videoFlag && mod(t,10)                               % Record a video frame every 10 iterations
        writeVideo(vid, getframe(gcf));
    end
    dxi = dxi*0;
    
    
    x=r.get_poses();
    
    if task1_satisfied
        for i = [task1_agents]
            
            dxi(1:2, i) =  pos_controller(x(1:2, i),payload_pos(:, 2));
            
        end
    end
    for i = [task2_agents]
        dxi(1:2, i) = pos_controller(x(1:2, i), fire_pos);
    end
    
    

    
    [~, closest_carry_id] = min(vecnorm(x(1:2, task1_agents) - payload_pos(:,1)));
    mean_vec = payload_pos(:, 1) - mean(x(1:2, task1_agents), 2);
    gain = max(norm(mean_vec)-payload_init_dis, 0);
    payload_pos(:,1) = payload_pos(:,1) - gain*(payload_pos(:, 1) - mean(x(1:2, task1_agents), 2));
    payload_mov = gain*(payload_pos(:, 1) - mean(x(1:2, task1_agents), 2));
    %% Avoid actuator errors
    
    % To avoid errors, we need to threshold dxi
    norms = arrayfun(@(x) norm(dxi(:, x)), 1:N);
    threshold = 3/4*r.max_linear_velocity;
    to_thresh = norms > threshold;
    to_thresh(1) = 0;
    dxi(:, to_thresh) = threshold*dxi(:, to_thresh)./norms(to_thresh);
    
    %% Use barrier certificate and convert to unicycle dynamics
    dxu = si_to_uni_dyn(dxi, x);
    dxu = uni_barrier_cert(dxu, x);
    
    %% Send velocities to agents
    
    %Set velocities
    r.set_velocities(1:N, dxu);
    
    %% Update Plot Handles
    update_plot_circles(x, species_tag, species, task1_agents, capabilities);
    spray_dis = .5;
    [fire_out, capabilities] = update_fire(x, task2_agents, capabilities, spray_dis, fire_out, fire_pos, fire_handle);
    
    update_cap_lines(x,water_cap, carry_cap, capabilities, cap0)
    for i = 1:N
        
        if ~isempty(find(i == task1_agents))
            species_line(i).XData = [x(1,i), payload_pos(1,1)];
            species_line(i).YData = [x(2,i), payload_pos(2,1)];
        end
    end
    
    marker_size_goal = num2cell(ones(1,length(payload_pos))*determine_marker_size(r, 0.20));
%     [g.MarkerSize] = marker_size_goal{:};
    font_size = determine_font_size(r, 0.05);
    leader_label.FontSize = font_size;
    
    g.XData =  g.XData - payload_mov(1);
    g.YData =  g.YData - payload_mov(2);
    
    
    
    %Iterate experiment
    r.step();
end



% We can call this function to debug our experiment!  Fix all the errors
% before submitting to maximize the chance that your experiment runs
% successfully.
r.debug();
if videoFlag; close(vid); end

%% Helper Functions
function [fire_out, cap] = update_fire(x, task2_agents,cap,spray_dis, fire_out,fire_pos, fire_handle)

x_task2 = x(1:2, task2_agents);
fire_out_prev = fire_out;
for i = 1:length(x_task2)
    
    if (norm(x_task2(:, i) - fire_pos ) < spray_dis) & (cap(task2_agents(i),2) > 0)
        
        active_fire = [find(~fire_out); length(fire_out)+1];
        agent_wtr = floor(cap(task2_agents(i), 2)*10);
        
        if (active_fire(1) + agent_wtr < length(fire_out))
            
            fire_out(active_fire(1):(active_fire(1) + agent_wtr)) = true;
        else
            fire_out(active_fire(1):end) = true;
        end
        
        cap(task2_agents(i), 2) = 0;
    end
end
out_idx = find(fire_out ~= fire_out_prev);
for id = 1:length(out_idx)
    % fire_handle().Color = [1 1 1 ];
    fire_handle(out_idx(id)).XData =fire_handle(i).XData  -10;
end

end
function [found] = update_obstacle(x, obstacle_pos, obs, sensing)
x = x(1:2, :);
dist = reshape(x', length(x), 1, 2) - reshape(obstacle_pos, 1, length(obstacle_pos), 2);
dist = sqrt(sum(dist.^2, 3));
found = dist < ones(length(x), length(obstacle_pos)).*sensing';
found = sum(found,1) ~= 0;
found_idx = find(found);
for fo = found_idx
    obs(fo).Color = [0,0,0];
end

end
function update_plot_circles(x,handl, species, task1_agents, capabilities)

t = 0; %linspace(0,2*pi,1);
for i = 1:numel(x)/3
    if  ~isempty(find(i == task1_agents))
        rad = 0;
        set(handl(i), 'XData', x(1,i) + rad*cos(t), 'YData', x(2,i) + rad*sin(t));
    else
        rad  = 0;
        set(handl(i), 'XData', x(1,i) + rad*cos(t), 'YData', x(2,i) + rad*sin(t));
    end
end
end
function update_cap_lines(x,water_cap, carry_cap, capabilities, cap0)
norm_cap = capabilities./max(cap0,[],1);
t = 0; %linspace(0,2*pi,1);
water_offset = [.1; .1];
carry_offset = [.15 .1];
for i = 1:numel(x)/3
    water_cap(i).XData = [x(1, i) + water_offset(1) , x(1, i) + water_offset(1)];
    water_cap(i).YData = [x(2,i) + water_offset(2) , x(2,i) + water_offset(2) + .25 * norm_cap(i,1)];
    
    carry_cap(i).XData = [x(1, i) + carry_offset(1) , x(1, i) + carry_offset(1)];
    carry_cap(i).YData = [x(2,i) + carry_offset(2) , x(2,i) + carry_offset(2) + .25 * norm_cap(i,2)];
end
end

% Marker Size Helper Function to scale size with figure window
% Input: robotarium instance, desired size of the marker in meters
function marker_size = determine_marker_size(robotarium_instance, marker_size_meters)

% Get the size of the robotarium figure window in pixels
curunits = get(robotarium_instance.figure_handle, 'Units');
set(robotarium_instance.figure_handle, 'Units', 'Points');
cursize = get(robotarium_instance.figure_handle, 'Position');
set(robotarium_instance.figure_handle, 'Units', curunits);

% Determine the ratio of the robot size to the x-axis (the axis are
% normalized so you could do this with y and figure height as well).
marker_ratio = (marker_size_meters)/(robotarium_instance.boundaries(2) -...
    robotarium_instance.boundaries(1));

% Determine the marker size in points so it fits the window. cursize(3) is
% the width of the figure window in pixels. (the axis are
% normalized so you could do this with y and figure height as well).
marker_size = cursize(3) * marker_ratio;

end

% Font Size Helper Function to scale size with figure window
% Input: robotarium instance, desired height of the font in meters
function font_size = determine_font_size(robotarium_instance, font_height_meters)

% Get the size of the robotarium figure window in point units
curunits = get(robotarium_instance.figure_handle, 'Units');
set(robotarium_instance.figure_handle, 'Units', 'Pixels');
cursize = get(robotarium_instance.figure_handle, 'Position');
set(robotarium_instance.figure_handle, 'Units', curunits);

% Determine the ratio of the font height to the y-axis
font_ratio = (font_height_meters)/(robotarium_instance.boundaries(4) -...
    robotarium_instance.boundaries(3));

% Determine the font size in points so it fits the window. cursize(4) is
% the hight of the figure window in points.
font_size = cursize(4) * font_ratio;

end
