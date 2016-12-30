/*
 
 File: AQRecorder.mm
 Abstract: n/a
 Version: 2.4
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 
 */

#include "AQRecorder.h"

// ____________________________________________________________________________________
// AudioQueue callback function, called when an input buffers has been filled.
void AQRecorder::MyInputBufferHandler(	void *								inUserData,
                                      AudioQueueRef						inAQ,
                                      AudioQueueBufferRef					inBuffer,
                                      const AudioTimeStamp *				inStartTime,
                                      UInt32								inNumPackets,
                                      const AudioStreamPacketDescription*	inPacketDesc)
{
	AQRecorder *aqr = (AQRecorder *)inUserData;
        if (inNumPackets > 0) {
//                NSLog(@"...............%ld", inNumPackets * 2);
                aqr->handleSampledData((uint8_t *)inBuffer->mAudioData, 2 * inNumPackets);
        }
        
        // if we're not stopping, re-enqueue the buffe so that it gets filled again
        if (aqr->IsRunning()) {
                AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
        }
}

void AQRecorder::handleSampledData(uint8_t *samplesBuffer, uint32_t bufferSize)
{
        if (_listener) {
                _listener->onSampledData(samplesBuffer, bufferSize);
        }
}

AQRecorder::AQRecorder()
{
	mIsRunning = false;
	mRecordPacket = 0;
}

AQRecorder::~AQRecorder()
{
	AudioQueueDispose(mQueue, TRUE);
}

void AQRecorder::SetupAudioFormat(UInt32 inFormatID)
{
	memset(&mRecordFormat, 0, sizeof(mRecordFormat));
        
    mRecordFormat.mSampleRate = 8000;
    mRecordFormat.mChannelsPerFrame = 1;

	mRecordFormat.mFormatID = kAudioFormatLinearPCM;

        // if we want pcm, default to signed 16-bit little-endian
        mRecordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    mRecordFormat.mBitsPerChannel = 16;
        mRecordFormat.mBytesPerPacket = mRecordFormat.mBytesPerFrame = (mRecordFormat.mBitsPerChannel / 8) * mRecordFormat.mChannelsPerFrame;
    mRecordFormat.mFramesPerPacket = 1;
}

void AQRecorder::StartRecord(AQRecorderListener *listener)
{
        _listener = listener;
        
	int i, bufferByteSize;
        
        // specify the recording format
        SetupAudioFormat(kAudioFormatLinearPCM);
        
        AudioQueueNewInput(
                           &mRecordFormat,
                           MyInputBufferHandler,
                           this /* userData */,
                           NULL /* run loop */, NULL /* run loop mode */,
                           0 /* flags */, &mQueue);
        
        // get the record format back from the queue's audio converter --
        // the file may require a more specific stream description than was necessary to create the encoder.
        mRecordPacket = 0;
        
        // allocate and enqueue buffers
        //bufferByteSize = ComputeRecordBufferSize(&mRecordFormat, .5);	// enough bytes for half a second
        bufferByteSize = 640;// * 2;为G726的数据作铺垫
        for (i = 0; i < kNumberRecordBuffers; ++i) {
                AudioQueueAllocateBuffer(mQueue, bufferByteSize, &mBuffers[i]);
                AudioQueueEnqueueBuffer(mQueue, mBuffers[i], 0, NULL);
        }
        
        // start the queue
        mIsRunning = true;
        AudioQueueStart(mQueue, NULL);
}

void AQRecorder::StopRecord()
{
	// end recording
	mIsRunning = false;
        _listener = NULL;
        AudioQueueStop(mQueue, true);
	AudioQueueDispose(mQueue, true);

        for (int i = 0; i < kNumberRecordBuffers; ++i) {
                AudioQueueFreeBuffer(mQueue, mBuffers[i]);
        }
}
