//
//  AudioRecordController.h
//  iMon
//
//  Created by Jiexiong Zhou on 12-6-30.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#ifndef iMon_AudioRecordController_h
#define iMon_AudioRecordController_h

#include "AQRecorder.h"

typedef void (*RecodeCallbackFunc)(void *userData, uint8_t *samplesBuffer, uint32_t bufferSize);

class AudioRecordController : public AQRecorderListener
{
public:
        virtual void onSampledData(uint8_t *samplesBuffer, uint32_t bufferSize) {
                 printf("onSampledData...bufferSize: %d\n", bufferSize);
//                if (bufferSize != 1280) {
//                        return;
//                }
                _func(_userData, samplesBuffer, bufferSize);
        }
        
        AudioRecordController() {
                _recorder = NULL;
        }
        
        int start(RecodeCallbackFunc func, void *userData) {
                _recorder = new AQRecorder;
                if (NULL == _recorder) {
                        return -1;
                }
                
                _func = func;
                _userData = userData;
                _recorder->StartRecord(this);
                return 0;
        }
        
        void stop() {
                if (NULL != _recorder) {
                        _recorder->StopRecord();
                        delete _recorder;
                        _recorder = NULL;
                        _userData = NULL;
                }
        }
        
private:
        AQRecorder *_recorder;
        RecodeCallbackFunc _func;
        void *_userData;
};

#endif
