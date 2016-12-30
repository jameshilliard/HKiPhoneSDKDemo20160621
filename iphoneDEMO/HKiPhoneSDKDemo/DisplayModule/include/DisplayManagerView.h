//
//  DisplayManagerView.h
//  SurveillanceClient
//
//  Created by Zhou Jiexiong on 12-1-31.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "DisplayView.h"


typedef enum {
        // 标准显示布局
        //LayoutType_1x1, <==> 独占模式
        LayoutType_2x2 = 4,
        LayoutType_3x3 = 9,
        LayoutType_4x4 = 16,
        
        /* 优先显示单元位于整个区域 左上方
         * <LayoutType_A_B_C_D>
         * A: 优先显示单元 占总显示面积的比例
         * B: 优先显示单元右边区域 占总显示面积的比例
         * C: 优先显示单元底部区域 占总显示面积的比例
         * D: 优先显示单元对角区域 占总显示面积的比例
         */
        LayoutType_4_2_2_1 = 0x6,
        LayoutType_9_3_3_1 = 0x8,
        LayoutType_16_4_4_1 = 0xA,//10
        LayoutType_25_5_5_1 = 0xC,//12
        LayoutType_36_6_6_1 = 0xE,//14
        // 优先显示单元位于整个区域 右上方
        LayoutType_2_4_2_1 = 0x16,
        LayoutType_3_9_3_1 = 0x18,
        LayoutType_4_16_4_1 = 0x1A,
        LayoutType_5_25_5_1 = 0x1C,
        LayoutType_6_36_6_1 = 0x1E,
        // 优先显示单元位于整个区域 左下方
        LayoutType_2_1_4_2 = 0x26,
        LayoutType_3_1_9_3 = 0x28,
        LayoutType_4_1_16_4 = 0x2A,
        LayoutType_5_1_25_5 = 0x2C,
        LayoutType_6_1_36_6 = 0x2E,
        // 优先显示单元位于整个区域 右上方
        LayoutType_1_2_2_4 = 0x36,
        LayoutType_1_3_3_9 = 0x38,
        LayoutType_1_4_4_16 = 0x3A,
        LayoutType_1_5_5_25 = 0x3C,
        LayoutType_1_6_6_36 = 0x3E
} LayoutType;

typedef struct {
        CGRect frame;// 在同一显示布局下，该成员保持不变
        DisplayView *display;
} DisplayArea;

@protocol DisplayManagerViewDelegate <NSObject>
@optional
- (void)selectionChangedFromDisplay:(DisplayView *)fromDisplay 
                          toDisplay:(DisplayView *)toDisplay;
- (void)singleTapOnDisplay:(DisplayView *)display;
- (void)swipeOnDisplay:(DisplayView *)display direction:(NSInteger)direction;
- (void)didExclusive:(BOOL)isExclusive;
- (void)wantCloseVideo:(DisplayView *)display;
//- (void)didDoubleClickedDisplay:(DisplayView *)display FromExclusive:(BOOL)isExclusive;
- (BOOL)canExitExclusive;
@end

@interface DisplayManagerView : UIView <DisplayViewDelegate> {
        id<DisplayManagerViewDelegate> _delegate;
        UIPanGestureRecognizer *_panGestureRecognizer;
        
        // 以下两成员用于处理DisplayView的选中与反选中
	DisplayView *_currentDisplay;
        DisplayView *_previousDisplay;
        
	BOOL _isExclusive;

        DisplayArea *_displayArea;
        uint32_t _areaIndex;//用于更新显示单元坐标
        uint32_t _maxDisplayNum;//显示单元总数
        uint32_t _currentDisplayNum;//当前可见的显示单元数量
//        LayoutType _currentLayout;//当前显示布局
        
        uint32_t _blankIndex;//当前没放置DisplayView的位置索引
        DisplayView *_paningDisplay;//当前正在响应PAN操作的DisplayView
        CGPoint _paningPoint;
        
        // 在进行PAN等一些操作时，改变子视图尺寸，会导致父视图layoutSubviews函数的调用
        // 但除父视图改变的情况外，程序会自动处理各子视图的位置关系，而不是在该函数当中执行默
        // 认的处理，所以增加此成员变量用以区别上不同情况。
        CGSize _currentSize;
}

- (DisplayView *)displayAtIndex:(NSInteger)index;
- (DisplayView *)currentDisplay;//返回当前选中的DisplayView实例
- (void)setCurrentDisplay:(DisplayView *)display;
- (void)setCurrentDisplayAccrodingPoint:(CGPoint)point ofView:(UIView *)view;
- (void)setLayout:(LayoutType)layoutType;//设置显示布局
- (void)exclusive:(BOOL)flag;//使当前选中的DisplayView实例进入/退出独占模式

- (void)setLayoutIfNeeded;
- (void)restoreLayout;

@property (assign) id<DisplayManagerViewDelegate> delegate;
@property (assign) LayoutType currentLayout;
@end
