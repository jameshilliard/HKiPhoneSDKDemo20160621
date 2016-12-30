//
//  DisplayView.h
//  SurveillanceClient
//
//  Created by Jiexiong Zhou on 12-4-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef __cplusplus
#include "VideoRenderer.h"
#endif

#define IS_SINGLE_PLAY_MODE     YES

@class DisplayView;

@protocol DisplayViewDelegate <NSObject>

@optional
- (void)displayView:(DisplayView *)displayView tapCount:(NSInteger)tapCount;
- (void)displayView:(DisplayView *)displayView swipeDirection:(NSInteger)swipeDirection;
- (void)displayViewWantCloseVideo:(DisplayView *)displayView;
@end

@interface VideoView : UIView
@end

@interface DisplayView : UIView {
        id<DisplayViewDelegate> _delegate;
        void *_userData;
        BOOL _isDrawBorder;
        BOOL _isSelected;
        
#ifdef __cplusplus
        VideoRenderer *_videoRenderer;
#endif
        VideoView *_videoView;
        
        UILabel *_infoLabel;
        
        UIImageView *_recordFlag;
        UIImageView *_ImgUp;
        UIImageView *_ImgDown;
        UIImageView *_ImgRight;
        UIImageView *_ImgLeft;
        CGRect      _orgBounds;
        CGPoint     _frameCenter;
        
        UISwipeGestureRecognizer *_singleFingerSwipeUp;
        UISwipeGestureRecognizer *_singleFingerSwipeDown;
        UISwipeGestureRecognizer *_singleFingerSwipeLeft;
        UISwipeGestureRecognizer *_singleFingerSwipeRight;
        
        UIPanGestureRecognizer *_singleTapRecognizer;
        CGPoint     _beginPoint;
        CGPoint     _beginCenter;
        int _recognizerType;//1为UISwipeGestureRecognizer，2为UITapGestureRecognizer
        UIActivityIndicatorView *_activityView;
}

@property (assign) id<DisplayViewDelegate> delegate;
@property (assign) void *userData;
@property (assign) BOOL isExclusive;
@property (assign) unsigned int channelNum;
@property (assign, readonly) BOOL isDrawVideo;
@property (assign) BOOL bDrawRealSize;

+ (void)setStopDrawing:(BOOL)flag;

- (void)displayVideo:(void *)video 
          videoWidth:(uint32_t)videoWidth 
         videoHeight:(uint32_t)videoHeight 
         orientation:(int)orientation 
      drawRecordFlag:(BOOL)drawRecordFlag;

- (void)setSelected:(BOOL)isSelected;
- (void)setDrawBorder:(BOOL)isDrawBorder;
- (void)clear;

- (void)setInfoLabel:(NSString *)info;
- (void)setViewFrame:(CGRect)frame;

- (void)setRecordFlag:(UIImage *)image;

- (void)setPTZImgUp:(UIImage *)image;
- (void)setPTZImgDown:(UIImage *)image;
- (void)setPTZImgRight:(UIImage *)image;
- (void)setPTZImgLeft:(UIImage *)image;
- (void)showPTZImg:(int)dt isShow:(BOOL)isShow;

- (void)showRecordFlag:(BOOL)isShow;
- (void)resetFrame;
- (void)startActivityView:(BOOL)isStart;
- (void)hidenCloseButton:(BOOL)close;
@end
