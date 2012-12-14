/* =============================================================
 * find_next_whisker.c 
 * [w,score] = find_next_whisker(w0, enum_range, I, filters_vec,velocity_mat)
 * =============================================================
 */

#include "mex.h"
#include "matrix.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "mex_utils.h"
#include "matrix2d.h"
#include "spline.h"
#include "find_next_whisker.h"

#define round(X) (floor(X+0.5))
#define sqr(X) ((X)*(X)))
#define RAD_TO_DEG(x) ((x)/PI*180)

#define MIN_ANGLE -90
#define MAX_ANGLE 90

/* =========================================================
   find_next_whisker

   This code assumes either npoints is 3 or 4
   ========================================================= */

void find_next_whisker(int w0_x[], /* input whisker suggestion (x) */ 
		       int w0_y[], /* input whisker suggestion (y) */
		       int enum_range_x[], /* range of enum values around w0 */
		       int enum_range_y[], 
		       TMatrix2D image,		  /* image matrix */
		       TMatrix2D filters[],       /* filters for angles from -90 to 90 */
		       TMatrix2D velocity_mat, 
					/* correction to convolution matrix according to velocity */
		       int nwhisker_points, /* number of spline points - should be 3 or 4 only */
		       int o_w_x[],  /* output whisker suggestion (x) */
		       int o_w_y[],  /* output whisker suggestion (y) */
		       float *o_score_p, /* output score */
		       float *o_stddev_p, /* output std-dev of score */
		       int *o_n_p )   /* size of jitter */
{
{
  /* get the convolution matrix */   
  int i,j,k,l;
  int v,w;
  int range_i,range_j,range_k,range_l;
  int range_v,range_w;
  int min_y, max_y, tmp;			/* calculate I_Conv only in this y range */
  int ncols;
  TMatrix2D I_Conv; 
  float score;
  int *w_x, *w_y;
  float sum_score, sum_score_sq; /* used for calculating stddev of score */
  int   n_score;                 /* number of scores used to calc stddev */
  

  w_x = allocate_ivector(0, nwhisker_points - 1);
  w_y = allocate_ivector(0, nwhisker_points - 1);

  *o_score_p = sum_score = sum_score_sq = 0.;
  n_score = 0;
  
  switch (nwhisker_points) {

  case 3: /* case of a 3-point spline */
    
    range_i = enum_range_y[0];
    range_j = enum_range_y[1];
    range_k = enum_range_y[2];
    range_v = enum_range_x[1]; /* change only middle point of x */

    ncols = Mat2D_getnCols( image );
    tmp = IMIN(w0_y[1],w0_y[2]);
    min_y = IMAX(IMIN(w0_y[0],tmp ) - range_i - range_j - range_k , 0);
    tmp = IMAX(w0_y[1],w0_y[2]);
    max_y = IMIN(IMAX(w0_y[0],tmp ) + range_i + range_j + range_k , ncols-1);
 
/*   mexPrintf("w0_y %d %d %d ranges %d %d %d min_y %d max_y %d\n", */
/*	      w0_y[0],w0_y[1],w0_y[2],range_i,range_j,range_k,min_y,max_y); */

    get_I_Conv(w0_x,w0_y,nwhisker_points,image, min_y, max_y, filters, &I_Conv);
  
    Mat2D_mulAllMat(I_Conv, velocity_mat);  /* I_Conv = I_Conv .* velocity_mat */

    /* enum over enum_range */
    
    w_x[0] = w0_x[0];
    w_x[2] = w0_x[2];

    for (i=-range_i;i<=range_i;i++) {
    
      w_y[0] = w0_y[0] + i;

      for (j=-range_j;j<=range_j;j++) {

	w_y[1] = w0_y[1]+ i + j;

	for (k=-range_k;k<=range_k;k++) {

	  w_y[2] = w0_y[2] + i + j + k;

	  for (v=-range_v;v<=range_v;v++) {

	    w_x[1] = w0_x[1] + v;

	    if (w_x[1] > w_x[0] && w_x[1] < w_x[2]) { /* permitted positions for middle point */
	   
	      score = get_score(w_x,w_y,nwhisker_points,I_Conv);

	      if (score > *o_score_p) {

		    *o_score_p = score;
		    memcpy( o_w_x, w_x, nwhisker_points*sizeof(float) );
		    memcpy( o_w_y, w_y, nwhisker_points*sizeof(float) );
		    
	      } else {
	      
	         sum_score += score;
	         sum_score_sq += score*score;
	         n_score++;
	      }
	    }
	  }
	}
      }
    }
    
    break;

  case 4: /* case of a 4-point spline */

    range_i = enum_range_y[0];
    range_j = enum_range_y[1];
    range_k = enum_range_y[2];
    range_l = enum_range_y[3];
    range_v = enum_range_x[1]; 
    range_w = enum_range_x[2];

    ncols = Mat2D_getnCols( image );
    tmp = IMIN(IMIN(IMIN(w0_y[0],w0_y[1]),w0_y[2]),w0_y[3]);
    min_y = IMAX(tmp - range_i - range_j - range_k , 0); /* minimum possible y val*/
    tmp = IMAX(IMAX(IMAX(w0_y[0],w0_y[1]),w0_y[2]),w0_y[3]);
    max_y = IMIN(tmp + range_i + range_j + range_k , ncols-1); /* maximum possible y val */
 
/*    mexPrintf("w0_y %d %d %d %d ranges %d %d %d %d min_y %d max_y %d\n", */
/*	      w0_y[0],w0_y[1],w0_y[2],w0_y[3],range_i,range_j,range_k,range_l,min_y,max_y); */

    get_I_Conv(w0_x,w0_y,nwhisker_points,image, min_y, max_y, filters, &I_Conv);
  
    Mat2D_mulAllMat(I_Conv, velocity_mat);  /* I_Conv = I_Conv .* velocity_mat */

    /* enum over enum_range */

    w_x[0] = w0_x[0];
    w_x[3] = w0_x[3];

    for (i=-range_i;i<=range_i;i++) {
    
      w_y[0] = w0_y[0] + i;

      for (j=-range_j;j<=range_j;j++) {

	w_y[1] = w0_y[1]+ i + j;

	for (k=-range_k;k<=range_k;k++) {

	  w_y[2] = w0_y[2] + i + j + k;

	  for (l=-range_l;l<=range_l;l++) {

	    w_y[3] = w0_y[3] + i + j + k + l;

	    for (v=-range_v;v<=range_v;v++) {

	      w_x[1] = w0_x[1] + v;

	      for (w=-range_w;w<=range_w;w++) {

		w_x[2] = w0_x[2] + w;

		if (w_x[0] < w_x[1] && 
		    w_x[1] < w_x[2] &&
		    w_x[2] < w_x[3] ) { /* permitted positions for middle point */
	   
		  score = get_score(w_x,w_y,nwhisker_points,I_Conv);
		  
		  if (score > *o_score_p) {

		    *o_score_p = score;
		    memcpy( o_w_x, w_x, nwhisker_points*sizeof(float) );
		    memcpy( o_w_y, w_y, nwhisker_points*sizeof(float) );
		    
	      } else {
	      
	         sum_score += score;
	         sum_score_sq += score*score;
	         n_score++;
	      }  
		}
	      }
	    }
	  }
	}
      }
    }
    
    break;

  default:
    
    mexErrMsgTxt("change number of spline points to 3 or 4");

  } /* end switch */

  /* calculate std-dev*/
  
  if (n_score > 1) {
  
    *o_stddev_p = sqrt(sum_score_sq / (n_score - 1) - 
                    sum_score*sum_score/(n_score-1)/n_score); 
    
  } else {
  
    *o_stddev_p = 0;
  }
  *o_n_p = n_score + 1;
  
  Mat2D_destroy(&I_Conv);

  free_ivector( w_x, 0, nwhisker_points - 1 );
  free_ivector( w_y, 0, nwhisker_points - 1 );

}
}

/* ==========================================================================
   get_score 
   ========================================================================== */
float get_score(int w_x[],int w_y[],int nwhisker_points,TMatrix2D I_Conv)
{
  float **conv_dat;
  float score = 0;
  int min_x,max_x;
  int *yy, x;
  int ncols, nrows;

  conv_dat = Mat2D_getDataFloat(I_Conv);
  ncols = Mat2D_getnCols(I_Conv);
  nrows = Mat2D_getnRows(I_Conv);
  
  min_x = IMAX(w_x[0],0);
  max_x = IMIN(w_x[nwhisker_points-1],nrows-1);

  get_spline(w_x,w_y,nwhisker_points,min_x, max_x, &yy);
  
  for (x=min_x;x<=max_x;x++)
    if (yy[x]>=0 && yy[x]<ncols)
      score += conv_dat[x][yy[x]];
  
  free_ivector(yy,min_x,max_x);

  return(score);
}
/* ==========================================================================
   get_I_Conv

   Convulve I_Conv with oriented filter according to the whisker angle
   ========================================================================== */
void get_I_Conv(int *w0_x,int *w0_y,int nwhisker_points, 
		TMatrix2D image, int min_y, int max_y,
		TMatrix2D filters[], TMatrix2D *I_Conv_p)
{
  int i,x_val;
  int *yy;
  int *angle_vec;
  int spline_len;  
  int filt_size;
  int min_x, max_x;
  int nrows;

  nrows = Mat2D_getnRows(image);

  /* calculate spline of w0 */

  min_x = IMAX(w0_x[0],0);
  max_x = IMIN(w0_x[nwhisker_points-1],nrows-1);

  filt_size = (Mat2D_getnRows(filters[0])-1)/2;

  get_spline(w0_x,w0_y,nwhisker_points,min_x-COL_WIDTH, max_x+COL_WIDTH, &yy);
  get_angle_vec(yy,min_x,max_x,COL_WIDTH,&angle_vec);

    /* for (i=0;i<nwhisker_points;i++) */
    /*    mexPrintf("w0[%d]: %d %d\n",i,w0_x[i],w0_y[i]); */
    /* mexPrintf("\n"); */
    /* for (x_val=min_x;x_val<=max_x;x_val++) */
    /*     mexPrintf("spline[%d]: %d angle = %d\n",x_val,yy[x_val],angle_vec[x_val]); */
    /*   mexPrintf("\n"); */

  /* convolve each column of I_Conv with correct filter (according to angle) */

  convolve_image_by_angle(image,filters,filt_size,angle_vec,
			  min_x,max_x,min_y,max_y,I_Conv_p);

  free_ivector(yy,min_x-COL_WIDTH, max_x+COL_WIDTH);
  free_ivector(angle_vec,min_x,max_x);

 /*  Mat2D_display(*I_Conv_p); */
}

/* ===========================================================================
   convolove_image_by_angle
   
   convolove image with filters according to angle_vec
   =========================================================================== */

void convolve_image_by_angle(TMatrix2D image,TMatrix2D filters[],int filt_size,
			     int angle_vec[],int min_x,int max_x, int min_y, int max_y,
			     TMatrix2D *I_Conv_p)
{
  int i,j,u,v;
  TMatrix2D work_image; /* this is really created */
  TMatrix2D current_filter; /* this just points to the filters[] array */
  int ang;
  int nrows_im,ncols_im,nrows_flt,ncols_flt;
  float **dat,**wdat, **o_dat, **flt_dat;

  *I_Conv_p = Mat2D_createFrom(image);
  Mat2D_fillAllValue(*I_Conv_p,0.);

  o_dat = Mat2D_getDataFloat((*I_Conv_p));
  
  nrows_im = Mat2D_getnRows(image); /* this is the C and not the matlab convention */
  ncols_im = Mat2D_getnCols(image);
  nrows_flt = Mat2D_getnRows(filters[0]); /* assume all filters are of same size */
  ncols_flt = Mat2D_getnCols(filters[0]);
  
  /* mexPrintf("nrows_im = %d, ncols_im = %d\n",nrows_im,ncols_im); */

  /* create a version of image with padded edges */

  dat = Mat2D_getDataFloat(image);
  work_image = Mat2D_create(nrows_im+2*filt_size,ncols_im+2*filt_size,MAT2D_FLOAT);
  Mat2D_fillAllValue(work_image,0.);

  wdat = Mat2D_getDataFloat(work_image);

  for (i=0;i<nrows_im;i++)
    for (j=0;j<ncols_im;j++)
      wdat[i+filt_size][j+filt_size] = dat[i][j];

  /* enum over row, and find the appropriate filter */

  for (i=min_x;i<=max_x;i++){

    ang = angle_vec[i];
    current_filter = filters[ang - MIN_ANGLE];
    flt_dat = Mat2D_getDataFloat(current_filter);
    
    /* convolve with appropriate filter */

    for (j=min_y; j<=max_y; j++) 
      for (u=0;u<2*filt_size+1;u++)
	for (v=0;v<2*filt_size+1;v++)
	  o_dat[i][j] += wdat[i+u][j+v]* flt_dat[u][v];
  }
  
  Mat2D_destroy(&work_image);
  
}

/* ===========================================================================
   get_angle_vec

   for each point in yy[from_ind..to_ind], get its angle. 
   assume yy is allocated in the range yy[from_ind-col_width..to_ind+col_width]
   =========================================================================== */
  
void get_angle_vec(int *yy,int from_ind,int to_ind,int col_width, int **angle_vec)
{
  int x_val;

  *angle_vec = allocate_ivector(from_ind,to_ind);

  for (x_val = from_ind; x_val <= to_ind; x_val++) {

    (*angle_vec)[x_val] = 
      (int) round(RAD_TO_DEG( atan ((yy[x_val+col_width] - yy[x_val-col_width] + 0.)/
				    (2*col_width + 1))));
  } 
}

/* ===========================================================================
   get_spline   x , y - spline points
   xx, yy - output (allocated) spline interpolation 
   =========================================================================== */
void get_spline(int i_x[],int i_y[],int nwhisker_points, int min_x, int max_x, int **yy)
{

  int i, status, x_val;
  float *x, *y, *y2;
  float y_val;
  int start_ind, end_ind;

  x = allocate_vector( 1, nwhisker_points );
  y = allocate_vector( 1, nwhisker_points );
  y2 = allocate_vector( 1, nwhisker_points );

  for (i = 0; i<nwhisker_points; i++) {
    x[i+1] = i_x[i] + 0.;
    y[i+1] = i_y[i] + 0.;
  }

  *yy = allocate_ivector( min_x, max_x );
  
  spline( x,y, y2, nwhisker_points ); /* calculate the 2nd derivatives of y at spline points */
  
  for (x_val = min_x;x_val <= max_x; x_val++) {

    status = splint( x, y, y2, nwhisker_points, (float) x_val, &y_val );
    if (status != 1) 
      mexErrMsgTxt("bad spline");
    (*yy)[x_val] = round ( y_val );  
  }

  free_vector( x, 1,nwhisker_points);
  free_vector( y, 1,nwhisker_points);
  free_vector( y2, 1,nwhisker_points);

}
/* ===============================================================================
/* Display a Matrix 
/* =============================================================================== */
void Display_Matrix(TMatrix2D mat)
{
  int i,j;
  int nrows,ncols;

  nrows = Mat2D_getnRows(mat);
  ncols = Mat2D_getnCols(mat);

  for (i= 0;i<nrows;i++)
  {
    /* mexPrintf("[\t"); */
    for (j= 0;j<ncols;j++)
    {
      switch (Mat2D_getType(mat)) {
      case MAT2D_FLOAT:
/*	mexPrintf("%f\t",Mat2D_getDataFloat(mat)[i][j]); */
	break;
      case MAT2D_DOUBLE:
/*	mexPrintf("%f\t",Mat2D_getDataDouble(mat)[i][j]); */
	break;
      }
    }
  /*  mexPrintf("]\n"); */
  }
}
/* ===========================================================================
  the Gateway routine 
* ============================================================================ */

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
  double *i_w0, *i_enum_range,*i_image, *i_filters, *i_velocity_mat;  
					/* variables for input from matlab */
  double *o_w,*o_score, *o_stddev, *o_n; /* variables for output to matlab */
  int i, j, k, count, npoints, ndims, number_of_dims;
  int nwhisker_points;
  const int *dim_array;
  float score, stddev;
  int n_score;
  TMatrix2D image, velocity_mat;
  int ncols, mrows, velocity_mrows, velocity_ncols, filter_len;
  int *w_x, *w_y;
  int *w0_x,*w0_y;
  int *enum_range_x,*enum_range_y;
  TMatrix2D *filters;

  Mat2D_error = mexErrMsgTxt; /* set the error function of the TMatrix2D package to this */

  if (nrhs != 5)
    mexErrMsgTxt("Five inputs required");
  if (nlhs != 4)
    mexErrMsgTxt("Four outputs required");

  /* create a pointer to the w0 input matrix */

  i_w0 = mxGetPr(prhs[0]);
  
  /* get the dimenstions of the w0 matrix */ 
  nwhisker_points = mxGetM(prhs[0]);
  ndims = mxGetN(prhs[0]);

  if (nwhisker_points != 3 && nwhisker_points != 4 )
    mexErrMsgTxt("change number of spline points to 3 or 4");
  if (ndims != 2)    
    mexErrMsgTxt("size(w0,2) must be 2"); 

  /* create a poiter to the enum_range input matrix */

  i_enum_range = mxGetPr(prhs[1]);

  /* get the dimenstions of the w0 matrix */

  npoints = mxGetM(prhs[1]);
  ndims = mxGetN(prhs[1]);

  if (npoints != nwhisker_points)
    mexErrMsgTxt("num of enum_range points should correspond to number of spline points");
  if (ndims != 2)    
    mexErrMsgTxt("size(enum_range,2) must be 2");

  /* create a pointer to the image matrix */
  
  i_image = mxGetPr(prhs[2]);
  
  /* get the dimensions of the image matrix */

  mrows = mxGetM(prhs[2]);
  ncols = mxGetN(prhs[2]);

 /* mexPrintf("mrows %d ncols %d \n",mrows,ncols); */

  /* create a pointer to the filters data structure */

  i_filters = mxGetPr(prhs[3]);
  number_of_dims = mxGetNumberOfDimensions(prhs[3]);
  dim_array = mxGetDimensions(prhs[3]);
  
  if (number_of_dims != 3)
    mexErrMsgTxt("number of dimensions of filters_vec must be 3");
  if (dim_array[2] != MAX_ANGLE - MIN_ANGLE + 1)
    mexErrMsgTxt("number if angles must be 181 (from -90 to 90)");
  if (dim_array[0] != dim_array[1])
    mexErrMsgTxt("filters must be square");

  filter_len = dim_array[0];
 /* mexPrintf("filter_len = %d\n",filter_len); */
  
  /* get velocity_mat */
  
  i_velocity_mat = mxGetPr(prhs[4]);
  
  /* get the dimensions of the image matrix */

  velocity_mrows = mxGetM(prhs[4]);
  velocity_ncols = mxGetN(prhs[4]);
  
  if (velocity_mrows != mrows || velocity_ncols != ncols)
    mexErrMsgTxt("velocity_mat must have same size as image");

  /* allocate space for local variables */

  w_x = allocate_ivector(0, nwhisker_points - 1);
  w_y = allocate_ivector(0, nwhisker_points - 1);
  w0_x = allocate_ivector(0, nwhisker_points - 1);
  w0_y = allocate_ivector(0, nwhisker_points - 1);
  enum_range_x = allocate_ivector(0, nwhisker_points - 1);
  enum_range_y = allocate_ivector(0, nwhisker_points - 1);
  
  /* copy input variables (double) to local variables (int or float) */

  for ( i = 0; i < nwhisker_points; i++) {
    w0_x[i] = i_w0[i] - 1;   /* correct for the difference between Matlab (starting from 1) and C (starting from 0) */
    w0_y[i] = i_w0[i+nwhisker_points] - 1;
    enum_range_x[i] = i_enum_range[i];
    enum_range_y[i] = i_enum_range[i+nwhisker_points];
  }

  image = Mat2D_create(ncols,mrows,MAT2D_FLOAT); /* move from matlab to C convention */
  for ( i = 0; i < ncols; i++)
    for ( j = 0; j < mrows; j++)
      Mat2D_getDataFloat(image)[i][j] = i_image[i*mrows+j];
  
  filters = (TMatrix2D *) mxCalloc( MAX_ANGLE - MIN_ANGLE + 1, sizeof(TMatrix2D) );


  for ( i =0, count = 0; i <= MAX_ANGLE - MIN_ANGLE; i++){
    filters[i] = Mat2D_create( filter_len, filter_len, MAT2D_FLOAT );
    for (j = 0; j < filter_len; j++)
      for (k = 0; k < filter_len; k++, count++ )
	Mat2D_getDataFloat(filters[i])[j][k] = i_filters[count]; 
  }  
     
  velocity_mat = Mat2D_create(ncols,mrows,MAT2D_FLOAT); /* move from matlab to C convention */
  for ( i = 0; i < ncols; i++)
    for ( j = 0; j < mrows; j++)
      Mat2D_getDataFloat(velocity_mat)[i][j] = i_velocity_mat[i*mrows+j];
  
/* call the C function */

  find_next_whisker(w0_x,w0_y,enum_range_x,enum_range_y,
		    image,filters,velocity_mat, nwhisker_points,
		    w_x,w_y,&score, &stddev, &n_score);
 
  /* set the output pointer to the output o_w matrix */
  
  plhs[0] = mxCreateDoubleMatrix(npoints,ndims,mxREAL);
  o_w = mxGetPr(plhs[0]); 
   
  /* assign a pointer to the o_score output */
  
  plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
  o_score = mxGetPr(plhs[1]);

  /* assign a pointer to the o_stddev output */
  
  plhs[2] = mxCreateDoubleMatrix(1,1,mxREAL);
  o_stddev = mxGetPr(plhs[2]);
  
  /* assign a pointer to the o_n output */
  
  plhs[3] = mxCreateDoubleMatrix(1,1,mxREAL);
  o_n = mxGetPr(plhs[3]);
  
  /* fill the output variables */

  *o_score = score;
  *o_stddev = stddev;
  *o_n = (double) n_score;
  
  for ( i = 0; i < nwhisker_points; i++) {
    o_w[i] = w_x[i] + 1;			/* C [0] --> Matlab [1] */
    o_w[i+nwhisker_points] = w_y[i] + 1;
  }

  /* free variables */

  Mat2D_destroy(&image);

  for ( i=0; i<= MAX_ANGLE - MIN_ANGLE; i++)
    Mat2D_destroy(&(filters[i]));
  mxFree(filters);

  Mat2D_destroy(&velocity_mat);
  
  free_ivector(w0_x, 0, nwhisker_points-1);
  free_ivector(w0_y, 0, nwhisker_points-1);
  free_ivector(enum_range_x, 0, nwhisker_points-1);
  free_ivector(enum_range_y, 0, nwhisker_points-1);
  free_ivector(w_x, 0, nwhisker_points-1);
  free_ivector(w_y, 0, nwhisker_points-1);

}
  

  
  
