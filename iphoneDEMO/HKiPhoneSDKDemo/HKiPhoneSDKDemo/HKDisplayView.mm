//
//  HKDisplayView.m
//  oupailong
//
//  Created by hkmac on 15/1/27.
//  Copyright (c) 2015年 hk. All rights reserved.
//

#import "HKDisplayView.h"
#import "CocoaPCMPlayer.h"
#import "AudioRecordController.h"
#import "lm_yuv2rgb.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "DisplayManagerView.h"
#import "avrecord.h"

@interface HKDisplayView () <DisplayManagerViewDelegate>
{
        AudioRecordController _recordControl;//
        SystemSoundID cameraSoundID;//拍照声音

        unsigned int _recordTick;//录像tick
        
        struct {
                BOOL bNeedSnapShot;
                BOOL bNeedSnapAudio;
                BOOL bToAlbum;
                char filePath[1024];
        } _snapShotStruct;
        
        
        struct {
                BOOL bNeedRecord;
                BOOL bToAlbum;
                BOOL bWaitKeyFrame;
                AV_RECORD_CONTEXT *avRecordContext;
                int videoCodec;// 0: H264, 1: MPEG4, 2: MJPEG, 3:hkdvr, 4:H264_2
                uint32_t frameWidth;
                uint32_t frameHeight;
                uint32_t frameRate;
                char filePath[1024];
                char tempKeyFrameBuf[200 * 1024];
                int tempKeyFrameBufLength;
                
        } _recordStruct;
}
@property (nonatomic, strong) CocoaPCMPlayer *thePCMPlayer;//语音播放控制
@property (retain, nonatomic) DisplayManagerView *dispMan;

@property (nonatomic, strong) NSLock *snapShotLock;
@property (nonatomic, strong) NSLock *recordLock;
@end

@implementation HKDisplayView


/**
 *	@brief	说话到设备的回调函数
 *
 *	@param 	userData 	SurveillanceDevice *
 *	@param 	samplesBuffer 	音频数据，格式为PCM
 *	@param 	bufferSize 	音频大小
 */
static void recodeCallbackFunc(void *userData, uint8_t *samplesBuffer, uint32_t bufferSize)
{
        HKDisplayView *controller = (__bridge HKDisplayView *)userData;
        [controller sendSpeakerAudio:samplesBuffer bufferSize:bufferSize];
        //        device->talkTo(samplesBuffer, bufferSize);
        //        hk_AudioData((char *)samplesBuffer, bufferSize, 0);
}

- (void)initialize
{
        memset(&_snapShotStruct, 0, sizeof(_snapShotStruct));
        yuv2rgb_init();
        self.thePCMPlayer = [[CocoaPCMPlayer alloc] initWithFrameSize:8192 * 2];

        self.snapShotLock = [[NSLock alloc] init];
        
        [self hk_Speaker:true];

        
        self.dispMan = [[DisplayManagerView alloc] init];
        //                _dispMan.currentDisplay.bDrawRealSize = YES;
        [_dispMan exclusive:YES];//单个画面
        [_dispMan.currentDisplay setDrawBorder:NO];
        _dispMan.delegate = self;
        [_dispMan.currentDisplay startActivityView:YES];
        _dispMan.userInteractionEnabled = YES;
        [_dispMan.currentDisplay setRecordFlag:[UIImage imageNamed:@"record_flag"]];
        _dispMan.frame = self.bounds;
        
        [self addSubview:_dispMan];
}

- (id)initWithFrame:(CGRect)frame
{
        self = [super initWithFrame:frame];
        if (self) {
                [self initialize];
        }
        return self;
}

- (void)awakeFromNib
{
        [self initialize];
}

- (void)layoutSubviews
{
        [super layoutSubviews];
        
        _dispMan.frame = self.bounds;

}
- (void)dealloc
{
        [super dealloc];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

//打开手机扬声器
-(void) hk_Speaker:(bool)bOpen
{
        UInt32 route;
        OSStatus error;
        UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
        
        error = AudioSessionSetProperty (
                                         kAudioSessionProperty_AudioCategory,
                                         sizeof (sessionCategory),
                                         &sessionCategory
                                         );
        
        route = bOpen?kAudioSessionOverrideAudioRoute_Speaker:kAudioSessionOverrideAudioRoute_None;
        error = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(route), &route);
        
}

- (void)doSnapShotWithSnapPath:(char *)snapPath rgbData:(uint8_t *)rgb24 width:(uint32_t)width height:(uint32_t)height flip:(int)flip toAlbum:(BOOL)bAlbum Audio:(BOOL)bAudio
{
        int bitsPerComponent = 8;
        int bitsPerPixel = 24;
        int bytesPerRow = 3 * width;
        
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        
        CGBitmapInfo bmpInof = kCGBitmapByteOrderDefault;
        
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgb24, width * height * 3, NULL);
        
        CGImageRef imageRef =  CGImageCreate(width, height,
                                             bitsPerComponent,
                                             bitsPerPixel,
                                             bytesPerRow,
                                             colorSpaceRef,
                                             bmpInof,
                                             provider,
                                             NULL,
                                             NO,
                                             renderingIntent);
        /* For JPG
         0: UIImageOrientationDownMirrored
         1: UIImageOrientationUp
         2: UIImageOrientationDown
         3: UIImageOrientationUpMirrored
         */
        UIImage *bmpImage = nil;
        if (0 == flip) {
                bmpImage = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationDownMirrored];
        } else if (1 == flip) {
                bmpImage = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationUp];
        } else if (2 == flip) {
                bmpImage = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationDown];
        } else if (3 == flip) {
                bmpImage = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationUpMirrored];
        }
        if (bAlbum) {
                //将图片保存到相册
                NSData *outputData;
                outputData = UIImageJPEGRepresentation(bmpImage, 1.0);
                
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library writeImageDataToSavedPhotosAlbum:outputData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                        if (error && error.code == -3311) {
                                NSLog(@"保存照片失败: %@", error);
                                if ([_delegate respondsToSelector:@selector(snapShotFailed:)]) {
                                        [_delegate snapShotFailed:error];
                                }
                        }
                }];
//                [library release];
                
        }
        //保存图片到指定路径
        NSData *outputData = UIImageJPEGRepresentation(bmpImage, 1.0);
        [outputData writeToFile:[NSString stringWithUTF8String:snapPath] atomically:YES];
        
        NSLog(@"snapshot path: %s", snapPath);
        
        
        // Release Resource
        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        
        //抓拍快门声
        if (bAudio) {
                AudioServicesPlaySystemSound(cameraSoundID);
        }
}

- (void)displayVideo:(void *)video videoWidth:(uint32_t)videoWidth videoHeight:(uint32_t)videoHeight
{
        //fliptype  0正常   1水平   2垂直, 水平翻转时旋转控件，其他翻转旋转画面
        [_dispMan.currentDisplay displayVideo:video videoWidth:videoWidth videoHeight:videoHeight orientation:0 drawRecordFlag:NO];
        
        [_snapShotLock lock];
        if (_snapShotStruct.bNeedSnapShot) {
                //抓拍
                uint8_t *rgb24 = (uint8_t *)malloc(videoWidth * videoWidth * 3);
                BOOL captureSuccess = NO;
                if (NULL != rgb24) {
                        uint8_t *pYUV[3];
                        pYUV[0] = (uint8_t *)video;
                        pYUV[1] = pYUV[0] + videoWidth * videoHeight;
                        pYUV[2] = pYUV[1] + videoWidth * videoHeight / 4;
                        
                        yuv2rgb_convert(pYUV[0], pYUV[1], pYUV[2], rgb24, videoWidth, videoHeight);
                        
                        [self doSnapShotWithSnapPath:_snapShotStruct.filePath rgbData:rgb24 width:videoWidth height:videoHeight flip:0 toAlbum:_snapShotStruct.bToAlbum Audio:_snapShotStruct.bNeedSnapAudio];
                        
                        free(rgb24);
                        captureSuccess = YES;
                }
                memset(&_snapShotStruct, 0, sizeof(_snapShotStruct));
        }
        [_snapShotLock unlock];
}

- (void)sendSpeakerAudio:(uint8_t *)sampleBuffer bufferSize:(uint32_t)size
{
        if ([_delegate respondsToSelector:@selector(sendSpeakerAudio:length:)]) {
                [_delegate sendSpeakerAudio:sampleBuffer length:size];
        }
}

- (void)playListenAudio:(uint8_t *)audio length:(uint32_t)length
{
        [_thePCMPlayer feed:audio length:length];
}

- (BOOL)openAudioSpeaker:(BOOL)bOpen
{
        if (bOpen) {
                //开启麦克风
                return _recordControl.start(recodeCallbackFunc, (__bridge void *)self) >= 0;
        } else {
                //关闭麦克风
                _recordControl.stop();
                return YES;
        }
}

- (void)snapShotToPath:(NSString *)filePath withPhotoAlbum:(BOOL)bAlbum withAudio:(BOOL)bAudio
{
        [_snapShotLock lock];
        if (!_snapShotStruct.bNeedSnapShot) {
                memset(&_snapShotStruct, 0, sizeof(_snapShotStruct));
                _snapShotStruct.bNeedSnapShot = YES;
                _snapShotStruct.bToAlbum = bAlbum;
                if (filePath) {
                        strcpy(_snapShotStruct.filePath, filePath.UTF8String);
                }
                _snapShotStruct.bNeedSnapAudio = bAudio;
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if ([_snapShotLock tryLock]) {
                                if (_snapShotStruct.bNeedSnapShot && [filePath isEqualToString:[NSString stringWithUTF8String:_snapShotStruct.filePath]]) {
                                        NSLog(@"抓拍失败");
                                        memset(&_snapShotStruct, 0, sizeof(_snapShotStruct));
                                        if ([_delegate respondsToSelector:@selector(snapShotFailed:)]) {
                                                [_delegate snapShotFailed:[NSError errorWithDomain:@"抓拍失败" code:-1 userInfo:nil]];
                                        }
                                }
                                [_snapShotLock unlock];
                        }
                });
                
        }
        [_snapShotLock unlock];
}

/**
 *	@brief	写录像数据
 *
 *	@param 	data 	灵气
 *	@param 	length 	长度
 *	@param 	type 	I/P帧类型
 */
- (void)handleRecordData:(void *)data length:(unsigned int)length frametype:(int)type
{
        [_recordLock lock];
        NSLog(@"----------length %u, type %d", length, type);
        if (!_recordStruct.bNeedRecord) {
                [_recordLock unlock];
                return;
        }
        if (_recordStruct.bNeedRecord) {
                if (_recordStruct.bWaitKeyFrame && type == 2) {
                        _recordStruct.bWaitKeyFrame = NO;
                }
                
                if (_recordStruct.bWaitKeyFrame) {
                        NSLog(@"等待I帧");
                        [_recordLock unlock];
                        return;
                }
                
                Mov_Record_Write_Video((unsigned char *)data, (int)length, type == 2);
        }
        [_recordLock unlock];
        
}


/**
 *	@brief	开始录像
 *
 *	@param 	filePath 	文件路径
 *	@param 	bAlbum 	是否保存到相册 （暂时没有作用）
 *	@param 	videoCodec 	视频数据类型 // 0: H264, 1: MPEG4, 2: MJPEG, 3:hkdvr, 4:H264_2
 */

- (void)startRecordWithPath:(NSString *)filePath withPhotoAlbum:(BOOL)bAlbum videoCodec:(int)videoCodec;
{
        [_recordLock lock];
        if (!_recordStruct.bNeedRecord) {
                memset(_recordStruct.filePath, 0, sizeof(_recordStruct.filePath));
                strcpy(_recordStruct.filePath, filePath.UTF8String);
                _recordStruct.videoCodec = videoCodec;
                _recordStruct.bToAlbum = bAlbum;
                _recordStruct.bWaitKeyFrame = YES;
                _recordStruct.tempKeyFrameBufLength = 0;
                memset(_recordStruct.tempKeyFrameBuf, 0, sizeof(_recordStruct.tempKeyFrameBuf));
                _recordTick = 0;
                
                Mov_Record_Init(_recordStruct.frameWidth, _recordStruct.frameHeight, 15, 0);
                Mov_Record_Open(filePath.UTF8String);
                
                _recordStruct.bNeedRecord = YES;
                
        }
        [_recordLock unlock];
}

/**
 *	@brief	停止录像
 */
- (void)stopRecord
{
        [_recordLock lock];
        if (_recordStruct.bNeedRecord) {
                _recordStruct.bNeedRecord = NO;
                
                Mov_Record_Close();
                
        }
        [_recordLock unlock];
}


- (void)resetFrame
{
        _dispMan.frame = self.bounds;
}

#pragma mark - DisplayManagerViewDelegate
- (void)singleTapOnDisplay:(DisplayView *)display
{
        [_delegate singleTapOnHKDisplayView];
}

@end
