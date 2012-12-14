function varargout = plot_average_whisker_position(g_tWT)

global g_tWT % load global parameter

% Check data indeed exists
if ~isfield(g_tWT.MovieInfo, 'AvgWhiskerPos')
    warndlg('No data on average whisker position tracking found. Aborting now.')
    return
end

% Open figure and plot data
hFig = figure;
subplot(2,1,1)
plot(g_tWT.MovieInfo.AvgWhiskerPos(:,1))
xlabel('Time')
ylabel('X position (pix)')
title(g_tWT.MovieInfo.Filename, 'interpreter','none')
axis tight

subplot(2,1,2)
plot(g_tWT.MovieInfo.AvgWhiskerPos(:,2))
xlabel('Time')
ylabel('Y position  (pix)')
axis tight

% Figure title
sName = g_tWT.MovieInfo.Filename;
if ispc
    vIndx = findstr(sName, '\');
    sName = sName(vIndx(end)+1:end);
else
    vIndx = findstr(sName, '/');
    sName = sName(vIndx(end)+1:end);
end
set(hFig, 'name', sName, 'numberTitle', 'off')

return
