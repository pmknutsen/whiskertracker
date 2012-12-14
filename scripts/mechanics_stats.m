function mechanics_stats(sWT)
% Collect statistics for the mechanics analysis and export to Excel.
%
% INSTALLATION:
% To run this script, copy it to the ./scripts folder where WT has been
% installed (most likely, this has already been done for you). To run the
% script, select the menu item Options -> Scripts -> mechanics_stats.m
%
% PURPOSE:
% This script computes the angle, reaction angle, base curvature and
% integrated curvature for every marked whisker and exports the results to
% Excel. If the movie has been calibrated, the output will be in mm.
% Otherwise, outputs will be in pixels. The script only outputs to Excel
% the FIRST tracked frame of every whisker. Additional fields, such as the
% whisker name, framenumber, cyclenumber and time is also written to Excel.
% These last fields are extracted from the name of the whisker. Thus, the
% naming of the whisker must follow the strict conventions explained in the
% following paragraph.
%
% HOW TO USE:
% In order for this script to work properly and output the correct values
% to Excel, you must name the marked whiskers according to the following
% convention: WHISKER_TIME_CYCLE, where WHISKER is the name of the whiskers
% (e.g. C1), TIME is any name you wish to designate to the relative time
% you marked the whisker (e.g. C for contact) and CYCLE is the cycle-number
% (e.g. 1). Thus, a valid whisker name is for instance: B3_C_2
%
% Although you can use any character, number or string for TIME, be
% consistent! The following naming for TIME is recommended:
%
%   0 (zero), at movement onset
%   C, at time of contact
%   D, at X time after contact (see below)
%   M, at max protraction
% 

if ~isfield(sWT.MovieInfo, 'WhiskerIdentity')
    warndlg('No whiskers have been labelled.', 'WT Error')
    return;
end

% Get names all unique whiskers
cAllWhiskerNames = {''};
for w = 1:length(sWT.MovieInfo.WhiskerIdentity)
    cAllWhiskerNames{w} = sWT.MovieInfo.WhiskerIdentity{w}{1}(1:2);
end
cWhiskerNames = unique(cAllWhiskerNames);

% Initialize figure where all whiskers will be plotted
hFig = figure;
hAx = axes;
axis equal
axis ij
set(hAx, 'xlim', [0 sWT.MovieInfo.Width], 'ylim', [0 sWT.MovieInfo.Height], 'box', 'off'); % size should be the same as the video
hold on
title(sWT.MovieInfo.Filename, 'interpreter', 'none');

% Initialize the cell that will hold all the data to be exported to Excel.
% This cell is composed of 7 columns that, respectively, contain;
%   1   whisker name (WH)
%   2   relative time in whisk cycle (T)
%   3   absolute time in movie (frame-number; F)
%   4   cycle number (CYC)
%   5   whisker angle (A)
%   6   whisker curvature (C)
%   7   whisker reaction angle (RA)
%   8   whisker integrated curvature (IC)
cData = cell(8,1);

% Collect data
% For each unique whisker, collect from N frames curvature at base,
% integrated curvature, angle and reaction angle.

% Iterate over unique whiskers
for w_this = 1:length(cWhiskerNames)
    % Get whisker indices of current whisker in
    % Get frames in which current whisker was marked
    vIndx = find(strcmp(cAllWhiskerNames, cWhiskerNames{w_this}));
    
    % Iterate over marked instances of current whisker
    for w_inst = 1:length(vIndx)
        % Get time
        sWhiskerName = sWT.MovieInfo.WhiskerIdentity{vIndx(w_inst)}{1};
        vUnderscoreIndx = findstr(sWhiskerName, '_');
        sTime = sWhiskerName((vUnderscoreIndx(1)+1):(vUnderscoreIndx(2)-1));
        
        % Get cycle number
        sCycleNumber = sWhiskerName((vUnderscoreIndx(2)+1):end);
        
        % Find the 1st frame current whisker instance was tracked (usually,
        % the whisker will only have been tracked in one frame, but in case
        % it was tracked across several frames use just the 1st frame)
        mSpl = sWT.MovieInfo.SplinePoints(:, :, :, vIndx(w_inst));
        vTrackedFramesIndx = find(squeeze(any(all(mSpl,2)))); % all tracked frame indices
        mSpl = mSpl(:,:,vTrackedFramesIndx(1));

        % Get whisker spline
        [vXX, vYY] = wt_spline(mSpl(:,1), mSpl(:,2), min(mSpl(:,1)):max(mSpl(:,1)));
        plot(vXX, vYY, 'color', sWT.Colors(vIndx(w_inst),:))
        hTxt = text(vXX(end), vYY(end), sWT.MovieInfo.WhiskerIdentity{vIndx(w_inst)}, 'color', sWT.Colors(vIndx(w_inst),:), 'horizontalalignment', 'left');
        set(hTxt, 'interpreter', 'none')
        
        % Get angle
        [nAngle, nIntersect] = wt_get_angle(mSpl, sWT.MovieInfo.RefLine, sWT.MovieInfo.AngleDelta);
        
        % Get curvature at base
        nCurvature = wt_get_curv_at_base(mSpl);
        % - convert from pixels to mm
        if isfield(sWT.MovieInfo, 'PixelsPerMM')
            nCurvature = nCurvature .* sWT.MovieInfo.PixelsPerMM;
            %nCurvature = nCurvature / sWT.MovieInfo.PixelsPerMM;
        end
        
        % Get reaction angle
        %  - for this we first need [X,Y] coordinates of the object
        try     % - object marked (we always assume there is only ONE object marked!)
            vObjIndex = find(all(~isnan(sWT.MovieInfo.ObjectRadPos), 2));
            mObjXY = sWT.MovieInfo.ObjectRadPos(vObjIndex(1),:,:);
            nReactionAngle = wt_get_reaction_angle(mSpl, sWT.MovieInfo.RefLine, mObjXY);
            plot(mObjXY(1), mObjXY(2), 'ko')
            plot(mObjXY(1), mObjXY(2), 'kx')
        catch   % - no object marked
            nReactionAngle = 0;
        end

        % Get integrated curvature
        nIntCurv = wt_get_integrated_curvature(mSpl);
        % - convert from pixels to mm
        if isfield(sWT.MovieInfo, 'PixelsPerMM')
            nIntCurv = nIntCurv / sWT.MovieInfo.PixelsPerMM;
        end
        
        % Store spline information in cell that will be exported to Excel,
        % in the columnar format; [WH T F CYC A C RA IC]
        cData{1} = [cData{1}; cWhiskerNames(w_this)];       % whisker name
        cData{2} = [cData{2}; mat2cell(sTime)];             % relative time in whisk cycle
        cData{3} = [cData{3}; vTrackedFramesIndx(1)];       % absolute time in movie (frame-number)
        cData{4} = [cData{4}; mat2cell(sCycleNumber)];      % cycle number
        cData{5} = [cData{5}; nAngle];                      % angle
        cData{6} = [cData{6}; nCurvature];                  % curvature
        cData{7} = [cData{7}; nReactionAngle];              % reaction angle
        cData{8} = [cData{8}; nIntCurv];                    % integrated curvature
    end
end

% Export data to Excel
%  One sheet for each whisker. Data is tabulated as follows:
%  [WH T F CYC A C RA IC]
cHeaders = {'Whisker' 'Time' 'Frame' 'Cycle' 'Angle' 'Curvature' 'ReactionAngle' 'IntegratedCurvature'};

Excel = actxserver('Excel.Application'); % Open new instance of Excel
set(Excel, 'Visible', 1);

% Create new workbook
Workbooks = Excel.Workbooks;
Workbook = invoke(Workbooks, 'Add');
Sheets = Excel.ActiveWorkBook.Sheets;
cCols = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};
% Make the 1st sheet active
invoke(get(Sheets, 'Item', 1), 'Activate');
Activesheet = Excel.Activesheet;

% Iterate over cells that contain data
for c = 1:length(cHeaders)
    % Insert header
    Range = get(Activesheet, 'Range', sprintf('%s1', cCols{c}), sprintf('%s1', cCols{c}));
    set(Range, 'Value', cHeaders{c})
    % Insert data
    nLastRow = size(cData{c}, 1) + 1;
    Range = get(Activesheet, 'Range', sprintf('%s2', cCols{c}), sprintf('%s%d', cCols{c}, nLastRow));
    set(Range, 'Value', cData{c})
end

% Display a warning if the movie has not been calibrated
if ~isfield(sWT.MovieInfo, 'PixelsPerMM')
    warndlg('This movie has not been calibrated. Curvature and Integrated Curvature measurements are therefore in units of pixels.', 'WT Warning')
end

return
