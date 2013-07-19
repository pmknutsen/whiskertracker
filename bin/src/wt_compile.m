% wt_compile
% Compile WhiskerTracker C code as native and platform specific MEX file
%
% Note that this file may not run as-is. It has been written and found to compile
% the code successfully on 32 and 64 bit Linux and Windows machines. Modifications
% may be required for other platforms
%

clc

clear find_next_whisker
clear rotate_matrix

LINUX = 1;
WINDOWS = 0;

if isunix

    mex -inline find_next_whisker.c mex_utils.c matrix2d.c spline.c -outdir /home/home/Analysis/wt_dev_version/bin/linux/
    %mex -inline rotate_matrix.c matrix2d.c

elseif isunix

    !del *.dll
    mex -inline find_next_whisker.c mex_utils.c matrix2d.c spline.c -outdir ..\windows
    %mex -inline rotate_matrix.c matrix2d.c
    
else
	disp()
    
end
