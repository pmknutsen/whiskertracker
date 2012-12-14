/***********************************************************
 * Matrix2D (version 1.0)                                  *
 * ******************************************************* *
 * Copyright 2002 P. Lacroix                               *
 *  All Rights Reserved					   *
 * <<< This version uses mxMalloc, mxFree , Dori >>>       *
 * ******************************************************* *
 *   This library is free for personal applications. If    *
 * you use it, thank you to signal it in your application. *
 *   If you want to distribute it, thank you to make a link*
 * to our website:                                         *
 *   http://dev.tplanet.net/Matrix2D                       *
 *   To report bugs, suggest enhancements, etc. to the     *
 * Authors, send email to dev@tplanet.net                  *
 *   This library is distributed in the hope that it will  *
 * be useful, but without any warranty.                    *
 ***********************************************************/

#include <stdio.h>
#include <stdlib.h>
/* #include <mem.h> */
#include <math.h>
#include <string.h>
#include "mex.h"
#include "matrix.h"
#include "values.h"

#include "matrix2d.h"

char   Mat2D_charValue= 0;
short  Mat2D_shortValue= 0;
long   Mat2D_longValue= 0;
float  Mat2D_floatValue= 0.;
double Mat2D_doubleValue= 0.;

void Mat2D_defaultError(char *Message)
{
  fprintf(stderr,"%s",Message);
  exit(1);
}

void (*Mat2D_error)(char *)= Mat2D_defaultError;

#ifndef min
#define min(a,b) (((a)>(b))?(b):(a))
#endif

#ifndef max
#define max(a,b) (((a)>(b))?(a):(b))
#endif

/* Operation de gestion des matrices */

void Mat2D_allocData(TMatrix2D mat)
{
  int   sizeElement;
  void *data;
  int   r;

  sizeElement= Mat2D_getElementSize(mat);
  data= mxMalloc(sizeElement*mat->nRows*mat->nCols);

  mat->data= (void **)mxMalloc(sizeof(void *)*mat->nRows);
  for (r= 0;r<mat->nRows;r++)
    mat->data[r]= (void *)((int)data+r*mat->nCols*sizeElement);
}

void Mat2D_freeData(TMatrix2D mat)
{
  if (mat->data[0]!= NULL) mxFree(mat->data[0]); /* On libere le bloc memoire des donnes de la matrice */
  if (mat->data!= NULL) mxFree(mat->data);    /* On libere les pointeurs sur les debut de lignes */
}

void Mat2D_swapData(TMatrix2D mat1,TMatrix2D mat2)
{
  void **temp;
  temp= mat2->data;
  mat2->data= mat1->data;
  mat1->data= temp;
}

void Mat2D_swapAll(TMatrix2D mat1,TMatrix2D mat2)
{
  void        **temp;
  int           v;
  TMatrix2DType typ;

  temp= mat2->data;
  mat2->data= mat1->data;
  mat1->data= temp;

  v= mat2->nRows;
  mat2->nRows= mat1->nRows;
  mat1->nRows= v;

  v= mat2->nCols;
  mat2->nCols= mat1->nCols;
  mat1->nCols= v;

  typ= mat2->type;
  mat2->type= mat1->type;
  mat1->type= typ;
}

TMatrix2D Mat2D_create(int nRows,int nCols,TMatrix2DType type)
{
  TMatrix2D mat;

  mat= (TMatrix2D)mxMalloc(sizeof(struct _TMatrix2D));
  mat->type= type;
  mat->nRows= nRows;
  mat->nCols= nCols;
  mat->isSub= 0;
  if (nRows*nCols== 0)
    mat->data= NULL;
  else
    Mat2D_allocData(mat);

  return mat;
}

TMatrix2D Mat2D_createFrom(TMatrix2D mat)
{
  return Mat2D_create(Mat2D_getnRows(mat),
                      Mat2D_getnCols(mat),
                      Mat2D_getType(mat));
}

TMatrix2D Mat2D_createNull(void)
{
  return Mat2D_create(0,0,MAT2D_CHAR);
}

TMatrix2D Mat2D_createSub(TMatrix2D mat,int rOrg,int cOrg,int nRows,int nCols)
{
  TMatrix2D matDest;
  int       sizeElement;
  int       r;

  matDest= Mat2D_createNull();
  matDest->nRows= nRows;
  matDest->nCols= nCols;
  matDest->type= mat->type; 
  matDest->isSub= 1;

  sizeElement= Mat2D_getElementSize(mat);

  matDest->data= (void **)mxMalloc(sizeof(void *)*nRows);
  for (r= 0;r<matDest->nRows;r++)
    matDest->data[r]= (void *)((int)(mat->data[r+rOrg])+cOrg*sizeElement);

  return matDest;
}

void Mat2D_destroy(TMatrix2D *mat)
{
  if (!((*mat)->isSub)) /* On ne detruit pas les donnee d'une sous-matrice */
  {
    if ((*mat)->data!= NULL) /* Ca peut etre une matrice nulle */
      Mat2D_freeData(*mat);
  }
  else
    mxFree((*mat)->data);
  mxFree(*mat);
  *mat= NULL;
}

TMatrix2D Mat2D_clone(TMatrix2D src)
{
  TMatrix2D dst;
  int       r;
  int       sizeElement;

  dst= Mat2D_create(src->nRows,src->nCols,src->type);
  sizeElement= Mat2D_getElementSize(src);

  memcpy(dst->data[0],src->data[0],src->nRows*src->nCols*sizeElement);
  /* On part de l'hypothese que les donnees sont toutes contigues */

  return dst;
}

void Mat2D_resize(TMatrix2D mat,int nRows,int nCols)
{
  if ((Mat2D_getnRows(mat)== nRows)&&(Mat2D_getnCols(mat)== nCols)) return;
  if (mat->data!= NULL) /* Ca peut etre une matrice nulle */
    Mat2D_freeData(mat);
  mat->nRows= nRows;
  mat->nCols= nCols;
  Mat2D_allocData(mat);
}

void Mat2D_changeType(TMatrix2D mat,TMatrix2DType newType)
{
  if (Mat2D_getType(mat)== newType) return;
  if (mat->data!= NULL) /* Ca peut etre une matrice nulle */
    Mat2D_freeData(mat);
  mat->type= newType;
  Mat2D_allocData(mat);
}

#define round(X) floor(X+0.5)
#define sqr(X) ((X)*(X))

void Mat2D_convertType(TMatrix2D mat,TMatrix2DType newType)
{
  TMatrix2D     matD;
  int           r,c;
  double        temp;

  if (Mat2D_getType(mat)== newType) return;

  matD= Mat2D_create(Mat2D_getnRows(mat),Mat2D_getnCols(mat),newType);

  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
    {
      switch (Mat2D_getType(mat))
      {
        case MAT2D_CHAR  : temp= Mat2D_getDataChar(mat)[r][c]; break;
        case MAT2D_SHORT : temp= Mat2D_getDataShort(mat)[r][c]; break;
        case MAT2D_LONG  : temp= Mat2D_getDataLong(mat)[r][c]; break;
        case MAT2D_FLOAT : temp= Mat2D_getDataFloat(mat)[r][c]; break;
        case MAT2D_DOUBLE: temp= Mat2D_getDataDouble(mat)[r][c]; break;
      }
      switch (newType)
      {
        case MAT2D_CHAR  : Mat2D_getDataChar(matD)[r][c]= round(temp); break;
        case MAT2D_SHORT : Mat2D_getDataShort(matD)[r][c]= round(temp); break;
        case MAT2D_LONG  : Mat2D_getDataLong(matD)[r][c]= round(temp); break;
        case MAT2D_FLOAT : Mat2D_getDataFloat(matD)[r][c]= temp; break;
        case MAT2D_DOUBLE: Mat2D_getDataDouble(matD)[r][c]= temp; break;
      }
    }

  Mat2D_swapAll(mat,matD);
  Mat2D_destroy(&matD);
}

void Mat2D_resizeAndChangeType(TMatrix2D mat,int nRows,int nCols,TMatrix2DType newType)
{
  Mat2D_changeType(mat,newType);
  Mat2D_resize(mat,nRows,nCols);
}

int Mat2D_getElementSize(TMatrix2D mat)
{
  switch (mat->type)
  {
    case MAT2D_CHAR  : return sizeof(char);
    case MAT2D_SHORT : return sizeof(short);
    case MAT2D_LONG  : return sizeof(long);
    case MAT2D_FLOAT : return sizeof(float);
    case MAT2D_DOUBLE: return sizeof(double);
  }
  return 0;
}

void Mat2D_checkType(TMatrix2D mat,TMatrix2DType type)
{
  if (Mat2D_getType(mat)!= type)
    Mat2D_error("Type de la matrice incorrect");
}

/* Operation avec fichiers */
void Mat2D_loadFromMat(TMatrix2D mat,char *fileName)
{
  FILE         *in;
  char          ch[128];
  TMatrix2DType Typ;
  unsigned int  nRows,nCols;
  unsigned int  r,c;

  if ((in= fopen(fileName,"r"))== NULL) Mat2D_error("Ouverture du fichier impossible");

  fgets(ch,128,in);
  if (strcmp(ch,"Matrix2D\n")!= 0) Mat2D_error("Format inconnu");

  fgets(ch,128,in);
  if (strcmp(ch,"Char\n")== 0) Typ= MAT2D_CHAR;
  else
  if (strcmp(ch,"Short\n")== 0) Typ= MAT2D_SHORT;
  else
  if (strcmp(ch,"Long\n")== 0) Typ= MAT2D_LONG;
  else
  if (strcmp(ch,"Float\n")== 0) Typ= MAT2D_FLOAT;
  else
  if (strcmp(ch,"Double\n")== 0) Typ= MAT2D_DOUBLE;
  else
    Mat2D_error("Format inconnu");

  fgets(ch,128,in);
  sscanf(ch,"%d %d",&nRows,&nCols);
  Mat2D_resizeAndChangeType(mat,nRows,nCols,Typ);

  fgets(ch,128,in);

  if (strcmp(ch,"Binary\n")== 0)
  /* Donnee sous forme binaire */
  {
    fclose(in);
    in= fopen(fileName,"rb");
    fseek(in,-(int)nRows*nCols*Mat2D_getElementSize(mat),SEEK_END);
    fread(Mat2D_getAllData(mat),Mat2D_getElementSize(mat),nRows*nCols,in);
  }
  else
  /* Donne sous forme texte */
  if (strcmp(ch,"Text\n")== 0)
  {
    for (r= 0;r<nRows;r++)
      for (c= 0;c<nCols;c++)
      {
        switch (Typ)
        {
          case MAT2D_CHAR  : fscanf(in,"%d",&Mat2D_getDataChar(mat)[r][c]); break;
          case MAT2D_SHORT : fscanf(in,"%h",&Mat2D_getDataShort(mat)[r][c]); break;
          case MAT2D_LONG  : fscanf(in,"%l",&Mat2D_getDataLong(mat)[r][c]); break;
          case MAT2D_FLOAT : fscanf(in,"%f",&Mat2D_getDataFloat(mat)[r][c]); break;
          case MAT2D_DOUBLE: fscanf(in,"%lf",&Mat2D_getDataDouble(mat)[r][c]); break;
        }
      }
  }
  else
    Mat2D_error("Format inconnu");

  fclose(in);
}

void Mat2D_saveToMat(TMatrix2D mat,char *fileName)
{
  FILE         *out;
  int           r,c;

  if ((out= fopen(fileName,"wb"))== NULL) Mat2D_error("Ouverture du fichier impossible");

  fprintf(out,"%s","Matrix2D\n");
  switch (Mat2D_getType(mat))
  {
    case MAT2D_CHAR  : fprintf(out,"Char\n"); break;
    case MAT2D_SHORT : fprintf(out,"Short\n"); break;
    case MAT2D_LONG  : fprintf(out,"Long\n"); break;
    case MAT2D_FLOAT : fprintf(out,"Float\n"); break;
    case MAT2D_DOUBLE: fprintf(out,"Double\n"); break;
  }

  fprintf(out,"%d %d\n",mat->nRows,mat->nCols);

  fprintf(out,"Binary\n");
  fwrite(Mat2D_getAllData(mat),Mat2D_getElementSize(mat),mat->nRows*mat->nCols,out);

  fclose(out);
}

/* Operation mathematiques sur les matrices */

void Mat2D_transpose(TMatrix2D mat)
{
  TMatrix2D matD;
  int       r,c;
  int       nRows,nCols;
  int       size;
  unsigned char **dataS;
  unsigned char **dataD;

  nRows= Mat2D_getnRows(mat);
  nCols= Mat2D_getnCols(mat);
  size= Mat2D_getElementSize(mat);
  matD= Mat2D_create(nCols,nRows,Mat2D_getType(mat));
  dataS= Mat2D_getDataChar(mat);
  dataD= Mat2D_getDataChar(matD);

  for (r= 0;r<nRows;r++)
    for (c= 0;c<nCols;c++)
      memcpy(&(dataD[c][r*size]),&dataS[r][c*size],size);

  Mat2D_swapAll(mat,matD);
  Mat2D_destroy(&matD);
}

TMatrix2D Mat2D_determinantAux(TMatrix2D matSrc,int exceptRow)
{
  TMatrix2D matDest;
  int       sizeElement;
  int       r,rc;

  matDest= Mat2D_createNull();
  matDest->type= Mat2D_getType(matSrc);
  matDest->nRows= matSrc->nRows-1;
  matDest->nCols= matSrc->nRows-1;
  matDest->isSub= 1;
  sizeElement= Mat2D_getElementSize(matSrc);

  matDest->data= (void **)mxMalloc(sizeof(void *)*(matSrc->nRows-1));

  rc= 0;
  for (r= 0;r<matSrc->nRows;r++)
    if (r!= exceptRow)
      matDest->data[rc++]= (void *)((int)(matSrc->data[r])+sizeElement);

  return matDest;
}
       
double Mat2D_determinant(TMatrix2D mat)
{
  TMatrix2D matSub;
  int       nCols;
  int       sign;
  double    det;
  int       r;

  if (Mat2D_getnRows(mat)!= Mat2D_getnCols(mat)) Mat2D_error("Matrice non carree");

  nCols= Mat2D_getnCols(mat);
  if (nCols== 1)
    switch (Mat2D_getType(mat))
    {
      MAT2D_CHAR  : return Mat2D_getDataChar(mat)[0][0];
      MAT2D_SHORT : return Mat2D_getDataShort(mat)[0][0];
      MAT2D_LONG  : return Mat2D_getDataLong(mat)[0][0];
      MAT2D_FLOAT : return Mat2D_getDataFloat(mat)[0][0];
      MAT2D_DOUBLE: return Mat2D_getDataDouble(mat)[0][0];
    }
  else
  if (nCols== 2)
  {
    switch (Mat2D_getType(mat))
    {
      case MAT2D_CHAR  : return Mat2D_getDataChar(mat)[0][0]*Mat2D_getDataChar(mat)[1][1]-
                                Mat2D_getDataChar(mat)[1][0]*Mat2D_getDataChar(mat)[0][1];
      case MAT2D_SHORT : return Mat2D_getDataShort(mat)[0][0]*Mat2D_getDataShort(mat)[1][1]-
                                Mat2D_getDataShort(mat)[1][0]*Mat2D_getDataShort(mat)[0][1];
      case MAT2D_LONG  : return Mat2D_getDataLong(mat)[0][0]*Mat2D_getDataLong(mat)[1][1]-
                                Mat2D_getDataLong(mat)[1][0]*Mat2D_getDataLong(mat)[0][1];
      case MAT2D_FLOAT : return Mat2D_getDataFloat(mat)[0][0]*Mat2D_getDataFloat(mat)[1][1]-
                                Mat2D_getDataFloat(mat)[1][0]*Mat2D_getDataFloat(mat)[0][1];
      case MAT2D_DOUBLE: return Mat2D_getDataDouble(mat)[0][0]*Mat2D_getDataDouble(mat)[1][1]-
                                Mat2D_getDataDouble(mat)[1][0]*Mat2D_getDataDouble(mat)[0][1];
    }
  }

  sign= 1;
  for(r= 0;r<mat->nRows;r++)
  {
    matSub= Mat2D_determinantAux(mat,r);
    switch (Mat2D_getType(mat))
    {
      case MAT2D_CHAR  : det+= sign*Mat2D_getDataChar(mat)[r][0]*Mat2D_determinant(matSub); break;
      case MAT2D_SHORT : det+= sign*Mat2D_getDataShort(mat)[r][0]*Mat2D_determinant(matSub); break;
      case MAT2D_LONG  : det+= sign*Mat2D_getDataLong(mat)[r][0]*Mat2D_determinant(matSub); break;
      case MAT2D_FLOAT : det+= sign*Mat2D_getDataFloat(mat)[r][0]*Mat2D_determinant(matSub); break;
      case MAT2D_DOUBLE: det+= sign*Mat2D_getDataDouble(mat)[r][0]*Mat2D_determinant(matSub); break;
    }
    sign=-sign;
    Mat2D_destroy(&matSub);
  }

  return(det);
}

double Mat2D_trace(TMatrix2D mat)
{
  int i;
  double trace;

  if (Mat2D_getnRows(mat)!= Mat2D_getnCols(mat)) Mat2D_error("Matrice non carree");
  trace= 0;
  for (i= 0;i<Mat2D_getnRows(mat);i++)
    switch (Mat2D_getType(mat))
    {
      case MAT2D_CHAR  : trace+= Mat2D_getDataChar(mat)[i][i]; break;
      case MAT2D_SHORT : trace+= Mat2D_getDataShort(mat)[i][i]; break;
      case MAT2D_LONG  : trace+= Mat2D_getDataLong(mat)[i][i]; break;
      case MAT2D_FLOAT : trace+= Mat2D_getDataFloat(mat)[i][i]; break;
      case MAT2D_DOUBLE: trace+= Mat2D_getDataDouble(mat)[i][i]; break;
    }
  return trace;
}

void Mat2D_inverse(TMatrix2D mat)
{
  double    det;
  TMatrix2D com,A;
  int       r,c,u,v,du,dv;

  Mat2D_checkType(mat,MAT2D_DOUBLE);
  if (Mat2D_getnRows(mat)!= Mat2D_getnCols(mat)) Mat2D_error("Matrice non carree");
  det= Mat2D_determinant(mat);
  if (det== 0) {
   /*  Mat2D_display(mat); */
    Mat2D_error("Inversion impossible (determinant nul)");
  }
  com= Mat2D_createFrom(mat);
  A= Mat2D_create(Mat2D_getnRows(mat)-1,Mat2D_getnCols(mat)-1,Mat2D_getType(mat));

  for (r=0;r<Mat2D_getnRows(mat);r++)
    for (c=0;c<Mat2D_getnCols(mat);c++)
    {
      for (u=0;u<Mat2D_getnRows(mat);u++)
        if (u!= r)
          for (v=0;v<Mat2D_getnCols(mat);v++)
            if (v!= c)
            {
              if (u>r) du= -1; else du= 0;
              if (v>c) dv= -1; else dv= 0;
              Mat2D_getDataDouble(A)[u+du][v+dv]= Mat2D_getDataDouble(mat)[u][v];
            }
      Mat2D_getDataDouble(com)[r][c]= (1+((r+c)%2)*(-2))*Mat2D_determinant(A)/det;
    }
  Mat2D_swapAll(mat,com);
  Mat2D_destroy(&com);
  Mat2D_transpose(mat);
}

void Mat2D_add(TMatrix2D mat1,TMatrix2D mat2)
{
  int       r,c;
  TMatrix2D matD;

  if ((mat1->nRows!= mat1->nRows)||(mat1->nCols!= mat1->nCols)||(mat1->type!= mat1->type)) Mat2D_error("Matrice incompatibles");
  matD= Mat2D_create(mat1->nRows,mat1->nCols,mat1->type);
  for (r=0;r<matD->nRows;r++)
    for (c=0;c<matD->nCols;c++)
      switch (Mat2D_getType(matD))
      {
        case MAT2D_CHAR  : Mat2D_getDataChar(matD)[r][c]= Mat2D_getDataChar(mat1)[r][c]+Mat2D_getDataChar(mat2)[r][c]; break;
        case MAT2D_SHORT : Mat2D_getDataShort(matD)[r][c]= Mat2D_getDataShort(mat1)[r][c]+Mat2D_getDataShort(mat2)[r][c]; break;
        case MAT2D_LONG  : Mat2D_getDataLong(matD)[r][c]= Mat2D_getDataLong(mat1)[r][c]+Mat2D_getDataLong(mat2)[r][c]; break;
        case MAT2D_FLOAT : Mat2D_getDataFloat(matD)[r][c]= Mat2D_getDataFloat(mat1)[r][c]+Mat2D_getDataFloat(mat2)[r][c]; break;
        case MAT2D_DOUBLE: Mat2D_getDataDouble(matD)[r][c]= Mat2D_getDataDouble(mat1)[r][c]+Mat2D_getDataDouble(mat2)[r][c]; break;
      }
  Mat2D_swapAll(mat1,matD);
  Mat2D_destroy(&matD);
}

void Mat2D_product(TMatrix2D mat1,TMatrix2D mat2)
{
  int       r,c,k;
  TMatrix2D matD;

  if ((mat1->nCols!= mat2->nRows)||(mat1->type!= mat1->type)) Mat2D_error("Matrice incompatibles");
  matD= Mat2D_create(mat1->nRows,mat1->nCols,mat1->type);
  for (r=0;r<matD->nRows;r++)
    for (c=0;c<matD->nCols;c++)
    {
      switch (Mat2D_getType(matD))
      {
        case MAT2D_CHAR  : Mat2D_getDataChar(matD)[r][c]= 0; break;
        case MAT2D_SHORT : Mat2D_getDataShort(matD)[r][c]= 0; break;
        case MAT2D_LONG  : Mat2D_getDataLong(matD)[r][c]= 0; break;
        case MAT2D_FLOAT : Mat2D_getDataFloat(matD)[r][c]= 0; break;
        case MAT2D_DOUBLE: Mat2D_getDataDouble(matD)[r][c]= 0; break;
      }
      for (k= 0;k<mat1->nCols;k++)
        switch (Mat2D_getType(matD))
        {
          case MAT2D_CHAR  : Mat2D_getDataChar(matD)[r][c]+= Mat2D_getDataChar(mat1)[r][k]*Mat2D_getDataChar(mat2)[k][c]; break;
          case MAT2D_SHORT : Mat2D_getDataShort(matD)[r][c]+= Mat2D_getDataShort(mat1)[r][k]*Mat2D_getDataShort(mat2)[k][c]; break;
          case MAT2D_LONG  : Mat2D_getDataLong(matD)[r][c]+= Mat2D_getDataLong(mat1)[r][k]*Mat2D_getDataLong(mat2)[k][c]; break;
          case MAT2D_FLOAT : Mat2D_getDataFloat(matD)[r][c]+= Mat2D_getDataFloat(mat1)[r][k]*Mat2D_getDataFloat(mat2)[k][c]; break;
          case MAT2D_DOUBLE: Mat2D_getDataDouble(matD)[r][c]+= Mat2D_getDataDouble(mat1)[r][k]*Mat2D_getDataDouble(mat2)[k][c]; break;
        }
    }
  Mat2D_swapAll(mat1,matD);
  Mat2D_destroy(&matD);
}


void Mat2D_rotate90(TMatrix2D mat)
{
  TMatrix2D matD;
  int       r,c;
  int       nRows,nCols;
  int       size;
  char    **dataS;
  char    **dataD;

  nRows= Mat2D_getnRows(mat);
  nCols= Mat2D_getnCols(mat);
  size= Mat2D_getElementSize(mat);
  matD= Mat2D_create(nCols,nRows,Mat2D_getType(mat));
  dataS= (char **)Mat2D_getData(mat);
  dataD= (char **)Mat2D_getData(matD);

  for (r= 0;r<nRows;r++)
    for (c= 0;c<nCols;c++)
      memcpy(&(dataD[nCols-1-c][r*size]),&dataS[r][c*size],size);

  Mat2D_swapAll(mat,matD);
  Mat2D_destroy(&matD);
}

void Mat2D_rotate270(TMatrix2D mat)
{
  TMatrix2D matD;
  int       r,c;
  int       nRows,nCols;
  int       size;
  char    **dataS;
  char    **dataD;

  nRows= Mat2D_getnRows(mat);
  nCols= Mat2D_getnCols(mat);
  size= Mat2D_getElementSize(mat);
  matD= Mat2D_create(nCols,nRows,Mat2D_getType(mat));
  dataS= (char **)Mat2D_getData(mat);
  dataD= (char **)Mat2D_getData(matD);

  for (r= 0;r<nRows;r++)
    for (c= 0;c<nCols;c++)
      memcpy(&(dataD[c][(nRows-1-r)*size]),&dataS[r][c*size],size);

  Mat2D_swapAll(mat,matD);
  Mat2D_destroy(&matD);
}

void Mat2D_rotate180(TMatrix2D mat)
{
  int       r,c;
  int       nRows,nCols;
  int       size;
  char    **data;
  char      temp[MAT2D_MAXSIZEELEMENT];

  nRows= Mat2D_getnRows(mat);
  nCols= Mat2D_getnCols(mat);
  size= Mat2D_getElementSize(mat);
  data= (char **)Mat2D_getData(mat);

  for (r= 0;r<nRows/2;r++)
    for (c= 0;c<nCols;c++)
    {
      memcpy(temp,&data[r][c*size],size);
      memcpy(&data[r][c*size],&data[nRows-1-r][(nCols-1-c)*size],size);
      memcpy(&data[nRows-1-r][(nCols-1-c)*size],temp,size);
    }
}

/* Sous fonction de Mat2D_Convolve */
/* Cette convolution est plus lente car elle effectue des verifications en plus */
void Mat2D_convolveCorner(int r,int c,
                           void   **dataS,void **dataD,
                           double **dataC,
                           int nRows,int nCols,
                           int nCRows,int nCCols,
                           TMatrix2DType Typ)
{
  int    u,v;
  double value;
  int    ar,ac;

  value= 0.;
  for (u= 0;u<nCRows;u++)
    for (v= 0;v<nCCols;v++)
    {
      ar= r+u;
      ac= c+v;
      if (ar<0) ar=0;
      if (ar>=nRows) ar= nRows-1;
      if (ac<0) ac=0;
      if (ac>=nCols) ac= nCols-1;
      switch (Typ)
      {
        case MAT2D_CHAR  : value+= (double)((unsigned char **)dataS)[ar][ac]*dataC[u][v]; break;
        case MAT2D_SHORT : value+= (double)((short **)dataS)[ar][ac]*dataC[u][v]; break;
        case MAT2D_LONG  : value+= (double)((long **)dataS)[ar][ac]*dataC[u][v]; break;
        case MAT2D_FLOAT : value+= (double)((float **)dataS)[ar][ac]*dataC[u][v]; break;
        case MAT2D_DOUBLE: value+= (double)((double **)dataS)[ar][ac]*dataC[u][v]; break;
      }
    }
  switch (Typ)
  {
    case MAT2D_CHAR  : ((unsigned char **)dataD)[r+nCRows/2][c+nCCols/2]= round(value); break;
    case MAT2D_SHORT : ((short **)dataD)[r+nCRows/2][c+nCCols/2]= round(value); break;
    case MAT2D_LONG  : ((long **)dataD)[r+nCRows/2][c+nCCols/2]= round(value); break;
    case MAT2D_FLOAT : ((float **)dataD)[r+nCRows/2][c+nCCols/2]= value; break;
    case MAT2D_DOUBLE: ((double **)dataD)[r+nCRows/2][c+nCCols/2]= value; break;
  }
}

void Mat2D_convolve(TMatrix2D mat,TMatrix2D matC)
{
  int       r,c,u,v;
  int       nCRows,nCCols;
  int       nRows,nCols;
  double    value;
  void    **dataS,**dataD;
  double  **dataC;
  TMatrix2D matD;
                 
  if (Mat2D_getType(matC)!= MAT2D_DOUBLE)
    Mat2D_error("La matrice de convolution doit etre de type double");

  matD= Mat2D_createFrom(mat);

  nRows= Mat2D_getnRows(mat);
  nCols= Mat2D_getnCols(mat);
  nCRows= Mat2D_getnRows(matC);
  nCCols= Mat2D_getnCols(matC);

  dataS= Mat2D_getData(mat);
  dataD= Mat2D_getData(matD);
  dataC= Mat2D_getDataDouble(matC);

  /* On s'occupe d'abord des coins */
  for (r= -nCRows/2;r<nRows-nCRows/2;r++)
  {
    for (c= -nCCols/2;c<nCCols/2;c++)
      Mat2D_convolveCorner(r,c,dataS,dataD,dataC,nRows,nCols,nCRows,nCCols,Mat2D_getType(mat));
    for (c= nCols-3*nCCols/2;c<nCols-nCCols/2;c++)
      Mat2D_convolveCorner(r,c,dataS,dataD,dataC,nRows,nCols,nCRows,nCCols,Mat2D_getType(mat));
  }
  for (c= nCCols/2;c<nCols-3*nCCols/2;c++)
  {
    for (r= -nCRows/2;r<nCRows/2;r++)
      Mat2D_convolveCorner(r,c,dataS,dataD,dataC,nRows,nCols,nCRows,nCCols,Mat2D_getType(mat));
    for (r= nRows-3*nCRows/2;r<nRows-nCRows/2;r++)
      Mat2D_convolveCorner(r,c,dataS,dataD,dataC,nRows,nCols,nCRows,nCCols,Mat2D_getType(mat));
  }
  /* ...puis du reste de l'image */
  switch (Mat2D_getType(mat))
  {
    case   MAT2D_CHAR: for (r= 0;r<nRows-nCRows;r++)
                         for (c= 0;c<nCols-nCCols;c++)
                         {
                           value= 0.;
                           for (u= 0;u<nCRows;u++)
                             for (v= 0;v<nCCols;v++)
                               value+= ((unsigned char **)dataS)[r+u][c+v]*dataC[u][v];
                           ((unsigned char **)dataD)[r+nCRows/2][c+nCCols/2]= round(value);
                         }
                       break;
    case  MAT2D_SHORT: for (r= 0;r<nRows-nCRows;r++)
                         for (c= 0;c<nCols-nCCols;c++)
                         {
                           value= 0.;
                           for (u= 0;u<nCRows;u++)
                             for (v= 0;v<nCCols;v++)
                               value+= ((short **)dataS)[r+u][c+v]*dataC[u][v];
                           ((short **)dataD)[r+nCRows/2][c+nCCols/2]= round(value);
                         }
                       break;
    case   MAT2D_LONG: for (r= 0;r<nRows-nCRows;r++)
                         for (c= 0;c<nCols-nCCols;c++)
                         {
                           value= 0.;
                           for (u= 0;u<nCRows;u++)
                             for (v= 0;v<nCCols;v++)
                               value+= ((long **)dataS)[r+u][c+v]*dataC[u][v];
                           ((long **)dataD)[r+nCRows/2][c+nCCols/2]= round(value);
                         }
                       break;
    case  MAT2D_FLOAT: for (r= 0;r<nRows-nCRows;r++)
                         for (c= 0;c<nCols-nCCols;c++)
                         {
                           value= 0.;
                           for (u= 0;u<nCRows;u++)
                             for (v= 0;v<nCCols;v++)
                               value+= ((float **)dataS)[r+u][c+v]*dataC[u][v];
                           ((float **)dataD)[r+nCRows/2][c+nCCols/2]= value;
                         }
                       break;
    case MAT2D_DOUBLE: for (r= 0;r<nRows-nCRows;r++)
                         for (c= 0;c<nCols-nCCols;c++)
                         {
                           value= 0.;
                           for (u= 0;u<nCRows;u++)
                             for (v= 0;v<nCCols;v++)
                               value+= ((double **)dataS)[r+u][c+v]*dataC[u][v];
                           ((double **)dataD)[r+nCRows/2][c+nCCols/2]= value;
                         }
                       break;
  }
  Mat2D_swapData(mat,matD);
  Mat2D_destroy(&matD);
}

/* Si matMod est de type Float, alors r�sultat en float */
/* Si matMod est de type Double, alors r�sultat en double */
/* sinon, r�sultat en double */
void Mat2D_gradientModule(TMatrix2D matMod,TMatrix2D mat,TMatrix2D matConv)
{
  TMatrix2D matR,matC;
  int       newType;
  int       r,c;
  void    **dataR;
  void    **dataC;
  void    **dataMod;

  newType= Mat2D_getType(matMod);
  if ((newType!= MAT2D_FLOAT)&&(newType!= MAT2D_DOUBLE)) newType= MAT2D_DOUBLE;
  Mat2D_resizeAndChangeType(matMod,Mat2D_getnRows(mat),Mat2D_getnCols(mat),newType);

  matR= Mat2D_clone(mat);
  Mat2D_convertType(matR,newType);
  matC= Mat2D_clone(matR);

  /* Calcul des composantes en r et c du gradient */
  Mat2D_convolve(matR,matConv);
  Mat2D_rotate90(matConv);
  Mat2D_convolve(matC,matConv);
  Mat2D_rotate270(matConv); /* On remet matconv comme il etait initialement */

  dataR= Mat2D_getData(matR);
  dataC= Mat2D_getData(matC);
  dataMod= Mat2D_getData(matMod);

  /* Calcul du module */

  if (newType== MAT2D_FLOAT)
  {
    for (r= 0;r<Mat2D_getnRows(mat);r++)
      for (c= 0;c<Mat2D_getnCols(mat);c++)
        ((float **)dataMod)[r][c]= sqrt(sqr(((float **)dataR)[r][c])+sqr(((float **)dataC)[r][c]));
  }
  else
  /* calcul en Double */
  {
    for (r= 0;r<Mat2D_getnRows(mat);r++)
      for (c= 0;c<Mat2D_getnCols(mat);c++)
        ((double **)dataMod)[r][c]= sqrt(sqr(((double **)dataR)[r][c])+sqr(((double **)dataC)[r][c]));
  }
  Mat2D_destroy(&matR);
  Mat2D_destroy(&matC);
}

void Mat2D_addAllValue(TMatrix2D mat,double v)
{
  int r,c;

  for (r= 0;r<mat->nRows;r++)
    for (c= 0;c<mat->nCols;c++)
    {
      switch (mat->type)
      {
        case MAT2D_CHAR  : Mat2D_getDataChar(mat)[r][c]+= (char)v; break;
        case MAT2D_SHORT : Mat2D_getDataShort(mat)[r][c]+= (short)v; break;
        case MAT2D_LONG  : Mat2D_getDataLong(mat)[r][c]+= (long)v; break;
        case MAT2D_FLOAT : Mat2D_getDataFloat(mat)[r][c]+= (float)v; break;
        case MAT2D_DOUBLE: Mat2D_getDataDouble(mat)[r][c]+= v; break;
      }
    }
}

void Mat2D_subFromAllValue(TMatrix2D mat,double v)
{
  int r,c;

  for (r= 0;r<mat->nRows;r++)
    for (c= 0;c<mat->nCols;c++)
    {
      switch (mat->type)
      {
        case MAT2D_CHAR  : Mat2D_getDataChar(mat)[r][c]  = (char)(1.-(double)Mat2D_getDataChar(mat)[r][c]); break;
        case MAT2D_SHORT : Mat2D_getDataShort(mat)[r][c] = (short)(1.-(double)Mat2D_getDataShort(mat)[r][c]); break;
        case MAT2D_LONG  : Mat2D_getDataLong(mat)[r][c]  = (long)(1.-(double)Mat2D_getDataLong(mat)[r][c]); break;
        case MAT2D_FLOAT : Mat2D_getDataFloat(mat)[r][c] = 1.-Mat2D_getDataFloat(mat)[r][c]; break;
        case MAT2D_DOUBLE: Mat2D_getDataDouble(mat)[r][c]= 1.-Mat2D_getDataDouble(mat)[r][c]; break;
      }
    }
}

void Mat2D_mulAllMat(TMatrix2D mat1,TMatrix2D mat2)
{
  int r,c;

  if ((Mat2D_getType(mat1)!= Mat2D_getType(mat2))||
      (Mat2D_getnRows(mat1)!= Mat2D_getnRows(mat2))||
      (Mat2D_getnCols(mat1)!= Mat2D_getnCols(mat2)))
    Mat2D_error("Les matrices doivent �tre identiques");
 
  for (r= 0;r<mat1->nRows;r++)
    for (c= 0;c<mat1->nCols;c++)
    {
      switch (mat1->type)
      {
        case MAT2D_CHAR  : Mat2D_getDataChar(mat1)[r][c]  *= Mat2D_getDataChar(mat2)[r][c]; break;
        case MAT2D_SHORT : Mat2D_getDataShort(mat1)[r][c] *= Mat2D_getDataShort(mat2)[r][c]; break;
        case MAT2D_LONG  : Mat2D_getDataLong(mat1)[r][c]  *= Mat2D_getDataLong(mat2)[r][c]; break;
        case MAT2D_FLOAT : Mat2D_getDataFloat(mat1)[r][c] *= Mat2D_getDataFloat(mat2)[r][c]; break;
        case MAT2D_DOUBLE: Mat2D_getDataDouble(mat1)[r][c]*= Mat2D_getDataDouble(mat2)[r][c]; break;
      }
    }
}

void Mat2D_mulAllValue(TMatrix2D mat,double v)
{
  int r,c;

  for (r= 0;r<mat->nRows;r++)
    for (c= 0;c<mat->nCols;c++)
    {
      switch (mat->type)
      {
        case MAT2D_CHAR  : Mat2D_getDataChar(mat)[r][c] = (unsigned char)((double)Mat2D_getDataChar(mat)[r][c]*v); break;
        case MAT2D_SHORT : Mat2D_getDataShort(mat)[r][c] = (short)((double)Mat2D_getDataShort(mat)[r][c]*v); break;
        case MAT2D_LONG  : Mat2D_getDataLong(mat)[r][c] = (long)((double)Mat2D_getDataLong(mat)[r][c]*v); break;
        case MAT2D_FLOAT : Mat2D_getDataFloat(mat)[r][c] *= (float)v; break;
        case MAT2D_DOUBLE: Mat2D_getDataDouble(mat)[r][c]*= v; break;
      }
    }
}

void Mat2D_invAllValue(TMatrix2D mat)
{
  int r,c;

  for (r= 0;r<mat->nRows;r++)
    for (c= 0;c<mat->nCols;c++)
    {
      switch (mat->type)
      {
        case MAT2D_CHAR  : Mat2D_getDataChar(mat)[r][c]  = (char)(1./(double)Mat2D_getDataChar(mat)[r][c]); break;
        case MAT2D_SHORT : Mat2D_getDataShort(mat)[r][c] = (short)(1./(double)Mat2D_getDataShort(mat)[r][c]); break;
        case MAT2D_LONG  : Mat2D_getDataLong(mat)[r][c]  = (long)(1./(double)Mat2D_getDataLong(mat)[r][c]); break;
        case MAT2D_FLOAT : Mat2D_getDataFloat(mat)[r][c] = 1./Mat2D_getDataFloat(mat)[r][c]; break;
        case MAT2D_DOUBLE: Mat2D_getDataDouble(mat)[r][c]= 1./Mat2D_getDataDouble(mat)[r][c]; break;
      }
    }
}

void Mat2D_minmaxValue(TMatrix2D mat,double vMin,double vMax)
{
  int    r,c;

  for (r= 0;r<mat->nRows;r++)
    for (c= 0;c<mat->nCols;c++)
    {
      switch (mat->type)
      {
        case MAT2D_CHAR  : Mat2D_getDataChar(mat)[r][c]= min((char)vMax,max((char)vMin,Mat2D_getDataChar(mat)[r][c])); break;
        case MAT2D_SHORT : Mat2D_getDataShort(mat)[r][c]= min((short)vMax,max((short)vMin,Mat2D_getDataShort(mat)[r][c])); break;
        case MAT2D_LONG  : Mat2D_getDataLong(mat)[r][c]= min((long)vMax,max((long)vMin,Mat2D_getDataLong(mat)[r][c])); break;
        case MAT2D_FLOAT : Mat2D_getDataFloat(mat)[r][c]= min((float)vMax,max((float)vMin,Mat2D_getDataFloat(mat)[r][c])); break;
        case MAT2D_DOUBLE: Mat2D_getDataDouble(mat)[r][c]= min(vMax,max(vMin,Mat2D_getDataDouble(mat)[r][c])); break;
      }
    }
}

void Mat2D_findMinMaxInteger(TMatrix2D mat,long *vMin,long *vMax)
{
  int r,c;

  *vMin= MAXLONG;
  *vMax= -MAXLONG;
  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
    {
      switch (Mat2D_getType(mat))
      {
        case MAT2D_CHAR: *vMin= min(*vMin,Mat2D_getDataChar(mat)[r][c]);
                         *vMax= max(*vMax,Mat2D_getDataChar(mat)[r][c]); break; 
        case MAT2D_SHORT: *vMin= min(*vMin,Mat2D_getDataShort(mat)[r][c]);
                          *vMax= max(*vMax,Mat2D_getDataShort(mat)[r][c]); break;
        case MAT2D_LONG: *vMin= min(*vMin,Mat2D_getDataLong(mat)[r][c]);
                         *vMax= max(*vMax,Mat2D_getDataLong(mat)[r][c]); break;
      }
    }
}

void Mat2D_findMinMaxFloat(TMatrix2D mat,double *vMin,double *vMax)
{
  int r,c;

  *vMin= MAXDOUBLE;
  *vMax= -MAXDOUBLE;
  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
    {
      switch (Mat2D_getType(mat))
      {
        case MAT2D_FLOAT : *vMin= min(*vMin,Mat2D_getDataFloat(mat)[r][c]);
                           *vMax= max(*vMax,Mat2D_getDataFloat(mat)[r][c]); break;
        case MAT2D_DOUBLE: *vMin= min(*vMin,Mat2D_getDataDouble(mat)[r][c]);
                           *vMax= max(*vMax,Mat2D_getDataDouble(mat)[r][c]); break;
      }
    }
}

double Mat2D_findMinFloat(TMatrix2D mat)
{
  int    r,c;
  double vMin;

  vMin= MAXDOUBLE;
  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
    {
      switch (Mat2D_getType(mat))
      {
        case MAT2D_FLOAT : vMin= min(vMin,Mat2D_getDataFloat(mat)[r][c]); break;
        case MAT2D_DOUBLE: vMin= min(vMin,Mat2D_getDataDouble(mat)[r][c]); break;
      }
    }
  return vMin;
}

double Mat2D_findMaxFloat(TMatrix2D mat)
{
  int    r,c;
  double vMax;

  vMax= -MAXDOUBLE;
  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
    {
      switch (Mat2D_getType(mat))
      {
        case MAT2D_FLOAT : vMax= max(vMax,Mat2D_getDataFloat(mat)[r][c]); break;
        case MAT2D_DOUBLE: vMax= max(vMax,Mat2D_getDataDouble(mat)[r][c]); break;
      }
    }
  return vMax;
}

void Mat2D_normalizeValue(TMatrix2D mat,double vMin,double vMax)
{
  long   longMin,longMax;
  double doubleMin,doubleMax;
  double vMul;
  int    r,c;

  switch (Mat2D_getType(mat))
  {
    case MAT2D_CHAR  : ;
    case MAT2D_SHORT : ;
    case MAT2D_LONG  : Mat2D_findMinMaxInteger(mat,&longMin,&longMax);
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= 0;c<Mat2D_getnCols(mat);c++)
                         {
                           vMul= (longMax-longMin);
                           if (vMul== 0) vMul= 1;
                           vMul= (vMax-vMin)/vMul;
                           switch (Mat2D_getType(mat))
                           {
                             case MAT2D_CHAR : Mat2D_getDataChar(mat)[r][c]= round((((double)Mat2D_getDataChar(mat)[r][c])-longMin)*vMul+vMin); break;
                             case MAT2D_SHORT: Mat2D_getDataShort(mat)[r][c]= round((((double)Mat2D_getDataShort(mat)[r][c])-longMin)*vMul+vMin); break;
                             case MAT2D_LONG : Mat2D_getDataLong(mat)[r][c]= round((((double)Mat2D_getDataLong(mat)[r][c])-longMin)*vMul+vMin); break;
                           }
                         }
                       break;
    case MAT2D_FLOAT : ;
    case MAT2D_DOUBLE: Mat2D_findMinMaxFloat(mat,&doubleMin,&doubleMax);
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= 0;c<Mat2D_getnCols(mat);c++)
                         {
                           vMul= (doubleMax-doubleMin);
                           if (vMul== 0) vMul= 1;
                           vMul= (vMax-vMin)/vMul;
                           switch (Mat2D_getType(mat))
                           {
                             case MAT2D_FLOAT : Mat2D_getDataFloat(mat)[r][c]= ((Mat2D_getDataFloat(mat)[r][c])-doubleMin)*vMul+vMin; break;
                             case MAT2D_DOUBLE: Mat2D_getDataDouble(mat)[r][c]= ((Mat2D_getDataDouble(mat)[r][c])-doubleMin)*vMul+vMin; break;
                           }
                         }
                       break;
  }
}

void Mat2D_fillAll(TMatrix2D mat)
{
  Mat2D_fill(mat,0,0,Mat2D_getnRows(mat),Mat2D_getnCols(mat));
}

void Mat2D_fillAllValue(TMatrix2D mat,double v)
{
  Mat2D_fillValue(mat,0,0,Mat2D_getnRows(mat),Mat2D_getnCols(mat),v);
}

void Mat2D_fillValue(TMatrix2D mat,int rMin,int cMin,int rMax,int cMax,double v)
{
  int r,c;
  
  switch (Mat2D_getType(mat))
  {
    case MAT2D_CHAR  : for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataChar(mat)[r][c]= v; break;
    case MAT2D_SHORT : for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataShort(mat)[r][c]= v; break;
    case MAT2D_LONG  : for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataLong(mat)[r][c]= v; break;
    case MAT2D_FLOAT : for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataFloat(mat)[r][c]= v; break;
    case MAT2D_DOUBLE: for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataDouble(mat)[r][c]= v; break;
  }
}

void Mat2D_fill(TMatrix2D mat,int rMin,int cMin,int rMax,int cMax)
{
  int r,c;
  
  switch (Mat2D_getType(mat))
  {
    case MAT2D_CHAR  : for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataChar(mat)[r][c]= Mat2D_charValue; break;
    case MAT2D_SHORT : for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataShort(mat)[r][c]= Mat2D_shortValue; break;
    case MAT2D_LONG  : for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataLong(mat)[r][c]= Mat2D_longValue; break;
    case MAT2D_FLOAT : for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataFloat(mat)[r][c]= Mat2D_floatValue; break;
    case MAT2D_DOUBLE: for (r= rMin;r<rMax;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataDouble(mat)[r][c]= Mat2D_doubleValue; break;
  }
}

void Mat2D_clip(TMatrix2D mat,int rMin,int cMin,int rMax,int cMax)
{
  int r,c;
  
  switch (Mat2D_getType(mat))
switch (Mat2D_getType(mat))  {
    case MAT2D_CHAR  : for (r= 0;r<rMin;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataChar(mat)[r][c]= Mat2D_charValue;
                       for (r= rMax;r<Mat2D_getnRows(mat);r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataChar(mat)[r][c]= Mat2D_charValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= 0;c<cMin;c++)
                           Mat2D_getDataChar(mat)[r][c]= Mat2D_charValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= cMax;c<Mat2D_getnCols(mat);c++)
                           Mat2D_getDataChar(mat)[r][c]= Mat2D_charValue;
                       break;
    case MAT2D_SHORT : for (r= 0;r<rMin;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataShort(mat)[r][c]= Mat2D_shortValue;
                       for (r= rMax;r<Mat2D_getnRows(mat);r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataShort(mat)[r][c]= Mat2D_shortValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= 0;c<cMin;c++)
                           Mat2D_getDataShort(mat)[r][c]= Mat2D_shortValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= cMax;c<Mat2D_getnCols(mat);c++)
                           Mat2D_getDataShort(mat)[r][c]= Mat2D_shortValue;
                       break;
    case MAT2D_LONG  : for (r= 0;r<rMin;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataLong(mat)[r][c]= Mat2D_longValue;
                       for (r= rMax;r<Mat2D_getnRows(mat);r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataLong(mat)[r][c]= Mat2D_longValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= 0;c<cMin;c++)
                           Mat2D_getDataLong(mat)[r][c]= Mat2D_longValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= cMax;c<Mat2D_getnCols(mat);c++)
                           Mat2D_getDataLong(mat)[r][c]= Mat2D_longValue;
                       break;
    case MAT2D_FLOAT : for (r= 0;r<rMin;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataFloat(mat)[r][c]= Mat2D_floatValue;
                       for (r= rMax;r<Mat2D_getnRows(mat);r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataFloat(mat)[r][c]= Mat2D_floatValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= 0;c<cMin;c++)
                           Mat2D_getDataFloat(mat)[r][c]= Mat2D_floatValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= cMax;c<Mat2D_getnCols(mat);c++)
                           Mat2D_getDataFloat(mat)[r][c]= Mat2D_floatValue;
                       break;
    case MAT2D_DOUBLE: for (r= 0;r<rMin;r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataDouble(mat)[r][c]= Mat2D_doubleValue;
                       for (r= rMax;r<Mat2D_getnRows(mat);r++)
                         for (c= cMin;c<cMax;c++)
                           Mat2D_getDataDouble(mat)[r][c]= Mat2D_doubleValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= 0;c<cMin;c++)
                           Mat2D_getDataDouble(mat)[r][c]= Mat2D_doubleValue;
                       for (r= 0;r<Mat2D_getnRows(mat);r++)
                         for (c= cMax;c<Mat2D_getnCols(mat);c++)
                           Mat2D_getDataDouble(mat)[r][c]= Mat2D_doubleValue;
                       break;
  }
}

/* Autres operations */
void Mat2D_binarizeChar(TMatrix2D mat,unsigned char treshold,unsigned char vLow,unsigned char vHigh)
{
  int r,c;

  Mat2D_checkType(mat,MAT2D_CHAR);
  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
      if (Mat2D_getDataChar(mat)[r][c]>=treshold)
        Mat2D_getDataChar(mat)[r][c]= vHigh;
      else
        Mat2D_getDataChar(mat)[r][c]= vLow;
}

/* Image File Operations */

/* Internal functions */
char _PNM_readChar(FILE *in)
{
  char ch;

  do
  {
    ch= getc(in);
    if (ch== EOF) return 0;
    if (ch== '#')
    {
      do
      {
        ch= getc(in);
        if (ch== EOF) return 0;
      } while ((ch!= '\n')&&(ch!= '\r'));
    }
  } while (ch<=32);
  return ch;
}

int _PNM_readInt(FILE* in)
{
  char ch;
  int  res;

  ch= _PNM_readChar(in);
  res= 0;
  do
  {
    res= res*10+(ch-'0');
    ch= getc(in);
  } while ((ch>='0')&&(ch<='9'));
  return res;
}

void _PNM_readHeader(FILE **in,char         *fileName,
                              char         *imageType,
                              char         *isBinary,
                              unsigned int *nRows,
                              unsigned int *nCols,
                              int          *maxValue)
{
  char s;

  if ((*in= fopen(fileName,"rt"))== NULL) Mat2D_error("Ouverture du fichier impossible");

  s= _PNM_readChar(*in);
  if (s!= 'P') Mat2D_error("Format de fichier inconnu");
  *imageType= _PNM_readChar(*in)-'0';
  if ((*imageType<1)||(*imageType>6)) Mat2D_error("Format de fichier inconnu");
  *isBinary= *imageType>=4;
  *imageType-= (*imageType>=4)?3:0;
  *nCols= _PNM_readInt(*in);
  *nRows= _PNM_readInt(*in);

  if (*imageType!= 1)
  {
    *maxValue= _PNM_readInt(*in);
    if ((*maxValue<0)||(*maxValue>255)) Mat2D_error("Valeur maximale hors limites");
  }
  else
    *maxValue= 1;
}

void Mat2D_loadGrayFromPNM(TMatrix2D mat,char *fileName)
{
  FILE           *in;
  char            imageType,isBinary;
  unsigned int    nRows,nCols;
  int             maxValue;
  unsigned int    r,c,b,p;
  unsigned char **data;
  char            red,green,blue;
  char           *buffer;

  _PNM_readHeader(&in,fileName,&imageType,&isBinary,&nRows,&nCols,&maxValue);
  Mat2D_resizeAndChangeType(mat,nRows,nCols,MAT2D_CHAR);
  data= (unsigned char **)Mat2D_getData(mat);

  if (isBinary)
  {
    fclose(in);
    in= fopen(fileName,"rb");
    switch (imageType)
    {
      case 1: fseek(in,-ceil((float)nCols/8)*nRows,SEEK_END);
              buffer= mxMalloc(ceil((float)nCols/8));
              for (r= 0;r<nRows;r++)
              {
                fread(buffer,1,ceil((float)nCols/8),in);
                b= 8;
                p= -1;
                for (c= 0;c<nCols;c++)
                {
                  if (b== 8)
                  {
                    b= 0;
                    p++;
                  }
                  data[r][c]= (buffer[p]>>(7-b))&1;
                  b++;
                }
              }
              mxFree(buffer);
              break;
      case 2: fseek(in,-(int)nRows*nCols,SEEK_END);
              fread(Mat2D_getAllData(mat),1,nCols*nRows,in); break;
      case 3: fseek(in,-(int)nRows*nCols*3,SEEK_END);
              buffer= mxMalloc(nCols*3);
              for (r= 0;r<nRows;r++)
              {
                fread(buffer,1,nCols*3,in);
                for (c= 0;c<nCols;c++)
                {
                  data[r][c]= ((unsigned char)buffer[c*3]+
                               (unsigned char)buffer[c*3+1]+
                               (unsigned char)buffer[c*3+2])/3;
                }
              }
              mxFree(buffer);
              break;
    }
  }
  else
  {
    for (r= 0;r<nRows;r++)
      for (c= 0;c<nCols;c++)
      {
        switch (imageType)
        {
          case 1: ; /* Meme cas que le 2 */
          case 2: fscanf(in,"%d",&data[r][c]); break;
          case 3: fscanf(in,"%d",&red);
                  fscanf(in,"%d",&green);
                  fscanf(in,"%d",&blue);
                  data[r][c]= ((int)red+(int)green+(int)blue)/3; break;
        }
      }
  }
  fclose(in);

  if (imageType!= 1)
    if (maxValue!= 255)  /* Ajuster sur 255 */
      for (r= 0;r<nRows;r++)
        for (c= 0;c<nCols;c++)
          data[r][c]= ((unsigned char)data[r][c])*255/maxValue;
}

void Mat2D_loadRGBFromPNM(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName)
{
  FILE           *in;
  char            imageType,isBinary;
  unsigned int    nRows,nCols;
  int             maxValue;
  unsigned int    r,c,b,p;
  unsigned char **dataR,**dataG,**dataB;
  char            red,green,blue;
  char           *buffer;

  _PNM_readHeader(&in,fileName,&imageType,&isBinary,&nRows,&nCols,&maxValue);
  Mat2D_resizeAndChangeType(matR,nRows,nCols,MAT2D_CHAR);
  Mat2D_resizeAndChangeType(matG,nRows,nCols,MAT2D_CHAR);
  Mat2D_resizeAndChangeType(matB,nRows,nCols,MAT2D_CHAR);
  dataR= (unsigned char **)Mat2D_getData(matR);
  dataG= (unsigned char **)Mat2D_getData(matG);
  dataB= (unsigned char **)Mat2D_getData(matB);

  if (isBinary)
  {
    fclose(in);
    in= fopen(fileName,"rb");
    switch (imageType)
    {
      case 1: fseek(in,-ceil((float)nCols/8)*nRows,SEEK_END);
              buffer= mxMalloc(ceil((float)nCols/8));
              for (r= 0;r<nRows;r++)
              {
                fread(buffer,1,ceil((float)nCols/8),in);
                b= 8;
                p= -1;
                for (c= 0;c<nCols;c++)
                {
                  if (b== 8)
                  {
                    b= 0;
                    p++;
                  }
                  dataR[r][c]= (buffer[p]>>(7-b))&1;
                  dataG[r][c]= dataR[r][c];
                  dataB[r][c]= dataR[r][c];
                  b++;
                }
              }
              mxFree(buffer);
              break;
      case 2: fseek(in,-(int)nRows*nCols,SEEK_END);
              fread(Mat2D_getAllData(matR),1,nCols*nRows,in);
              for (r= 0;r<nRows;r++)
                for (c= 0;c<nCols;c++)
                {
                  dataG[r][c]= dataR[r][c];
                  dataB[r][c]= dataR[r][c];
                }
              break;
      case 3: fseek(in,-(int)nRows*nCols*3,SEEK_END);
              buffer= mxMalloc(nCols*3);
              for (r= 0;r<nRows;r++)
              {
                fread(buffer,1,nCols*3,in);
                for (c= 0;c<nCols;c++)
                {
                  dataR[r][c]= buffer[c*3];
                  dataG[r][c]= buffer[c*3+1];
                  dataB[r][c]= buffer[c*3+2];
                }
              }
              mxFree(buffer);
              break;
    }
  }
  else
  {
    for (r= 0;r<nRows;r++)
      for (c= 0;c<nCols;c++)
      {
        switch (imageType)
        {
          case 1: ; /* Meme cas que le 2 */
          case 2: fscanf(in,"%d",&dataR[r][c]);
                  dataG[r][c]= dataR[r][c];
                  dataB[r][c]= dataR[r][c];
                  break;
          case 3: fscanf(in,"%d",&red);
                  fscanf(in,"%d",&green);
                  fscanf(in,"%d",&blue);
                  dataR[r][c]= red;
                  dataG[r][c]= green;
                  dataB[r][c]= blue;
                  break;
        }
      }
  }
  fclose(in);

  if (imageType!= 1)
    if (maxValue!= 255)  /* Ajuster sur 255 */
      for (r= 0;r<nRows;r++)
        for (c= 0;c<nCols;c++)
        {
          dataR[r][c]= ((unsigned char)dataR[r][c])*255/maxValue;
          dataG[r][c]= ((unsigned char)dataG[r][c])*255/maxValue;
          dataB[r][c]= ((unsigned char)dataB[r][c])*255/maxValue;
        }
}

char *extractFileExt(char *fileName)
{
  int pos;

  pos= strlen(fileName)-1;
  while ((fileName[pos]!= '.')&&(pos>0))
    pos--;
  return fileName+pos;
}

void Mat2D_saveGrayToPNM(TMatrix2D mat,char *fileName)
{
  FILE *out;
  int   imageType;
  char  Ext[256];

  strcpy(Ext,extractFileExt(fileName));
  /*strlwr(Ext);*/

  if (strcmp(Ext,".pbm")== 0) imageType= 4;
  else
  if (strcmp(Ext,".pgm")== 0) imageType= 5;
  else
  if (strcmp(Ext,".ppm")== 0) imageType= 6;
  else
    Mat2D_error("Extension de fichier incorrecte");

  if ((out= fopen(fileName,"wb"))== NULL) Mat2D_error("Ouverture du fichier impossible");
  fprintf(out,"P%d\n",imageType);
  fprintf(out,"%d %d\n",mat->nCols,mat->nRows);
  fprintf(out,"255\n");

  switch (imageType)
  {
    case 4: ; break;
    case 5: fwrite(Mat2D_getAllData(mat),1,mat->nCols*mat->nRows,out); break;
    case 6: ; break;
  }

  fclose(out);
}

void Mat2D_saveRGBToPNM(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName)
{
  FILE  *out;
  int    imageType;
  char   Ext[256];
  char  *buffer;
  int    r,c;
  unsigned char **dataR,**dataG,**dataB;

  strcpy(Ext,extractFileExt(fileName));
  /*strlwr(Ext);*/

  if (strcmp(Ext,".pbm")== 0) imageType= 4;
  else
  if (strcmp(Ext,".pgm")== 0) imageType= 5;
  else
  if (strcmp(Ext,".ppm")== 0) imageType= 6;
  else
    Mat2D_error("Extension de fichier incorrecte");

  if ((out= fopen(fileName,"wb"))== NULL) Mat2D_error("Ouverture du fichier impossible");
  fprintf(out,"P%d\n",imageType);
  fprintf(out,"%d %d\n",matR->nCols,matR->nRows);
  fprintf(out,"255\n");

  dataR= (unsigned char **)Mat2D_getData(matR);
  dataG= (unsigned char **)Mat2D_getData(matG);
  dataB= (unsigned char **)Mat2D_getData(matB);

  switch (imageType)
  {
    case 4: ; break;
    case 5: ; break;
    case 6: buffer= mxMalloc(matR->nCols*3);
            for (r= 0;r<matR->nRows;r++)
            {
              for (c= 0;c<matR->nCols;c++)
              {
                buffer[c*3]= dataR[r][c];
                buffer[c*3+1]= dataG[r][c];
                buffer[c*3+2]= dataB[r][c];
              }
              fwrite(buffer,1,matR->nCols*3,out);
            }
            mxFree(buffer);
            break;
  }

  fclose(out);
}

void Mat2D_loadRGBFromTGA(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName)
{
  FILE          *in;
  char          *buffer;
  unsigned char **dataR,**dataG,**dataB;
  char           IDLength;
  char           ColorMapType;
  char           ImageType;
  char           ColorMapSpecification[5];
  unsigned short XOrigin,YOrigin;
  unsigned short Width,Height;
  char           PixelDepth;
  char           ImageDescriptor;
  int            r,c;

  if ((in= fopen(fileName,"rb"))== NULL) Mat2D_error("Ouverture du fichier impossible");

  IDLength= getc(in);
  ColorMapType= getc(in);
  if (ColorMapType!= 0) Mat2D_error("Table des couleurs non supportees");

  ImageType= getc(in);
  if (ImageType!= 2) Mat2D_error("Image non True-Color");

  fread(ColorMapSpecification,1,5,in);
  fread(&XOrigin,1,2,in);
  fread(&YOrigin,1,2,in);
  fread(&Width,1,2,in);
  fread(&Height,1,2,in);
  PixelDepth= getc(in);
  ImageDescriptor= getc(in);
  if (ImageDescriptor>8) Mat2D_error("Format non support�");
  fseek(in,IDLength,SEEK_CUR);

  Mat2D_resizeAndChangeType(matR,Height,Width,MAT2D_CHAR);
  Mat2D_resizeAndChangeType(matG,Height,Width,MAT2D_CHAR);
  Mat2D_resizeAndChangeType(matB,Height,Width,MAT2D_CHAR);

  dataR= (unsigned char **)Mat2D_getData(matR);
  dataG= (unsigned char **)Mat2D_getData(matG);
  dataB= (unsigned char **)Mat2D_getData(matB);

  switch (PixelDepth)
  {
    case 16: buffer= mxMalloc(Width*2);
             for (r= 0;r<Height;r++)
             {
               fread(buffer,1,Width*2,in);
               for (c= 0;c<Width;c++)
               {
                 /* red=5Bits,green=6Bits,blue=5Bits */
                 dataR[Height-1-r][c]= (((unsigned short *)buffer)[c]>>7)&248;
                 dataG[Height-1-r][c]= (((unsigned short *)buffer)[c]>>2)&248;
                 dataB[Height-1-r][c]= (((unsigned short *)buffer)[c]<<3)&248;
               }
             }
             mxFree(buffer);
             break;
    case 24: buffer= mxMalloc(Width*3);
             for (r= 0;r<Height;r++)
             {
               fread(buffer,1,Width*3,in);
               for (c= 0;c<Width;c++)
               {
                 dataR[Height-1-r][c]= buffer[c*3+2];
                 dataG[Height-1-r][c]= buffer[c*3+1];
                 dataB[Height-1-r][c]= buffer[c*3];
               }
             }
             mxFree(buffer);
             break;
    case 32: buffer= mxMalloc(Width*4);
             for (r= 0;r<Height;r++)
             {                          
               fread(buffer,1,Width*4,in);
               for (c= 0;c<Width;c++)
               {
                 dataR[Height-1-r][c]= buffer[c*4+2];
                 dataG[Height-1-r][c]= buffer[c*4+1];
                 dataB[Height-1-r][c]= buffer[c*4];
               }
             }
             mxFree(buffer);
             break;
    default: Mat2D_error("Format non support�");
  }

  fclose(in);
}

void Mat2D_saveRGBToTGA(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName)
{
  FILE          *out;
  char          *buffer;
  char           IDLength= 0;
  char           ColorMapType= 0;
  char           ImageType= 2;
  char           ColorMapSpecification[5]= {0,0,0,0,0};
  unsigned short XOrigin= 0,YOrigin= 0;
  unsigned short Width,Height;
  char           PixelDepth= 24;
  char           ImageDescriptor= 0;
  int            r,c;

  Mat2D_checkType(matR,MAT2D_CHAR);
  Mat2D_checkType(matG,MAT2D_CHAR);
  Mat2D_checkType(matB,MAT2D_CHAR);

  if ((out= fopen(fileName,"wb"))== NULL) Mat2D_error("Ouverture du fichier impossible");

  putc(IDLength,out);
  putc(ColorMapType,out);
  putc(ImageType,out);
  fwrite(ColorMapSpecification,1,5,out);
  fwrite(&XOrigin,1,2,out);
  fwrite(&YOrigin,1,2,out);
  Width= Mat2D_getnCols(matR);
  fwrite(&Width,1,2,out);
  Height= Mat2D_getnRows(matR);
  fwrite(&Height,1,2,out);
  putc(PixelDepth,out);
  putc(ImageDescriptor,out);

  buffer= mxMalloc(Width*3); 
  for (r= 0;r<Height;r++)
  {
    for (c= 0;c<Width;c++)
    {
      buffer[c*3+2]= Mat2D_getDataChar(matR)[Height-1-r][c];
      buffer[c*3+1]= Mat2D_getDataChar(matG)[Height-1-r][c];
      buffer[c*3]= Mat2D_getDataChar(matB)[Height-1-r][c];
    }
    fwrite(buffer,1,Width*3,out);
  }
  mxFree(buffer);
  fclose(out);
}

void Mat2D_loadGrayFromTGA(TMatrix2D mat,char *fileName)
{
  TMatrix2D matR,matG,matB;
  int       r,c;

  matR= Mat2D_createNull();
  matG= Mat2D_createNull();
  matB= Mat2D_createNull();
  Mat2D_loadRGBFromTGA(matR,matG,matB,fileName);
  Mat2D_resizeAndChangeType(mat,Mat2D_getnRows(matR),Mat2D_getnCols(matR),MAT2D_CHAR);
  
  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
      Mat2D_getDataChar(mat)[r][c]= (Mat2D_getDataChar(matR)[r][c]+
                                     Mat2D_getDataChar(matG)[r][c]+
                                     Mat2D_getDataChar(matB)[r][c])/3;

  Mat2D_destroy(&matR);
  Mat2D_destroy(&matG);
  Mat2D_destroy(&matB);
}

void Mat2D_loadRGBFromGraphicFile(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName)
{
  char  Ext[256];

  strcpy(Ext,extractFileExt(fileName));
  /*strlwr(Ext);*/

  if ((strcmp(Ext,".pbm")== 0)||(strcmp(Ext,".pgm")== 0)||(strcmp(Ext,".ppm")== 0))
    Mat2D_loadRGBFromPNM(matR,matG,matB,fileName);
  else
  if (strcmp(Ext,".tga")== 0)
    Mat2D_loadRGBFromTGA(matR,matG,matB,fileName);
  else
    Mat2D_error("Format de fichier non reconnue");
}

void Mat2D_loadGrayFromGraphicFile(TMatrix2D mat,char *fileName)
{
  char  Ext[256];

  strcpy(Ext,extractFileExt(fileName));
  /*strlwr(Ext);*/

  if ((strcmp(Ext,".pbm")== 0)||(strcmp(Ext,".pgm")== 0)||(strcmp(Ext,".pgm")== 0))
    Mat2D_loadGrayFromPNM(mat,fileName);
  else
    Mat2D_error("Format de fichier non reconnue");
}

void Mat2D_saveRGBToGraphicFile(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName)
{
  char  Ext[256];

  strcpy(Ext,extractFileExt(fileName));
  /*strlwr(Ext);*/

  if ((strcmp(Ext,".pbm")== 0)||(strcmp(Ext,".pgm")== 0)||(strcmp(Ext,".ppm")== 0))
    Mat2D_saveRGBToPNM(matR,matG,matB,fileName);
  else
  if (strcmp(Ext,".tga")== 0)
    Mat2D_saveRGBToTGA(matR,matG,matB,fileName);
  else
    Mat2D_error("Format de fichier non reconnue");
}

void Mat2D_applyLUTChar(TMatrix2D mat,char lut[256])
{
  int r,c;

  Mat2D_checkType(mat,MAT2D_CHAR);

  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
      Mat2D_getDataChar(mat)[r][c]= lut[Mat2D_getDataChar(mat)[r][c]];
}

/* Geometric Transformations */
void Mat2D_makeHMatTranslation(TMatrix2D mat,double dR,double dC)
{
  Mat2D_resizeAndChangeType(mat,3,3,MAT2D_DOUBLE);
  Mat2D_getDataDouble(mat)[0][0]= 1.;
  Mat2D_getDataDouble(mat)[0][1]= 0.;
  Mat2D_getDataDouble(mat)[0][2]= dR;
  Mat2D_getDataDouble(mat)[1][0]= 0.;
  Mat2D_getDataDouble(mat)[1][1]= 1.;
  Mat2D_getDataDouble(mat)[1][2]= dC;
  Mat2D_getDataDouble(mat)[2][0]= 0.;
  Mat2D_getDataDouble(mat)[2][1]= 0.;
  Mat2D_getDataDouble(mat)[2][2]= 1.;
}

void Mat2D_makeHMatRotation(TMatrix2D mat,double alpha)
{
  Mat2D_resizeAndChangeType(mat,3,3,MAT2D_DOUBLE);
  Mat2D_getDataDouble(mat)[0][0]= cos(alpha);
  Mat2D_getDataDouble(mat)[0][1]= -sin(alpha);
  Mat2D_getDataDouble(mat)[0][2]= 0.;
  Mat2D_getDataDouble(mat)[1][0]= sin(alpha);
  Mat2D_getDataDouble(mat)[1][1]= cos(alpha);
  Mat2D_getDataDouble(mat)[1][2]= 0.;
  Mat2D_getDataDouble(mat)[2][0]= 0.;
  Mat2D_getDataDouble(mat)[2][1]= 0.;
  Mat2D_getDataDouble(mat)[2][2]= 1.;
}

void Mat2D_makeHMatZoom(TMatrix2D mat,double ratio)
{
  Mat2D_resizeAndChangeType(mat,3,3,MAT2D_DOUBLE);
  Mat2D_getDataDouble(mat)[0][0]= ratio;
  Mat2D_getDataDouble(mat)[0][1]= 0.;
  Mat2D_getDataDouble(mat)[0][2]= 0.;
  Mat2D_getDataDouble(mat)[1][0]= 0.;
  Mat2D_getDataDouble(mat)[1][1]= ratio;
  Mat2D_getDataDouble(mat)[1][2]= 0.;
  Mat2D_getDataDouble(mat)[2][0]= 0.;
  Mat2D_getDataDouble(mat)[2][1]= 0.;
  Mat2D_getDataDouble(mat)[2][2]= 1.;
}

void Mat2D_makeHMatZoomRotationTranslation(TMatrix2D mat,double dR,double dC,double alpha,double ratio)
{
  TMatrix2D matT;

  matT= Mat2D_createNull();
  Mat2D_makeHMatZoom(mat,ratio);
  Mat2D_makeHMatRotation(matT,alpha);
  Mat2D_product(mat,matT);
  Mat2D_makeHMatTranslation(matT,dR,dC);
  Mat2D_product(mat,matT);
  Mat2D_destroy(&matT);
}

void Mat2D_applyHMatTransformation(TMatrix2D mat,TMatrix2D matT)
{
  int       r,c;
  double    ar,ac,nr,nc,h;
  TMatrix2D matD;
  TMatrix2D matI;

  Mat2D_checkType(mat,MAT2D_FLOAT);
  matD= Mat2D_createFrom(mat);
  Mat2D_fillAllValue(matD,0.);

  matI= Mat2D_clone(matT);
  Mat2D_inverse(matI);

  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
    {
      ar= r-Mat2D_getnRows(mat)/2;
      ac= c-Mat2D_getnCols(mat)/2;

      h= Mat2D_getDataDouble(matI)[2][0]*ar+
         Mat2D_getDataDouble(matI)[2][1]*ac+
         Mat2D_getDataDouble(matI)[2][2];
      nr= (Mat2D_getDataDouble(matI)[0][0]*ar+
           Mat2D_getDataDouble(matI)[0][1]*ac+
           Mat2D_getDataDouble(matI)[0][2])/h;
      nc= (Mat2D_getDataDouble(matI)[1][0]*ar+
           Mat2D_getDataDouble(matI)[1][1]*ac+
           Mat2D_getDataDouble(matI)[1][2])/h;
      nr= nr+Mat2D_getnRows(mat)/2;
      nc= nc+Mat2D_getnCols(mat)/2;

      if ((nr>=0)&&(nr<=Mat2D_getnRows(mat)-1)
        &&(nc>=0)&&(nc<=Mat2D_getnCols(mat)-1))
        Mat2D_getDataFloat(matD)[r][c]= Mat2D_getDataFloat(mat)[(int)nr][(int)nc];
    }

  Mat2D_swapData(mat,matD);
  Mat2D_destroy(&matD);
  Mat2D_destroy(&matI);
}

void Mat2D_applyHMatTransformationHQ(TMatrix2D mat,TMatrix2D matT)
{
  int           r,c;
  double        ar,ac,nr,nc,h;
  TMatrix2D     matD;
  TMatrix2D     matI;
  float         p00,p10,p01,p11;
  double        vr,vc;

  Mat2D_checkType(mat,MAT2D_FLOAT);
  matD= Mat2D_createFrom(mat);
  Mat2D_fillAllValue(matD,0.);
  matI= Mat2D_clone(matT);
  Mat2D_inverse(matI);

  for (r= 0;r<Mat2D_getnRows(mat);r++)
    for (c= 0;c<Mat2D_getnCols(mat);c++)
    {
      ar= r-Mat2D_getnRows(mat)/2;
      ac= c-Mat2D_getnCols(mat)/2;

      h= Mat2D_getDataDouble(matI)[2][0]*ar+
         Mat2D_getDataDouble(matI)[2][1]*ac+
         Mat2D_getDataDouble(matI)[2][2];
      nr= (Mat2D_getDataDouble(matI)[0][0]*ar+
           Mat2D_getDataDouble(matI)[0][1]*ac+
           Mat2D_getDataDouble(matI)[0][2])/h;
      nc= (Mat2D_getDataDouble(matI)[1][0]*ar+
           Mat2D_getDataDouble(matI)[1][1]*ac+
           Mat2D_getDataDouble(matI)[1][2])/h;
      nr= nr+Mat2D_getnRows(mat)/2;
      nc= nc+Mat2D_getnCols(mat)/2;

      if ((floor(nr)<0)||(floor(nr)>=Mat2D_getnRows(mat))
        ||(floor(nc)<0)||(floor(nc)>=Mat2D_getnCols(mat)))
        p00= 0.;
      else
        p00= Mat2D_getDataFloat(mat)[(int)floor(nr)][(int)floor(nc)];
      if ((ceil(nr)<0)||(ceil(nr)>=Mat2D_getnRows(mat))
        ||(floor(nc)<0)||(floor(nc)>=Mat2D_getnCols(mat)))
        p10= 0.;
      else
        p10= Mat2D_getDataFloat(mat)[(int)ceil(nr)][(int)floor(nc)];
      if ((floor(nr)<0)||(floor(nr)>=Mat2D_getnRows(mat))
        ||(ceil(nc)<0)||(ceil(nc)>=Mat2D_getnCols(mat)))
        p01= 0.;
      else
        p01= Mat2D_getDataFloat(mat)[(int)floor(nr)][(int)ceil(nc)];
      if ((ceil(nr)<0)||(ceil(nr)>=Mat2D_getnRows(mat))
        ||(ceil(nc)<0)||(ceil(nc)>=Mat2D_getnCols(mat)))
        p11= 0.;
      else
        p11= Mat2D_getDataFloat(mat)[(int)ceil(nr)][(int)ceil(nc)];
      vr= nr-floor(nr);
      vc= nc-floor(nc);

      Mat2D_getDataFloat(matD)[r][c]= p00*(1-vr)*(1-vc)+
                                     p10*vr*(1-vc)+
                                     p01*(1-vr)*vc+
                                     p11*vr*vc;
    }

  Mat2D_swapData(mat,matD);
  Mat2D_destroy(&matD);
  Mat2D_destroy(&matI);
}

/* ===============================================================================
   Display a Matrix 
   =============================================================================== */
void Mat2D_display(TMatrix2D mat)
{
  int i,j;
  int nrows,ncols;

  nrows = Mat2D_getnRows(mat);
  ncols = Mat2D_getnCols(mat);

  for (i= 0;i<nrows;i++)
  {
    mexPrintf("[\t");
    for (j= 0;j<ncols;j++)
    {
      switch (Mat2D_getType(mat)) {
      case MAT2D_FLOAT:
	mexPrintf("%f\t",Mat2D_getDataFloat(mat)[i][j]);
	break;
      case MAT2D_DOUBLE:
	mexPrintf("%f\t",Mat2D_getDataDouble(mat)[i][j]);
	break;
      default: 
	Mat2D_error("Type non support�");
      }
    }
    mexPrintf("]\n");    
  }
}
