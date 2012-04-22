function [ distance ] = calculate_distance( point1, point2 )
%CALCULATE_DISTANCE Summary of this function goes here
%   Detailed explanation goes here
    distance = sqrt((point1(1) - point2(1))^2 + (point1(2) - point2(2))^2);
end

