//
//  VideoRenderer.h
//
//  Created by Jiexiong Zhou on 12-7-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#ifndef _VIDEO_RENDERER_H_
#define _VIDEO_RENDERER_H_

#include <pthread.h>

typedef struct {
        void *video;
        uint32_t videoWidth;
        uint32_t videoHeight;
        int orientation;
        bool isRenderVideo;
} VideoRenderParam;

class VideoRenderer
{
public:
        // 根据当前运行的系统平台及其硬件特性，创建最优的VideoRender实例
        static VideoRenderer *create();
        // 创建基于OpenGL通用版本的VideoRender实例
        static VideoRenderer *createOpenGL();
        // 创建基于OpenGL ES1的VideoRender实例
        static VideoRenderer *createOpenGLES1();
        // 创建基于OpenGL ES2的VideoRender实例
        static VideoRenderer *createOpenGLES2();
        virtual ~VideoRenderer();
        virtual void resize(void *opaque) = 0;
        virtual void render(VideoRenderParam *param) = 0;
        
protected:
        virtual int initialize() = 0;
        VideoRenderer(void *context);
        void lockContext();
        void unlockContext();
        
protected:
        void *_context;
        
private:
        pthread_mutex_t _contextMutex;
};

#endif
