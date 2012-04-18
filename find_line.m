function [bound] = find_line( rect, start, finish, dir )

    X_VAL = 1; Y_VAL = 2;

    start_x = rect(start,X_VAL); start_y = rect(start,Y_VAL);
    end_x = rect(finish,X_VAL); end_y = rect(finish,Y_VAL);

    m = (start_y - end_y) / (start_x - end_x);
    c = start_y - (m * start_x);

    if (dir == Y_VAL),      % Left or right boundary
        y_min = min(start_y, end_y); y_max = max(start_y, end_y);
        % y = mx + c => x = (y - c) / m
        bound = zeros(y_max - y_min + 1, 2);
        bound(:,2) = (y_min : y_max);
        bound(:,1) = arrayfun(@(y) (round((y-c)/m)), (y_min : y_max));  
    else
        x_min = min(start_x, end_x); x_max = max(start_x, end_x);
        % y = mx + c 
        bound = zeros(x_max - x_min + 1, 2);
        bound(:,1) = (x_min : x_max);
        bound(:,2) = arrayfun(@(x) (round(m*x + c)), (x_min : x_max));  
    end
end

