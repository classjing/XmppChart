//
//  AppDelegate.m
//  XmppChart
//
//  Created by classjing on 14-4-1.
//  Copyright (c) 2014年 define. All rights reserved.
//

#import "AppDelegate.h"

#define kMainStroyboardName     @"Main"
#define kLoginStoryboardName    @"Login"

// 赋值语句不能够写在.h中，只能写在.m中
// 使用此种方式，可以保证常量字符串在内存中有且仅有一个地址
NSString * const kXMPPLoginUserNameKey = @"xmppUserName";
NSString * const kXMPPLoginPasswordKey = @"xmppPassword";
NSString * const kXMPPLoginHostNameKey = @"xmppHostName";

@interface AppDelegate() <XMPPStreamDelegate>
{
    LoginFailedBlock        _failedBlock;
    
    XMPPReconnect           *_xmppReconnect;                // 重新连接的模块
    XMPPvCardCoreDataStorage    *_xmppvCardCoreDataStorage; // 电子名片数据存储扩展
}

/**
 *  设置XMPPStream
 */
- (void)setupXmppStream;

/**
 *  释放XMPPStream
 */
- (void)teardownXmppStream;

/**
 *  连接到服务器
 */
- (void)connect;

/**
 *  断开连接
 */
- (void)disconnect;

/**
 *  用户上线
 */
- (void)goOnline;

/**
 *  用户下线
 */
- (void)goOffline;

@end

@implementation AppDelegate

#pragma mark - 切换Storyboard
- (void)showStoryboardWithBoardName:(NSString *)boardName
{
    // 如果是点登录按钮或者注册按钮，此时_failedBlock是有内容
    _failedBlock = nil;
    
    // 在OC开发中UIView都是在使用时加载的，懒加载，延迟加载
    // 实例化MainStoryboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:boardName bundle:nil];
    
    // 在主线程上更新Storyboard
    dispatch_async(dispatch_get_main_queue(), ^{
        self.window.rootViewController = storyboard.instantiateInitialViewController;
        
        if (!_window.isKeyWindow) {
            [_window makeKeyAndVisible];
        }
    });
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // 实例化window
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    // 设置颜色日志
//    [DDLog addLogger:[DDTTYLogger sharedInstance]];
//    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
//    
//    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor blueColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
    
    // 1. 实例化XMPPStream
    [self setupXmppStream];
    
    return YES;
}

#pragma mark - 注销激活状态
- (void)applicationWillResignActive:(UIApplication *)application
{
    [self disconnect];
}

#pragma mark - 应用程序被激活
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self connect];
}

// 应用程序收到来自系统的内存警告时调用
// applicationDidReceiveMemoryWarning默认会做什么？
// 野指针？ 指向一块已经被销毁的内存地址
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    // 安全释放
    //    NSString *str = [[NSString alloc] init];
    //    str = nil;
    // weak assign
    // weak关键字，在对象被释放后，自动将指针指向nil，而assign不会
}

// 系统退出到后台，如果内存不足，系统会自动调用AppDelegate的dealloc方法
// 可以在此方法中，做内存清理工作
- (void)dealloc
{
    [self teardownXmppStream];
}

#pragma mark - 成员方法
#pragma mark 登录&注册
- (void)connectOnFailed:(LoginFailedBlock)faild
{
    // 1. 保存块代码
    _failedBlock = faild;
    
    // 如果已经存在到服务器的长连接，先断开到服务器的连接
    // 提示：在使用连接之前，需要首先判断连接是否存在，
    // 因为再次建立的连接有可能应为MyJID的不同，让服务器无法区分准确的客户端！
    if (!_xmppStream.isDisconnected) {
        [_xmppStream disconnect];
    }
    
    // 连接到服务器
    [self connect];
}

#pragma mark 用户注销
- (void)logout
{
    [self disconnect];
    
    // 切换到Login视图控制器
    [self showStoryboardWithBoardName:kLoginStoryboardName];
}

#pragma mark - XMPP相关方法
- (void)setupXmppStream
{
    // 断言！再此程序断言：_xmppStream必须是nil，如果不是nil，程序强行中断！
    // 要求调用方，必须自觉自律，要求是唯一的，你就应该是唯一的。
    // 断言针对程序的核心代码区，有重要的保护作用！
    // 要求在开发过程中，就能够及时的发现错误，而不是去频繁的修改核心代码！
    NSAssert(_xmppStream == nil, @"XMPPStream被重复实例化！");
    
    // 1. 实例化
    _xmppStream = [[XMPPStream alloc] init];
    
    // 2. 实例化要扩展的模块
    // 1> 重新连接
    _xmppReconnect = [[XMPPReconnect alloc] init];
    // 2> 电子名片
    _xmppvCardCoreDataStorage = [XMPPvCardCoreDataStorage sharedInstance];
    _xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardCoreDataStorage];
    _xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
    
    // 3> 花名册
    _xmppRosterCoreDataStorage = [[XMPPRosterCoreDataStorage alloc] init];
    _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterCoreDataStorage];
    // 自动接收好友订阅请求，当前版本已经无需设置
    // 提示后续可以探索，需要认证添加好友的功能！
    [_xmppRoster setAutoAcceptKnownPresenceSubscriptionRequests:YES];
    // 自动从服务器加载好友信息
    [_xmppRoster setAutoFetchRoster:YES];
    
    // 4> 消息归档
    // 提示：不要使用sharedInstance，否则不同账号的聊天记录会保存在同一个CoreData数据库中
    _xmppMessageArchivingCoreDataStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    _xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_xmppMessageArchivingCoreDataStorage];
    //5>聊天室
    _xmppRoomCoreDataStorage = [[XMPPRoomCoreDataStorage alloc] init];
//     _xmppStream.myJID = [XMPPJID jidWithUser:@"lisi" domain:@"zhengjing.local" resource:nil];
//    _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self jid:_xmppStream.myJID];
    
    //[_xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // 3. 激活扩展模块
    [_xmppReconnect activate:_xmppStream];
    [_xmppvCardTempModule activate:_xmppStream];
    [_xmppvCardAvatarModule activate:_xmppStream];
    [_xmppRoster activate:_xmppStream];
    [_xmppMessageArchiving activate:_xmppStream];
    //[_xmppRoom activate:_xmppStream];
    //[_xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // 4. 设置代理
    // 提示：使用类似框架时，包括看网络开源代码，大多数会使用dispatch_get_main_queue()
    // 使用主线程队列通常不容易出错，自己开发时，一定要用多线程。
    // 一旦出问题，通常是UI更新的问题，此时对于理解多线程的工作非常有帮助！
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

- (void)teardownXmppStream
{
    // 在做内存清理工作的步骤，与实例化XMPPStream的工作刚好相反
    // 1. 删除XMPPStream的代理
    [_xmppStream removeDelegate:self];
    
    // 2. 断开XMPPStream的连接
    [_xmppStream disconnect];
    
    // 3. 停止模块
    [_xmppReconnect deactivate];
    [_xmppvCardTempModule deactivate];
    [_xmppvCardAvatarModule deactivate];
    [_xmppRoster deactivate];
    [_xmppMessageArchiving deactivate];
    
    // 4. 清理内存
    _xmppReconnect = nil;
    
    _xmppvCardAvatarModule = nil;
    _xmppvCardCoreDataStorage = nil;
    _xmppvCardTempModule = nil;
    
    _xmppRosterCoreDataStorage = nil;
    _xmppRoster = nil;
    
    _xmppMessageArchivingCoreDataStorage = nil;
    _xmppMessageArchiving = nil;
    
    _xmppStream = nil;
}

- (void)connect
{
    // 2. 从系统偏好读取用户信息
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *hostName = [defaults stringForKey:kXMPPLoginHostNameKey];
    NSString *userName = [defaults stringForKey:kXMPPLoginUserNameKey];
    
    // 如果用户名或者主机为空，不再继续
    if (hostName.length == 0 || userName.length == 0) {
        // 用户名和主机都为空说明用户没有登录，通常是第一次运行程序
        // 直接显示登录窗口
        [self showStoryboardWithBoardName:kLoginStoryboardName];
        
        return;
    }
    
    // 设置XMPPStream的hostName&JID
    _xmppStream.hostName = hostName;
    _xmppStream.myJID = [XMPPJID jidWithUser:userName domain:hostName resource:nil];
    
    // 连接
    // GCDAsnycSocket框架中，所有的网络通讯都是异步的
    NSError *error = nil;
    if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
        DDLogInfo(@"%@", error.localizedDescription);
    } else {
        DDLogInfo(@"发送连接请求成功");
    }
}

- (void)disconnect
{
    // 通知服务器，我下线了
    [self goOffline];
    
    // 真正的断开连接
    [_xmppStream disconnect];
}

- (void)goOnline
{
    DDLogInfo(@"用户上线");
    
    // 通知服务器用户上线，服务器知道用户上线后，可以根据服务器记录的好友关系，
    // 通知该用户的其他好友，当前用户上线
    XMPPPresence *presence = [XMPPPresence presence];
    DDLogInfo(@"%@", presence);
    
    // 将展现状态发送给服务器
    [_xmppStream sendElement:presence];
}

- (void)goOffline
{
    DDLogInfo(@"用户下线");
    
    // 通知服务器用户下线
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    DDLogInfo(@"%@", presence);
    
    [_xmppStream sendElement:presence];
}

#pragma mark - XMPPStream协议代理方法
#pragma mark 完成连接
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    DDLogInfo(@"连接成功");
    
    // 登录到服务器，将用户密码发送到服务器验证身份
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPLoginPasswordKey];
    
    if (_isRegisterUser) {
        // 注册
        [_xmppStream registerWithPassword:password error:nil];
    } else {
        // 用户登录
        [_xmppStream authenticateWithPassword:password error:nil];
    }
}

#pragma mark 断开连接
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    DDLogInfo(@"断开连接 %@", error);
    if (_failedBlock && error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _failedBlock(kLoginNotConnection);
        });
    }
}

#pragma mark 注册成功
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    [self goOnline];
    [self showStoryboardWithBoardName:kMainStroyboardName];
}

#pragma mark 注册失败
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error
{
    // 注册失败，要通知登录窗口
    // 通常用户名重复会注册失败
    // 判断出错处理块代码是否定义
    if (_failedBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _failedBlock(kLoginRegisterError);
        });
    }
}

#pragma mark 身份验证成功
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogInfo(@"身份验证成功!");
    
    // 通知服务器用户上线，QQ上面自己头像“亮”是客户端干的，只需要通知服务器，上线即可
    // 后续操作都是客户端针对状态，自行调整的
    [self goOnline];
    
    // 显示Main.storyboard
    [self showStoryboardWithBoardName:kMainStroyboardName];
}

#pragma mark 用户名或者密码错误
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    DDLogInfo(@"用户名或者密码错误");
    
    // 判断出错处理块代码是否定义
    if (_failedBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _failedBlock(kLoginLogonError);
        });
    }
    
    // 如果用户名或者密码错误，将系统偏好中的内容清除
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults removeObjectForKey:kXMPPLoginHostNameKey];
    [defaults removeObjectForKey:kXMPPLoginPasswordKey];
    [defaults removeObjectForKey:kXMPPLoginUserNameKey];
    
    [defaults synchronize];
}

#pragma mark 接收到其他用户的展现数据
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    // 通过跟踪发现，如果展现的类型是subscribe，说明是由其他客户端发起的添加好友请求
    // 如果展现的类型是subscribe，直接接受用户请求
    if ([presence.type isEqualToString:@"subscribe"]) {
        // 订阅我的人是presence.from
        // 接受from的请求即可
        [_xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
    }
}



@end

