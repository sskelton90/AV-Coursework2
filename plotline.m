% gets the point on a line across the window for sin(t)*r + cos(t)*c = d
function [cr,cc] = plotline(t,d)

  sn = sin(t);
  cs = cos(t);
  tr = zeros(640,1);
  tc = zeros(480,1);
  count = 0;
  if abs(cs) < 0.1
    for c = 1 : 640
      r = (d - cs*c) / sn;
      if r > 0 & r < 481
        count = count +1;
        tr(count) = r;
        tc(count) = c;
      end
    end
  else
    for r = 1 : 480
      c = (d - sn*r) / cs;
      if c > 0 & c < 641
        count = count +1;
        tr(count) = r;
        tc(count) = c;
      end
    end
  end
  cr = tr(1:count);
  cc = tc(1:count);


