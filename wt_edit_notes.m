function wt_edit_notes
% wt_edit_notes
% Open dialog to insert file specific notes
%
global g_tWT

% Suppress dialog if we are currently processing movies in batch mode
tDBStack = dbstack;
if any(strcmp({tDBStack.name}, 'wt_batch_redo')), return, end

% Fetch existing notes
if isfield(g_tWT.MovieInfo, 'Notes')
    sNotes = g_tWT.MovieInfo.Notes;
else sNotes = ''; end

% Display input dialog:
% Note that dialog is modal and user cannot interact with WT until the
% input dialog is closed
options.movegui = 'onscreen';
cNotes = inputdlg('', 'WT Notes', 10, {sNotes}, options);

% Save new notes
if isempty(cNotes), return
else g_tWT.MovieInfo.Notes = cell2mat(cNotes); end

return