function [ tl, tr, bl, br ] = find_case( image, mask )
%FIND_CASE Find the rectangle that represents the case the man is holding.
% 
%     masked(:,:,1) = image(:,:,1).*mask;
%     masked(:,:,2) = image(:,:,2).*mask;
%     masked(:,:,3) = image(:,:,3).*mask;
    
    im_crop = imcrop(image(:,:,1:3), [0, 280, 640, 480]);
    mean(mean(im_crop(:,:,3)))
    [I,J] = find(im_crop(:,:,3) < 0.1 + mean(mean(im_crop(:,:,3))));
    final = zeros(240,640,6);
    for j = 1 : length(I),
        final(I(j),J(j),4:6) = [255 255 255];   % transfer colour
    end
    
    figure, imshow(uint8(final(:,:,4:6)))
    
%     figure, imshow(im_crop)
%     im_crop = masked;
    
%     [NPts,W] = size(masked(:,:,3));
%     patchid = zeros(NPts,1);
%     planelist = zeros(20,4);
% 
% find surface patches
% here just get 5 first planes - a more intelligent process should be
% used in practice. Here we hope the 4 largest will be included in the
% 5 by virtue of their size
% remaining = masked;
% size(remaining)
% for i = 1 : 4   
% 
%   select a random small surface patch
%   [oldlist,plane] = select_patch2(remaining);
% 
%   grow patch
%   stillgrowing = 1;
%   while stillgrowing
% 
%     find neighbouring points that lie in plane
%     stillgrowing = 0;
%     [newlist,remaining] = getallpoints(plane,oldlist,remaining,NPts);
%     [NewL,W] = size(newlist);
%     [OldL,W] = size(oldlist);
% if i == 1
%  plot3(newlist(:,1),newlist(:,2),newlist(:,3),'r.')
%  save1=newlist;
% elseif i==2 
%  plot3(newlist(:,1),newlist(:,2),newlist(:,3),'b.')
%  save2=newlist;
% elseif i == 3
%  plot3(newlist(:,1),newlist(:,2),newlist(:,3),'g.')
%  save3=newlist;
% elseif i == 4
%  plot3(newlist(:,1),newlist(:,2),newlist(:,3),'c.')
%  save4=newlist;
% else
%  plot3(newlist(:,1),newlist(:,2),newlist(:,3),'m.')
%  save5=newlist;
% end
% pause(1)
%     
%     if NewL > OldL + 50
%       refit plane
%       [newplane,fit] = fitplane(newlist);
% [newplane',fit,NewL]
%       planelist(i,:) = newplane';
%       if fit > 0.04*NewL       % bad fit - stop growing
%         break
%       end
%       stillgrowing = 1;
%       oldlist = newlist;
%       plane = newplane;
%     end
%   end
% 
% waiting=1
% 	 pause(1)
% 
% ['**************** Segmentation Completed']
% 
% end
    
%     figure, imshow(im_crop)
    
%     foreground = (abs(im_crop(:,:,1)) < 15 & abs(im_crop(:,:,1) > 5)) ...
%     | (abs(im_crop(:,:,2)) < 15 & abs(im_crop(:,:,2) > 5)) ...
%     | (abs(im_crop(:,:,3)) < 50 & abs(im_crop(:,:,3) > 5));

%     figure, imshow(foreground)
%     edges = edge(foreground, 'canny', [0.08,0.4], 3);
%     
%     [r,c] = find(edges == 1);
%     figure,
%     plot(r,c,'k.')
%     axis([0 640 0 480])
%     axis xy
% 
%   
%   flag = 1;
%   sr = r;
%   sc = c;
%   llinecount = 0;
%   llinea = zeros(100,2);
%   llinem = zeros(100,2);
%   llinel = zeros(100,1);
%   llineg = zeros(100,1);
%   llinet = zeros(100,1);
%   llined = zeros(100,1);
%   while flag == 1
%     ransacplane(masked, 1, 0.1,0.01,0.001,150,3);
%     if flag == 1 & newcountl > 0 
%       pointsleft = size(nr);
%       sr = nr;
%       sc = nc;
%       llinecount = llinecount+1;
%       [llinea(llinecount,:),llinem(llinecount,:),llinel(llinecount), ...
%             llineg(llinecount)] = descrseg(frl,fcl,foreground,8);
%       llinet(llinecount) = t;
%       llined(llinecount) = d;
%       
%        [cr,cc] = plotline(t,d);
%        figure(3)
%        imshow(im_crop)
%        plot(cc,cr)
%         line(cc,cr);
%     end
%   end    

end