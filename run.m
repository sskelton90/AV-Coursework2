%% run
% This file contains the main method for running the sequence of images and
% homography

%% Toggles
% Toggle mouse input to find new coordinates
find_new_points = 0; 

% Toggle write to video
write_video = 0;

%% Set up Homography
% Read the given background image
files = dir(fullfile('Images', '*.mat'));
field = imread('Images/field.jpg');

% Find the coordinates of the corners of the background image
[field_y, field_x,~] = size(field);
XY = [[1,1]',[1,field_x]',[field_y,1]',[field_y,field_x]']';

% Find the coordinates of the background plane
rect  = [ 41, 130; 477, 91; 474, 452; 40, 429 ];
UV = [[41, 130]', [40, 429]', [478, 91]', [477, 452]']'; 

% Read the images from the video being transferred
base = 'Images/kick/';
animation = cell(15,1);
for i = 1 : 15,
    animation{i} = imread(strcat(base,int2str(i),'.jpg'));
end

% Find the coordinates of the corners of the video to transfer
[anim_y, anim_x, ~] = size(animation{1});
XY_A  = [[1,1]',[1,anim_x]', [anim_y,1]', [anim_y,anim_x]']';  

%% Find the background plane and homographic transfer
bg_trapezoid = find_trapezoid(480, 640, rect);

P = esthomog(UV,XY,4);

n_files = length(files);
images = cell(1, n_files);
avg_z  = zeros(480, 640, n_files);

%% Set up video writer
if (write_video),
    vw = VideoWriter('AV_movie.avi');
    vw.FrameRate = 6;
    vw.open();
end

%% Preload images

for i = 1 : n_files,

    curr_image = load(fullfile('Images',files(i).name));    
    vars = fieldnames(curr_image);
    
    for j = 1:length(vars)
        assignin('base', vars{j}, curr_image.(vars{j}));
    end

    % Reshape from long array to 640x480x6 matrix    
    im = reshape(curr_image.(vars{1}), 640, 480, 6);
    
    % Swap dimensions 1 and 2
    final = permute(im, [2 1 3]);
    
    images{i} = final;
    avg_z(:,:,i) = final(:,:,3);
    
    % Configure the trapezoid, if necessary
    if (i == 1 && find_new_points),
        [X,Y] = ginput(4);
        for k = 1 : 4,
            disp(['Point ' num2str(k) ' is at (' num2str(X(k)) ',' ...
                num2str(Y(k)) ').']);
        end
    end
end

clear 'xyzrgb_*';
clear UV; clear XY;

%% Use the average z coordinates of the first 7 frames to find the wall
% The threshold for foreground images is 0.1 above the mean for the top
% half of the image, and one standard deviation above the mean, for the
% bottom half of the image.

new_avg_z = avg_z(:,:,1:7);
mean_z = mean(new_avg_z, 3);
variance_z = (avg_z - repmat(mean_z, [1,1,n_files])).^2;
std_z  = mean(variance_z, 3);
std_z(1:240,:) = 0.1;
threshold = mean_z + std_z;

%% Preload homography of background image

[I, J] = find(bg_trapezoid);

bg_projection = zeros(480, 680, 3);
for i = 1 : length(I),
   % Project destination pixel into source
   v = P * [ I(i), J(i), 1 ]';        
   % Undo projective scaling and round to nearest integer
   y = round(v(1)/v(3));              
   x = round(v(2)/v(3));
   if y == 0, y = 1; end
   if x == 0, x = 1; end
   if y > field_y, y = field_y; end
   if x > field_x, x = field_x; end
   bg_projection(I(i), J(i),:) = field(y,x,:);
end

%% Find pixels for transfer, carry out transfer

for i = 1 : n_files,
    disp('-------------------------------------------------');
    disp(['Using file ' num2str(i)]);
    final = images{i};
    final_z = final(:,:,3);

    % The plane is given by the intersection of the pixels that are below
    % the threshold and within the trapezoid
    is_background = final_z < threshold;
    is_background = is_background .* bg_trapezoid;
    
    [I,J] = find(is_background);
    
    % Transfer the colours
    for j = 1 : length(I),
        final(I(j),J(j),4:6) = bg_projection(I(j),J(j),:);
    end
    
   % imshow(uint8(final(:,:,4:6)));
    
    %if i == 0,
    if (i > 13 && i < 29),      % Transfer video
        
        anim = animation{i - 13};

        disp('Removing the background.');
        tic;
        
        % Find the small rectangular plane.
        % It is always found in the bottom half of the video, so mask the
        % top half out. Limit the colour to a dark colour with a blue
        % component > 20 to remove some of the leg pixels.
        
        mask = [zeros(270, 640) ; ones(200, 640); zeros(10, 640)];
        colourmask = (sum(final(:,:,4:6),3) < 150);
        colourmask = colourmask .* (sum(final(:,:,4:6),3) > 20);
        mask = mask .* colourmask;
        
        % The plane also has to be in the front portion of the current
        % frame.
        not_background = final_z > mean(mean(final_z)) + 0.36;
        not_background = not_background .* mask;
        
%        [I,J] = find(not_background);
%         for j = 1 : length(I),
%             % Red denotes that it is not in the background
%             final(I(j),J(j),4:6) = [255 0 0];   % transfer colour
%         end
        
    
        % Limit the search space to the largest connected component of the
        % current pixels
        largest = getlargest(not_background);
        [I,J] = find(largest);

        searchspace = zeros(length(I),5);
        for j = 1 : length(I),
            
            % Light blue denotes that it is part of the largest connected
            % component
            %final(I(j), J(j),4:6) = [0 255 255];
            searchspace(j,:) = [I(j), J(j), final(I(j),J(j),1), ... 
                                            final(I(j),J(j),2), ... 
                                            final(I(j),J(j),3)];
        end
        toc;
        
        disp('Fitting a plane to the largest connected component.');
        tic;
        % Fit a plane to the filtered points, and check for all points to 
        % see if they lie on the plane.
        [plane,fit] = fitplane(searchspace(:,3:5));

        ss = zeros(480,640);
        for r = 290 : 470,
            for c = 1 : 640,
                xyzw = [final(r,c,1), final(r,c,2), final(r,c,3), 1];
                if ( abs(dot(xyzw, plane)) < 0.035 ),
                    ss(r,c) = 1;
                end
            end
        end
        toc;
        
        % Limit the search space to the largest connected component that
        % lies on the plane
        largest = getlargest(ss);
        [I,J] = find(largest);

        binary_image = zeros(480,640);
        for j = 1 : length(I),
        % Pink denotes that it is part of largest component on the plane
%                  final(I(j), J(j),4:6) = [255 0 255];
                 binary_image(I(j),J(j)) = 255;
        end
        
%         imshow(uint8(final(:,:,4:6)));
%         pause;
        
        disp('Finding the corners.');
        tic;
        
        % Find the corners within the binary image
        im_opened = imopen(binary_image, strel('rectangle',[8 8]));
        C = corner(im_opened, 'QualityLevel', 0.2);

        maxc = max(C);
        minc = min(C);
        meancx = 0.5 * (maxc(1) + minc(1));

        % If the point is higher than the max possible value, remove it
        % from the list
        I = find(C(:,2) < maxc(2) - 130);
        C(I,:) = [];

        % Find the maximum distance between any two points
        max_dist = 0;
        for d1 = 1 : length(C),
            for d2 = d1 + 1 : length(C),
                distance = calculate_distance(C(d1,:),C(d2,:));
                if distance > max_dist,
                    max_dist = distance;
                    point1 = C(d1,:);
                    point2 = C(d2,:);
                    index1 = d1;
                    index2 = d2;
                end
            end
        end

        newC = setdiff(C,[point1 ; point2],'rows');

        % Find the next maximum distance between any two points
        % Ensure that these points are not too near the previously selected
        % ones
        
        max_dist = 0;
        for d1 = 1 : length(newC),
            for d2 = d1 + 1 : length(newC),
                distance = calculate_distance(newC(d1,:),newC(d2,:));
                if distance > max_dist,
                    d1_p1 = calculate_distance(newC(d1,:),point1);
                    d1_p2 = calculate_distance(newC(d1,:),point2);
                    d2_p1 = calculate_distance(newC(d2,:),point1);
                    d2_p2 = calculate_distance(newC(d2,:),point2);

                    dists = [d1_p1, d1_p2, d2_p1, d2_p2];

                    if (~isempty(find(dists < 50, 1))),
                        continue
                    end

                    max_dist = distance;
                    point3 = newC(d1,:);
                    point4 = newC(d2,:);
                end
            end
        end
        toc;
        
        % Sort the points into top left, bottom left, top right and bottom
        % right
        
        homo_points = [point1 ; point2 ; point3 ; point4];

        left_most = sortrows(homo_points,1);
        right_most = sortrows(left_most(3:4,:),2);
        left_most = sortrows(left_most(1:2,:),2);

        top_left = left_most(1,:);
        top_right = right_most(1,:);
        bottom_right = right_most(2,:);
        bottom_left = left_most(2,:);

        UV = [top_left', top_right', bottom_left', bottom_right']'; 
        P = esthomog(UV,XY_A,4);

        % Do the homography for the video images
        for r = 1 : size(final,2)
            for c = 1 : size(final,1)
                v = P * [r,c,1]';        
                y = round(v(1)/v(3));
                x = round(v(2)/v(3));
                if (x >= 1) && (x <= anim_x) && (y >= 1) && (y <= anim_y)
                    final(c,r,4:6) = anim(y,x,:);   % transfer colour
                end
            end
        end
    end
  
    % RGB image layers must be converted to uint8 to display
      imshow(uint8(final(:,:,4:6)));
    
    if (write_video)
        disp('Writing video.')
        tic;
        writeVideo(vw,getframe(gcf));
        toc;
    else
        pause;
    end
end

if (write_video)
    close(vw);
end

disp('Complete');