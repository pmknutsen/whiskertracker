/***********************************************************
 * Matrix2D (version 1.0)                                  *
 * ******************************************************* *
 * Copyright 2002 P. Lacroix                               *
 *  All Rights Reserved                                    *
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

#ifndef _MATRIX2D_
#define _MATRIX2D_

#ifdef __cplusplus
  extern "C" {
#endif

#ifndef PI
#define PI 3.1415
#endif

typedef enum
{
  MAT2D_CHAR=1,
  MAT2D_SHORT,
  MAT2D_LONG,
  MAT2D_FLOAT,
  MAT2D_DOUBLE
} TMatrix2DType;

struct _TMatrix2D
{
  TMatrix2DType type;
  int           nRows;
  int           nCols;
  char          isSub;
  void        **data;
};

typedef struct _TMatrix2D *TMatrix2D;

#define MAT2D_MAXSIZEELEMENT sizeof(double)

#define Mat2D_getnRows(mat) ((mat)->nRows)
#define Mat2D_getnCols(mat) ((mat)->nCols)
#define Mat2D_getType(mat) ((mat)->type)
#define Mat2D_getData(mat) ((mat)->data)
#define Mat2D_getAllData(mat) ((mat)->data[0])

#define Mat2D_getDataChar(mat)   ((unsigned char **)(mat)->data)
#define Mat2D_getDataShort(mat)  ((short **)(mat)->data)
#define Mat2D_getDataLong(mat)   ((long **)(mat)->data)
#define Mat2D_getDataFloat(mat)  ((float **)(mat)->data)
#define Mat2D_getDataDouble(mat) ((double **)(mat)->data)

extern char   Mat2D_charValue;
extern short  Mat2D_shortValue;
extern long   Mat2D_longValue;
extern float  Mat2D_floatValue;
extern double Mat2D_doubleValue;

extern void (*Mat2D_error)(char *);

/* Elementary operations */
TMatrix2D     Mat2D_create(int nRows,int nCols,TMatrix2DType type);
TMatrix2D     Mat2D_createNull(void);
TMatrix2D     Mat2D_createFrom(TMatrix2D mat);
TMatrix2D     Mat2D_createSub(TMatrix2D mat,int rOrg,int cOrg,int nRows,int nCols);
void          Mat2D_destroy(TMatrix2D *mat);
TMatrix2D     Mat2D_clone(TMatrix2D mat);
void          Mat2D_resize(TMatrix2D mat,int nRows,int nCols);
void          Mat2D_changeType(TMatrix2D mat,TMatrix2DType newType);
void          Mat2D_convertType(TMatrix2D mat,TMatrix2DType newType);
void          Mat2D_resizeAndChangeType(TMatrix2D mat,int nRows,int nCols,TMatrix2DType newType);
int           Mat2D_getElementSize(TMatrix2D mat);
void          Mat2D_checkType(TMatrix2D mat,TMatrix2DType type);

/* Filling operations */
void          Mat2D_fillAll(TMatrix2D mat);
void          Mat2D_fillAllValue(TMatrix2D mat,double v);
void          Mat2D_fill(TMatrix2D mat,int rMin,int cMin,int rMax,int cMax);
void          Mat2D_fillValue(TMatrix2D mat,int rMin,int cMin,int rMax,int cMax,double v);
void          Mat2D_clip(TMatrix2D mat,int rMin,int cMin,int rMax,int cMax);

/* Math operations */
void          Mat2D_transpose(TMatrix2D mat);
double        Mat2D_determinant(TMatrix2D mat);
double        Mat2D_trace(TMatrix2D mat);
void          Mat2D_inverse(TMatrix2D mat);
void          Mat2D_add(TMatrix2D mat1,TMatrix2D mat2);
void          Mat2D_product(TMatrix2D mat1,TMatrix2D mat2);
void          Mat2D_rotate90(TMatrix2D mat);
void          Mat2D_rotate270(TMatrix2D mat);
void          Mat2D_rotate180(TMatrix2D mat);
void          Mat2D_addAllValue(TMatrix2D mat,double v);
void          Mat2D_subFromAllValue(TMatrix2D mat,double v);
void          Mat2D_mulAllMat(TMatrix2D mat1,TMatrix2D mat2);
void          Mat2D_mulAllValue(TMatrix2D mat,double v);
void          Mat2D_invAllValue(TMatrix2D mat);
void          Mat2D_normalizeValue(TMatrix2D mat,double vMin,double vMax);
void          Mat2D_minmaxValue(TMatrix2D mat,double vMin,double vMax);
double        Mat2D_findMinFloat(TMatrix2D mat);
double        Mat2D_findMaxFloat(TMatrix2D mat);
void          Mat2D_convolve(TMatrix2D mat,TMatrix2D matC);
void          Mat2D_gradientModule(TMatrix2D matMod,TMatrix2D mat,TMatrix2D matConv);

/* Geometric Transformations */
void          Mat2D_makeHMatTranslation(TMatrix2D mat,double dR,double dC);
void          Mat2D_makeHMatRotation(TMatrix2D mat,double alpha);
void          Mat2D_makeHMatZoom(TMatrix2D mat,double ratio);
void          Mat2D_makeHMatZoomRotationTranslation(TMatrix2D mat,double dR,double dC,double alpha,double ratio);
void          Mat2D_applyHMatTransformation(TMatrix2D mat,TMatrix2D matT);
void          Mat2D_applyHMatTransformationHQ(TMatrix2D mat,TMatrix2D matT);

/* File Operations */
void          Mat2D_loadFromMat(TMatrix2D mat,char *fileName);
void          Mat2D_saveToMat(TMatrix2D mat,char *fileName);

/* Image File Operations */
void          Mat2D_loadRGBFromPNM(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName);
void          Mat2D_loadGrayFromPNM(TMatrix2D mat,char *fileName);
void          Mat2D_saveRGBToPNM(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName);
void          Mat2D_saveGrayToPNM(TMatrix2D mat,char *fileName);

void          Mat2D_loadRGBFromTGA(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName);
void          Mat2D_saveRGBToTGA(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName);
void          Mat2D_loadGrayFromTGA(TMatrix2D mat,char *fileName);

void          Mat2D_loadGrayFromGraphicFile(TMatrix2D mat,char *fileName);
void          Mat2D_loadRGBFromGraphicFile(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName);
void          Mat2D_saveRGBToGraphicFile(TMatrix2D matR,TMatrix2D matG,TMatrix2D matB,char *fileName);

void          Mat2D_applyLUTChar(TMatrix2D mat,char lut[256]);

void          Mat2D_gaussianBlur(TMatrix2D mat,int ray);

/* Other operations */
void          Mat2D_binarizeChar(TMatrix2D mat,unsigned char treshold,unsigned char vLow,unsigned char vHigh);

/* Added by Dori */
void Mat2D_display(TMatrix2D mat);

#ifdef __cplusplus
  }
#endif

#endif
