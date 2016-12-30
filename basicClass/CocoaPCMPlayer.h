//
//  CocoaPCMPlayer.h
//  CocoaPCMPlayer
//
//  Created by Zhou Jiexiong on 12-2-13.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioToolbox/AudioFormat.h>
#import <pthread.h>

#define AUDIO_BUFFER_COUNT 10

typedef struct
{
	//int readIndex;
        int writeIndex;
        int frameCount;
        pthread_mutex_t mutex;
        pthread_cond_t cond;
} AUDIO_BUFFER_INFO;

@interface CocoaPCMPlayer : NSObject {
        AudioQueueRef _audioQueue;
        AudioQueueBufferRef _queueBuffer[AUDIO_BUFFER_COUNT];
        AUDIO_BUFFER_INFO _bufferInfo;
        uint32_t _frameSize;
}

- (id)initWithFrameSize:(uint32_t)frameSize;
- (void)release;
- (void)setVolume:(uint32_t)volume;//0: 静音， 1～99：调节音量大小
- (double)getSoftVolume;//获取当前音量

- (void)feed:(uint8_t *)audio length:(uint32_t)length;
- (void)clear;

@end
