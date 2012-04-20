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


for i = 1 : n_files,

    final = images{i};
    final_z = final(:,:,3);
    
    is_background = final_z < threshold;
    is_background = is_background .* test_im;
    
    [I,J] = find(is_background);
    
    for j = 1 : length(I),
        final(I(j),J(j),4:6) = test_im_2(I(j),J(j),:);   % transfer colour
    end

    is_background = final_z > mean_z + (3 * std_z);
    [I,J] = find(is_background);
         find_case(final, ~is_background);
    % RGB image layers must be converted to uint8 to display
    imshow(uint8(final(:,:,4:6)));

    pause;

end    
disp('Done');
