% find a candidate planar patch
function [fitlist,plane] = select_patch2(points)

    [L,D,Z] = size(points);
  
  tmpnew = []
  tmprest = []

  % pick a random point until a successful plane is found
  success = 0;
  while ~success
    idx = floor(L*rand);
    idy = floor(D*rand);
    while points(idx,idy,1) == 0 || idx == 0 || idy == 0
        idx = floor(L*rand);
        idy = floor(D*rand);
    end

    pnt = points(idx,idy,1);
  
    % find points in the neighborhood of the given point
    DISTTOL = 5.0;
    fitcount = 0;
    restcount = 0;
    for i = 1 : L
        for j = 1:D
            if (points(i,j,1) == 0)
                continue
            end
            dist = norm(points(i,j,1) - pnt);
              if dist < DISTTOL
                fitcount = fitcount + 1;
                tmpnew(fitcount,:) = [i j points(i,j,1)];
              else
                restcount = restcount + 1;
                size(points)
                tmprest(restcount,:) = [i j points(i,j,1)];
              end
        end
    end
    oldlist = tmprest(1:restcount,:);
    
    tmpnew(1:fitcount,:)

    if fitcount > 100
      % fit a plane
      [plane,resid] = fitplane(tmpnew(1:fitcount,:))

      if resid < 0.1
        fitlist = tmpnew(1:fitcount,:);
        return
      end
    end
  end  