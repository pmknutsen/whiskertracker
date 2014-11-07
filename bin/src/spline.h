/* =============================================================
 * spline.c - 3 point spline function as taken from Numerical Recipes p. 96
 *
 * Given arrays x[1..N] and y[1..N], containing a tabulated function, i.e. y(i) = f[x(i)], 
 * this routine returns an array y2[1..N] that contains the second derivatives of the 
 * interpolating function at the tabulated points x(j). The spline is the natural 
 * spline - assuming y2[1] = 0 and y2[N] = 0
 * =============================================================
 */

void spline(float x[],float y[], float y2[],int npoints);

/* ====================================================================
 *
 *   given the arrays xa[1..N] and ya[1..N] which tabulate a function, *
 *   and y2a[1..N] which is the output from spline above, and given a  *
 *   value x, this routine returns a cubic-spline interpolated value y *
 * 
 * ====================================================================*/

int splint(float xa[],float ya[],float y2a[],int npoints,float x,float *y);
