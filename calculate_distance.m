function [ distance ] = calculate_distance( point1, point2 )
% CALCULATE_DISTANCE Calculates the euclidean distance between two points
    distance = sqrt((point1(1) - point2(1))^2 + (point1(2) - point2(2))^2);
end

