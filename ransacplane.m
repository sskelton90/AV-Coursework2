% extracts a line of the form sin(t)*r + cos(t)*c = d from the
% given edge pixels, returns a reduced list. Matched pixels
% must lie within tol distance of the line and probd is the
% probability that a pixel is part of the line. probnd is the 
% probability that the second pixel lies on the same line
% probf is the allowed failure probability. MINLEN is the minimum 
% allowable line length. [rr,rc] are the count remaining pixels
% Selected pixels are on fign
% [frfr,frfc] are the selected newcount points
%

function [] = ransacplane(depth, tol,probd,probnd,probf,MINLEN,fign)

  % compute limit to matching tries
  N = ceil(log(probf)/ log(1 - probd*probd));

  s = size(depth);
  for i=1:N
      points_in_plane = 0;
      
      random_points = zeros(3,3);
      
      for j=1:3
        r = rand(3,1);
        selected = round(r * s);

        if selected(1) == 0
            selected(1) = 1;
        end
        
        if selected(2) == 0
           selected(2) = 1;
        end
        random_points(j,1) = selected(1);
        random_points(j,2) = selected(2);
        random_points(j,3) = depth(selected(1), selected(2), 1);
      end
      
      % plane equation
      v1 = random_points(1,:) - random_points(3,:);
      v2 = random_points(2,:) - random_points(3,:);
      
      cross_product = cross(v1,v2);
      coeff = dot(-random_points(3,:), cross(random_points(1,:), random_points(2,:)));
      plane_eq = [cross_product  coeff];
      
      for k = 1:s(1)
        for l = 1:s(2)
            if 
            distance = (plane_eq' * [depth(k,l,1)  1])/(sqrt(sum(cross_product.^2)));
            if (abs(distance) < tol)
                points_in_plane = points_in_plane + 1;
                plane_points(:,points_in_plane) = [k l depth(k,l,1)];
            end
        end
      end
      
      if points_in_plane >= MINLEN
         state = 1;
         break;
      end
  end
  
  if state == 0
    'Hello'
  else
    'got here'
    plane_points(1,:)
    plot3(plane_points(1,:), plane_points(2,:), plane_points(3,:),'b+');
    axis([0 480 0 640 0 480])
    grid on
  end
end

  

  
  


