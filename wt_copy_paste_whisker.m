function wt_copy_paste_whisker(sOption, nW)
% Copy/paste a selected whisker to/from clipoard

switch sOption
    case 'copy'
        CopyPasteWhisker(nW, 'copy');
    case 'paste'
        CopyPasteWhisker(nW, 'paste');
        wt_display_frame;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CopyPasteWhisker(nW, sAction)
global g_tWT

persistent sCopiedName
persistent mCopiedCoords

nCurrFrame = g_tWT.CurrentFrameBuffer.Frame;

switch sAction
    case 'copy'
        % Get current frame
    	mCopiedCoords = g_tWT.MovieInfo.SplinePoints(:,:,nCurrFrame,nW); % copy current frame only
    	sCopiedName = cell2mat(g_tWT.MovieInfo.WhiskerIdentity{nW});
        if ~isempty(sCopiedName)
            wt_set_status(['Whisker ' sCopiedName ' has been copied to the clipboard'])
        else
            wt_set_status(['Whisker ' sCopiedName 'has been copied to the clipboard'])
        end
    case 'paste'
        if isempty(mCopiedCoords)
            wt_set_status('No available whisker in clipboard to paste')
            return
        end
        % New whisker index
        if isempty(g_tWT.MovieInfo.SplinePoints)
            nNewW = 1;
        else
            nNewW = size(g_tWT.MovieInfo.SplinePoints, 4) + 1;
        end

        % Save whisker data
        % Note: Copied whisker is copied into current frame
        g_tWT.MovieInfo.SplinePoints(:,:,nCurrFrame,nNewW) = mCopiedCoords;

        g_tWT.MovieInfo.Angle(1:nCurrFrame, nNewW) = NaN;
        g_tWT.MovieInfo.Angle(nCurrFrame, nNewW) = 0;

        g_tWT.MovieInfo.Intersect(1:nCurrFrame, 1:2, nNewW) = [NaN NaN];
        g_tWT.MovieInfo.Intersect(nCurrFrame, 1:2, nNewW) = [0 0];

        g_tWT.MovieInfo.MidPointConstr(1:2, nNewW) = [0 0]';
        g_tWT.MovieInfo.WhiskerSide(nNewW) = 1; % 0=left, 1=right

        g_tWT.MovieInfo.LastFrame(nNewW) = g_tWT.MovieInfo.NumFrames;
        
        % TODO: Change all zeros to NaNs in SplinePoints!
        %vIndx = find(g_tWT.MovieInfo.SplinePoints(:,:,:,nNewW) == 0);
        
        if isempty(sCopiedName)
            g_tWT.MovieInfo.WhiskerIdentity{nNewW} = '';
        else
            g_tWT.MovieInfo.WhiskerIdentity{nNewW} = mat2cell(sCopiedName);
        end

        wt_set_status('')
end

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
