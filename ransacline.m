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

function [flag,t,d,nr,nc,count,frfr,frfc,newcount] = ransacline(r,c,tol,probd,probnd,probf,MINLEN,fign)

  % compute limit to matching tries
  N = ceil(log(probf)/ log(1 - probd*probd));

  % do matching tries
  flag=0;
  nr = r;
  nc = c;
  t = 0;
  d = 0;
  newcount=0;
  frfr = 0;
  frfc = 0;
  lenr = length(r);
  for i = 1 : N

    % pick two random edge points
    ind = ceil(lenr*rand(2,1))
    if ind(1) == ind(2)
      continue
    end

    % count number of points in list within tolerance
    count = 0;
    rcount = 0;
    tr = zeros(lenr,1);
    tc = zeros(lenr,1);
    fr = zeros(lenr,1);
    fc = zeros(lenr,1);
    vecp = [c(ind(2)) - c(ind(1)), r(ind(1)) - r(ind(2))];
    vecp = vecp / norm(vecp);
    rf = r(ind(1));
    cf = c(ind(1));
    for k = 1 : lenr
      dist = abs(vecp*[r(k) - rf, c(k) - cf]');
      if dist < tol
        count = count + 1;
        fr(count) = r(k);
        fc(count) = c(k);
      else
        rcount = rcount + 1;
        tr(rcount) = r(k);
        tc(rcount) = c(k);
      end
    end

    % see if got enough
    if count > MINLEN

%tmpt = atan2(c(ind(2)) - c(ind(1)), r(ind(1)) - r(ind(2)))
%tmpd = sin(tmpt)*r(ind(1)) + cos(tmpt)*c(ind(1))
      % fit line thru the points
      S = zeros(3,3);
      for k = 1 : count
        vec = [fr(k)/100, fc(k)/100, 1];
        S = S + vec'*vec;
      end
      [U,D,V]= svd(S);
      parm = V(:,3)';               % use component from smallest EV
      parm = parm / sqrt(parm(1)^2 + parm(2)^2);
      t = atan2(parm(1),parm(2));
      d = sin(t)*r(ind(1)) + cos(t)*c(ind(1));

      % select valid portion of line - a point is valid if it has
      % at least Nm*p within Nm pixels of it on the line. p = 0.95, Nm = 45
      % this eliminates accidental crossings
      Nm = 45;
      thresh = Nm*Nm;
      fvalid = zeros(lenr,1);
      for k = 1 : count
        closecbt = 0;
        for l = 1 : count
          nvec = [fr(k)-fr(l),fc(k)-fc(l)];
          dist2 = nvec*nvec';
          if dist2 < thresh;
            closecbt = closecbt +1;
          end
        end
        if closecbt > 0.95*Nm
          fvalid(k)=1;
        end
      end
      if sum(fvalid) < 10
        continue
      end

% over draw used points in red      
% figure
% title('image lines found by RANSAC')
% hold on
% axis([0 640 0 480])
% axis ij
% for k = 1 : count
% if fvalid(k)
% plot(fc(k),fr(k),'r.')
% end
% end
      % copy over used and unused points
      newcount = 0;
      rfr = zeros(lenr,1);
      rfc = zeros(lenr,1);
      for k = 1 : count
      if fvalid(k)    % a valid point
          newcount = newcount + 1;
          rfr(newcount) = fr(k);
          rfc(newcount) = fc(k);
        else          % point belongs to another segment
          rcount = rcount + 1;
          tr(rcount) = fr(k);
          tc(rcount) = fc(k);
        end
      end
      flag = 1;
      nr = tr(1:rcount);    % return unused portion
      nc = tc(1:rcount);
      frfr = rfr(1:newcount); % plus matched points
      frfc = rfc(1:newcount);
      return
    end
  end

  

  
  
