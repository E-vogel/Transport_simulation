clear
close all

% Field Settings
fig = figure;
fig.Position = [200 200 900 300];
axx_min = 0;
axx_max = 60;
axy_min = 0;
axy_max = 20;

axis([axx_min axx_max axy_min axy_max])
xline(axx_min:axx_max,'Alpha',0.3)
hold on
yline(axy_min:axy_max,'Alpha',0.3)
rectangle('Position',[0 0 axx_max/3 axy_max],'FaceColor',[0 0 1 0.1],'EdgeColor','none')
rectangle('Position',[axx_max*2/3 0 axx_max/3 axy_max],'FaceColor',[1 0 0 0.1],'EdgeColor','none')
axis off
daspect([1 1 1])
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Initial Setup of Cargo
[x,y] = meshgrid(axx_min:axy_max-1,axy_min:axy_max-1);
cargo.X(:,1) = reshape(x,[],1);
cargo.X(:,2) = reshape(y,[],1);
cargo.X = cargo.X + 0.5;
cargo.S = scatter(cargo.X(:,1),cargo.X(:,2),50,'filled','b');

% Initial Setup of Agents
[x,y] = meshgrid(axx_max/2:2:axx_max*0.6,axy_min:2:axy_max*0.5);
agents.X(:,1) = reshape(x,[],1);
agents.X(:,2) = reshape(y,[],1);
agents.X = agents.X + 0.5;
agents.V = zeros(length(agents.X(:,1)),2);
agents.S = scatter(agents.X(:,1),agents.X(:,2),200,'LineWidth',2);
agents.S.CData = autumn(length(agents.X(:,1)));


% Set delivery location
Xs_max = axx_max - 0.5;

% create video
% video = VideoWriter("Transport_simulation.avi",'Uncompressed AVI');
% open(video)

% Simulation loop
while Xs_max > axx_max - 0.5 - (axy_max - axy_min) + 10

    % Search for the status of whether the agent is carrying cargo or not 
    % (detected if the agent and the cargo are at the same coordinates)
    for i = 1:length(agents.X(:,1))
        if any(ismember(cargo.X,agents.X(i,:),"row"))
            agents.state(i) = find(ismember(cargo.X,agents.X(i,:),"row"));
        else
            agents.state(i) = 0;
        end
    end

    
    % Set agents.state to 0 when you arrive at the delivery location.
    idx = find(cargo.X(:,1) == Xs_max);
    agents.state(find(any(agents.state == idx))) = 0;

    % If the vertical line is filled with cargo, the next line
    if length(find(cargo.X(:,1) == Xs_max)) == axy_max && ~ismember(Xs_max,agents.X(:,1))
        Xs_max = Xs_max - 1;
    end

    % Determination of the agent's direction of travel
    agents.V = zeros(length(agents.X(:,1)),2);
    for i = 1:length(agents.X(:,1))
        if agents.state(i) ~= 0 % If the agent has cargo
            if ismember(agents.X(i,:)+[1 0],agents.X,'row')
                agents.V(i,2) = 2*randi([0 1]) - 1;
            elseif ismember(agents.X(i,:)+[1 0],cargo.X,'row')
                if length(find(cargo.X(:,1) == Xs_max & cargo.X(:,2) <= axy_max/2)) == length(find(cargo.X(:,1) == Xs_max & cargo.X(:,2) > axy_max/2))
                    agents.V(i,2) = 2*randi([0 1]) - 1;
                else
                    agents.V(i,2) = sign(length(find(cargo.X(:,1) == Xs_max & cargo.X(:,2) <= axy_max/2)) - length(find(cargo.X(:,1) == Xs_max & cargo.X(:,2) > axy_max/2)));
                end
            else
                agents.V(i,1) = 1;
            end
        else % If the agent has no cargo
            if ismember(agents.X(i,:)+[-1 0],agents.X,'row')
                agents.V(i,2) = 2*randi([0 1]) - 1;
            elseif agents.X(i,1) <= axx_max*0.05
                agents.V(i,:) = 2*randi([0 1],1,2) - 1;
            else
                agents.V(i,1) = -1;
            end
        end
    end

    % If going out of the field to the next step, stop
    agents.V(agents.X(:,1) + agents.V(:,1) < axx_min,1) = 0;
    agents.V(agents.X(:,1) + agents.V(:,1) > axx_max,1) = 0;

    agents.V(agents.X(:,2) + agents.V(:,2) < axy_min,2) = 0;
    agents.V(agents.X(:,2) + agents.V(:,2) > axy_max,2) = 0;
    
    % If a collision occurs in the next step, stop
    agents_X_tmp = agents.X + agents.V;
    [~,ia] = unique(agents_X_tmp,"row");
    for i = 1:length(agents.X(:,1))
        if ~ismember(i,ia) || ismember(agents_X_tmp(i,:),agents.X,"row") || agents.state(i) ~= 0 && ismember(agents_X_tmp(i,:),cargo.X,"row")
            agents.V(i,:) = [0 0];
        end
    end


    % Update agents coordinates
    agents.X = agents.X + agents.V;
    agents.S.XData = agents.X(:,1);
    agents.S.YData = agents.X(:,2);

    % Update cargo coordinates
    [~,idx_agents] = find(agents.state ~= 0);
    cargo.X(agents.state(idx_agents) ,:) = agents.X(idx_agents,:);
    cargo.S.XData = cargo.X(:,1);
    cargo.S.YData = cargo.X(:,2);

%     frame = getframe(gcf);
%     writeVideo(video,frame)
    drawnow
end
% close(video)