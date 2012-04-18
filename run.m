function run()

files = dir(fullfile('Images', '*.mat'));
field = imread('Images/field.jpg');

% Clockwise from top left.
%rect = [ 130, 41; 429, 40; 452, 477; 91, 478 ];
%rect = [ 41, 130; 40, 429; 477, 452; 478, 91 ];

rect  = [ 41, 130; 478, 91; 477, 452; 40, 429 ];

% If we want to redo these... 
find_new_points = 0; 

% First pick out the trapezoid
test_im = find_trapezoid(480, 640, rect);
%test_im = test_im';

% Find the homographic transfer
field_x = size(field, 1);
field_y = size(field, 2);

%UV = [[41,130]',[478,91]',[477,452]',[40,429]']';    % target points

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
clear 'xyzrgb_*'
%% First, use the average z-coords of each pixel to decide where the wall is
mean_z = mean(avg_z, 3);
std_z  = std(avg_z, 0, 3);

%% Preload all the homography

[I, J] = find(test_im == 1);

%%
test_im_2 = zeros(480, 680, 3);
for i = 1 : length(I),
   v = P * [ I(i), J(i), 1 ]';        % project destination pixel into source
   y = round(v(1)/v(3));              % undo projective scaling and round to nearest integer
   x = round(v(2)/v(3));
   if y == 0, y = 1; end
   if x == 0, x = 1; end
   if y > field_y, y = field_y; end
   if x > field_x, x = field_x; end
   test_im_2(I(i), J(i),:) = field(x,y,:);
end

%%

for i = 1 : n_files,

    final = images{i};
    final_z = final(:,:,3);
    std_z = std_z .* test_im;
    [I,J] = find(abs(final_z - mean_z) < std_z);
    
    for i = 1 : length(I),  
        final(I(i),J(i),4:6) = test_im_2(I(i),J(i),:);   % transfer colour
    end
    
    
%     for r = 1 : size(final,1),
%         for c = 1 : size(final,2),
%             if (test_im(r,c) == 1),
%                if ( abs(final(r,c,3) - mean_z(r,c)) < std_z(r,c) ),
%                    final(r,c,4:6)=test_im_2(r,c,:);   % transfer colour
%                end
%             end
%         end
%     end
    % RGB image layers must be converted to uint8 to display
    imshow(uint8(final(:,:,4:6)));
    pause;

end    

