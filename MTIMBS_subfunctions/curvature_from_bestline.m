function kappa = curvature_from_bestline(bestline)
% curvature_from_bestline  Compute heading theta by fitting cubic polynomials
%   theta = curvature_from_bestline(bestline)
% Input:
%   bestline - points as Nx2 or 2xN (x then y)
% Output:
%   theta     - heading angle at each point (first and last = NaN)
%
% Fits x(s) and y(s) with cubic polynomials in parameter s (cumulative arc
% length) using polyfit, differentiates those polynomials, and returns
% theta = atan2(dy/ds, dx/ds) evaluated at the original s points.

% Validate and normalize input to Nx2
if isempty(bestline)
    kappa = [];
    return
end
sz = size(bestline);
if sz(1) == 2 && sz(2) > 2
    pts = bestline.';      % 2xN -> Nx2
elseif sz(2) == 2
    pts = bestline;
else
    error('bestline must be Nx2 or 2xN with x and y coordinates.');
end

x = pts(:,1);
y = pts(:,2);
n = numel(x);
if n < 2
    kappa = NaN(size(x));
    return
end

% Parameterize by cumulative arc length
dx = diff(x);
dy = diff(y);
ds = sqrt(dx.^2 + dy.^2);
s = [0; cumsum(ds)];

% Ensure s is strictly increasing (tiny jitter if needed)
if any(diff(s) == 0)
    s = s + (0:numel(s)-1).' * eps(max(1, max(s)));
end

% Choose polynomial degree (max 3, but limited by number of points-1)
max_deg = 7; %this sets the number of critical points in the curvature, but also is more likely to cause weird fluctuations or edge effects.
deg = min(max_deg, n-1);

% Fit polynomials: coefficients highest-to-lowest power
px = polyfit(s, x, deg);
py = polyfit(s, y, deg);

% Derivative coefficients: if p = [a3 a2 a1 a0], dp = [3a3 2a2 a1]
dpx = polyder(px);
dpy = polyder(py);

% Evaluate derivatives at s
dxds = polyval(dpx, s);
dyds = polyval(dpy, s);

% Second derivatives
ddpx = polyder(dpx);
ddpy = polyder(dpy);

d2xds2 = polyval(ddpx, s);
d2yds2 = polyval(ddpy, s);

% kappa = abs(dxds .* d2yds2 - dyds .* d2xds2);
speed2 = dxds.^2 + dyds.^2;
kappa = abs(dxds .* d2yds2 - dyds .* d2xds2) ./ (speed2).^(3/2);
% ignore the ends since this is where parameterization might have edge
% effects
kappa(1:ceil(max_deg)) = nan(ceil(max_deg),1); kappa(end-ceil(max_deg)+1:end) = nan(ceil(max_deg),1);

if size(kappa,1) ~= size(bestline,1)
    kappa = nan(size(bestline,1),1);
end

% % Compute heading and set endpoints to NaN
% theta = atan2(dyds, dxds);
% 
% ptheta = polyfit(s, theta, deg);
% dptheta = polyder(ptheta);
% dtheta_ds = polyval(dptheta, s);

% figure()
% hold on
% plot_curvature(x,y,kappa)
% figure()

end

function plot_curvature(x,y,kappa)
% Plot each (x,y) point colored by theta (minimal)
x = x(:); y = y(:); t = kappa(:);
scatter(x, y, 20, t, 'filled');    % size 20, filled markers
colormap(jet); colorbar;            % adjust colormap as desired
axis equal tight;
set(gca, 'YDir', 'reverse');
xlabel('x'); ylabel('y'); title('\Kappa at points');
end
