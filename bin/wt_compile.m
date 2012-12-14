%%%% WT_COMPILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Execute this file in the Matlab prompt to recompile the C code
clc

clear find_next_whisker
clear rotate_matrix

LINUX = 1;
WINDOWS = 0;

if LINUX

    mex -inline find_next_whisker.c mex_utils.c matrix2d.c spline.c -outdir /home/home/Analysis/wt_dev_version/bin/linux/
    %mex -inline rotate_matrix.c matrix2d.c

elseif WINDOWS

    !del *.dll
    mex -inline find_next_whisker.c mex_utils.c matrix2d.c spline.c -outdir ..\windows
    %mex -inline rotate_matrix.c matrix2d.c
    
end
