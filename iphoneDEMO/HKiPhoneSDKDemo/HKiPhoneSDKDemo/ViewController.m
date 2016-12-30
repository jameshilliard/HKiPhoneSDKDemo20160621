//
//  ViewController.m
//  HKiPhoneSDKDemo
//
//  Created by hkmac on 15/3/5.
//  Copyright (c) 2015年 hk. All rights reserved.
//

#import "ViewController.h"
#import "HKCameraControl.h"
#import "HKDecodeSDK.h"
#import "hkipc.h"
#import "HKDisplayView.h"
#import "avrecord.h"
#import <sys/time.h>

@interface ViewController () <HKDecodeSDKDelegate, HKDisplayViewDelegate>
{
        BOOL _bLoginSuccess;
        BOOL _bPTZMoving;
        BOOL _bScaning;
        enum {ConnectingTypeNone,
                ConnectingTypeVideoWait105,
                ConnectingTypeVideoWait106,
                ConnectingTypeListenAudioWait105,
                ConnectingTypeListenAudioWait106,
                ConnectingTypeSpeakerAudioWait105,
                ConnectingTypeSpeakerAudioWait106,
                ConnectingTypeRegistServerSuccess,      //注册监控服务成功
                ConnectingTypeRegistServerFail,         //注册监控服务失败
                ConnectingTypeLoginSuccess,             //登陆成功
                ConnectingTypeLoginFail,                //登陆失败
        } _connectingType;

}
@property (nonatomic, strong) NSMutableDictionary *lanDeviceDict;
@property (nonatomic, strong) NSMutableDictionary *WanDeviceDict;//外网设备列表
@property (nonatomic, copy) NSString *selectedDeviceID;
@property (nonatomic, strong) HKDecodeSDK *decodeSDK;
@property (nonatomic, strong) HKCameraControl *cameraControl;
@property (nonatomic, strong) HekaiDeviceDesc *operationDevice;

@property (weak, nonatomic) IBOutlet UITableView *deviceListTableView;
@property (weak, nonatomic) IBOutlet UILabel *operationDeviceLabel;
@property (weak, nonatomic) IBOutlet HKDisplayView *displayView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet  UITextField *asscode;//设备访问密码
@property (weak, nonatomic) IBOutlet UITextField *loginAccount;
@property (weak, nonatomic) IBOutlet UITextField *loginPassword;

@property (weak, nonatomic) IBOutlet UITextField *sendDataTextField;

@property (weak, nonatomic) IBOutlet UIButton * recordBtn;

@property (nonatomic,assign) BOOL isLocal;//当前选中是外网还是局域网
@property (nonatomic,assign) BOOL isRecord;//当前是否在录像

@property (nonatomic, strong) NSLock *loginLock;

- (IBAction)login:(id)sender;
- (IBAction)getDeviceState:(id)sender;

- (IBAction)playVideo:(id)sender;
- (IBAction)stopVideo:(id)sender;
- (IBAction)refresh:(id)sender;
- (IBAction)listen:(id)sender;
- (IBAction)stopListen:(id)sender;
- (IBAction)speak:(id)sender;
- (IBAction)stopSpeak:(id)sender;
- (IBAction)capture:(id)sender;

- (IBAction)ptzUp:(id)sender;
- (IBAction)ptzDown:(id)sender;
- (IBAction)ptzLeft:(id)sender;
- (IBAction)ptzRight:(id)sender;
- (IBAction)tpzScan:(id)sender;

- (IBAction)sendDataToWanOrLan:(id)sender;
- (IBAction)recordDev:(id)sender; //录像

@end

@implementation ViewController

//设备报警回调
static void HKAlarmCallback(void *userData,int nCmd, int iCount, char *cBuf, int ilParm)
{
        NSLog(@"Alarm = .=");
        NSLog(@"cmd:%d ---data:%s",nCmd,cBuf);
        if(nCmd != 201){
                return;
        }
        if(userData == NULL){
                return;
        }
        ViewController *p = (__bridge ViewController *)userData;
        
        dispatch_async(dispatch_get_main_queue()
                       , ^{
                               NSString *data = [NSString stringWithFormat:@"%s",cBuf ];
                               [p.label_handleData setText:data];
                
                       });
        
}

//局域网设备节点回调函数
static void HKLanDataCallback(void *userData, char *devid, char *devType, int hkid, int iCount,int iStatus,char *audioType )
{
        if (userData == NULL) {
                return;
        }
        ViewController *p = (__bridge ViewController *)userData;
        
        if (strcmp("301", devid) == 0) {
                //忽略301信息
                return;
        }
        
        HEKAI_DEVICE_DESC deviceDesc;
        memset(&deviceDesc, 0x0, sizeof (deviceDesc));
        
        strcpy(deviceDesc.alias, devid);
        strcpy(deviceDesc.deviceId, devid);
        strcpy(deviceDesc.deviceType, devType);
        deviceDesc.isLocalDevice = 1;
        deviceDesc.localDeviceId = hkid;
        deviceDesc.chanNum = iCount;
        deviceDesc.isOnline = (1 == iStatus || 2 == iStatus) ? 1 : 0;
        
        if (0 == strcmp(audioType, "PCM")) {
                deviceDesc.audioType = HEKAI_AUDIO_PCM;
        } else if (0 == strcmp(audioType, "G711")) {
                deviceDesc.audioType = HEKAI_AUDIO_G711A;
        } else if (0 == strcmp(audioType, "G726")) {
                deviceDesc.audioType = HEKAI_AUDIO_G726;
        } else if (0 == strcmp(audioType, "G729")) {
                deviceDesc.audioType = HEKAI_AUDIO_G729;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [p handleHKLanDataCallback:deviceDesc];
        });
}

static void HKSystemCallback(void *userData, int nCmd, char *cBuf, int iLen)
{
        ViewController *p = (__bridge ViewController *)userData;
        [p handleSystemCallback:nCmd withBuf:cBuf withiLen:iLen];
}

- (void)viewDidLoad {
        [super viewDidLoad];
        // Do any additional setup after loading the view, typically from a nib.
        _bLoginSuccess = NO;
        _bPTZMoving = NO;
        _bScaning = NO;
        _connectingType = ConnectingTypeNone;
        _isLocal = YES;
        self.lanDeviceDict = [NSMutableDictionary dictionaryWithCapacity:0];
        self.WanDeviceDict = [NSMutableDictionary dictionaryWithCapacity:0];
        //============初始化解码器
        self.decodeSDK = [[HKDecodeSDK alloc] initWithDelegate:self];
        
        //============初始化局域网回调
        hk_InitLAN((__bridge void *)(self), &HKLanDataCallback);
        InitAlarmInfo((__bridge void *)(self),&HKAlarmCallback);
        _displayView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
        [super viewDidAppear:animated];

        hk_LanRefresh_EX(1);
}
- (void)didReceiveMemoryWarning {
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}

- (void)handleHKLanDataCallback:(HEKAI_DEVICE_DESC)desc
{
        NSString *deviceID = [NSString stringWithUTF8String:desc.deviceId];
        if ([_lanDeviceDict.allKeys containsObject:deviceID]) {
                //如果不是新设备，则只是更新设备里的数据，目前局域网设备只有hkid会更新
                HekaiDeviceDesc *existDevice = [_lanDeviceDict objectForKey:deviceID];
                if (existDevice.deviceDesc.localDeviceId != desc.localDeviceId) {
                        HEKAI_DEVICE_DESC desc = existDevice.deviceDesc;
                        desc.localDeviceId = desc.localDeviceId;
                        existDevice.deviceDesc = desc;
                }

        } else {
                NSLog(@"发现新设备 %@", deviceID);
                HekaiDeviceDesc *device = [[HekaiDeviceDesc alloc] init];
                device.deviceDesc = desc;
                [_lanDeviceDict setObject:device forKey:deviceID];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                        [_deviceListTableView reloadData];
                });
        }
}

//hk_StartLogin---->nCmd; 0 成功，1密码错误，3网络不通，14 网络断开. cBuf =NULL,iLen=0;
- (void)handleSystemCallback:(int)nCmd withBuf:(char *)cBuf withiLen:(int)iLen
{
        NSLog(@"======ncmd %d cbuf %s", nCmd, cBuf);
        switch (nCmd) {
                case 0:
                        //登录成功
                        NSLog(@"登录成功");
                        _bLoginSuccess = YES;
                        [self showAlertWithInfo:@"登录成功"];
                        [self userLoginSuccess:ConnectingTypeLoginSuccess];
                        break;
                case 3:
                        //网络不通
                        NSLog(@"网络不通，请稍后再试");
                        _bLoginSuccess = NO;
                        [self showAlertWithInfo:@"网络不通，请稍后再试"];
                        break;
                case 102:
                {
                        NSLog(@"设备列表");
                        [self procWanDeviceListInfo:cBuf totalCount:iLen];
                }
                        break;
                case 105:
                case 106:
                {
                        NSString *strBuf = [NSString stringWithUTF8String:cBuf];
                        strBuf = (NSString *)[[strBuf componentsSeparatedByString:@"flag="] objectAtIndex:1];
                        NSLog(@"系统回调返回 %d", nCmd);
                        [self procWanVideoConnectCommand:nCmd withFlag:strBuf.intValue];
                }
                        break;
                        
                case 101:
                {
                        if (strcmp(cBuf, "1") == 0) {
                                NSLog(@"注册监控服务成功");
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                        [self registMoniterSuccess:ConnectingTypeRegistServerSuccess];
                                });
                        } else {
                                NSLog(@"注册监控服务失败");
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                        [self registMoniterSuccess:ConnectingTypeRegistServerFail];
                                });
                        }
                
                }
                        break;
                case 119:
                {
                        dispatch_async(dispatch_get_main_queue(), ^{
                                _textView.text = [NSString stringWithUTF8String:cBuf];
                        });
                }
                        break;
                default:
                        break;
        }
}


- (void)procWanDeviceListInfo:(char *)deviceInfo totalCount:(int)iTotal
{
         @synchronized(self){
                 if (strcmp(deviceInfo, "0") == 0) {
                        NSLog(@"该用户下没有设备......");
                 }

                int iCount, iFormid;
                char cDevType[64] = {0};//设备类型
                char cAlias[64] = {0};  //别名
                char cDevid[64] = {0};  //设备id
                char cDeviceAccessPwd[64] = {0};//设备访问密码
                char cUserAccessPwd[64] = {0};  //用户密码
                char audioType[12] = {0};       //音频类型
                int isAdminDev, isOnline, popedom;//是否管理员设备 是否在线 权限
                const char *fmt = "DevFlag%%equal%%%[^%]%%comma%%formid%%equal%%%d%%comma%%alias%%equal%%%[^%]%%comma%%devid%%equal%%%[^%]%%comma%%Count%%equal%%%d%%comma%%type%%equal%%2%%comma%%audio%%equal%%%[^%]%%comma%%admin%%equal%%%d%%comma%%status%%equal%%%d%%comma%%popedom%%equal%%%d%%comma%%devAccess%%equal%%%[^%]%%comma%%userAccess%%equal%%%[^%]";
                sscanf(deviceInfo, fmt, cDevType, &iFormid, cAlias, cDevid, &iCount, audioType, &isAdminDev, &isOnline, &popedom);

                NSString *deviceID = [NSString stringWithUTF8String:cDevid];
                NSString *strAlias = [[NSString alloc] initWithBytes:cAlias length:strlen(cAlias) encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
//                NSString *strVideoType = [NSString stringWithUTF8String:cDevType];
//                NSString *strAudioType = [NSString stringWithUTF8String:audioType];
//                NSString *strDevAccessPwd = [NSString stringWithUTF8String:cDeviceAccessPwd];
//                NSString *strUserAccessPwd = [NSString stringWithUTF8String:cUserAccessPwd];
                 
                 HEKAI_DEVICE_DESC deviceDesc;
                 memset(&deviceDesc, 0x0, sizeof (deviceDesc));
                 strcpy(deviceDesc.alias, cAlias);
                 strcpy(deviceDesc.deviceId, cDevid);
                 strcpy(deviceDesc.deviceType, cDevType);
                 deviceDesc.isLocalDevice = 0;
                 deviceDesc.localDeviceId = 0;
                 deviceDesc.chanNum = iCount;
                 deviceDesc.isOnline = isOnline;
                 
                 if (0 == strcmp(audioType, "PCM")) {
                         
                         deviceDesc.audioType = HEKAI_AUDIO_PCM;
                         
                 } else if (0 == strcmp(audioType, "G711")) {
                         
                         deviceDesc.audioType = HEKAI_AUDIO_G711A;
                         
                 } else if (0 == strcmp(audioType, "G726")) {
                         
                         deviceDesc.audioType = HEKAI_AUDIO_G726;
                         
                 } else if (0 == strcmp(audioType, "G729")) {
                         
                         deviceDesc.audioType = HEKAI_AUDIO_G729;
                         
                 }
                 
                 HekaiDeviceDesc *device = [[HekaiDeviceDesc alloc] init];
                 device.deviceDesc = deviceDesc;
                 [_WanDeviceDict setObject:device forKey:deviceID];
                 

                 //刷新设备列表
                dispatch_async(dispatch_get_main_queue(), ^{
                        [_deviceListTableView reloadData];
                });
           
         }
        
}


//登录接口，登录成功后，需要注册监控服务，那样才算真的成功了
- (void)userLoginSuccess:(int)ret{
        if(ret == ConnectingTypeLoginSuccess){
                //检查是否超时 这里最好添加超时计时
                NSLog(@"登陆成功开始注册监控服务");
                hk_RegionMonServer();
        }else{
        
                NSLog(@"登陆失败");
        }
}


//注册外网监控服务 如果成功的话 获取外网账户设备列表  失败的话则退出系统
- (void)registMoniterSuccess:(int)ret{
        if(ret == ConnectingTypeRegistServerSuccess){
                int result = hk_GetItem(0);
                if(result < 0){
                        NSLog(@"获取设备列表");
                }
        }else{
                NSLog(@"退出当前系统");
                hk_QuitSysm();
        }

}


#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
        return 2;
        
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        switch (section) {
                case 0:
                        return _lanDeviceDict.count;
                        break;
                case 1:
                        return _WanDeviceDict.count;
                        break;
                default:
                        return 0;
                        break;
        }
        
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
        NSString *retValue = nil;
        if (section == 0) {
                retValue = @"LAN";
        } else if (section == 1) {
                retValue = @"WAN";
        } else {
                NSLog(@"为啥子嘞？");
        }
        return retValue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
         UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceListTableViewCellIdentifier" forIndexPath:indexPath];
        if(indexPath.section == 0){
                
                HekaiDeviceDesc *device = [_lanDeviceDict objectForKey:[_lanDeviceDict.allKeys objectAtIndex:row]];
                
                cell.textLabel.text = [NSString stringWithUTF8String:device.deviceDesc.deviceId];
        }else{
               
                
                HekaiDeviceDesc *device = [_WanDeviceDict objectForKey:[_WanDeviceDict.allKeys objectAtIndex:row]];
                
                cell.textLabel.text = [NSString stringWithUTF8String:device.deviceDesc.deviceId];
                
        }
   
        return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
        if(section == 0){
                HekaiDeviceDesc *device = [_lanDeviceDict objectForKey:[_lanDeviceDict.allKeys objectAtIndex:row]];
                self.selectedDeviceID = [NSString stringWithUTF8String:device.deviceDesc.deviceId];
                NSLog(@"select %@", _selectedDeviceID);
                _isLocal = YES;
        }else{
                HekaiDeviceDesc *device = [_WanDeviceDict objectForKey:[_WanDeviceDict.allKeys objectAtIndex:row]];

                self.selectedDeviceID = [NSString stringWithUTF8String:device.deviceDesc.deviceId];
                NSLog(@"select %@", _selectedDeviceID);
                _isLocal = NO;
        
        }
        
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
        NSLog(@"will deselect %@", _selectedDeviceID);
        self.selectedDeviceID = nil;
}

- (void)showAlertWithInfo:(NSString *)info
{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:info delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
        });
}

/*
 * 当操作云台上、下、左、右时，设备会一直往设置的方向转动，必须发送停止命令才会停止转动。
 */
- (void)ptzOperation:(int)iValue
{
        if (_bPTZMoving) {
                [_cameraControl cameraBasicControl:HKCameraControlTypePTZStop];
        } else {
                switch (iValue) {
                        case 1:
                                //left
                                [_cameraControl cameraBasicControl:HKCameraControlTypePTZLeft];
                                break;
                        case 2:
                                //right
                                [_cameraControl cameraBasicControl:HKCameraControlTypePTZRight];
                                break;
                        case 3:
                                //up
                                [_cameraControl cameraBasicControl:HKCameraControlTypePTZUp];
                                break;
                        case 4:
                                //down
                                [_cameraControl cameraBasicControl:HKCameraControlTypePTZDown];
                                break;
                        default:
                                NSLog(@"不恰当的操作");
                                break;
                }
        }
        _bPTZMoving = !_bPTZMoving;
}

- (void)ptzScaning
{
        if (_bScaning) {
                //停止全方位巡航
                [_cameraControl cameraBasicControl:HKCameraControlTypePTZStopCruise];
        } else {
                //开始全方位巡航
                [_cameraControl cameraBasicControl:HKCameraControlTypePTZAllCruise];
        }
        _bScaning = !_bScaning;
}

/**
 *	@brief	解析互联网呼叫105、106回调信息
 *
 *	@param 	nCmd 	105、106
 *	@param 	flag 	成功、失败标志
 */
- (void)procWanVideoConnectCommand:(int)nCmd withFlag:(int)flag
{
        int type = _connectingType;
        _connectingType = ConnectingTypeNone;
        
        if (nCmd == 105) {
                if (flag == 5 || flag == 6 || flag == 7) {
                        //105返回成功，继续等待106 ConnectingTypeVideoWait105 / ConnectingTypeAudioWait105
                        
                        if (type == ConnectingTypeVideoWait105) {
                                _connectingType = ConnectingTypeVideoWait106;
                                
                        } else if (type == ConnectingTypeListenAudioWait105) {
                                _connectingType = ConnectingTypeListenAudioWait106;
                                
                        } else if (type == ConnectingTypeSpeakerAudioWait105) {
                                _connectingType = ConnectingTypeSpeakerAudioWait106;
                                
                        } else {
                                NSLog(@"成功了，这是什么105类型----->%d", type);
                        }
                } else {
                        //105返回失败
                        if (type == ConnectingTypeVideoWait105) {//视频105
                                [self openVideoFailed];
                                
                        } else if (type == ConnectingTypeListenAudioWait105) {//音频105
                                [self openListenAudioFailed];
                                
                        } else if (type == ConnectingTypeSpeakerAudioWait105) {//音频105
                                [self openSpeakerAudioFailed];
                                
                        } else {
                                NSLog(@"失败了，这是什么105类型--->%d", type);
                        }
                }
        } else if (nCmd == 106) {
                if (flag == 1) {
                        //106返回成功，音视频呼叫成功
                        if (type == ConnectingTypeVideoWait106) {//视频106
                                [self openVideoSuccess];
                                
                        } else if (type == ConnectingTypeListenAudioWait106) {//音频106
                                [self openListenAudioSuccess];
                                
                        } else if (type == ConnectingTypeSpeakerAudioWait106) {//音频106
                                [self openSpeakerAudioSuccess];
                                
                        } else {
                                NSLog(@"成功了，但这是什么106类型--->%d", type);
                        }
                } else {
                        //106返回失败
                        if (type == ConnectingTypeVideoWait106) {//视频106
                                [self openVideoFailed];
                                
                        } else if (type == ConnectingTypeListenAudioWait106) {//音频106
                                [self openListenAudioFailed];
                                
                        } else if (type == ConnectingTypeSpeakerAudioWait106) {//音频106
                                [self openSpeakerAudioFailed];
                                
                        } else {
                                NSLog(@"失败了，可这是什么106类型--->%d", type);
                        }
                }
        }
}

- (void)enableOperation:(BOOL)bEnable
{

}

- (void)openVideoSuccess
{
        _operationDeviceLabel.text = [NSString stringWithUTF8String:_operationDevice.deviceDesc.deviceId];
        
        //1、把视频callid加到解码器中，解码器会把解码和未解码的数据都从代理方法中返回
        [_decodeSDK addCallID:_operationDevice.videoCallid];
        
        [self enableOperation:YES];
}

- (void)openVideoFailed
{
        _connectingType = ConnectingTypeNone;
        _operationDevice.videoCallid = nil;
        self.operationDevice = nil;
        self.cameraControl = nil;
        
        [self enableOperation:NO];
}

- (void)openListenAudioSuccess
{
        //1、把音频收听callid加到解码器中，解码器会把解码的数据从代理方法中返回
        [_decodeSDK addAudioCallID:_operationDevice.audioListenCallID withAudioType:_operationDevice.deviceDesc.audioType];
}

- (void)openListenAudioFailed
{
        
}

- (void)openSpeakerAudioSuccess
{
        //1、打开解码器音频说功能
        [_decodeSDK talkOpen:_operationDevice.deviceDesc.audioType];
        //2、采集手机音频
        [_displayView openAudioSpeaker:YES];
}

- (void)openSpeakerAudioFailed
{
        
}

#pragma mark - 
- (void)sendSpeakerAudio:(uint8_t *)audio length:(uint32_t)length
{
        //将采集到的音频数据发给解码器
        [_decodeSDK talkTo:audio withSize:length];
}

#pragma mark - HKDecodeSDKDelegate

//未解码的原始视频数据
- (void)DecodeSDK:(HKDecodeSDK *)sdk recordDataCallback:(const SCC_MideData *)data
{
       
        if(_isRecord == YES){
                 NSLog(@"record data.....");
                [_displayView handleRecordData:data->pDataBuf length:data->nSize frametype:data->nFreamType];
        }

}

//解码了的视频数据
- (void)DecodeSDK:(HKDecodeSDK *)sdk CallID:(NSString *)callid decodedMediaData:(RENDER_FRAME_DESC *)frameDesc
{
//        NSLog(@"video frameDesc->length %d, frameDesc->frameWidth %d, frameDesc->frameHeight %d", frameDesc->length, frameDesc->frameWidth, frameDesc->frameHeight);
        [_displayView displayVideo:frameDesc->media videoWidth:frameDesc->frameWidth videoHeight:frameDesc->frameHeight];
}

//解码后的PCM格式的音频数据
- (void)DecodeSDK:(HKDecodeSDK *)sdk decodedAudioData:(RENDER_FRAME_DESC *)frameDesc
{
//                NSLog(@"audio frameDesc->length %d, frameDesc->media %p", frameDesc->length, frameDesc->media);
        [_displayView playListenAudio:frameDesc->media length:frameDesc->length];
}

- (IBAction)login:(id)sender {
   
        _bLoginSuccess = NO;
        //1、初始化互联网系统回调
        hk_InitWAN((__bridge void *)(self), &HKSystemCallback);
        //2、登录，用户名和密码都使用固定的
        NSString *account= self.loginAccount.text;
        NSString *password = self.loginPassword.text;
        
        if(account == nil ||password == nil ||[account isEqualToString:@""]||[password isEqualToString:@""]){
                [self showAlertWithInfo:@"账号或者密码不能为空"];
                return;
        }
        
        int ret = hk_StartLogin([account UTF8String], [password UTF8String], "www.scc21.com");
        if (ret < 0) {
                [self showAlertWithInfo:@"登录失败"];
        }
}


- (IBAction)logout:(id)sender {
        //退出互联网系统
        hk_QuitSysm();
}



- (IBAction)getDeviceState:(id)sender {
        if (_selectedDeviceID) {
                //获取设备互联网状态
                sccGetDevStatus((char *)_selectedDeviceID.UTF8String);
        }
}

- (IBAction)playVideo:(id)sender {
        if (_isLocal == YES){
                self.operationDevice = [_lanDeviceDict objectForKey:_selectedDeviceID];
                self.cameraControl = [[HKCameraControl alloc] initWithDeviceID:_selectedDeviceID hkid:_operationDevice.deviceDesc.localDeviceId asLocalDevice:_operationDevice.deviceDesc.isLocalDevice];
        }else{
        
                self.operationDevice = [_WanDeviceDict objectForKey:_selectedDeviceID];
                self.cameraControl = [[HKCameraControl alloc] initWithDeviceID:_selectedDeviceID hkid:_operationDevice.deviceDesc.localDeviceId asLocalDevice:_operationDevice.deviceDesc.isLocalDevice];
        }
        _connectingType = ConnectingTypeNone;
        BOOL bMainStream = YES;//主/子码流方式呼叫
        int ret = -1;
        char callid[64] = {0};
        if (_operationDevice.deviceDesc.isLocalDevice) {
                //局域网设备呼叫视频
                ret = hk_DoLanInvite_EX(callid, _operationDevice.deviceDesc.localDeviceId, _operationDevice.deviceDesc.deviceType, 0, bMainStream);
                if (ret < 0) {
                        self.operationDevice = nil;
                        self.cameraControl = nil;
                        [self showAlertWithInfo:@"局域网设备呼叫视频失败"];
                } else {
                        _operationDevice.videoCallid = [NSString stringWithUTF8String:callid];
                        [self openVideoSuccess];
                }
        } else {
                //互联网呼叫视频
                _connectingType = ConnectingTypeVideoWait105;
                
                NSString *strAsscode = self.asscode.text;
                char *accessPassword = [strAsscode UTF8String];//呼叫设备备的时候，需要设备的访问密码，这里假设设备的密码为5173
                ret = sccWANDevidCalling(bMainStream, callid, _operationDevice.deviceDesc.deviceId, accessPassword, _operationDevice.deviceDesc.deviceType, 0);
                if (ret < 0) {
                        self.operationDevice = nil;
                        self.cameraControl = nil;
                        _connectingType = ConnectingTypeNone;
                        [self showAlertWithInfo:@"互联网设备呼叫视频失败"];
                } else {
                        //MARK: 呼叫接口返回成功，等待互联网105回调
                        _operationDevice.videoCallid = [NSString stringWithUTF8String:callid];
                        NSLog(@"互联网呼叫第一步成功");
                }
        }
}

- (IBAction)stopVideo:(id)sender {
        //1、把视频callid从解码器中移除
        [_decodeSDK removeCallID:_operationDevice.videoCallid];
        _connectingType = ConnectingTypeNone;
        //2、关闭视频，其实关闭视频与音频的接口都是一样的，只不过callid不同
        if (_operationDevice.deviceDesc.isLocalDevice) {
                hk_DoLanClose(_operationDevice.videoCallid.UTF8String);
        } else {
                hk_DoMonCloseDialog(_operationDevice.deviceDesc.deviceId, (char *)_operationDevice.videoCallid.UTF8String);
        }
        _operationDeviceLabel.text = nil;
        _operationDevice.videoCallid = nil;
        self.operationDevice = nil;
        self.cameraControl = nil;
}

- (IBAction)refresh:(id)sender {
        [_lanDeviceDict removeAllObjects];
        //刷新局域网设备，当程序进入后台时，请调用hk_LanRefresh_EX(2);
        hk_LanRefresh_EX(1);
}

//收听设备的声音
- (IBAction)listen:(id)sender {
        _connectingType = ConnectingTypeNone;
        int ret = -1;
        char callid[64] = {0};
        if (_operationDevice.deviceDesc.isLocalDevice) {
                //局域网呼叫音频收听
                ret = hk_DoLanAudioInvite(callid, _operationDevice.deviceDesc.localDeviceId, 0, _operationDevice.deviceDesc.deviceType, 0);
                if (ret < 0) {
                        [self showAlertWithInfo:@"局域网设备音频收听失败"];
                } else {
                        _operationDevice.audioListenCallID = [NSString stringWithUTF8String:callid];
                        [self openListenAudioSuccess];
                }
        } else {
                //互联网呼叫音频收听
                _connectingType = ConnectingTypeListenAudioWait105;
                ret = hk_DoWanAudioInvite(callid, _operationDevice.deviceDesc.deviceId, 0, _operationDevice.deviceDesc.deviceType, 0);
                if (ret < 0) {
                        _connectingType = ConnectingTypeNone;
                        [self showAlertWithInfo:@"互联网设备音频收听失败"];
                } else {
                        //MARK: 呼叫接口调用成功，等待互联网105回调
                        _operationDevice.audioListenCallID = [NSString stringWithUTF8String:callid];
                        NSLog(@"互联网音频收听第一步成功");
                }
        }
}

- (IBAction)stopListen:(id)sender {
        //1、将音频收听callid从解码器中移除
        [_decodeSDK removeAudioCallID:_operationDevice.audioListenCallID];
        _connectingType = ConnectingTypeNone;
        //2、关闭音频收听
        if (_operationDevice.deviceDesc.isLocalDevice) {
                hk_DoLanClose(_operationDevice.audioListenCallID.UTF8String);
        } else {
                hk_DoMonCloseDialog(_operationDevice.deviceDesc.deviceId, (char *)_operationDevice.audioListenCallID.UTF8String);
        }
        _operationDevice.audioListenCallID = nil;
}

//说话到设备
- (IBAction)speak:(id)sender {
        _connectingType = ConnectingTypeNone;
        int ret = -1;
        char callid[64] = {0};
        if (_operationDevice.deviceDesc.isLocalDevice) {
                //局域网呼叫音频说
                ret = hk_DoLanAudioSayInvite(callid, _operationDevice.deviceDesc.localDeviceId, 0, _operationDevice.deviceDesc.deviceType, 0);
                if (ret < 0) {
                        [self showAlertWithInfo:@"局域网设备音频说失败"];
                } else {
                        _operationDevice.audioSpeakCallID = [NSString stringWithUTF8String:callid];
                        [self openSpeakerAudioSuccess];
                }
        } else {
                //互联网呼叫音频说
                _connectingType = ConnectingTypeSpeakerAudioWait105;
                ret = hk_DoWanAudioSayInvite(callid, _operationDevice.deviceDesc.deviceId, 0, _operationDevice.deviceDesc.deviceType, 0);
                if (ret < 0) {
                        _connectingType = ConnectingTypeNone;
                        [self showAlertWithInfo:@"互联网设备音频说失败"];
                } else {
                        //MARK: 呼叫接口调用成功，等待互联网105回调
                        _operationDevice.audioSpeakCallID = [NSString stringWithUTF8String:callid];
                        NSLog(@"互联网音频说第一步成功");
                }
        }
}

- (IBAction)stopSpeak:(id)sender {
        //1、停止采集音频
        [_displayView openAudioSpeaker:NO];
        //2、关闭解码器音频说
        [_decodeSDK talkClose];
        //3、关闭设备音频说
        if (_operationDevice.deviceDesc.isLocalDevice) {
                hk_DoLanClose(_operationDevice.audioSpeakCallID.UTF8String);
        } else {
                hk_DoMonCloseDialog(_operationDevice.deviceDesc.deviceId, (char *)_operationDevice.audioSpeakCallID.UTF8String);
        }

        _operationDevice.audioSpeakCallID = nil;
}

//抓拍图像
- (IBAction)capture:(id)sender {
        [_displayView snapShotToPath:@"抓拍路径" withPhotoAlbum:YES withAudio:NO];
}

//云台上，注意：云台上、下、左、右接口的触发条件为touch down、touch up inside、touch up outside
- (IBAction)ptzUp:(id)sender {
        [self ptzOperation:3];
}

//云台下
- (IBAction)ptzDown:(id)sender {
        [self ptzOperation:4];
}

//云台左
- (IBAction)ptzLeft:(id)sender {
        [self ptzOperation:1];
}

//云台右
- (IBAction)ptzRight:(id)sender {
        [self ptzOperation:2];
}

//全方位巡航
- (IBAction)tpzScan:(id)sender {
        [self ptzScaning];
}


//透传数据到外网设备
- (IBAction)sendDataToWanOrLan:(id)sender{
        if(_isLocal == NO){
                char *devid = self.operationDevice.deviceDesc.deviceId;
                NSString *text= [NSString stringWithFormat:@"data=%@;",self.sendDataTextField.text ];
                
                if(text == nil){
                        text = @"data=your data is nil;";
                }else{}
                const char *txt = [text UTF8String];
                
                sccWanSendDataDev(devid,txt,0);
        }else{
                int hkid = self.operationDevice.deviceDesc.localDeviceId;
                NSString *text= [NSString stringWithFormat:@"data=%@;",self.sendDataTextField.text];
                if(text == nil){
                        text = @"data=your data is nil;";
                }
                const char *txt = [text UTF8String];
                sccLanSendDataDev(hkid,txt,0);
        
        }
}

//录像
- (IBAction)recordDev:(id)sender{
        //如果正在录像的话 则停止录像
        if(_isRecord==YES){
           [_recordBtn setTitle:@"record" forState:UIControlStateNormal];
           [_displayView stopRecord];
           _isRecord = NO;
        }else{
           [_recordBtn setTitle:@"stoprecord" forState:UIControlStateNormal];
 
          
           //录像文件名称
           struct timeval tv;
           gettimeofday(&tv, NULL);
           struct tm *tm = localtime(&tv.tv_sec);
           NSString *filename = [NSString stringWithFormat:@"%.4d%.2d%.2d%.2d%.2d%.2d.mov", tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday, tm->tm_hour, tm->tm_min, tm->tm_sec];
           
           //录像保存路径
           NSString *targetPath = [[self RecordTargetDir:_selectedDeviceID] stringByAppendingPathComponent:filename];
           NSLog(@"开始录像 %@", targetPath);
            
           //开始录像
           [_displayView startRecordWithPath:targetPath withPhotoAlbum:NO videoCodec:0];
           _isRecord = YES;
        }

}


//创建路径
- (NSString *)RecordTargetDir:(NSString *)deviceID
{
        NSString *rootPath = [[self RecordRootDir] stringByAppendingPathComponent:deviceID];
        NSString *dirPath = [rootPath stringByAppendingPathComponent:@"TargetDir"];
        [self makeDirectory:dirPath];
        return dirPath;
}

- (NSString *)RecordRootDir
{
        NSString *cachePath = [self cacheDirectoryPath];
        NSString *dirPath = [cachePath stringByAppendingPathComponent:@"Record"];
        [self makeDirectory:dirPath];
        return dirPath;
}

- (NSString *)cacheDirectoryPath
{
        NSArray *paths=NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        return [paths objectAtIndex:0];
}

- (void)makeDirectory:(NSString *)path {
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
}

//获取录像路径

@end
