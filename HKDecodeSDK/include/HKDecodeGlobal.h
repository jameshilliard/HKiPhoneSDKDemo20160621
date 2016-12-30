#ifndef _PLAYER_H_
#define _PLAYER_H_

// 媒体帧类型定义
#define MEDIA_FRAME_TYPE_VIDEO	(1 << 0) /**< 视频帧. */
#define MEDIA_FRAME_TYPE_KEY	(1 << 1) /**< 视频帧(关键帧). */
#define MEDIA_FRAME_TYPE_FAST	(1 << 2) /**< 需要播放器进行快速处理（不根据视频帧PTS进行延时）的视频帧. */
#define MEDIA_FRAME_TYPE_AUDIO	(1 << 3) /**< 音频帧. */
#define MEDIA_FRAME_TYPE_GPS	(1 << 4) /**< GPS帧. */
#define MEDIA_FRAME_TYPE_HDR	(1 << 5) /**< 录像文件头部帧. */
#define MEDIA_FRAME_TYPE_TAIL	(1 << 6) /**< 录像文件尾部帧. */
#define MEDIA_FRAME_TYPE_DATA	(1 << 7) /**< 数据帧. */
#define MEDIA_FRAME_TYPE_NSTR	(1 << 8) /**< 新媒体流通知帧. */
#define MEDIA_FRAME_TYPE_EOS	(1 << 9) /**< 媒体流结束通知帧. */
#define MEDIA_FRAME_TYPE_INDEX	(1 << 10)/**< 索引构建结束通知帧. */
#define MEDIA_FRAME_TYPE_RECORD_DATA    (1 << 11)/*录像回调未解码数据*/

#define common_string_length    32

#define SAFE_DELETE(ptr) 	do { if (NULL != ptr) { delete ptr; ptr = NULL; } } while (0)
#define SAFE_FREE(ptr) 		do { if (NULL != ptr) { free(ptr); ptr = NULL; } } while (0)

typedef enum {
	PLAYER_OPENED,
	PLAYER_STARTED,
	PLAYER_PAUSED,
	PLAYER_CLOSED
}PLAYER_STATE;

/// 渲染帧描述.
typedef struct {
	uint32_t type;		/**< 媒体帧类型. */
	uint32_t length;	/**< 媒体长度. */
	uint8_t *media;		/**< 媒体数据(已解码). */
	uint64_t timestamp;	/**< 当前渲染的媒体时间点(ms). */
        uint32_t frameWidth;	/**< 视频宽度. */
	uint32_t frameHeight;	/**< 视频高度. */
	uint32_t frameRate;	/**< 视频帧率(fps). */
	uint32_t bitRate;	/**< 媒体码率(bps). */
	int orientation;	/**< 视频朝向. */
} RENDER_FRAME_DESC;


/// 媒体帧描述.
typedef struct {
	int type;		/**< 媒体帧类型. */
	int orientation;	/**< 视频帧朝向. */
	uint8_t *media;		/**< 指向媒体缓冲的指针. */
	uint32_t length;	/**< 有效的媒体字节长度. */
	uint32_t padding;	/**< 内部使用. */
	uint64_t pts;		/**< 显示时间截. */
        unsigned int waitPTS;   /*与上一帧的间隔*/
} MEDIA_FRAME_DESC;

typedef enum {
        HEKAI_AUDIO_Unknow = 0,
        HEKAI_AUDIO_PCM,
        HEKAI_AUDIO_G711A,
        HEKAI_AUDIO_G726,
        HEKAI_AUDIO_G729
} HEKAI_AUDIO_TYPE;

#pragma mark - 视频参数
struct _VideoConfigParam {
        int bright;//亮度
        int saturation;//饱和度
        int contrast;//对比度
        int sharp;//锐度
        int mediaQuality;//画面质量
        int stream;//码流
        int frameRate;//帧率
        int resolution;//分辨率
};

typedef struct _VideoConfigParam VideoConfigParam;

#pragma mark - 报警信息
struct _AlarmConfigParam {
        int motionDetectionSensitive;//移动帧测敏感度 0关闭 [1 10]
        int audioDetectionSensitive;//声音帧测敏感度  0不支持 1关闭 2低 3中 4高
        int PIR;//人体感应开关 0不支持 1关闭 2开启
        int SDRecordWhenAlarm;//报警SD卡录像开关
        int alarmPicture;//报警图片数
        int version;//当前设备软件版本  0为旧版本，1为新版本
};

typedef struct _AlarmConfigParam AlarmConfigParam;

#pragma mark - 邮件信息
struct _EmailConfigParam {
        int sensitive;//移动帧测敏感度
        int pictureNum;//报警发送邮件时发送的图片张数
        int ioalarm;//IO报警开关
        int alarmSendEmail;//报警是否发送邮件的开关
        int sderror;//此参数暂时没用
        int port;//端口
        int entype;//协议
        int isTest;//是否发送测试邮件
        char senderEmail[common_string_length];//发送者邮箱
        char receiverEmail[common_string_length];//接收者邮箱
        char smtpServer[common_string_length];//smtp服务器
        char senderUsername[common_string_length];//发送者用户名
        char senderPassword[common_string_length];//发送者密码
        char emailInfo[common_string_length];//email信息，本参数暂无用，不用处理
};

typedef struct _EmailConfigParam EmailConfigParam;

#pragma mark - SD卡信息
struct _SDConfigParam {
        int autoRecord;//自动开机录像
        int recordAudio;//录音频
        int loopRecord;//循环录像
        int splitSize;//录像分割大小
        int totalSize;//SD卡总空间
        int usedSize;//已使用空间
        int leftSize;//剩余空间
        int motionRecord;//移动侦测报警 录像
        int IORecord;//IO报警 录像
};

typedef struct _SDConfigParam SDConfigParam;

#pragma mark - FTP参数
struct _FTPConfigParam {
        int isUseFTP;
        int ftpPort;
        char ftpServer[common_string_length];
        char ftpUsername[common_string_length];
        char ftpPassword[common_string_length];
        char ftpCodeType[common_string_length];
};
typedef struct _FTPConfigParam FTPConfigParam;

#pragma mark - WiFi参数
struct _WifiConfigParam {
        int isDHCP;
        int isUseWifi;
        char ssid[common_string_length];
        char address[common_string_length];
        char gateway[common_string_length];
        char submask[common_string_length];
        char dns[common_string_length];
        char mac[common_string_length];
        char password[common_string_length * 10];
        char wifiMisc[common_string_length * 10];
};

typedef struct _WifiConfigParam WifiConfigParam;

#pragma mark - IP参数
struct _IPConfigParam {
        int isDHCP;
        char address[common_string_length];
        char gateway[common_string_length];
        char submask[common_string_length];
        char dns[common_string_length];
        char mac[common_string_length];
        int status;
        int version;
};

typedef struct _IPConfigParam IPConfigParam;

#pragma mark - NAS参数
struct _NASConfigParam {
        int isUseNAS;//是否启用NAS
        char ipAddress[16];//IP地址
        char *nasPath;//NAS文件路径
        int splitSize;//NAS录像分割大小
        int isRecordAudio;//是否录制语音
};

typedef struct _NASConfigParam NASConfigParam;


typedef struct {
        int videoCodec;// 0: H264, 1: MPEG4
        uint32_t frameWidth;
        uint32_t frameHeight;
        uint32_t frameRate;
        char alias[64];
} HEKAI_RECORD_DESC;

typedef struct {
        int chanNum;//通道个数
        int isLocalDevice;
        int localDeviceId;//hkid
        HEKAI_AUDIO_TYPE audioType;
        int isOnline;
        int isAdminDev;
        int popedom;
        char alias[64];
        char deviceId[64];
        char deviceType[64];
} HEKAI_DEVICE_DESC;

@interface HekaiDeviceDesc : NSObject

@property(assign) HEKAI_DEVICE_DESC deviceDesc;

@property (nonatomic, copy) NSString *accessPassword;//访问密码
@property (nonatomic, copy) NSString *videoCallid;
@property (nonatomic, copy) NSString *audioListenCallID;
@property (nonatomic, copy) NSString *audioSpeakCallID;

@end

#pragma mark - 拓展参数，内部使用
typedef struct _PaulLightParam {
        int lightPower;//灯开关状态
        int lightAlarm;//报警开灯的开关状态
        int lightTimer;//定时开灯的开关状态
        
        char cStartTime[32];//定时开灯的开始时间
        char cEndTime[32];//定时开灯的结束时间
} PaulLightParam;

typedef struct _PaulDetectionParam {
        int pushPower;//push开关
        int motionMode;//1：动态模式，0静态模式
        int quietMotionTime;//静态探知时间
        int motionRecordTime;//动态侦测录像时间
        int liveTime;//在线视频预览时间
        char cStartTime[32];//通知开始时间
        char cEndTime[32];//通知结束时间

} PaulDetectionParam;

#endif//_PLAYER_H_
