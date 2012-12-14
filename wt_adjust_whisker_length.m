% WT_ADJUST_WHISKER_LENGTH
% Adjust whisker length to that of first known frame.
%
% Syntax:    [vX, vY] = wt_adjust_whisker_length(I,X,Y), where
%               I = I'th whisker
%               X = vector of X splinepoints
%               Y = vector of Y splinepoints
%           Output variables:
%               X = adjusted X splinepoints
%               Y = adjusted Y splinepoints
%
% This function works in conjunction with the WT GUI.

function [vX, vY] = wt_adjust_whisker_length(nChWhisker, vX, vY)

global g_tWT

vXorig = vX;
vYorig = vY;

% Make sure no values are equal on the x axis
while 1
    vIndx = find(~diff(vX));
    if length(vIndx) == 0, break, end
    vX(vIndx+1) = vX(vIndx) + 3;
end

% Length of initially marked whisker
nKnownFrames = find(g_tWT.MovieInfo.SplinePoints(1, 1, :, nChWhisker));
vXinit = g_tWT.MovieInfo.SplinePoints(:, 1, nKnownFrames(1), nChWhisker);
vYinit = g_tWT.MovieInfo.SplinePoints(:, 2, nKnownFrames(1), nChWhisker);
nWhiskerLength = GetWhiskerLength(vXinit, vYinit);

% Length of new whisker
try, nLen = GetWhiskerLength(vX, vY);
catch, wt_error('Error when recalculating whisker length'); end

if (length(vX) == 4) & (vX(end)>0 & vY(end)>0), nLastIndx = 4;
else, nLastIndx = 3; end

if nLen > nWhiskerLength % new whisker is LONGER than original
    vXX = min(vX((1:nLastIndx))):max(vX((1:nLastIndx))); % whisker spline in 1st known frame
    [vXX, vYY] = wt_spline(vX(1:nLastIndx), vY(1:nLastIndx), vXX);
    vCumLen = cumsum(sqrt(diff(vXX).^2 + diff(vYY).^2));
    [nDiff, nDiffIndx] = min(abs(vCumLen - nWhiskerLength));
    vX(nLastIndx) = vXX(nDiffIndx+1);
    vY(nLastIndx) = vYY(nDiffIndx+1);
elseif nLen < nWhiskerLength  % new whisker is SHORTER than original
    % Increase length of new whisker by 1 pix until its same length as original
    while nLen < nWhiskerLength
        % Extrapolate Y value at new X position
        vY(nLastIndx) = interp1(vX(1:nLastIndx), vY(1:nLastIndx), vX(nLastIndx)+1, 'spline', 'extrap');
        vX(nLastIndx) = vX(nLastIndx)+1;
        try, nLen = GetWhiskerLength(vX, vY);
        catch, wt_error('Error when computing whisker length'), end
    end
end

% Sort splinepoint in case 2nd and 3rd swapped places (should be in
% increasing order along X dimension)
vIndx = find(vX & vY);
mC = [vX vY];
mC(vIndx,:) = sortrows(mC(vIndx,:));
vX = mC(:,1);
vY = mC(:,2);

% Make sure no values are equal on the x axis
while 1
    vIndx = find(~diff(vX));
    if length(vIndx) == 0, break, end
    vX(vIndx+1) = vX(vIndx) + 3;
end

return

%%%% GET_WHISKER_LENGTH %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nLen  = GetWhiskerLength(vX, vY)
% Remove 4th element if present AND zero
vKeepXIndx = find(vX);
vX = vX(vKeepXIndx);
vY = vY(vKeepXIndx);

vXX = min(vX):max(vX); % whisker spline in 1st known frame
[vXX, vYY] = wt_spline(vX, vY, vXX);
nLen = sum(sqrt(diff(vXX).^2 + diff(vYY).^2));

return;
