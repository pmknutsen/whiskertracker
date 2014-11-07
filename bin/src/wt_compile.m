% wt_compile
% Compile WhiskerTracker C code as native and platform specific MEX file
%
% Require that a compiler is locally installed and configured.
% Use 'mex -setup' to configure your environment properly.
%
%

clc
disp('******* Compiling WhiskerTracker from C source *******')
disp('If any warnings are reported, it is strongly advices you correct these.');

% Get path to ./bin/ directory
sDir = which(mfilename);
sDir = sDir(1:(end-length(mfilename)-6));

% Perform platform specific compilation
if isunix
    % Compile for Linux
    sTargetDir = [sDir 'linux'];
    
    % Compile find_next_whisker.c
    eval(['mex find_next_whisker.c mex_utils.c matrix2d.c spline.c -outdir ''' sTargetDir ''''])
    
    % Compile rotate_matrix.c
    eval(['mex rotate_matrix.c matrix2d.c -outdir ''' sTargetDir ''''])

    % Remove .o files
    delete([sTargetDir filesep '*.o']);
    
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