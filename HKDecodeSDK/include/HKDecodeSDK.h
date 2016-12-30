//
//  HKDecodeSDK.h
//  HKReiFu
//
//  Created by hkmac on 14-9-10.
//  Copyright (c) 2014年 HeKai. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "HKDataHandle.h"
#import "HKDecodeGlobal.h"
#import "hkipc.h"


@class HKDecodeSDK;

@protocol HKDecodeSDKDelegate <NSObject>

@optional
/**
 *	@brief	录像数据返回接口，请不要阻塞该接口。
 *
 *	@param 	sdk 	HKDecodeSDK指针，这个代理的发送者
 *	@param 	data 	录像数据信息
 */
- (void)DecodeSDK:(HKDecodeSDK *)sdk recordDataCallback:(const SCC_MideData *)data;

/**
 *	@brief	解码后的视频数据返回
 *
 *	@param 	decode 	HKDecodeSDK指针，这个代理的发送者
 *	@param 	callid 	设备的callID
 *	@param 	frameDesc 	解码后的视频数据
 */
- (void)DecodeSDK:(HKDecodeSDK *)sdk CallID:(NSString *)callid decodedMediaData:(RENDER_FRAME_DESC *)frameDesc;

/**
 *	@brief	解码后的音频数据回调
 *
 *	@param 	decode 	HKDecodeSDK指针，这个代理的发送者
 *	@param 	frameDesc 	解码后的音频数据
 */
- (void)DecodeSDK:(HKDecodeSDK *)sdk decodedAudioData:(RENDER_FRAME_DESC *)frameDesc;

/**
 *	@brief	SD卡回放，未解码的视频数据，用于存录像
 *
 *	@param 	sdk 	HKDecodeSDK指针，这个代理的发送者
 *	@param 	data 	未解码的SD卡视频数据
 */
- (void)DecodeSDK:(HKDecodeSDK *)sdk SDRecordDataCallback:(const SCC_MideData *)data;

/**
 *	@brief	SD卡回放，解码后的视频数据
 *
 *	@param 	sdk 	HKDecodeSDK指针，这个代理的发送者
 *	@param 	frameDesc 	解码后的SD卡视频数据
 */
- (void)DecodeSDK:(HKDecodeSDK *)sdk SDDecodedMediaData:(RENDER_FRAME_DESC *)frameDesc;

- (void)DecodeSDK:(HKDecodeSDK *)sdk SDRecordDataCallback:(uint8_t *)pDataBuf size:(int)iSize frameType:(int)iType;

/**
 *	@brief	SD卡播放结束
 *
 *	@param 	sdk 	HKDecodeSDK指针，这个代理的发送者
 */
- (void)DecodeSDKSDMediaPlayEnd:(HKDecodeSDK *)sdk;

@end

@interface HKDecodeSDK : NSObject

- (id)initWithDelegate:(id<HKDecodeSDKDelegate>) delegate;

- (void)setDelegate:(id<HKDecodeSDKDelegate>)delegate;

/**
 *	@brief	设备呼叫成功后，把对应的callID加进来。就会有对应的视频原始数据和解码后的数据从代理接口中返回来
 *
 *	@param 	callid 	调用音视频呼叫接口后返回的唯一的callID。
 */
- (BOOL)addCallID:(NSString *)callid;

/**
 *	@brief	音频呼叫成功后，把对应的callID加进来，注意音频同时只能收听一个设备
 *
 *	@param 	callid 	调用音频听接口返回的唯一的callID
 *	@param 	audioType 	音频类型
 *
 */
- (BOOL)addAudioCallID:(NSString *)callid withAudioType:(HEKAI_AUDIO_TYPE)audioType;

/**
 *	@brief	设备SD卡数据呼叫成功后，把对应的callID加进来。就会有对应的视频原始数据和解码后的数据从代理接口中返回来
 *
 *	@param 	callid 	调用SD卡视频呼叫接口后返回的唯一的callID。
 */
- (BOOL)addSDCallID:(NSString *)callid;

/**
 *	@brief	关闭设备前，把对应的视频callID从对象中移除
 *
 *	@param 	callid 	调用音视频呼叫接口后返回的唯一的callID。
 */
- (BOOL)removeCallID:(NSString *)callid;

/**
 *	@brief	关闭音频收听前，把对应收听的音频callID从对象中移除
 *
 *	@param 	callid 	调用音频听接口返回的唯一的callID
 *
 */
- (BOOL)removeAudioCallID:(NSString *)callid;

/**
 *	@brief	关闭设备SD数据前，把对应的视频callID从对象中移除
 *
 *	@param 	callid 	调用SD卡视频呼叫接口后返回的唯一的callID。
 */
- (BOOL)removeSDCallID:(NSString *)callid;

/**
 *	@brief	手机说话传给设备
 *
 *	@param 	samplesBuffer 	PCM格式的音频数据
 *	@param 	bufferSize 	音频数据长度
 */
- (BOOL)talkTo:(uint8_t *)samplesBuffer withSize:(uint32_t)bufferSize;

/**
 *	@brief	开启收听
 *
 *	@param 	audioType 	设备的音频类型
 *
 */
- (BOOL)talkOpen:(HEKAI_AUDIO_TYPE)audioType;

/**
 *	@brief	关闭收听
 *
 */
- (BOOL)talkClose;

/**
 *	@brief	暂停解码
 */
+ (void)pause;

/**
 *	@brief	开始、恢复解码
 */
+ (void)start;

@end

