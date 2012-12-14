function wt_error( sErrString, varargin )
% WT_ERROR
% Display error message dialog.
%
% Usage:
%  wt_error(MSG, 'warn')     Issue a warning
%  wt_error(MSG, 'err')      Issue an error
%

global g_tWT

if ~isempty(varargin), sOpt = varargin{1};
else sOpt = 'err'; end

[St, I] = dbstack;

% Create cell from dbstack
cDBStack = {};
for i = 1:size(St, 1)
    cDBStack{i} = sprintf('  In %s at %d', St(i).name, St(i).line);
end

cWarn =  [{ sprintf('Error in %s:', St(I+1,1).name), ...
    sprintf('%s', sErrString), '', ...
    sprintf('Filename: %s', g_tWT.MovieInfo.Filename), ...
    '', 'Function call stack:' }, cDBStack, ...
    {'', 'If this is an unexpected error message it may be a bug. Please report bugs to whiskertracker@googlegroups.com and include a copy of the entire error message along with a description of what you attempted to do, and how.'}];

% Display error message in modal dialog window:
% If WT is in batch mode, dont display error. Instead, show a smaller
% dialog that reports an error occured and print exact error to the command
% prompt only.
tDBStack = dbstack;
if any(strcmp({tDBStack.name}, 'wt_batch_redo'))
    persistent hWarn
    if isempty(hWarn)
        hWarn = warndlg('A non-critical warning occurred during batch processing. See command line for details.', 'WT Error');
    end
    disp(cWarn)
else
    waitfor(warndlg(cWarn, 'WT Error'));
end


switch lower(sOpt)
    case 'warn'
        return
    case 'err'
        % Abort execution if this was an error
        error('Stopped in wt_error.')
end


return
