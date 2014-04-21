/* =============================================================
 * rotate_matrix.c 
 * o_mat = rotate_matrix(i_mat,angle)
 *
 * compile with the following command:
 * mex -inline rotate_matrix.c Matrix2D.c
 * =============================================================
 */

#include "mex.h"
#include "matrix.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "matrix2d.h"
#include "rotate_matrix.h"

#define round(X) (floor(X+0.5))
#define sqr(X) ((X)*(X)))
/*#define PI 3.14159*/
#define RAD_TO_DEG(x) ((x)/PI*180)
#define DEG_TO_RAD(x) ((x)/180*PI)

/* ===========================================================================
   rotate_matrix
   =========================================================================== */
void rotate_matrix(TMatrix2D mat,float angle)
{

TMatrix2D matT;

matT = Mat2D_createNull();

Mat2D_makeHMatRotation(matT,angle);

Mat2D_applyHMatTransformation(mat,matT);

Mat2D_destroy(&matT);

}

/* ===========================================================================
  the Gateway routine 
* ============================================================================ */

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
  
  double *i_mat, *i_angle;         /* variables for input from matlab */
  double *o_mat;		   /* variables for output to matlab */

  float angle;			   /* send to rotate_matrix() */
  TMatrix2D mat;                   /* matrix sent to (and returned from rotate_matrix() */

  int ncols, mrows, angle_m, angle_n,i,j,k;

  Mat2D_error = mexErrMsgTxt; /* set the error function of the TMatrix2D package to this */

  if (nrhs != 2)
    mexErrMsgTxt("Two inputs required (i_mat,angle)");
  if (nlhs != 1)
    mexErrMsgTxt("One output required (o_mat)");

  /* create a pointer to the i_mat input matrix */

  i_mat = mxGetPr(prhs[0]);
  
  /* get the dimenstions of the input matrix */ 
  mrows = mxGetM(prhs[0]);
  ncols = mxGetN(prhs[0]);

  /* get the angle */
  
  i_angle = mxGetPr(prhs[1]);
  
  /* get the dimensions of the i_angle (should be 1 by 1) */

    angle_m = mxGetM(prhs[1]);
    angle_n = mxGetN(prhs[1]);
  
  if (angle_m != 1 || angle_n != 1)
    mexErrMsgTxt("i_angle should be a scalar");

  /* copy input variables (double) to local variables (int or float) */

  angle = -DEG_TO_RAD( *i_angle); 

  mat = Mat2D_create(ncols,mrows,MAT2D_FLOAT); /* move from matlab to C convention */

  for ( i = 0; i < ncols; i++)
    for ( j = 0; j < mrows; j++)
      Mat2D_getDataFloat(mat)[i][j] = i_mat[i*mrows+j];
  
  /* call the C function */

  rotate_matrix(mat,angle); 
 
  /* set the output pointer to the output o_w matrix */
  
  plhs[0] = mxCreateDoubleMatrix(mrows,ncols,mxREAL);
  o_mat = mxGetPr(plhs[0]); 
   
  /* fill the output variable */

  for ( i = 0; i < ncols; i++)
    for ( j = 0; j < mrows; j++)
      o_mat[i*mrows+j] = Mat2D_getDataFloat(mat)[i][j];

  /* destroy the work matrix */

  Mat2D_destroy(&mat);

}
  
