%%%% WT_COMPILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Execute this file in the Matlab prompt to recompile the C code

clear find_next_whisker
clear rotate_matrix

!del *.dll
%mex -inline find_next_whisker.c mex_utils.c matrix2d.c spline.c
mex -inline rotate_matrix.c matrix2d.c
