#ifndef _AVRECORD_H_
#define _AVRECORD_H_

//#ifdef __linux
#include "avcodec.h"
#include "swscale.h"
#include "avformat.h"

//#else
//#include "avcodec.h"
//#endif

#ifdef __cplusplus
extern "C"
{
#endif

#define FORMAT_MOV					0
#define FORMAT_3GP					1
#define FORMAT_AVI					2
#define FORMAT_ERROR				3

typedef enum _VIDEO_CODEC
        {
                MJPG,
                H264,
                MP4S
        }VIDEO_CODEC;
        
        typedef enum _AUDIO_CODEC
        {
                PCM,
                ADPCM,
        }AUDIO_CODEC;
        
        typedef struct _AUDIO_CHUNK
        {
                unsigned int tick;
                uint8_t *data;
                int len;
                int sample;
                int index;
                AUDIO_CODEC codec;

        }AUDIO_CHUNK;
        
        typedef struct _VIDEO_FRAME
        {
                VIDEO_CODEC codec;
                unsigned char *data;
                unsigned int len;
                unsigned short keyframe;
                unsigned int tick;
                short resolution;
        }VIDEO_FRAME;

typedef struct tagAVRecordContext
{
	AVFormatContext *oc;
    
	AVStream *audio_st, *video_st;
	
	int is_video_first;
	
	unsigned int first_tick;
	unsigned int video_tick;
	unsigned int audio_tick;
	int first_video;

	unsigned int format;
	
	int video;
	VIDEO_CODEC v_codec;
	unsigned long width;
	unsigned long height;
	unsigned long bitrate;

	int audio;

	//CRITICAL_SECTION critical_section;
    
    //Howard 2013-12-26 +++
    int avc_extradata_len;
    void* avc_extradata;
    int check_avc_extradata;
    
} AV_RECORD_CONTEXT;

void init_av_record_lib();

//	0 ok, < 0 failed
int init_av_record(AV_RECORD_CONTEXT * c, unsigned int format);

//	0 ok, < 0 failed
int add_av_record_video_stream(AV_RECORD_CONTEXT * c, VIDEO_CODEC codec, unsigned long width, unsigned long height, unsigned long bitrate);

//	0 ok, < 0 failed
int add_av_record_audio_stream(AV_RECORD_CONTEXT * c);

//	0 ok, < 0 failed; is_video_first: is video frame as the first frame of file
int open_av_record(AV_RECORD_CONTEXT * c, const char * filename, int is_video_first);

//	0 ok, < 0 failed, 1 should end record
int write_av_record_video(AV_RECORD_CONTEXT * c, VIDEO_FRAME * frame);

//	0 ok, < 0 failed, 1 should end record
int write_av_record_audio(AV_RECORD_CONTEXT * c, AUDIO_CHUNK * chunk);
void close_av_record(AV_RECORD_CONTEXT * c);

#ifdef __cplusplus
}
#endif

#endif
