function wt_graphs( varargin )
% WT_GRAPHS
% Organize and create graphs
%
% Usage:
%   wt_graphs
%   wt_graphs(CMD)
%   wt_graphs(VAR, TGL)
%
% Inputs:
%   CMD     close
%           refresh
%   VAR     angle
%           curvature
%   TGL     Toggle parameter ON/OFF
%           

global g_tWT

persistent p_vRefLine;
persistent p_vPlotWhichWhiskers;
persistent p_cActivePlots;
persistent p_nAngleDelta;

% Determine which plots to show
if nargin ~= 2
    % Reset all parameters (e.g. when menu is closed)
    if nargin == 1
        switch lower(varargin{1})
            case 'close'
                p_vPlotWhichWhiskers = [];
                p_cActivePlots = [];
                delete(findobj('Name', 'WT Plots'))
                return;
            case 'refresh'
                p_vRefLine = [];
                g_tWT.MovieInfo.PositionOffset = [];
                wt_graphs;
        end
    end
    % Activate menu, or create new if it does not exist
    if findobj('Tag', 'plotprefs'), figure(findobj('Tag', 'plotprefs'));
    else CreateMenu; end    
else
    %%% PLOT GRAPHS
    % If there are two input arguments, it means either that
    %   1 - a graph should be turned ON/OFF, or
    %   2 - if the first argument is a number that a whisker should be turned ON/OFF
    nFS = g_tWT.MovieInfo.FramesPerSecond;
    if nargin == 2 || nargin == 0
        sPlotWhat = varargin{1}; % type of plot
        nShow = varargin{2}; % if plot should be turned 1=ON or 0=OFF
        if ~isempty(str2num(sPlotWhat))
            sPlotWhat = str2num(sPlotWhat);
            if nShow
                if isempty(p_vPlotWhichWhiskers), p_vPlotWhichWhiskers = sPlotWhat;
                else p_vPlotWhichWhiskers(end+1) = sPlotWhat; end
            else
                if isempty(p_vPlotWhichWhiskers), return; % we shouldn't get here...
                else % Remove whisker from list
                    p_vPlotWhichWhiskers = p_vPlotWhichWhiskers(find(p_vPlotWhichWhiskers~=sPlotWhat));
                end
            end
        else
            % Create list of plots to show
            if nShow % turn ON
                if isempty(p_cActivePlots), p_cActivePlots = {sPlotWhat};
                else p_cActivePlots{end+1} = sPlotWhat; end
            else % turn OFF
                if isempty(p_cActivePlots), return; % we shouldn't get here...
                else % Remove plot from list
                    vKeep = [];
                    for p = 1:size(p_cActivePlots,2)
                        if ~strcmp(char(p_cActivePlots{p}), sPlotWhat)
                            vKeep = [vKeep p];
                        end
                    end
                    p_cActivePlots = {p_cActivePlots{[vKeep]}};
                end
            end
        end
    else wt_error('Mistake in input argument list'); return; end

    % Don't open window if there are no head movements or options selected
    if islogical(p_vPlotWhichWhiskers~=0) && (isempty(p_vPlotWhichWhiskers) || isempty(p_cActivePlots))
        return
    end
    
    % Open figure window if not already opened
    if isempty(findobj('Name', 'WT Plots'))
        figure;
        set(gcf, 'NumberTitle', 'off', ...
            'Name', 'WT Plots', ...
            'Doublebuffer', 'on', ...
            'MenuBar', 'figure', ...
            'Renderer', 'painters', ...
            'BackingStore', 'on' );
        CreatePushButtons;
    else figure(findobj('Name', 'WT Plots')); CreatePushButtons; end
    
    % Determine which figure to plot, calculate their midlines and
    % respective positions in the current subplot.
    %  - work from bottom of figure and up...
    % keep structure that contains 1) type of plot, 2) mid-line, 3) height
    % (2 and 3 is for normalization of the trace and the calibration bars)
    % We keep track of plot-type by name and number (for sorting)
    tPlots = struct('order',{{'Triggers', 'Object distance', 'Base Translation', 'Curvature', 'Angle', 'Velocity', 'Acceleration'}});
    tPlots.proportion = [ ...
            .1 ...  % triggers
            .15 ...  % positon from object
            .15 ...  % Base Translation
            .15 ...  % curvature
            .15 ...  % angle
            .15 ...  % velocity
            .15 ...  % acceleration
        ];
    tPlots.midline = zeros(1, size(tPlots.order, 2));
    tPlots.height  = zeros(1, size(tPlots.order, 2));
    % Units of plots and calibration bars
    tPlots.calib   = [...
            NaN, ... % ON/OFF
            2, ...  % Object distance, mm or pix
            1, ...  % Base Translation, mm or pix
            NaN, ...  % Curvature, mm or pix
            5, ...  % Degrees angle
            500, ...   %  Velocity, deg/sec
            250 ...   % Acceleration, deg/sec^2
        ];
    nCurrHeightUsed = 0; % Available height of subplot already used
    for p = 1:size(tPlots.order, 2)
        % Check if plot should be included
        if sum(strcmp(p_cActivePlots, char(tPlots.order(p)))) >= 1
            tPlots.midline(p) = nCurrHeightUsed + tPlots.proportion(p)/2;
            tPlots.height(p)  = tPlots.proportion(p);
            nCurrHeightUsed = nCurrHeightUsed + tPlots.proportion(p);
        end
    end

    % Expand all traces to occupy full height of subplot (ie. normalize to height of 1)    
    tPlots.midline = tPlots.midline ./ nCurrHeightUsed;
    tPlots.height  = tPlots.height  ./ nCurrHeightUsed;

    % Number of extra panels (e.g. for triggered averages
    if sum( [strcmp(p_cActivePlots, 'Avg cycle (trig A)') strcmp(p_cActivePlots, 'Avg cycle (trig B)')])
        bExtraPanel = 1;
    else bExtraPanel = 0; end
    
    %  - delete existing traces if reference angle or AngleDelta has
    %    changed (also happens when user clicks Refresh)
    if (~isequal(p_vRefLine, g_tWT.MovieInfo.RefLine) ...
            || ~isequal(p_nAngleDelta, g_tWT.MovieInfo.AngleDelta)) ...
            && ~isempty(p_nAngleDelta)
        g_tWT.MovieInfo.Angle = [];
        g_tWT.MovieInfo.Intersect = [];
        g_tWT.MovieInfo.PositionOffset = [];
        g_tWT.MovieInfo.Curvature = [];
        p_vRefLine = g_tWT.MovieInfo.RefLine;
        p_nAngleDelta = g_tWT.MovieInfo.AngleDelta;
    end
    
    % Iterate over whiskers
    for w = 1:length(p_vPlotWhichWhiskers)
        % All plots are normalized according to their proportionate height
        % to the subplot (see above)
        if bExtraPanel
            nFrameStart = 1+5*(w-1);
            nFrameEnd = nFrameStart+3;
            hLeftPanel = subplot(length(p_vPlotWhichWhiskers), 4+bExtraPanel, [nFrameStart:nFrameEnd]); hold on
            hRightPanel = subplot(length(p_vPlotWhichWhiskers), 4+bExtraPanel, nFrameEnd+1); hold on
            nRightPanelLength = 0;
        else
            hLeftPanel = subplot(length(p_vPlotWhichWhiskers), 1, w); hold on
        end
        
        % Plot head movements
        if p_vPlotWhichWhiskers(w) == 0
            vN = FilterSeries(g_tWT.MovieInfo.Nose(:,2));
            [vN, sUnit] = wt_pix_2_mm(vN ./ max(vN));
            PlotTrace(vN, vN, hLeftPanel, 'nose', 0.5, 'Head Y Pos', nFS)
            hold on
            nCurrentFrame = get(g_tWT.Handles.hSlider, 'Value');
            hFrameMarker = plot([nCurrentFrame nCurrentFrame].*(1000/nFS), [-.5 1.5], 'r:');
            set(hFrameMarker, 'Tag', 'framemarker')
            set(hLeftPanel, 'ylim', [0 1], ...
                'ytick', [], ...
                'xlim', [1 nMovDur], ...
                'box', 'on', ...
                'FontSize', 8, ...
                'Tag', 'tracesplot', ...
                'ButtonDownFcn', [sprintf('v=get(gca,''CurrentPoint'');wt_display_frame(round(v(1,1)/%d))', 1000/nFS)] );
            axes(hLeftPanel);
            title(sprintf('%s, %d frames/sec, LoPass=%dHz', ....
                g_tWT.MovieInfo.Filename, ...
                g_tWT.MovieInfo.FramesPerSecond, ...
                str2double(get(findobj('tag','lowpass'), 'String')) ));
            xlabel('Time (ms)');
            % Create black bar bar to the left of the plot
            vPosition = get(hLeftPanel, 'Position');
            uicontrol(gcf, 'Style', 'frame', ...
                'Units', 'Normalized', ...
                'Position', [vPosition(1)-0.075 vPosition(2) 0.025 vPosition(4)], ...
                'ForegroundColor', [0 0 0], 'BackgroundColor', [0 0 0] );
            continue;
        end

        % Find missing frames
        vSplFrames = find(sum(sum(g_tWT.MovieInfo.SplinePoints(:,:,:,p_vPlotWhichWhiskers(w)))) > 0); % tracked frames
        try
            vAngFrames = find(g_tWT.MovieInfo.Angle(:,p_vPlotWhichWhiskers(w)) ~= 0 ); % frames with computed angle
            vMissingFrames = setdiff(vSplFrames, vAngFrames); % tracked frames without angle
        catch vMissingFrames = vSplFrames; end

        %  - compute
        if ~isempty(vMissingFrames)
            mSplinePoints = g_tWT.MovieInfo.SplinePoints(:, :, vMissingFrames, p_vPlotWhichWhiskers(w));
            % angle
            [g_tWT.MovieInfo.Angle(vMissingFrames, p_vPlotWhichWhiskers(w)) g_tWT.MovieInfo.Intersect(vMissingFrames,1:2,p_vPlotWhichWhiskers(w))] = ...
                wt_get_angle(mSplinePoints, g_tWT.MovieInfo.RefLine, g_tWT.MovieInfo.AngleDelta);
        end

        % Plot angle
        nAngleIndx = find(strcmp(tPlots.order, 'Angle'));
        vAngle = g_tWT.MovieInfo.Angle(:, p_vPlotWhichWhiskers(w));
        vAngleFilt = zeros(size(vAngle))*NaN;
        vAngle(vAngle==0) = NaN;
        vAngleFilt = FilterSeries(vAngle, 'angle');
        if tPlots.height(nAngleIndx) ~= 0
            [vAngle, nNormFact] = NormalizeToHeight(vAngleFilt, tPlots.midline(nAngleIndx), tPlots.height(nAngleIndx));
            PlotTrace(vAngle, vAngleFilt, hLeftPanel, 'angle', tPlots.midline(nAngleIndx), 'Angle', nFS);
            DrawCalibrationBar(nNormFact, tPlots.calib(nAngleIndx), vAngle, sprintf('%.1f deg', tPlots.calib(nAngleIndx)), nFS)
            PlotMaxDwellTime(vAngleFilt, vAngle, nNormFact, 'deg', nFS);
            %  - plot average angle
            if ~isempty(find(strcmpi(p_cActivePlots, 'Avg cycle (trig A)')))
                nLen = PlotTraceWithErrorBars(vAngle, vAngleFilt, g_tWT.MovieInfo.StimulusA, hRightPanel, 'angle-average-stimA');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
            if ~isempty(find(strcmpi(p_cActivePlots, 'Avg cycle (trig B)')))
                nLen = PlotTraceWithErrorBars(vAngle, vAngleFilt, g_tWT.MovieInfo.StimulusB, hRightPanel, 'angle-average-stimB');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
        end
        
        % Plot Base Translation (intersect)
        nIntersectIndx = find(strcmp(tPlots.order, 'Base Translation'));
        if tPlots.height(nIntersectIndx) ~= 0
            [vIntersect, sUnit] = wt_pix_2_mm(g_tWT.MovieInfo.Intersect(:, 2, p_vPlotWhichWhiskers(w)));
            vIntersectFilt = FilterSeries(vIntersect);
            [vIntersect, nNormFact] = NormalizeToHeight(vIntersectFilt, tPlots.midline(nIntersectIndx), tPlots.height(nIntersectIndx));
            PlotTrace(vIntersect, vIntersectFilt, hLeftPanel, 'intersect', tPlots.midline(nIntersectIndx), 'Inters', nFS)
            DrawCalibrationBar(nNormFact, tPlots.calib(nIntersectIndx), vIntersect, sprintf('%d %s', tPlots.calib(nIntersectIndx), sUnit), nFS)
            PlotMaxDwellTime(vIntersectFilt, vIntersect, nNormFact, sprintf('%s', sUnit), nFS);
            %  - plot mean intersect
            if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig A)')))
                nLen = PlotTraceWithErrorBars(vIntersect, vIntersectFilt, g_tWT.MovieInfo.StimulusA, hRightPanel, 'intersect-average-stimA');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
            if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig B)')))
                nLen = PlotTraceWithErrorBars(vIntersect, vIntersectFilt, g_tWT.MovieInfo.StimulusB, hRightPanel, 'intersect-average-stimB');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
        end

        % Plot whisker's distance from object (Y position relative to object)
        nPosIndx = find(strcmp(tPlots.order, 'Object distance'));
        bBreak = 0;
        if tPlots.height(nPosIndx) ~= 0
            mWhisker = g_tWT.MovieInfo.SplinePoints(:,:,:, p_vPlotWhichWhiskers(w));
            % Head-movements are tracked
            try vObj = g_tWT.MovieInfo.ObjectRadPos(p_vPlotWhichWhiskers(w),:,:);
            catch
                warndlg('No object has been marked.');
                bBreak = 1;
            end
            
            if ~bBreak
                if isempty(g_tWT.MovieInfo.PositionOffset)
                    try
                        mRightEye = g_tWT.MovieInfo.RightEye;
                        mLeftEye = g_tWT.MovieInfo.LeftEye;
                        mNose = g_tWT.MovieInfo.Nose;
                        nWhiskerSide = g_tWT.MovieInfo.WhiskerSide(p_vPlotWhichWhiskers(w));
                        vPosFromObj = wt_get_position_offset(mWhisker, ...
                            vObj, ...
                            g_tWT.MovieInfo.ImCropSize, ...
                            g_tWT.MovieInfo.RadExt, ...
                            g_tWT.MovieInfo.HorExt, ...
                            mRightEye, ...
                            mLeftEye, ...
                            mNose, ...
                            nWhiskerSide );
                    catch
                        vPosFromObj = wt_get_position_offset(mWhisker, ...
                            vObj, ...
                            g_tWT.MovieInfo.ImCropSize, ...
                            g_tWT.MovieInfo.RadExt, ...
                            g_tWT.MovieInfo.HorExt );
                    end
                    g_tWT.MovieInfo.PositionOffset(1:length(vPosFromObj), p_vPlotWhichWhiskers(w)) = vPosFromObj;
                    g_tWT.MovieInfo.PositionOffset(find(g_tWT.MovieInfo.PositionOffset==0)) = NaN;
                end

                [vPosFromObj, sUnit] = wt_pix_2_mm(g_tWT.MovieInfo.PositionOffset(:, p_vPlotWhichWhiskers(w)));
                
                vPosFromObjFilt = FilterSeries(vPosFromObj);
                [vPosFromObj, nNormFact] = NormalizeToHeight(vPosFromObjFilt, tPlots.midline(nPosIndx), tPlots.height(nPosIndx));
                PlotTrace(vPosFromObj, vPosFromObjFilt, hLeftPanel, 'position-offset', tPlots.midline(nPosIndx), 'Pos', nFS)
                DrawCalibrationBar(nNormFact, tPlots.calib(nPosIndx), vPosFromObj, sprintf('%.f %s', tPlots.calib(nPosIndx), sUnit), nFS)
                PlotMaxDwellTime(vPosFromObjFilt, vPosFromObj, nNormFact, sprintf('%s', sUnit), nFS, 0);

                %  - plot average position
                if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig A)')))
                    nLen = PlotTraceWithErrorBars(vPosFromObj, vPosFromObjFilt, g_tWT.MovieInfo.StimulusA, hRightPanel, 'PositionFromPbject-average-stimA');
                    nRightPanelLength = max([nRightPanelLength nLen]);
                end
                if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig B)')))
                    nLen = PlotTraceWithErrorBars(vPosFromObj, vPosFromObjFilt, g_tWT.MovieInfo.StimulusB, hRightPanel, 'PositionFromPbject-average-stimB');
                    nRightPanelLength = max([nRightPanelLength nLen]);
                end
            end
        end

        % Plot velocity
        nVelocityIndx = find(strcmp(tPlots.order, 'Velocity'));
        if tPlots.height(nVelocityIndx) ~= 0
            vVelocityFilt = [NaN; diff(vAngleFilt)*g_tWT.MovieInfo.FramesPerSecond];
            [vVelocity, nNormFact] = NormalizeToHeight(vVelocityFilt, tPlots.midline(nVelocityIndx), tPlots.height(nVelocityIndx));            
            PlotTrace(vVelocity, vVelocityFilt, hLeftPanel, 'velocity', tPlots.midline(nVelocityIndx), 'Vel', nFS)
            DrawCalibrationBar(nNormFact, tPlots.calib(nVelocityIndx), vVelocity, sprintf('%d deg/sec', tPlots.calib(nVelocityIndx)), nFS)
            PlotMaxDwellTime(vVelocityFilt, vVelocity, nNormFact, '', nFS, 0);
            % Average velocity across cycles
            if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig A)')))
                nLen = PlotTraceWithErrorBars(vVelocity, vVelocityFilt, g_tWT.MovieInfo.StimulusA, hRightPanel, 'velocity-average-stimB');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
            if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig B)')))
                nLen = PlotTraceWithErrorBars(vVelocity, vVelocityFilt, g_tWT.MovieInfo.StimulusB, hRightPanel, 'velocity-average-stimB');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
        end
        
        % Plot acceleration
        nAccelerationIndx = find(strcmp(tPlots.order, 'Acceleration'));
        if tPlots.height(nAccelerationIndx) ~= 0
            vAccelerationFilt = [NaN; NaN; diff(diff(vAngleFilt))*g_tWT.MovieInfo.FramesPerSecond];
            [vAcceleration, nNormFact] = NormalizeToHeight(vAccelerationFilt, tPlots.midline(nAccelerationIndx), tPlots.height(nAccelerationIndx));            
            PlotTrace(vAcceleration, vAccelerationFilt, hLeftPanel, 'acceleration', tPlots.midline(nAccelerationIndx), 'Acc', nFS)
            DrawCalibrationBar(nNormFact, tPlots.calib(nAccelerationIndx), vAcceleration, sprintf('%d deg/sec^2', tPlots.calib(nAccelerationIndx)), nFS)
            PlotMaxDwellTime(vAccelerationFilt, vAcceleration, nNormFact, '', nFS, 0);
            % Average velocity across cycles
            if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig A)')))
                nLen = PlotTraceWithErrorBars(vAcceleration, vAccelerationFilt, g_tWT.MovieInfo.StimulusA, hRightPanel, 'acceleration-average-stimA');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
            if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig B)')))
                nLen = PlotTraceWithErrorBars(vAcceleration, vAccelerationFilt, g_tWT.MovieInfo.StimulusB, hRightPanel, 'acceleration-average-stimB');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
        end 
        
        % Plot curvature
        nCurvatureIndx = find(strcmp(tPlots.order, 'Curvature'));
        if tPlots.height(nCurvatureIndx) ~= 0

            % Find missing frames
            vSplFrames = find(sum(sum(g_tWT.MovieInfo.SplinePoints(:,:,:,p_vPlotWhichWhiskers(w)))) > 0); % tracked frames
            try
                vCurvFrames = find(g_tWT.MovieInfo.Curvature(:,p_vPlotWhichWhiskers(w)) ~= 0 ); % frames with computed curv
                vMissingFrames = setdiff(vSplFrames, vCurvFrames); % tracked frames without curv
            catch vMissingFrames = vSplFrames; end

            if ~isempty(vMissingFrames)
                mSplinePoints = g_tWT.MovieInfo.SplinePoints(:, :, vMissingFrames, p_vPlotWhichWhiskers(w));
                if g_tWT.MovieInfo.AngleDelta == 0
                    g_tWT.MovieInfo.Curvature(vMissingFrames, p_vPlotWhichWhiskers(w)) = wt_get_curv_at_base(mSplinePoints);
                else
                    g_tWT.MovieInfo.Curvature(vMissingFrames, p_vPlotWhichWhiskers(w)) = wt_get_curvature(mSplinePoints);
                end
                g_tWT.MovieInfo.Curvature([1:vMissingFrames(1) vMissingFrames(end):end], p_vPlotWhichWhiskers(w)) = NaN;
            end

            vCurvature = g_tWT.MovieInfo.Curvature(:, p_vPlotWhichWhiskers(w));
            sUnit = 'pix';
            if isfield(g_tWT.MovieInfo, 'PixelsPerMM')
                if ~isempty(g_tWT.MovieInfo.PixelsPerMM)
                    vCurvature = vCurvature .* g_tWT.MovieInfo.PixelsPerMM;
                    sUnit = 'mm';
                end
            end
            vCurvatureFilt = FilterSeries(vCurvature);
            [vCurvature, nNormFact] = NormalizeToHeight(vCurvatureFilt, tPlots.midline(nCurvatureIndx), tPlots.height(nCurvatureIndx));
            PlotTrace(vCurvature, vCurvatureFilt, hLeftPanel, 'curvature', tPlots.midline(nCurvatureIndx), 'Curv', nFS)
            DrawCalibrationBar(nNormFact, tPlots.calib(nCurvatureIndx), vCurvature, sprintf('%.2f s', tPlots.calib(nCurvatureIndx), sUnit), nFS)
            PlotMaxDwellTime(vCurvatureFilt, vCurvature, nNormFact, sprintf('%s', sUnit), nFS);
            %  - plot average curvature
            if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig A)')))
                nLen = PlotTraceWithErrorBars(vCurvature, vCurvatureFilt, g_tWT.MovieInfo.StimulusA, hRightPanel, 'curvature-average-stimA');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
            if ~isempty(find(strcmp(p_cActivePlots, 'Avg cycle (trig B)')))
                nLen = PlotTraceWithErrorBars(vCurvature, vCurvatureFilt, g_tWT.MovieInfo.StimulusB, hRightPanel, 'curvature-average-stimB');
                nRightPanelLength = max([nRightPanelLength nLen]);
            end
        end

        % Plot stimulus
        nTrigIndx = find(strcmp(tPlots.order, 'Triggers'));
        if tPlots.height(nTrigIndx) ~= 0
            vStimA = g_tWT.MovieInfo.StimulusA;
            vStimB = g_tWT.MovieInfo.StimulusB;
            vStimA(~vStimA) = NaN;
            vStimB(~vStimB) = NaN;
            % Normalize
            vStimA = vStimA / max(vStimA) * tPlots.height(nTrigIndx);
            vStimA = vStimA + tPlots.midline(nTrigIndx)-tPlots.height(nTrigIndx)/2;
            vStimB = vStimB / max(vStimB) * tPlots.height(nTrigIndx);
            vStimB = vStimB + tPlots.midline(nTrigIndx)-tPlots.height(nTrigIndx)/2;
            subplot(hLeftPanel);
            plot( (1:length(vStimA)) .* (1000/nFS) , vStimA/3, 'r', 'LineWidth', 4)
            subplot(hLeftPanel);
            plot((1:length(vStimB)) .*(1000/nFS), vStimB/1.5, 'g', 'LineWidth', 4)
        end
        hold on
        nCurrentFrame = get(g_tWT.Handles.hSlider, 'Value');
        hFrameMarker = plot([nCurrentFrame nCurrentFrame].*(1000/nFS), [-.5 1.5], 'r:');
        set(hFrameMarker, 'Tag', 'framemarker')

        % Set plot properties
        nMovDur = g_tWT.MovieInfo.NumFrames * (1000/g_tWT.MovieInfo.FramesPerSecond); % msec
        set(hLeftPanel, 'ylim', [0 1], ...
            'ytick', [], ...
            'xlim', [1 nMovDur], ...
            'box', 'on', ...
            'FontSize', 8, ...
            'Tag', 'tracesplot', ...
            'ButtonDownFcn', [sprintf('v=get(gca,''CurrentPoint'');wt_display_frame(round(v(1,1)/%d))', 1000/nFS)] );
        axes(hLeftPanel);
        title(sprintf('%s, %d frames/sec, LoPass=%dHz', ....
            g_tWT.MovieInfo.Filename, ...
            g_tWT.MovieInfo.FramesPerSecond, ...
            str2num(get(findobj('tag','lowpass'), 'String')) ), 'interpreter','none');
        xlabel('Time (ms)');
        if bExtraPanel
            if nRightPanelLength <= 0, nRightPanelLength = 100; end
            set(hRightPanel, 'ylim', [0 1], ...
                'ytick', [], ...
                'xlim', [1 nRightPanelLength], ...
                'box', 'on', ...
                'FontSize', 8 );
            axes(hRightPanel);
            title('Cycle average');
            xlabel('Time (msec)');
        end
        % Create colored bar left to plots that indicate whisker identity
        vPosition = get(hLeftPanel, 'Position');
        nWind = rem(p_vPlotWhichWhiskers(w), size(g_tWT.Colors,1));
        if nWind == 0, nWind = size(g_tWT.Colors,1); end
        uicontrol(gcf, 'Style', 'frame', ...
            'Units', 'Normalized', ...
            'Position', [vPosition(1)-0.075 vPosition(2) 0.025 vPosition(4)], ...
            'ForegroundColor', g_tWT.Colors(nWind, :), ...
            'BackgroundColor', g_tWT.Colors(nWind, :);
    end
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PrintHeader( sHeader , hWindow , nYpos )
uicontrol(hWindow, 'Style', 'frame', 'Position', [1 nYpos 150 20], ...
    'BackgroundColor', [.4 .4 .4] );
uicontrol(hWindow, 'Style', 'text', 'Position', [5 nYpos+2 145 14], ...
    'String', sHeader, ...
    'HorizontalAlignment', 'center', ...
    'foregroundcolor', [.9 .9 .9], ...
    'BackgroundColor', [.4 .4 .4], ...
    'FontWeight', 'bold' );
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Normalize time-series to fit within its dedicated vertical space in
% subplot.
function [vSeriesOut, nNormFact] = NormalizeToHeight(vSeriesIn, nMidline, nHeight);
if length(find(~isnan(vSeriesIn))) == 1
    vSeriesOut = vSeriesIn / max(vSeriesIn);
    nNormFact = max(vSeriesOut) ./ max(vSeriesIn);
else
    vSeriesOut = vSeriesIn - min(vSeriesIn);
    vSeriesOut = vSeriesOut / max(vSeriesOut) * nHeight;
    vSeriesOut = vSeriesOut + nMidline - nHeight/2;
    nHeightOrig = abs(diff([max(vSeriesIn) min(vSeriesIn)]));
    nHeightNew = abs(diff([max(vSeriesOut) min(vSeriesOut)]));
    nNormFact = nHeightNew ./ nHeightOrig;
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Low-pass filter timeseries according to GUI settings.
function vSeriesOut = FilterSeries(vSeriesIn,varargin)
global g_tWT
nLowPassFreq = str2double(get(findobj('tag','lowpass'), 'String'));
if ~isempty(nLowPassFreq) && ~(nLowPassFreq <= 0) && ~isnan(nLowPassFreq)
    [a,b] = butter(3, nLowPassFreq/(g_tWT.MovieInfo.FramesPerSecond/2), 'low');
    vFiltSrsIndx = find(~isnan(vSeriesIn));
    vFiltSeries = vSeriesIn(vFiltSrsIndx);
    vSeriesOut = zeros(size(vSeriesIn))*NaN;
    vSeriesOut(vFiltSrsIndx) = filtfilt(a, b, vFiltSeries);
else vSeriesOut = vSeriesIn; end
vSeriesOut(vSeriesOut==0) = NaN;
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate cycle average of time-series
function [vCycleAvg, vCycleError, mSegments] = GetCycleAverage(vSeriesIn, vStim)
vOnsets = find(diff(vStim)==1)+1; % find all onset moments
nMinSize = median(diff(vOnsets)) / 2;  % remove segments with durations smaller than half of the median duration
try
    vOnsets(diff(vOnsets) < nMinSize) = [];
catch
    wt_error('An error occurred when computing average cycles. Two or more cycles needed to compute an average.')
end

% Drop cycles that overlap with non-tracked frames
vDropIndx = find(vOnsets >= length(vSeriesIn));
if ~isempty(vDropIndx), vOnsets((vDropIndx(1)-1):vDropIndx(end)) = []; end

% Drop cycles not in the requested cycle range
nFromCycle = str2double(get(findobj('Tag', 'fromcycle'), 'string'));
if nFromCycle < 1, nFromCycle = 1; end
nToCycle = str2double(get(findobj('Tag', 'tocycle'), 'string'));
if nToCycle > length(vOnsets), nToCycle = length(vOnsets); end

% Create all segments to use
mSegments = [];
nIndx = 1;
nOnsets = length(vOnsets);
vOnsets = vOnsets - 50;
for s = 1:nOnsets
    if s < nFromCycle || s > nToCycle, continue, end
    if s == nOnsets
        %vNewSeg = vSeriesIn(vOnsets(s):end);
        vNewSeg = vSeriesIn(vOnsets(s):(vOnsets(s)+(vOnsets(s)-vOnsets(s-1))));
    else
        vNewSeg = vSeriesIn(vOnsets(s):vOnsets(s+1)-1);
    end
    if length(vNewSeg) > size(mSegments,1)
        % zeropad matrix that holds segments if new segment is longer than
        % all previous segments
        padarray(mSegments, length(vNewSeg)-size(mSegments,1), 0, 'post');
    end
    if isempty(mSegments)
        mSegments = vNewSeg;
    else
        mSegments(1:length(vNewSeg),nIndx) = vNewSeg;
    end
    nIndx = nIndx + 1;
end
% Calculate mean of all segments
vCycleAvg = nanmean(mSegments,2);
vCycleAvg = vCycleAvg(1:end-1);
% Calculate standard-error of all segments
vCycleError = nanstd(mSegments, 0, 2);% / sqrt(size(mSegments,2));
vCycleError = vCycleError(1:end-1);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw calibration bar in subplot
function DrawCalibrationBar(nNormFact, nCalibSize, vSeries, sCalibString, nFS)
global g_tWT
if isempty(vSeries), return; end
nCalibLineWidth = 6;
nCalibHeight = nCalibSize * nNormFact;
nXMax = g_tWT.MovieInfo.NumFrames * (1000/nFS);
plot([nXMax-nCalibLineWidth nXMax-nCalibLineWidth] .* (1000/nFS), [min(vSeries) min(vSeries)+nCalibHeight], 'k', 'LineWidth', nCalibLineWidth);
hTxt = text(nXMax+25, min(vSeries)+nCalibHeight/2, sCalibString);
set(hTxt, 'Rotation', -90, 'HorizontalAlignment', 'center', 'FontSize', 8);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate max dwell-time location in time series
% ex. PlotMaxDwellTime(vAngleFilt, vAngle, nNormFact, 'deg')
function  nMaxDwellTime = PlotMaxDwellTime(vSeriesOrig, vSeriesPlot, nNormFact, sString, nFS, varargin)
vBinCenters = min(vSeriesOrig):(max(vSeriesOrig)-min(vSeriesOrig))/100:max(vSeriesOrig);

% If data length == 1
if length(find(~isnan(vSeriesOrig))) < 2 || isempty(vBinCenters)
    nMaxDwellTime = 1;
    return
end

if ~isempty(varargin) % Plot line through a given value
    nMaxDwellTime = varargin{1};
else
    [vCount, vDwellTime] = hist(vSeriesOrig, vBinCenters);
    nMaxDwellTime = vDwellTime(vCount==max(vCount));
    nMaxDwellTime = nMaxDwellTime(1);
end
nY = (nMaxDwellTime*nNormFact) - diff([min(vSeriesPlot) min(vSeriesOrig*nNormFact)]);

hLine = plot([0 length(vSeriesOrig).*(1000/nFS)], [nY nY], 'g:', 'LineWidth', 2);
if strcmp(sString, 'deg')
    sLineString = sprintf('Y = %.5f %s)', nMaxDwellTime, sString);
    hTxt = text(-2, nY, sprintf('%.1f %s', nMaxDwellTime, sString));
else
    sLineString = sprintf('Y = %.5f %s', nMaxDwellTime, sString);
    hTxt = text(-2, nY, sprintf('%.1f %s', nMaxDwellTime, sString));
end
set(hLine, 'buttondownfcn', sprintf('msgbox(''%s'')', sLineString));
set(hTxt, 'FontSize', 6, 'HorizontalAlignment', 'right');
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create the menu window
function CreateMenu
global g_tWT

cOptions = {'Angle', 'Velocity', 'Acceleration', 'Curvature', 'Base Translation', 'Object distance', 'Triggers', 'Avg cycle (trig A)', 'Avg cycle (trig B)'};
% Set text parameters
nFontSize = 8;
nLinSep = 10;
nGuiElements = size(cOptions, 2) + size(g_tWT.MovieInfo.SplinePoints, 4) + 3; % options plus filter dialog
if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen)
    nGuiElements = nGuiElements + 1;
end
% Open figure window
vScrnSize = get(0, 'ScreenSize');
nFigHeight = nGuiElements * (nFontSize*2 + nLinSep) + 60;
nFigWidth = 150;
vFigPos = [5 vScrnSize(4)-(nFigHeight+21) nFigWidth nFigHeight];
hCurrWin = figure;
set(hCurrWin, 'NumberTitle', 'off', ...
    'Name', 'WT Menu', ...
    'Position', vFigPos, ...
    'MenuBar', 'none', ...
    'Tag', 'plotprefs', ...
    'CloseRequestFcn', 'wt_graphs(''close''); closereq;' )
% Place text string and boxes inside window
nCurrLine = nFigHeight;
nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
PrintHeader('Select plots', hCurrWin, nCurrLine)
for o = 1:size(cOptions, 2)
    nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
    uicontrol(hCurrWin, 'Style', 'checkbox', 'Position', [10 nCurrLine 150 20], ...
        'Callback', 'wt_graphs(get(gcbo,''string''), get(gcbo,''value''))', ...
        'String', char(cOptions(o)), ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [.8 .8 .8] );
end
% Filter options
nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
PrintHeader('Low-pass', hCurrWin, nCurrLine)
nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
uicontrol(hCurrWin, 'Style', 'edit', 'Position', [40 nCurrLine 40 20], ...
    'HorizontalAlignment', 'center', ...
    'Tag', 'lowpass' );
uicontrol(hCurrWin, 'Style', 'text', 'Position', [80 nCurrLine-4 30 20], ...
    'String', 'Hz', ...
    'BackgroundColor', [.8 .8 .8], ...
    'HorizontalAlignment', 'center' )
% Whisker representations
nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
PrintHeader('Select whiskers', hCurrWin, nCurrLine)
for w = 1:size(g_tWT.MovieInfo.SplinePoints, 4)
    if isempty(g_tWT.MovieInfo.SplinePoints), continue, end
    nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
    nWind = rem(w,size(g_tWT.Colors,1)),:);
    if nWind == 0, nWind = size(g_tWT.Colors,1); end
    hBox = uicontrol(hCurrWin, 'Style', 'checkbox', 'Position', [10 nCurrLine 125 20], ...
        'Callback', 'wt_graphs(get(gcbo, ''Tag''), get(gcbo, ''Value''))', ... % 0=OFF, 1=ON
        'HorizontalAlignment', 'right', ...
        'String', wt_whisker_id(w), ...
        'FontWeight', 'bold', ...
        'Tag', num2str(w), ...
        'foregroundColor', 'w', ...
        'BackgroundColor', g_tWT.Colors(nWind, :);
end
% Checkbox for plotting head-movements
if ~isempty(g_tWT.MovieInfo.EyeNoseAxLen)
    nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
    uicontrol(hCurrWin, 'Style', 'checkbox', 'Position', [10 nCurrLine 125 20], ...
        'Callback', 'wt_graphs(get(gcbo, ''Tag''), get(gcbo, ''Value''))', ... % 0=OFF, 1=ON
        'String', 'Head', ...
        'FontWeight', 'bold', ...
        'Tag', '0', ...
        'BackgroundColor', [0 0 0], ...
        'ForegroundColor', [1 1 1] );
end
% Refresh pushbutton
nCurrLine = nCurrLine - (nFontSize*2 + nLinSep);
uicontrol(hCurrWin, 'Style', 'pushbutton', 'Position', [10 nCurrLine 125 20], ...
    'Callback', 'wt_graphs(''refresh''); wt_graphs(get(gcbo, ''Tag''), get(gcbo, ''Value''))', ... % 0=OFF, 1=ON
    'String', 'Refresh', ...
    'FontWeight', 'bold' );
return;

%%%%% PLOTTRACE %%%%
function PlotTrace(vTrace, vUserData, hAxes, sIdent, vMidline, sString, nFS)
axes(hAxes)
vXX = (1:length(vTrace)) .* (1000/nFS);
hTrace = plot(vXX, vTrace, 'k');
cUserData = {sIdent, vUserData};
hTraceMenu = uicontextmenu;
set(hTrace, 'Tag', 'export-trace', 'UserData', cUserData, 'UIContextMenu', hTraceMenu)
uimenu(hTraceMenu, 'Label', 'Copy to new figure', 'Callback', 'x=get(gco,''userdata'');figure;plot(x{2})');
hTxt = text(-10, vMidline, sString);
set(hTxt, 'Rotation', 90, 'HorizontalAlignment', 'center', 'FontSize', 8);
return;

%%%% PLOTTRACEWITHERRORBARS %%%%
function nLen = PlotTraceWithErrorBars(vTrace, vUserData, vStim, hAxes, sIdent)
%vTrace = detrend(vTrace);

% Compute mean and standard-error
[vMean, vError, mSegments2] = GetCycleAverage(vTrace, vStim);
nLen = length(vMean);
[vUserData, vError2, mSegments] = GetCycleAverage(vUserData, vStim);

vColor = [.7 .7 .7];
axes(hAxes)
vMean = reshape(vMean, length(vMean), 1);
vError = reshape(vError, length(vError), 1);
vXt = (0:length(vError)-1)';
vXb = flipud(vXt);
vYt = vMean + vError;
vYb = flipud(vMean - vError);
fill([vXt;vXb], [vYt;vYb], vColor, 'EdgeColor', vColor)
hTrace = plot(0:length(vMean)-1,vMean, 'k');
cUserData = {sIdent, vUserData, mSegments};
hTraceMenu = uicontextmenu;
set(hTrace, 'Tag', 'export-trace', 'UserData', cUserData, 'UIContextMenu', hTraceMenu)
uimenu(hTraceMenu, 'Label', 'Copy to new figure', 'Callback', 'x=get(gco,''userdata'');figure;plot(x{2})');
uimenu(hTraceMenu, 'Label', 'Amplitude (max-min)', 'Callback', @ComputeAmplitude);

return

%%%% CREATEPUSHBUTTONS %%%%
function CreatePushButtons

hFromField = findobj('Tag', 'fromcycle');
if isempty(hFromField), nFromCycle = 2;
else nFromCycle = str2double(get(hFromField, 'string')); end

hToField = findobj('Tag', 'tocycle');
if isempty(hToField), nToCycle = 99;
else, nToCycle = str2double(get(hToField, 'string')); end

clf
uicontrol( 'Position', [5 5 20 20], ...
    'Style', 'pushbutton', ...
    'String', 'G', ...
    'FontSize', 7, 'HorizontalAlignment', 'center', ...
    'CallBack', @ToggleGrid );
uicontrol( 'Position', [30 5 20 20], ...
    'Style', 'pushbutton', ...
    'String', 'M', ...
    'FontSize', 7, 'HorizontalAlignment', 'center', ...
    'CallBack', @ToggleMarkers );
uicontrol( 'Position', [55 5 20 20], ...
    'Style', 'pushbutton', ...
    'String', 'E', ...
    'FontSize', 7, 'HorizontalAlignment', 'center', ...
    'CallBack', @ExportData );
uicontrol( 'Position', [85 5 100 20], ...
    'Style', 'text', ...
    'String', 'Average cycles', ...
    'FontSize', 7, ...
    'HorizontalAlignment', 'left' );
uicontrol( 'Position', [185 5 30 20], ...
    'Style', 'edit', ...
    'String', nFromCycle, ...
    'Tag', 'fromcycle', ...
    'FontSize', 7, 'HorizontalAlignment', 'center' );
uicontrol( 'Position', [215 5 20 20], ...
    'Style', 'text', ...
    'String', 'to', ...
    'FontSize', 7, 'HorizontalAlignment', 'center' );
uicontrol( 'Position', [235 5 30 20], ...
    'Style', 'edit', ...
    'String', nToCycle, ...
    'Tag', 'tocycle', ...
    'FontSize', 7, 'HorizontalAlignment', 'center' );
uicontrol( 'Position', [265 5 20 20], ...
    'Style', 'pushbutton', ...
    'String', '!', ...
    'FontSize', 7, 'HorizontalAlignment', 'center', ...
    'Callback', 'wt_graphs(''refresh''); wt_graphs(get(gcbo, ''Tag''), get(gcbo, ''Value''))'); % 0=OFF, 1=ON
drawnow;
return;

%%%% TOGGLEGRID %%%%
function ToggleGrid(varargin)
vhAxes = findobj(gcf, 'Type', 'axes'); % Get handles to all axes children
for i = 1:length(vhAxes)
    if strcmp(get(vhAxes(i), 'xgrid'), 'off')
        set(vhAxes(i), 'XGrid', 'on');
    else
        set(vhAxes(i), 'XGrid', 'off');
    end
end
return;

%%%% TOGGLEMARKERS ****
function ToggleMarkers(varargin)
persistent pMarkerStatus;
if isempty(pMarkerStatus), pMarkerStatus=0; end
pMarkerStatus = ~pMarkerStatus; % toggle marker-status
if pMarkerStatus, sMarker='.'; else, sMarker='none'; end
vhLines = findobj(gcf, 'Type', 'line');
set(vhLines, 'Marker', sprintf('%s',sMarker));
return;

%%%% EXPORTDATA %%%%
% Export all traces to either a plain text-file or Excel
function ExportData(varargin)
% Get object handles for all line-elements that will be exported
vhTraces = findobj('Tag', 'export-trace');
% Create container that will hold all the data
cData = cell({});
cHeaders = cell({});
for h = 1:length(vhTraces)
    cUserData = get(vhTraces(h), 'Userdata');
    cData{h} = cUserData{2};
    cHeaders{h} = cUserData{1};
end
% Query whether to export to Excel or text file
sAns = questdlg('Export to Excel or text file?', 'Export', 'Excel', 'Text file', 'Excel');
if isempty(sAns), return
else
    if strcmp(sAns, 'Excel')
        ExportToExcel(cHeaders, cData);
    else
        [sFilename, sPathname] = uiputfile('*.txt', 'Save data as');
        mData = [];
        for c = 1:size(cData,2)
            mData(1:length(cData{c}),size(mData,2)+1) = cData{c};
        end
        mData = [(0:(size(mData,1))-1)' mData]; % insert framenumber in 1st column
        dlmwrite([sPathname sFilename], mData, '\t');
    end
end

return;

%%% Compute amplitude on clicked trace
function ComputeAmplitude(varargin)
vX = get(gco, 'userdata');
persistent p_sWin
if isempty(p_sWin)
    p_sWin = sprintf('[1 %d]', length(vX{2}));
end
cAns = inputdlg('Window ([from to], samples):', 'WT', 1, {p_sWin});
if isempty(cAns), return, end
p_sWin = cAns{1};
vWin = eval(p_sWin);
% get all cycle segments
mXa = [];
vAmps = [];
for ci = 1:size(vX{3}, 2)
    mXa(:,ci) = eval(sprintf('vX{3}(%d:%d, %d)', vWin(1), vWin(2), ci));
    % compute amplitude (max-min) for each cycle
    vAmps(ci) = max(mXa(:,ci)) - min(mXa(:,ci));
end
%vXa = eval(sprintf('vX{2}(%d:%d)', vWin(1), vWin(2)));
msgbox(sprintf('Amplitude = %.2f +/- %.2f  (mean +/ -std)', nanmedian(vAmps), nanstd(vAmps) ));
return
