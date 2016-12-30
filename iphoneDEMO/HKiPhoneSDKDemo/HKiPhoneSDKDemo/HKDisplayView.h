//
//  HKDisplayView.h
//  oupailong
//
//  Created by hkmac on 15/1/27.
//  Copyright (c) 2015年 hk. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HKDisplayViewDelegate <NSObject>

- (void)sendSpeakerAudio:(uint8_t *)audio length:(uint32_t)length;
- (void)snapShotFailed:(NSError *)error;
- (void)singleTapOnHKDisplayView;

@end

@interface HKDisplayView : UIView

@property (nonatomic, assign) id<HKDisplayViewDelegate> delegate;

- (void)handleRecordData:(void *)data length:(unsigned int)length frametype:(int)type;

- (void)displayVideo:(void *)video videoWidth:(uint32_t)videoWidth videoHeight:(uint32_t)videoHeight;

- (void)playListenAudio:(uint8_t *)audio length:(uint32_t)length;

- (BOOL)openAudioSpeaker:(BOOL)bOpen;

- (void)snapShotToPath:(NSString *)filePath withPhotoAlbum:(BOOL)bAlbum withAudio:(BOOL)bAudio;

- (void)startRecordWithPath:(NSString *)filePath withPhotoAlbum:(BOOL)bAlbum videoCodec:(int)videoCodec;

- (void)stopRecord;

- (void)resetFrame;
@end
