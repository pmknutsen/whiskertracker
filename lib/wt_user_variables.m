function wt_user_variables(varargin)
% Create and modify user-defined variables
% The purpose of this function is to provide the user with an easy way to
% store experiment variables inside the WT .mat file. These user variables
% can also be variables that are accessed from within scripts.
%
% Note that adding or modifying experiment variables can be performed as a
% batch job.

% Copy user variables from persistent variable instead of GUI/
% This option is used for batch jobs, i.e. copying the variables of one
% movies to all other movies in directory/tree
if ~isempty(varargin)
    if strcmp(varargin{1}, 'copyfrommem')
        RetrieveUserVariables();
        return;
    end
end

global g_tWT;

% Check if variables window is already open. If YES, then retrieve and save
% variables, and close window
hFig = findobj('Tag', 'WTUserVariables', 'type', 'figure');
if ~isempty(hFig)
    RetrieveUserVariables();
    return
end

hFig = figure('closeRequestFcn', 'set(gcbf,''userdata'',''closed'')');
cColumnNames = {'Variable', 'Value', 'Type'};
cColumnFormat = {'char', 'char', {'String', 'Number'}}; 
cColumnEditable =  [true true true];

cData = repmat({''},200,3);

if isfield(g_tWT.MovieInfo, 'tUserVariables')
    for i = 1:length(g_tWT.MovieInfo.tUserVariables)
        cData{i, 1} = g_tWT.MovieInfo.tUserVariables(i).sVariable;
        cData{i, 2} = g_tWT.MovieInfo.tUserVariables(i).sValue;
        cData{i, 3} = g_tWT.MovieInfo.tUserVariables(i).sType;
    end
end

set(hFig, 'color', [.2 .2 .2], 'Name', 'WT User Variables', 'NumberTitle', 'off', 'ToolBar', 'none', ...
    'menuBar','none', 'Tag', 'WTUserVariables')
hTable = uitable('Units', 'normalized','Position', [0 0 1 1], 'Data', cData, 'ColumnName', ...
    cColumnNames, 'ColumnEditable', cColumnEditable, 'ColumnFormat', cColumnFormat, ...
    'ColumnWidth', {120, 282, 100}, 'Tag', 'WTUserVariablesTable');

% Create callback to this function when window is closed
set(hFig, 'CloseRequestFcn', 'wt_user_variables')

return

%%%% Retrieve and save user variables
function RetrieveUserVariables
global g_tWT
persistent cData

% Get figure handle
hFig = findobj('Tag', 'WTUserVariables', 'type', 'figure');

% If no window is open, then used persistent variable to fill g_tWT
if ~isempty(hFig)
    % Get table handle
    hTable = findobj('Tag', 'WTUserVariablesTable', 'type', 'uitable');    
    cData = get(hTable, 'data'); % modified data from table
end

g_tWT.MovieInfo.tUserVariables = struct([]); % clear variables
for c = 1:size(cData, 1)
    if isempty(cData{c,1}) || isempty(cData{c,2}), continue, end
    g_tWT.MovieInfo.tUserVariables(end+1).sVariable = cData{c, 1};
    g_tWT.MovieInfo.tUserVariables(end).sValue = cData{c, 2};
    g_tWT.MovieInfo.tUserVariables(end).sType = cData{c, 3};
end

% Delete user variables window
delete(hFig)

return

