function [test_im] = find_trapezoid( r, c, rect )
% FIND_TRAPEZOID Returns the pixels within the corners of a given 4-sided
% shape, from a bounded image of r rows and c columns 

    TOP_LEFT = 1; TOP_RIGHT = 2; BOTTOM_RIGHT = 3; BOTTOM_LEFT = 4;
    X_VAL = 1; Y_VAL = 2;

    b_l = find_line(rect, TOP_LEFT, BOTTOM_LEFT, Y_VAL);
    b_r = find_line(rect, TOP_RIGHT, BOTTOM_RIGHT, Y_VAL);
    b_t = find_line(rect, TOP_LEFT, TOP_RIGHT, X_VAL);
    b_b = find_line(rect, BOTTOM_LEFT, BOTTOM_RIGHT, X_VAL);

    % Find all the elements that fit within this trapezoid.
    test_im = zeros(r, c);

    for i = 1 : size(b_l,1),
        test_im(b_l(i,1), b_l(i,2)) = 1;
    end
    for i = 1 : size(b_r,1),
        test_im(b_r(i,1), b_r(i,2)) = 1;
    end
    for i = 1 : size(b_t,1),
        test_im(b_t(i,1), b_t(i,2)) = 1;
    end
    for i = 1 : size(b_b,1),
        test_im(b_b(i,1), b_b(i,2)) = 1;
    end

    for r = 1 : size(test_im,1),
        [i,j] = find(test_im(r,:) == 1);

        if (~isempty(i))
            test_im(r,min(j):max(j)) = repmat([1], length(max(j) - min(j) + 1),1);
        end  
    end
end