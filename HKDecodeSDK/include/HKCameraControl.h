//
//  HKDeviceSetting.h
//  HKDecodeSDK
//
//  Created by hkmac on 14/11/17.
//  Copyright (c) 2014年 HeKai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HKDecodeGlobal.h"

//#define NSLog(...)      {}

typedef NS_ENUM(NSInteger, SensorSettingType)
{
        SensorSettingTypeStudyCode = 204,//对码
        SensorSettingTypeSetAlarm,//布防
        SensorSettingTypeRemoveAlarm,//撤防
        SensorSettingTypeTestAlarm,//测试
        SensorSettingTypeCheckStudyState,//获取对码成功/失败状态,从报警回调函数(参考InitAlarmInfo)回调 307  0继续获取,-1对码失败,大于0 码值成功
        SensorSettingTypeContactState,//获取当前配对状态，从报警回调函数(参考InitAlarmInfo)回调 308 0设备没连接433，1 撒防状态，2 布防状态
};

/*
 云台控制类型
 */
typedef NS_ENUM(NSInteger, HKCameraControlType)
{
        HKCameraControlTypePTZStop = 0,//云台方向控制停止
        HKCameraControlTypePTZLeft,//云台向左
        HKCameraControlTypePTZRight,//云台向右
        HKCameraControlTypePTZUp,//云台向上
        HKCameraControlTypePTZDown,//云台向下
        
        HKCameraControlTypePTZLevelCruise,//云台水平巡航
        HKCameraControlTypePTZVerticalCruise,//云台垂直巡航
        HKCameraControlTypePTZAllCruise,//云台全方位巡航
        HKCameraControlTypePTZStopCruise,//云台停止巡航
        
        HKCameraControlTypeZoomIn,//拉近焦距
        HKCameraControlTypeZoomOut,//拉远焦距
        
        HKCameraControlTypeOpenAperture,//打开光圈
        HKCameraControlTypeCloseAperture,//关闭光圈
        
        HKCameraControlTypeLevelFlip,//水平翻转
        HKCameraControlTypeVerticalFlip,//垂直翻转
        
        HKCameraControlTypeMaxNumber

};

@interface HKCameraControl : NSObject

- (id)initWithDeviceID:(NSString *)deviceID hkid:(int)hkid asLocalDevice:(BOOL)isLocal;
- (void)updateCameraControlWithHkid:(int)hkid asLocalDevice:(BOOL)isLocal;

#pragma mark - 摄像机基础控制
/**
 *	@brief	摄像机云台、巡航、光圈、焦距等调节
 *
 *	@param 	type 	HKCameraControlType
 */
- (void)cameraBasicControl:(HKCameraControlType)type;

/**
 *	@brief	设置当前位置为预置位
 *
 *	@param 	position 	0~16
 */
- (void)addPresetWithPositon:(int)position;
/**
 *	@brief	移动到预置位position
 *
 *	@param 	position 	0~16
 */
- (void)move2PresetPosition:(int)position;

#pragma mark - 加载设备信息到本地
/**
 *	@brief	加载设备相关参数
 *
 *	@param 	deviceID 	设备ID
 *	@param 	hkid 	设备hkid
 *	@param 	isLanDevice 	是否为局域网设备
 */
- (void)loadDeviceInfo;

/**
 *	@brief	加载设备信息到本地
 *
 *	@param 	deviceID 	设备ID
 *	@param 	hkid 	局域网 hkid
 */
+ (void)loadDeviceInfo:(NSString *)deviceID hkid:(unsigned int)hkid;

#pragma mark - 设备参数获取与设置
/**
 *	@brief	读取设备视频参数
 *
 *	@param 	videoParam 	VideoConfigParam *
 *	@param 	deviceID 	设备ID
 *
 *	@return	YES/NO
 */
- (BOOL)readDeviceVideoInfo:(VideoConfigParam *)videoParam;

/**
 *	@brief	设置视频参数
 *
 *	@param 	videoParam 	VideoConfigParam
 *	@param 	deviceID 	设备ID
 *	@param 	hkid 	设备hkid
 *	@param 	isLanDevice 	是否为局域网设备
 *
 *	@return	YES/NO
 */
- (BOOL)writeDeviceVideoInfo:(VideoConfigParam)videoParam;

/**
 *	@brief	获取简单的报警配置信息，如果需要获取声音侦测敏感度和PIR，请调用本接口
 *
 *	@param 	alarmParam 	AlarmConfigParam *
 *	@param 	deviceID 	设备ID
 *
 *	@return	YES/NO
 */
- (BOOL)readDeviceSimpleAlarmInfo:(AlarmConfigParam *)alarmParam;

/**
 *	@brief	配置简单的报警配置信息，如果要配置声音侦测敏感度和PIR，请调用本接口
 *
 *	@param 	alarmParam 	AlarmConfigParam
 *	@param 	deviceID 	设备ID
 *	@param 	hkid 	设备hkid
 *	@param 	isLanDevice 	是否为局域网设备
 *
 *	@return	YES/NO
 */
- (BOOL)writeDeviceSimpleAlarmInfo:(AlarmConfigParam)alarmParam;

/**
 *	@brief	获取SD卡配置信息
 *
 *	@param 	sdParam 	SDConfigParam *
 *	@param 	deviceID 	设备ID
 *
 *	@return	YES/NO
 */
- (BOOL)readDeviceSDInfo:(SDConfigParam *)sdParam;

/**
 *	@brief	设置SD卡配置信息
 *
 *	@param 	sdParam 	SDConfigParam
 *	@param 	deviceID 	设备ID
 *	@param 	hkid            设备hkid
 *	@param 	isLanDevice 	是否为局域网设备
 *
 *	@return	YES/NO
 */
- (BOOL)writeDeviceSDInfo:(SDConfigParam)sdParam;

/**
 *	@brief	读取设备邮件报警配置信息，这里是邮件和报警信息都返回，但是没有声音侦测敏感度和PIR的参数
 *
 *	@param 	emailParam 	EmailConfigParam *
 *	@param 	deviceID 	设备ID
 *
 *	@return	YES/NO
 */
- (BOOL)readDeviceEmailAlarmInfo:(EmailConfigParam *)emailParam;

/**
 *	@brief	配置Email邮件信息
 *
 *	@param 	emailParam 	EmailConfigParam
 *
 *	@return	YES/NO
 */
- (BOOL)writeDeviceEmailAlarmInfo:(EmailConfigParam)emailParam;

/**
 *	@brief	获取简化版的报警配置参数，这里需要传入Email和SD卡参数的结构体，并且要把它们保存起来，以用于设置报警参数。但请注意这并不代表之后的Email和SD卡参数不需要重新获取。如果您的报警配置有声音侦测和PIR，请使用本接口来获取
 *
 *	@param 	alarmParam 	AlarmConfigParam *
 *	@param 	emailParam 	EmailConfigParam *
 *	@param 	sdParam 	SDConfigParam *
 *	@param 	deviceID 	设备ID
 *
 *	@return	YES/NO
 */
- (BOOL)readOldDeviceAlarmInfo:(AlarmConfigParam *)alarmParam emailConfigParam:(EmailConfigParam *)emailParam SDConfigParam:(SDConfigParam *)sdParam;

/**
 *	@brief	简化版的报警信息进行配置，这里需要把Email和SD卡参数的结构体传入，它们是在获取接口中返回的。
 *
 *	@param 	alarmParam 	AlarmConfigParam
 *	@param 	deviceID 	NSString
 *
 *	@return	成功为 YES，失败为 NO
 */
- (BOOL)writeOldDeviceAlarmInfo:(AlarmConfigParam)alarmParam emailConfigParam:(EmailConfigParam)emailParam SDConfigParam:(SDConfigParam)sdParam;

/**
 *	@brief	开启/关闭报警
 *
 *	@param 	bOpen 	0关闭 / 1开启
 *
 *	@return	YES/NO
 */
- (BOOL)openDeviceAlarmPower:(BOOL)bOpen;

/**
 *	@brief	读取设备WiFi信息，暂不支持互联网
 *
 *	@param 	wifiParam 	WifiConfigParam指针
 *
 *	@return	0成功，-1失败，-110互联网不支持该功能
 */
- (int)readDeviceWifiConfigParam:(WifiConfigParam *)wifiParam;

/**
 *	@brief	设置设备WiFi信息，暂不支持互联网
 *
 *	@param 	wifiParam 	WifiConfigParam
 *
 *	@return	成功为 YES，失败为 NO
 */
- (BOOL)writeDeviceWifiConfigParam:(WifiConfigParam)wifiParam;

/**
 *	@brief	获取设备的wifi节点, 请务必注册wifi节点回调(参考hkipc.h中的InitGetWifiSid函数)，所搜索到的wifi节点信息都会从这个回调里返回。暂不支持互联网
 *
 *	@param 	mac 	mac地址
 *
 *	@return	成功为 YES，失败为 NO
 */
- (BOOL)readWiFiSSIDInfoWithMacAddress:(char *)mac;

/**
 *	@brief	读取SD卡文件列表，以一页一页的方式读取
 *
 *	@param 	page 	当前页，从第1页开始
 *	@param 	size 	每一页读取的文件个数
 *
 *	@return	YES/NO
 */
- (BOOL)readSDFileWithPage:(NSInteger)page pageSize:(int)size;

/**
 *	@brief	删除SD卡文件
 *
 *	@param 	filename 	文件名
 *
 *	@return	YES/NO
 */
- (BOOL)deleteSDFile:(NSString *)filename;

/**
 *	@brief	锁定文件，防止循环录像时删除
 *
 *	@param 	filename 	文件名
 *	@param 	block 	锁定状态
 *
 *	@return	>=0成功
 */
- (int)lockSDFile:(NSString *)filename lock:(BOOL)block;

/**
 *	@brief	读取设备有线IP地址信息，暂不支持互联网
 *
 *	@param 	ipParam 	IPConfigParam指针
 *
 *	@return	>=0成功，-110互联网不支持
 */
- (int)readDeviceIPConfigParam:(IPConfigParam *)ipParam;

/**
 *	@brief	格式化SD卡，互联网暂不支持格式化SD卡，如果是互联网，请屏蔽格式化操作
 *
 *	@return	0成功，-1失败，-110互联网不支持该功能
 */
- (int)formatSDCard;

/**
 *	@brief	重启摄像机，暂不支持互联网
 *
 *	@param 	mac 	mac地址
 *
 *	@return	0成功，-1失败，-110互联网不支持该功能
 */
- (int)rebootDeviceWithMacAddress:(char *)mac;

/**
 *	@brief	恢复出厂设置，暂不支持互联网
 *
 *	@return	0成功，-1失败，-110互联网不支持该功能
 */
- (int)restoreFactorySettings;

/**
 *	@brief	手动升级摄像机，暂不支持互联网
 *
 *	@return	0成功，-1失败，-110互联网不支持该功能
 */
- (int)manuallyUpdateDevice;

/**
 *	@brief	透传接口，发送数据到设备
 *
 *	@param 	data 	透传数据，数据格式 data=xxxxxx; 长度不超过4k
 *
 *	@return	>=0成功，否则失败
 */
- (int)sendData2Device:(const char *)data;

/**
 *	@brief	艾礼富定制接口，判断是否允许呼叫设备
 *
 *	@return	>=0成功，否则失败；成功后，等待报警回调312
 */
- (int)enableCallDevice;

/**
 *	@brief	读取设备报警电话信息，该信息会从报警回调返回命令310
 *
 *	@return	>=0成功，否则失败
 */
- (int)readAlarmPhoneInfo;

@end
