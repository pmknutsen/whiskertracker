/*
  mex_utils.c - utilities from numerical recipes converted for mex use 
*/
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "mex.h"
#include "matrix.h"

#define NR_END 1
#define FREE_ARG char* 

/*=====================================================================================*/
float *allocate_vector(long nl, long nh)
/* allocate a float vector with subscript range v[nl..nh] */
{
float *v;
v=(float *) mxCalloc((size_t) (nh-nl+1+NR_END), sizeof(float) );
if (!v) mexErrMsgTxt("allocation failure in allocate_vector()");
return v-nl+NR_END;
}

/*=====================================================================================*/
int *allocate_ivector(long nl, long nh)
/* allocate a float vector with subscript range v[nl..nh] */
{
int *v;
v=(int *) mxCalloc((size_t) (nh-nl+1+NR_END), sizeof(int) );
if (!v) mexErrMsgTxt("allocation failure in allocate_ivector()");
return v-nl+NR_END;
}

/*=====================================================================================*/
void free_vector(float *v, long nl, long nh)
/* free a float vector allocated with allocate_vector() */
{
mxFree((FREE_ARG) (v+nl-NR_END));
}

/*=====================================================================================*/
void free_ivector(int *v, long nl, long nh)
/* free a float vector allocated with allocate_vector() */
{
mxFree((FREE_ARG) (v+nl-NR_END));
}

