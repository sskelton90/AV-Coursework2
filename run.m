files = dir(fullfile('Images', '*.mat'));
field = imread('Images/field.jpg');

rect  = [ 41, 130; 477, 91; 474, 452; 40, 429 ];

% If we want to redo these... 
find_new_points = 0; 

% First pick out the trapezoid
test_im = find_trapezoid(480, 640, rect);

% Find the homographic transfer
field_x = size(field, 2);
field_y = size(field, 1);

UV = [[41, 130]', [40, 429]', [478, 91]', [477, 452]']'; 
XY = [[1,1]',[1,field_x]',[field_y,1]',[field_y,field_x]']';    % source points

P = esthomog(UV,XY,4);

n_files = length(files);
images = cell(1, n_files);
avg_z  = zeros(480, 640, n_files);

% Setup video writer
vw = VideoWriter('AV_movie.avi');
vw.FrameRate = 6;
vw.open();

base = 'Images/excitement';
animation = [];
for i = 1 : 10,
    animation(i,:,:,:) = imread(strcat(base,int2str(i),'.jpg'));
end
%%

% Preload all the images
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

%% Separate the man from the wall.
clear 'xyzrgb_*';
clear UV; clear XY;
%% First, use the average z-coords of each pixel to decide where the wall is
new_avg_z = avg_z(:,:,1:7);

mean_z = mean(new_avg_z, 3);
variance_z = (avg_z - repmat(mean_z, [1,1,n_files])).^2;

std_z  = mean(variance_z, 3);
[I,J] = find(std_z == 0);

[~,~,v] = find(std_z);
new_std = mean(v);

disp(['Number of pixels with standard deviation 0: ' num2str(length(I))]);
disp(['New standard deviation for these pixels: ' num2str(new_std)]);

for i = 1 : length(I),
    if (I(i) < 240),
        std_z(I(i), J(i)) = new_std;
    end
end

std_z(1:240,:) = 0.1;
threshold = mean_z + std_z;

%% Preload all the homography

[I, J] = find(test_im == 1);

test_im_2 = zeros(480, 680, 3);
for i = 1 : length(I),
   v = P * [ I(i), J(i), 1 ]';        % project destination pixel into source
   y = round(v(1)/v(3));              % undo projective scaling and round to nearest integer
   x = round(v(2)/v(3));
   if y == 0, y = 1; end
   if x == 0, x = 1; end
   if y > field_y, y = field_y; end
   if x > field_x, x = field_x; end
   test_im_2(I(i), J(i),:) = field(y,x,:);
end

%%

for i = 1 : 35,

    final = images{i};
    final_z = final(:,:,3);

    is_background = final_z < threshold;
    is_background = is_background .* test_im;
    
    [I,J] = find(is_background);
    
    for j = 1 : length(I),
        final(I(j),J(j),4:6) = test_im_2(I(j),J(j),:);   % transfer colour
    end
    
    % Suitcase time
    mask = [zeros(270, 640) ; ones(200, 640); zeros(10, 640)];

    not_background = final_z > mean_z + (3.6 * std_z);

    colourmask = (sum(final(:,:,4:6),3) < 150);
    colourmask = colourmask .* (sum(final(:,:,4:6),3) > 20);
    mask = mask .* colourmask;
    
    not_background = final_z > mean(mean(final_z)) + 0.36;

    not_background = not_background .* mask;
    [I,J] = find(not_background);

    
    for j = 1 : length(I),
        final(I(j),J(j),4:6) = [255 0 0];   % transfer colour
    end
    
    % Find the largest connected component
    largest = getlargest(not_background);
    [I,J] = find(largest);

    searchspace = zeros(length(I),5);
    for j = 1 : length(I),
        final(I(j), J(j),4:6) = [0 255 255];
        searchspace(j,:) = [I(j), J(j), final(I(j),J(j),1), ... 
                                final(I(j),J(j),2), ... 
                                final(I(j),J(j),3)];
        
    end
  
    % Fit a plane to the filtered points, and check for all points to see
    % if they lie on the plane.
    [plane,fit] = fitplane(searchspace(:,3:5));
    binary_image = zeros(size(final,1), size(final,2));
    for r = 300 : 470,
        for c = 1 : 640,
            xyzw = [final(r,c,1), final(r,c,2), final(r,c,3), 1];
            if ( abs(dot(xyzw, plane)) < 0.02 ),
                final(r,c,4:6) = [255 0 255];
                binary_image(r,c) = 255;
            end
        end
    end
    if (i >= 15 && i <= 29),
        im_opened = imopen(binary_image, strel('rectangle',[8 8]));
        C = corner(im_opened, 'QualityLevel', 0.2);

        max_dist = 0;
        point1 = [[],[]];
        point2 = [[],[]];
        point3 = [[],[]];
        point4 = [[],[]];

        for d1 = 1 : length(C),
            for d2 = 2 : length(C),
                if d1 == d2,
                    continue
                end
                distance = calculate_distance(C(d1,:),C(d2,:));
                if distance > max_dist,
                    max_dist = distance;
                    point1(1) = C(d1,1);
                    point1(2) = C(d1,2);
                    point2(1) = C(d2,1);
                    point2(2) = C(d2,2);
                    index1 = d1;
                    index2 = d2;
                end
            end
        end

        newC = setdiff(C,[point1 ; point2],'rows');

        max_dist = 0;
        for d1 = 1 : length(newC),
            for d2 = 2 : length(newC),
                if d1 == d2,
                    continue
                end
                distance = calculate_distance(newC(d1,:),newC(d2,:));
                if distance > max_dist,
                    d1_p1 = calculate_distance(newC(d1,:),point1);
                    d1_p2 = calculate_distance(newC(d1,:),point2);
                    d2_p1 = calculate_distance(newC(d2,:),point1);
                    d2_p2 = calculate_distance(newC(d2,:),point2);

                    dists = [d1_p1, d1_p2, d2_p1, d2_p2];

                    if (~isempty(find(dists<50, 1))),
                        continue
                    end

                    max_dist = distance;
                    point3(1) = newC(d1,1);
                    point3(2) = newC(d1,2);
                    point4(1) = newC(d2,1);
                    point4(2) = newC(d2,2);
                end
            end
        end

        homo_points = [point1 ; point2 ; point3 ; point4];

        left_most = sortrows(homo_points,1);
        right_most = sortrows(left_most(3:4,:),2);
        left_most = sortrows(left_most(1:2,:),2);

        top_left = left_most(1,:);
        top_right = right_most(1,:);
        bottom_right = right_most(2,:);
        bottom_left = left_most(2,:);

        cat = imread('Images/cat.jpg');
        % Find the homographic transfer
        cat_x = size(animation, 3);
        cat_y = size(animation, 2);

        UV = [top_left', top_right', bottom_left', bottom_right']'; 
        XY = [[1,1]',[1,cat_x]', [cat_y,1]', [cat_y,cat_x]']';    % source points

        P = esthomog(UV,XY,4);

        for r = 1 : size(final,2)
            for c = 1 : size(final,1)
                v=P*[r,c,1]';        % project destination pixel into source
                y=round(v(1)/v(3));  % undo projective scaling and round to nearest integer
                x=round(v(2)/v(3));
                if (x >= 1) && (x <= cat_x) && (y >= 1) && (y <= cat_y)
                    final(c,r,4:6)=animation(1,y,x,:);   % transfer colour
                end
            end
        end
    end
    
%   RGB image layers must be converted to uint8 to display

    imshow(uint8(final(:,:,4:6)));
    writeVideo(vw,getframe(gcf));


end  
close(vw);

disp('Done');