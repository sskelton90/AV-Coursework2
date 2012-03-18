files = dir('Images');

for i=3:length(files),
    mat = load('-mat', fullfile('Images',files(i).name));
    
    vars = fieldnames(mat);
    for j = 1:length(vars)
        assignin('base', vars{j}, mat.(vars{j}));
    end

    % Reshape from long array to 640x480x6 matrix    
    im = reshape(mat.(vars{1}), 640, 480, 6);
    % Swap dimensions 1 and 2
    final = permute(im, [2 1 3]);

    % RGB image layers must be converted to uint8 to display
    figure, imshow(uint8(final(:,:,4:6)))
end

close all
