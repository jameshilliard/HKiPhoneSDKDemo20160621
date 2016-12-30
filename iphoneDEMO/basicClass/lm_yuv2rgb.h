/*
 * packed and tested by Peter.Xu @ 2009.8
 */
#ifndef	__LM_YUV2RGB_H__
#define	__LM_YUV2RGB_H__

#ifdef __cplusplus
extern "C" {
#endif

#pragma pack(push) //�������״̬ 
#pragma pack(2)//�趨Ϊ4�ֽڶ��� 

typedef struct _bitmapinfoheader{
	int biSize;
	int biWidth;
	int biHeight;
	short biPlanes;
	short biBitCount;
	int biCompression;
	int biSizeImage;
	int biXPelsPerMeter;
	int biYPelsPerMeter;
	int biClrUsed;
	int biClrImportant;
} bitmapinfoheader;

typedef struct _bitmapfileheader {
	short bfType;
	int bfSize;
	short bfReserved1;
	short bfReserved2;
	int bfOffBits;
} bitmapfileheader;

#pragma pack(pop)//�ָ�����״̬

// init the arrays for convertion
void yuv2rgb_init();
// doing the convert
int yuv2rgb_convert(unsigned char *src0,unsigned char *src1,
		unsigned char *src2, unsigned char *dst_ori, int width, int height);
// write to a file
int yuv2rgb_create_bmp_header(unsigned char *header, int xsize, int ysize);

#ifdef __cplusplus
}
#endif

#endif

