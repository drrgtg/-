//
//  ViewController.m
//  AudioRecordingAnd...
//
//  Created by FeZo on 16/6/23.
//  Copyright © 2016年 FezoLsp. All rights reserved.
//

#import "ViewController.h"

#define kRecordAudioFile @"myRecord.caf"

@interface ViewController ()
<
AVAudioPlayerDelegate,
AVAudioRecorderDelegate
>

/**
 *  biubiu录音
 */
@property (nonatomic,strong)AVAudioRecorder *recorder;//音频录音机
/**
 *  biubiu的必须对player强持有。
 */
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;//音频播放器，用于播放录音文件
@property (nonatomic,strong) NSTimer *timer;//录音声波监控（注意这里暂时不对播放进行监控）
@property (weak, nonatomic) IBOutlet UIProgressView *progress;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.progress.progress = 0.0f;
    // Do any additional setup after loading the view, typically from a nib.
}
#pragma mark ------------流媒体音频播放 --------------
- (IBAction)clickBtn4:(id)sender
{
    /**
     *  建议使用第三方库解决问题。具体有待研究
     */
}

#pragma mark ------------录音 --------------
/**
 *  录音
 *
 *  @param sender
 */
- (IBAction)clickBtn3:(id)sender
{
    [self setAudioSession];
}
-(AVAudioRecorder *)recorder
{
    if (!_recorder) {
        //创建录音文件保存路径
        NSURL *url=[self getSavePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _recorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _recorder.delegate=self;
        _recorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _recorder;
}
/**
 *  创建播放器
 *
 *  @return 播放器
 */
-(AVAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        NSURL *url=[self getSavePath];
        NSError *error=nil;
        _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
        _audioPlayer.numberOfLoops=0;
        [_audioPlayer prepareToPlay];
        if (error) {
            NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioPlayer;
}
/**
 *  录音声波监控定制器
 *
 *  @return 定时器
 */
-(NSTimer *)timer{
    if (!_timer) {
        _timer=[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return _timer;
}
-(void)audioPowerChange
{
    [self.recorder updateMeters];//更新测量值
    float power= [self.recorder averagePowerForChannel:0];//取得第一个通道的音频，注意音频强度范围时-160到0
    CGFloat progress=(1.0/160.0)*(power+160.0);
    [self.progress setProgress:progress];
}
- (void)setAudioSession
{
    
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    
    if (![self.recorder isRecording]) {
        [self.recorder record];//首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
        self.timer.fireDate=[NSDate distantPast];
    }
    else
    {
        [self.recorder pause];
        self.timer.fireDate=[NSDate distantFuture];
    }
}
- (IBAction)stopRecorder:(id)sender
{
    [self.recorder stop];
    self.timer.fireDate=[NSDate distantFuture];
    self.progress.progress=0.0;
}

/**
 *  获得录音文件保存位置
 *
 *  @return 录音文件位置
 */
-(NSURL *)getSavePath{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:kRecordAudioFile];
    NSLog(@"file path:%@",urlStr);
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}
/**
 *  录音文件信息设置
 *
 *  @return 录音设置
 */
-(NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //....其他设置等
    return dicM;
}
#pragma mark ------------recorderDelegate --------------
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (![self.audioPlayer isPlaying]) {
        [self.audioPlayer play];
    }
    NSLog(@"录音完成!");
}



#pragma mark ------------本地音频 --------------

/**
 *  播放音频
 *
 *  @param sender
 */
- (IBAction)clickBtn2:(id)sender
{
    //设置播放会话，在后台可以继续播放（还需要设置程序允许后台运行模式）

    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
        //启用远程控制事件接收
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [self becomeFirstResponder];
    
    [self playM4aAudio:@"小幸运长音频.m4a"];
}
/**
 *  后台控制，比如线控(耳机控制)
 */
#pragma mark 远程控制事件
-(void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    NSLog(@"%zd,%zd",event.type,event.subtype);
    if(event.type==UIEventTypeRemoteControl){
        switch (event.subtype)
        {
            case UIEventSubtypeRemoteControlPlay://100
                [self.audioPlayer play];
                break;
            case UIEventSubtypeRemoteControlPause:
            {
                NSLog(@"%@",@"UIEventSubtypeRemoteControlPause");
                if (self.audioPlayer.isPlaying) {
                    [self.audioPlayer pause];
                }else{
                    [self.audioPlayer play];
                }
            }
                break;
            case UIEventSubtypeRemoteControlStop:
                if (self.audioPlayer.isPlaying) {
                    [self.audioPlayer stop];
                }
                break;
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (self.audioPlayer.isPlaying) {
                    [self.audioPlayer pause];
                }else{
                    [self.audioPlayer play];
                }
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"Next...");
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                NSLog(@"Previous...");
                break;
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                NSLog(@"Begin seek forward...");
                break;
            case UIEventSubtypeRemoteControlEndSeekingForward:
                NSLog(@"End seek forward...");
                break;
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                NSLog(@"Begin seek backward...");
                break;
            case UIEventSubtypeRemoteControlEndSeekingBackward:
                NSLog(@"End seek backward...");
                break;
            default:
                break;
        }
    }
}



-(void)playM4aAudio:(NSString *)name
{
    //获得本地文件路径
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    NSURL *audioUrl = [NSURL fileURLWithPath:path];
    NSError *err=nil;
    //初始化player（只能播放本地音频）.
    self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:audioUrl error:&err];
    self.audioPlayer.delegate=self;
    //缓存到内存中播放，如果失败，则不播放
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    self.audioPlayer.numberOfLoops = MAXFLOAT;
    NSLog(@"%@",self.audioPlayer.settings);
    /**
     - (BOOL)prepareToPlay;
    - (BOOL)play;
    - (BOOL)playAtTime:(NSTimeInterval)time NS_AVAILABLE(10_7, 4_0); // play a sound some time in the future. time is an absolute time based on and greater than deviceCurrentTime.
    - (void)pause;			 //pauses playback, but remains ready to play.
    - (void)stop;
     */
}
#pragma mark ------------AVAudioPlayer delegate --------------
/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"%@,%d",player,flag);
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    NSLog(@"%@",error);
}
/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player NS_DEPRECATED_IOS(2_2, 8_0)
{
    NSLog(@"%s",__func__);
}

/* audioPlayerEndInterruption:withOptions: is called when the audio session interruption has ended and this player had been interrupted while playing. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags NS_DEPRECATED_IOS(6_0, 8_0)
{
    NSLog(@"%s",__func__);

}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags NS_DEPRECATED_IOS(4_0, 6_0)
{
    NSLog(@"%s",__func__);

}

/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player NS_DEPRECATED_IOS(2_2, 6_0)
{
    NSLog(@"%s",__func__);

}

#pragma mark ------------短小音频 --------------
/**
 *  播放短效音频
 *
 *  @param sender
 */
- (IBAction)clickBtn1:(id)sender
{
    [self playSoundEffect:@"小幸运短效音频.aif"];//可以播放最多30秒的短效音频
    
}
-(void)playSoundEffect:(NSString *)name
{
    NSString *audioFile=[[NSBundle mainBundle] pathForResource:name ofType:nil];
    //1.获得系统声音ID
    SystemSoundID soundID=999;
    /**
     * inFileUrl:音频文件url
     * outSystemSoundID:声音id（此函数会将音效文件加入到系统音频服务中并返回一个长整形ID）
     */
    NSURL *fileUrl=[NSURL fileURLWithPath:audioFile];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileUrl , &soundID);
    //如果需要在播放完之后执行某些操作，可以调用如下方法注册一个播放完成回调函数
    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL,soundCompleteCallback, NULL);
    //2.播放音频
    AudioServicesPlaySystemSound(soundID);//播放音效
//        AudioServicesPlayAlertSound(soundID);//播放音效并震动
}

/**
 *  播放完成回调函数
 *
 *  @param soundID    系统声音ID
 *  @param clientData 回调时传递的数据
 */
void soundCompleteCallback(SystemSoundID soundID,void * clientData){
    NSLog(@"播放完成...");
}
@end
