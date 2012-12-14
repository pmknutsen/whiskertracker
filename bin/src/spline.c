/* =============================================================
 * spline.c - 3 point spline function as taken from Numerical Recipes p. 96
 *
 * Given arrays x[1..N] and y[1..N], containing a tabulated function, i.e. y(i) = f[x(i)], 
 * this routine returns an array y2[1..N] that contains the second derivatives of the 
 * interpolating function at the tabulated points x(j). The spline is the natural 
 * spline - assuming y2[1] = 0 and y2[N] = 0 (assume arrays are from 1..N)
 * =============================================================
 */

#include <math.h>
#include "mex_utils.h"
#include "spline.h" 

void spline(float x[],float y[],float y2[],int npoints)
{
  int i,k;
  float p,qn,sig,un;
  float *u; 
  
  u = allocate_ivector(1,npoints);

  y2[1] = u[1] = 0.0; /* this defines a natural spline */
  y2[npoints] = 0.0;

  for (i=2;i<=npoints-1;i++) {  /* tridiagonal algorithm (whatever that is) */

    sig = (x[i]-x[i-1])/(x[i+1]-x[i-1]);
    p = sig*y2[i-1] + 2.0;
    y2[i] = (sig - 1.0)/p;
    u[i] = (y[i+1]-y[i])/(x[i+1]-x[i]) - (y[i]-y[i-1])/(x[i]-x[i-1]);
    u[i] = (6.0*u[i]/(x[i+1]-x[i-1])-sig*u[i-1])/p;
  }

  for (k=npoints-1; k>=1; k--)
    y2[k] = y2[k] * y2[k+1]+ u[k];

  free_ivector(u, 1, npoints);

}

/* ====================================================================
 *
 *   given the arrays xa[1..N] and ya[1..N] which tabulate a function, *
 *   and y2a[1..N] which is the output from spline above, and given a  *
 *   value x, this routine returns a cubic-spline interpolated value y *
 * 
 * ====================================================================*/
int splint(float xa[],float ya[],float y2a[],int npoints,float x,float *y)
{
  int klo,khi,k;
  float h,b,a;
 
  klo=1;
  khi = npoints;
  while (khi-klo > 1) {
    k = (khi+klo) >> 1;
    if (xa[k] > x) 
      khi = k;
    else
      klo = k;
  }
 
  h = xa[khi] - xa[klo];
  if (h == 0.0) return 0; /* bad input */

  a = (xa[khi] - x)/h;
  b = (x-xa[klo])/h;
  
  *y = a*ya[klo]+b*ya[khi]+((a*a*a-a)*y2a[klo]+(b*b*b-b)*y2a[khi])*(h*h)/6.0;

  return 1;
}  

    
