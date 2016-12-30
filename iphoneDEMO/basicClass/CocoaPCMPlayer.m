//
//  CocoaPCMPlayer.m
//  CocoaPCMPlayer
//
//  Created by Zhou Jiexiong on 12-2-13.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "CocoaPCMPlayer.h"

static void audioOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
        AUDIO_BUFFER_INFO *bufferInfo = (AUDIO_BUFFER_INFO *)inUserData;
        
        pthread_mutex_lock(&bufferInfo->mutex);
        
        --bufferInfo->frameCount;
        
        if (AUDIO_BUFFER_COUNT - 2 == bufferInfo->frameCount) {
                // 若条件成立，则说明feed函数调用线程已经阻塞，激活它
                pthread_cond_signal(&bufferInfo->cond);
        } else if (0 == bufferInfo->frameCount) {
                // 如果缓冲区里面已经没有有效的数据，则暂停AUDIO QUEUE
                printf("audio queue empty... PAUSE\n");
                AudioQueuePause(inAQ);
        }
        
        pthread_mutex_unlock(&bufferInfo->mutex);
}

@implementation CocoaPCMPlayer

- (id)initWithFrameSize:(uint32_t)frameSize; {
        self = [super init];
        if (self) {
                _frameSize = frameSize;
                //_bufferInfo.readIndex = 0;
                _bufferInfo.writeIndex = 0;
                _bufferInfo.frameCount = 0;
                pthread_mutex_init(&_bufferInfo.mutex, NULL);
                pthread_cond_init(&_bufferInfo.cond, NULL);
                
                AudioStreamBasicDescription format = {0};
                format.mSampleRate = 8000;
                format.mFormatID = kAudioFormatLinearPCM;
                format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
                format.mFramesPerPacket = 1;
                format.mChannelsPerFrame = 1;
                format.mBitsPerChannel = 16;
                format.mBytesPerFrame = 2;
                format.mBytesPerPacket = 2;
                
                OSStatus result;
                result = AudioQueueNewOutput(&format, audioOutputCallback, &_bufferInfo, CFRunLoopGetCurrent(),
                                             kCFRunLoopCommonModes, 0, &_audioQueue);
                if(0 != result) {
                        [super release];
                        return nil;
                }
                
                for(int i=0; i<AUDIO_BUFFER_COUNT; i++) {
                        result = AudioQueueAllocateBuffer(_audioQueue, frameSize, &_queueBuffer[i]);
                        if (0 != result) {
                                for (int j=0; j<i; j++) {
                                        AudioQueueFreeBuffer(_audioQueue, _queueBuffer[j]);
                                }
                                
                                AudioQueueDispose(_audioQueue, true);
                                [super release];
                                return nil;
                        }
                        _queueBuffer[i]->mAudioDataByteSize = frameSize;
                }
        }
        
        return self;
}

- (void)release {
        //NSLog(@"cocoa pcm player is dealloced.");
        AudioQueueStop(_audioQueue, true);
        
        for (int i=0; i<AUDIO_BUFFER_COUNT; i++) {
                AudioQueueFreeBuffer(_audioQueue, _queueBuffer[i]);
        }
        
        AudioQueueDispose(_audioQueue, true);
        
        pthread_mutex_destroy(&_bufferInfo.mutex);
        pthread_cond_destroy(&_bufferInfo.cond);
        
        [super release];
}

- (void)setVolume:(uint32_t)volume {
        double v = (double)volume / 99.0;
        if (v > 1.0) v = 1.0;
        if (v < 0.) v = 0.;
        
        AudioQueueSetParameter(_audioQueue,
                               kAudioQueueParam_Volume,
                               v);
}

- (double)getSoftVolume
{
        AudioQueueParameterValue outValue;
        AudioQueueGetParameter(_audioQueue, kAudioQueueParam_Volume, &outValue);
        return outValue;
}

- (void)feed:(uint8_t *)audio length:(uint32_t)length {
        pthread_mutex_lock(&_bufferInfo.mutex);
        
        if (0 == _bufferInfo.frameCount) {
                AudioQueueStart(_audioQueue, NULL);
        }
        
        // 如果缓冲区已经存在(AUDIO_BUFFER_COUNT - 1)未读帧
        // 说明缓冲区可写空间已满（包含正在被audio queue读取的一帧）
        //while (AUDIO_BUFFER_COUNT - 1 == _bufferInfo.frameCount) {
        if (AUDIO_BUFFER_COUNT - 1 == _bufferInfo.frameCount) {
                /*
                 printf("pre wait: _bufferInfo.frameCount == AUDIO_BUFFER_COUNT\n");
                 pthread_cond_wait(&_bufferInfo.cond, &_bufferInfo.mutex);
                 printf("post wait: _bufferInfo.frameCount == AUDIO_BUFFER_COUNT\n");
                 */
                pthread_mutex_unlock(&_bufferInfo.mutex);
                return;
        }
        
        // 将当前帧写进缓冲区
        memcpy(_queueBuffer[_bufferInfo.writeIndex]->mAudioData, audio, _frameSize);
        _queueBuffer[_bufferInfo.writeIndex]->mAudioDataByteSize = length;
        AudioQueueEnqueueBuffer(_audioQueue, _queueBuffer[_bufferInfo.writeIndex], 0, NULL);
        
        // 更新写索引
        _bufferInfo.writeIndex = ++_bufferInfo.writeIndex % AUDIO_BUFFER_COUNT;
        
        // 更新帧计数
        ++_bufferInfo.frameCount;
        
        pthread_mutex_unlock(&_bufferInfo.mutex);
}

- (void)clear {
        pthread_mutex_lock(&_bufferInfo.mutex);
        _bufferInfo.frameCount = 0;
        _bufferInfo.writeIndex = 0;
        pthread_mutex_unlock(&_bufferInfo.mutex);
        
        //AudioQueueFlush(_audioQueue);
}

@end
