
#define COL_WIDTH 10   /* for calculating angle of spline */

void find_next_whisker(int *w0_x, /* input whisker suggestion (x) */ 
		       int *w0_y, /* input whisker suggestion (y) */
		       int *enum_range_x, /* range of enum values around w0 */
		       int *enum_range_y, 
		       TMatrix2D image,		  /* image matrix */
		       TMatrix2D filters[],       /* filters for angles from -90 to 90 */
		       TMatrix2D velocity_mat, 
					/* correction to convolution matrix according to velocity */
		       int nwhisker_points, /* number of spline points - should be 3 or 4 only */
		       int *w_x,  /* output whisker suggestion (x) */
		       int *w_y,  /* output whisker suggestion (y) */
		       float *score, 		  /* output score */
		       float *stddev,       /* stddev of score */
		       int   *n);           /* size of jitter */

float get_score(int *w_x,int *w_y,int nwhisker_points,TMatrix2D I_Conv);
void get_I_Conv(int *w0_x,int *w0_y,int nwhisker_points,TMatrix2D image,int min_y, int max_y, 
		TMatrix2D filters[], TMatrix2D *I_Conv);
void get_spline(int *x,int *y,int nwhikser_points, int min_x, int max_x, int **yy);
void get_angle_vec(int *yy,int from_ind,int to_ind,int col_width, int **angle_vec);

void convolve_image_by_angle(TMatrix2D image,TMatrix2D filters[],int filt_size,
			     int angle_vec[],int min_x,int max_x,int min_y,int max_y,
			     TMatrix2D *I_Conv_p);

void Display_Matrix(TMatrix2D mat);
