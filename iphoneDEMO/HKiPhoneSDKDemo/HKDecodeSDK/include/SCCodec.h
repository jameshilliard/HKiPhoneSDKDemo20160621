#ifndef _SC_CODEC_H_
#define _SC_CODEC_H_

#include <stdint.h>

/*
 * videoEncoder
 */

typedef struct {
	uint32_t reserved;
} VideoEncoderCreateParam;

typedef struct {
	uint32_t reserved;
} VideoEncodeParam;

class VideoEncoder
{
public:
	virtual ~VideoEncoder() {}
	virtual int encode(VideoEncodeParam *encodeParam) = 0;
};

/*
 * VideoDecoder
 */

typedef enum {
	VideoDecoderBitstreamTypeUnknown,
	VideoDecoderBitstreamTypeOpenCoreH264,//只支持YUV420输出格式
	VideoDecoderBitstreamTypeH264,//FFMPEG
	VideoDecoderBitstreamTypeMPEG4,
	VideoDecoderBitstreamTypeMJPEG,
	VideoDecoderBitstreamTypeMJPEGB,
} VideoDecoderBitstreamType;

typedef enum {
	VideoDecoderOutputFormatTypeYUV420P,
	VideoDecoderOutputFormatTypeYUYV422,
	VideoDecoderOutputFormatTypeRGB565,
	VideoDecoderOutputFormatTypeBGR565,
	VideoDecoderOutputFormatTypeRGB24,
	VideoDecoderOutputFormatTypeBGR24,
	VideoDecoderOutputFormatTypeARGB,
	VideoDecoderOutputFormatTypeRGBA,
	VideoDecoderOutputFormatTypeABGR,
	VideoDecoderOutputFormatTypeBGRA
} VideoDecoderOutputFormatType;

typedef struct {
	VideoDecoderBitstreamType bitstreamType;
	VideoDecoderOutputFormatType outputFormatType;
	uint32_t frameWidth;
	uint32_t frameHeight;
	uint32_t frameRate;
} VideoDecoderCreateParam;

typedef struct {
	uint8_t *bitstream;
	uint32_t bitstreamLength;
	uint8_t *frameBuffer;
	uint32_t bufferSize;	// [IN/OUT]
	uint32_t frameWidth;	// [OUT]
	uint32_t frameHeight;	// [OUT]
	uint32_t decodedLength;	// [OUT]
} VideoDecodeParam;

class VideoDecoder
{
public:
	virtual ~VideoDecoder() {};
	virtual int decode(VideoDecodeParam *decodeParam) = 0;
	virtual int frameWidth() { return 0; }
	virtual int frameHeight() { return 0; }
};

/*
 * AudioEncoder
 */

typedef enum {
	AudioEncoderBitstreamTypeUnknown,
	AudioEncoderBitstreamTypeAAC,
	AudioEncoderBitstreamTypeG711a,
	AudioEncoderBitstreamTypeG711u,
	AudioEncoderBitstreamTypeADPCM_G726,
} AudioEncoderBitstreamType;

typedef struct {
	AudioEncoderBitstreamType bitstreamType;
	uint32_t sampleRate;
	uint32_t channels;
	uint32_t bitRate;
	uint32_t frameSize;
} AudioEncoderCreateParam;

typedef struct {
	uint8_t *frameBuffer;
	uint32_t bufferSize;
	uint8_t *bitstream;
	uint32_t bitstreamLength;
} AudioEncodeParam;

class AudioEncoder
{
public:
	virtual ~AudioEncoder() {};
	virtual int encode(AudioEncodeParam *encodeParam) = 0;
};

/*
 * AudioDecoder
 */

typedef enum {
	AudioDecoderBitstreamTypeUnknown,
	AudioDecoderBitstreamTypeAAC,
	AudioDecoderBitstreamTypeG711a,
	AudioDecoderBitstreamTypeG711u,
//	AudioDecoderBitstreamTypeADPCM_DVI4,
//	AudioDecoderBitstreamTypeADPCM_IMA_WAV,
	AudioDecoderBitstreamTypeADPCM_G726,
} AudioDecoderBitstreamType;

typedef struct {
	AudioDecoderBitstreamType bitstreamType;
	uint32_t channels;
	uint32_t sampleRate;
	uint32_t sampleSize;
	uint32_t bitRate;
} AudioDecoderCreateParam;

typedef struct {
	uint8_t *bitstream;
	uint32_t bitstreamLength;
	uint8_t *frameBuffer;
	uint32_t bufferSize;
} AudioDecodeParam;

class AudioDecoder
{
public:
	virtual ~AudioDecoder() {}
	virtual int decode(AudioDecodeParam *decodeParam) = 0;
};

/*
 * SCCodecFactory
 */

class SCCodecFactory
{
public:
	static SCCodecFactory *factory();
	VideoEncoder *create(VideoEncoderCreateParam *createParam);
	VideoDecoder *create(VideoDecoderCreateParam *createParam);
	AudioEncoder *create(AudioEncoderCreateParam *createParam);
	AudioDecoder *create(AudioDecoderCreateParam *createParam);

private:
	SCCodecFactory() {}
	~SCCodecFactory() {}
	static SCCodecFactory *_factory;
};

#endif//_SC_CODEC_H_
