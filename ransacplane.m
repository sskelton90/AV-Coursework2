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

function [points_in_plane, image] = ransacplane(depth, tol,probd,probnd,probf,MINLEN,fign)

  % compute limit to matching tries
  N = ceil(log(probf)/ log(1 - probd*probd));

  s = size(depth);
  
  image = zeros(s);
  for i=1:N
      points_in_plane = 0;
      
      random_points = []; 
      
      for j = 1:100
        r = rand(3,1);
        selected = round(r * s);

        if selected(1) == 0
            selected(1) = 1;
        end
        
        if selected(2) == 0
           selected(2) = 1;
        end
       
         random_points = [random_points ; depth(selected(1),selected(2), :)];
      end
      
      list = [];
      t = size(random_points);
      for k = 1:t(1)
          for l = 1:t(2)
              list = [list ; random_points(k,l,:)];
          end
      end
      
      [plane,fit] = fitplane(list);
            
%       % plane equation
%       v1 = random_points(1,:) - random_points(3,:);
%       v2 = random_points(2,:) - random_points(3,:);
%       
%       cross_product = cross(v1,v2);
%       coeff = dot(-random_points(3,:), cross(random_points(1,:), random_points(2,:)));
%       plane_eq = [cross_product' ; coeff];
%       
%       for k = 1:s(1)
%         for l = 1:s(2)
%             distance = (plane_eq' * [depth(k,l,1) ; depth(k,l,2) ; depth(k,l,3) ; 1])/(sqrt(sum(cross_product.^2)));
%             if (abs(distance) < tol)
%                 points_in_plane = points_in_plane + 1;
%                 plane_points(:,points_in_plane) = depth(k,l,:);
%                 image(k,l,:) = [255 255 255];
%             end
%         end
%       end
%       
      if points_in_plane >= MINLEN
         state = 1;
         break;
      end
  end
  
  if state == 0
    'Hello'
  else 
%     plane_points(1,:)
%     plot3(abs(plane_points(1,:)), abs(plane_points(2,:)), abs(plane_points(3,:)),'b+');
%     axis([0 480 0 640 0 480])
%     grid on
  end
end

  

  
  


