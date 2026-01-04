#ifndef _DISPLAY_CONSTS_H_
#define _DISPLAY_CONSTS_H_

static const int kScanConvert[192] = {
   0,8,16,24,32,40,48,56,
   1,9,17,25,33,41,49,57,
   2,10,18,26,34,42,50,58,
   3,11,19,27,35,43,51,59,
   4,12,20,28,36,44,52,60,
   5,13,21,29,37,45,53,61,
   6,14,22,30,38,46,54,62,
   7,15,23,31,39,47,55,63,

   64,72,80,88,96,104,112,120,
   65,73,81,89,97,105,113,121,
   66,74,82,90,98,106,114,122,
   67,75,83,91,99,107,115,123,
   68,76,84,92,100,108,116,124,
   69,77,85,93,101,109,117,125,
   70,78,86,94,102,110,118,126,
   71,79,87,95,103,111,119,127,

   128,136,144,152,160,168,176,184,
   129,137,145,153,161,169,177,185,
   130,138,146,154,162,170,178,186,
   131,139,147,155,163,171,179,187,
   132,140,148,156,164,172,180,188,
   133,141,149,157,165,173,181,189,
   134,142,150,158,166,174,182,190,
   135,143,151,159,167,175,183,191
};

static const unsigned int KVideoColorPalleteHILO[8][2] = {
{ 0X0, 0X0 },
{ 0X0000FF, 0X0000D8 },
{ 0XFF0000, 0XD80000 },
{ 0XFF00FF, 0XD800D8 },
{ 0X00FF00, 0X00D800 },
{ 0X00FFFF, 0X00D8D8 },
{ 0XFFFF00, 0XD8D800 },
{ 0XFFFFFF, 0XD8D8D8 }
};

static const int kDisplayBufferResolutionX = 256;
static const int kDisplayBufferResolutionY = 192;
static const int kDisplayResolutionX = 352;
static const int kDisplayResolutionY = 288;

static const int kWindowWidth = 1024;
static const int kWindowHeight = 768;
static const int BRIGHT_MODE = 0;
static const int OPAQUE_MODE = 1;


#endif