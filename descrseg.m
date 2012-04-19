% describe segment with point list ir and ic, returning
% direction a, midpoint m, length l and average contrast g
function [a,m,l,g] = descrseg(ir,ic,image,boxwidth)
  
  % fit line thru the points
  S = zeros(3,3);
  for k = 1 : length(ir)
    vec = [ir(k)/100, ic(k)/100, 1];
    S = S + vec'*vec;
  end
  [U,D,V]= svd(S);
  a = [-V(2,3),V(1,3)];               % use component from smallest EV
  a = a / norm(a);

  % find segment endpoints
  lam = zeros(length(ir),1);
  for k = 1 : length(ir)
     lam(k) = [ir(k)-ir(1),ic(k)-ic(1)]*a';
  end
  minlam = min(lam);
  maxlam = max(lam);
  bind = find(lam == minlam);
  eind = find(lam == maxlam);
  b = [ir(bind),ic(bind)];    % beginning point
  e = [ir(eind),ic(eind)];    % endding point
  
  % get length and midpoint
  l = maxlam-minlam;     % length
  m = (b+e)/2;           % midpoint

  % get contrast
  n = [-a(2),a(1)];      % perpendicular
  lset = 0; 
  rset = 0; 
  lcount = 0; 
  rcount = 0;
  [H,W] = size(image);
  for r = min(b(1),e(1))-boxwidth : max(b(1),e(1))+boxwidth
    for c = min(b(2),e(2))-boxwidth : max(b(2),e(2))+boxwidth
     if r < 1 | r > H
       continue
     end
     if c < 1 | c > W
       continue
     end
     x = [r,c];
      lambda = (x-b)*a';
      d = (x-b)*n';
      if 0 < lambda & lambda < l
        if 0 < d & d < boxwidth
          rcount = rcount + 1;
          rset = rset + double(image(r,c));
        end
        if -boxwidth < d & d < 0
          lcount = lcount + 1;
          lset = lset + double(image(r,c));
        end
      end
    end
  end
  g = lset/lcount - rset/rcount;
