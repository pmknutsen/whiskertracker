% wt_compile
% Compile WhiskerTracker C code as native and platform specific MEX file
%
% Note that this file may not run as-is. It has been written and found to compile
% the code successfully on 32 and 64 bit Linux and Windows machines. Modifications
% may be required for other platforms
%

clc
disp('******* Compiling WhiskerTracker from C source *******')

%clear find_next_whisker
%clear rotate_matrix

% Get path to ./bin/ directory
sDir = which(mfilename);
sDir = sDir(1:(end-length(mfilename)-6));

%sDir(findstr(sDir, ' ')) = '\';

if isunix
    % Compile for Linux
    sTargetDir = [sDir 'linux'];
    
    eval(['mex find_next_whisker.c mex_utils.c matrix2d.c spline.c -outdir ''' sTargetDir ''''])
    %mex -inline rotate_matrix.c matrix2d.c

elseif ispc
    % Compile for Windows
    sTargetDir = [sDir 'windows'];
    
    %!del *.dll
    eval(['mex -compatibleArrayDims -v find_next_whisker.c mex_utils.c matrix2d.c spline.c -outdir ''' sTargetDir ''''])
    %mex -inline rotate_matrix.c matrix2d.c
    
else
	error('This platform is not supported')
end


return