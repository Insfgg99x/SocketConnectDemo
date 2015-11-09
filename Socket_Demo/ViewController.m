//
//  ViewController.m
//  Socket_Demo
//
//  Created by 夏桂峰 on 15/11/8.
//  Copyright (c) 2015年 夏桂峰. All rights reserved.
//

#import "ViewController.h"
#import "Header.h"
#import "Message.h"

@interface ViewController ()<NSStreamDelegate,
                             UITableViewDataSource,
                             UITableViewDelegate,
                             UITextFieldDelegate,
                             UIAlertViewDelegate>
{
    //输入流
    NSInputStream *_inputStream;
    //输出流
    NSOutputStream *_outputStream;
    NSMutableArray *_dataArray;
    UITableView *_tbView;
    //底部输入视图
    UIView *_inputView;
    //连接出错
    BOOL _isConnectFailed;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUp];
    [self connectToHost:kHost withPort:kPort];
    [_outputStream addObserver:self forKeyPath:@"streamStatus" options:NSKeyValueObservingOptionNew context:nil];
    [self createUI];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([object isKindOfClass:[NSOutputStream class]])
    {
        if([keyPath isEqualToString:@"streamStatus"])
        {
            NSStreamStatus status=[[change objectForKey:@"new"] integerValue];
            if(status==NSStreamStatusError)
            {
                NSLog(@"连接断开");
            }
            
        }
    }
}
/**
 * 初始设置
 */
-(void)setUp
{
    self.view.backgroundColor=[UIColor whiteColor];
    self.title=@"Socket Demo";
    self.automaticallyAdjustsScrollViewInsets=NO;
    self.navigationController.navigationBar.barStyle=UIBarStyleBlack;
    _dataArray=[NSMutableArray array];
    //注册键盘出现和隐藏的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardWillHideNotification object:nil];
}
/**
 *  与主机建立socket连接
 *
 *  @param host 主机地址
 *  @param port 端口号
 */
-(void)connectToHost:(NSString *)host withPort:(int)port
{
    _isConnectFailed=NO;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    _inputStream=(__bridge NSInputStream *)readStream;
    _outputStream=(__bridge NSOutputStream *)writeStream;
    
    _inputStream.delegate=self;
    _outputStream.delegate=self;
    
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_inputStream open];
    [_outputStream open];
}
/**
 * 创建表视图
 */
-(void)createTableView
{
    _tbView=[[UITableView alloc]initWithFrame:CGRectMake(0, 64, kWidth, kHeight-64-44) style:UITableViewStylePlain];
    _tbView.delegate=self;
    _tbView.dataSource=self;
    _tbView.separatorStyle=UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tbView];
}
/**
 * 搭建界面
 */
-(void)createUI
{
    [self createTableView];
    _inputView=[[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_tbView.frame), kWidth, 44)];
    _inputView.backgroundColor=[UIColor lightGrayColor];
    [self.view addSubview:_inputView];
    
    UITextField *inputField=[[UITextField alloc]initWithFrame:CGRectMake(50, 6, kWidth-70, 32)];
    inputField.returnKeyType=UIReturnKeySend;
    inputField.backgroundColor=[UIColor whiteColor];
    inputField.borderStyle=UITextBorderStyleRoundedRect;
    inputField.delegate=self;
    [_inputView addSubview:inputField];
}
/**
 * 键盘位置改变时调用的方法
 */
-(void)keyboardFrameChanged:(NSNotification *)sender
{
    CGRect kbFrame=[[sender.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect tbFrame=_tbView.frame;
    tbFrame.size.height=kHeight-64-44-(kHeight-kbFrame.origin.y);
    _tbView.frame=tbFrame;
    CGRect inFrame=_inputView.frame;
    inFrame.origin.y=kHeight-(kHeight-kbFrame.origin.y)-44;
    _inputView.frame=inFrame;
}

#pragma mark -
#pragma mark - UITextField协议
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(!textField.text)
        return YES;
    if(_isConnectFailed)
    {
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"提示" message:@"连接出错" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"重连", nil];
        [alert show];
        return YES;
    }
    if(textField.text.length>0)
    {
        //发送消息
        [self sendMessage:textField.text];
        textField.text=nil;
    }
    return YES;
}
#pragma mark -
#pragma mark - UIAlertView
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //重连
    if(buttonIndex==1)
    {
        [self connectToHost:kHost withPort:kPort];
    }
}
#pragma mark -
#pragma mark - NSStream协议
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventErrorOccurred:
            
             NSLog(@"连接出错");
             _isConnectFailed=YES;
             break;
        case NSStreamEventOpenCompleted:
             //NSLog(@"打开输入输出流完成");
             break;
        case NSStreamEventHasBytesAvailable:
             NSLog(@"有数据可读取");
            [self readData];
             break;
        case NSStreamEventHasSpaceAvailable:
             //NSLog(@"有数据可发送");
             break;
        case NSStreamEventEndEncountered:
             NSLog(@"连接结束");
            [_inputStream close];
            [_outputStream close];
            [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            _isConnectFailed=YES;
            break;
        default:
            break;
    }
}
/**
 *  发送消息
 *
 *  @param msg 消息
 */
-(void)sendMessage:(NSString *)msg
{
    if(msg.length>0)
    {
        NSData *data=[msg dataUsingEncoding:NSUTF8StringEncoding];
        [_outputStream write:data.bytes maxLength:data.length];
        Message *message=[Message messageWithMsg:msg andType:MessageTypeSend];
        [_dataArray addObject:message];
        [_tbView reloadData];
        NSIndexPath *indexPath=[NSIndexPath indexPathForRow:_dataArray.count-1 inSection:0];
        [_tbView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}
/**
 *  读取数据
 */
-(void)readData
{
    uint8_t buffer[1024];
    NSInteger length=[_inputStream read:buffer maxLength:sizeof(buffer)];
    NSData *data=[NSData dataWithBytes:buffer length:length];
    NSString *msg=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    Message *message=[Message messageWithMsg:msg andType:MessageTypeReceive];
    [_dataArray addObject:message];
    [_tbView reloadData];
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:_dataArray.count-1 inSection:0];
    [_tbView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
}
#pragma mark - 
#pragma mark - UITableView协议
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID=@"cellID";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:cellID];
    if(!cell)
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    cell.textLabel.textAlignment=NSTextAlignmentRight;
    if(_dataArray.count>0)
    {
        Message *message=_dataArray[indexPath.row];
        cell.textLabel.text=message.msg;
        if(message.messageType)
            cell.textLabel.textAlignment=NSTextAlignmentLeft;
    }
    cell.textLabel.adjustsFontSizeToFitWidth=YES;
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    return cell;
}
#pragma mark - 
#pragma mark - UIScrollView协议
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.view endEditing:YES];
}
@end
