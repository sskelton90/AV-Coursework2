function [points_in_plane, failed] = growplane(all_points)
    
    xyz   = all_points(:,3:5);
    s     = size(all_points, 1);
    
    tol   = 0.005;
    
    for i = 1:100,

        % First, pick 3 random points
        order = randperm(s);
        idx = order(1:3);
        
        % Then find the equation of the plane
        v1    = xyz(idx(1),:) - xyz(idx(3),:);
        v2    = xyz(idx(2),:) - xyz(idx(3),:);
        x_pdt = cross(v1,v2);

        points_in_plane = [[],[]];
        currlen = 0;
        
        % Then iterate over all the points
        for j = 1 : s,
           
            %if ~(xyz(j,1) == 0 && xyz(j,2) == 0 && xyz(j,3) == 0),
                curr_d = dot(x_pdt', xyz(j,:) - xyz(idx(1),:)); 
                if (abs(curr_d) < tol),
                    currlen         = currlen + 1;                    
                    points_in_plane = [points_in_plane; all_points(j,1:2)];
                end
            %end
            
            if (currlen > 16000), 
                break; 
            end
        end
        
        if (currlen > 10000 && currlen < 16000),
            failed = 0;
            disp('Converged.');
            disp(['Iteration ' num2str(i) '. Points: ' num2str(currlen)]);
            return;
        elseif (i == 100),
            disp('Failed.');
            failed = 1;
        end
        
        disp(['Iteration ' num2str(i) '. Points: ' num2str(currlen)]);
        
    end
    
    
end