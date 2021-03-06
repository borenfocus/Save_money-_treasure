//
//  MycarTableViewController.m
//  车主省钱宝
//
//  Created by chenghao on 15/3/16.
//  Copyright (c) 2015年 ebaochina. All rights reserved.
//

#import "MycarTableViewController.h"
#import "Utils.h"
#import "MycarTableViewCell.h"
#import "WritecarinfoTableViewController.h"
#import <AFHTTPRequestOperationManager.h>
#import <CommonCrypto/CommonDigest.h>
#import "NullView.h"
#import "Lloadview.h"
#import "MainInfo.h"
#import "AppDelegate.h"
#import "MJRefresh.h"
#import "Checkshuju.h"
@interface MycarTableViewController ()<NullViewdelegate>
@property(nonatomic,retain)AFHTTPRequestOperationManager *manager;
@property(nonatomic,retain)NSMutableArray* carinfos;
@property(nonatomic,retain)NullView* nullview;
@property(nonatomic,retain)Lloadview *loadview;
@property(nonatomic)int page;
@end

@implementation MycarTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // 2.集成刷新控件
    [self setupRefresh];
    self.manager = [AFHTTPRequestOperationManager manager];
    self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    self.page = 1;
    self.carinfos = [NSMutableArray array];
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addcartostoptongzhi:) name:@"addcartostop" object:nil];
    
    [self Usercarforhttp];

}
/**
 *  集成刷新控件
 */
- (void)setupRefresh
{
    // 2.上拉加载更多(进入刷新状态就会调用self的footerRereshing)
    [self.tableView addFooterWithTarget:self action:@selector(footerRereshing)];
    self.tableView.footerPullToRefreshText = @"上拉加载更多数据";
    self.tableView.footerReleaseToRefreshText = @"松开马上加载";
    self.tableView.footerRefreshingText = @"加载中...";
}
- (void)footerRereshing
{
    self.page++;
    [self Usercarforhttp];
}
- (void)delayView{
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"Lloadview" owner:nil options:nil]; //&1
    self.loadview = [views lastObject];
    self.loadview.frame = Screen.bounds;
    [[UIApplication sharedApplication].keyWindow addSubview:self.loadview];
}
-(void)deleteView{
    [self.loadview removeFromSuperview];
}

//调用弹框视图
- (void)addpopview:(NSString*)title{
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NullView" owner:nil options:nil]; //&1
    self.nullview = [views lastObject];
    [self.nullview addpopview:self.nullview andtitle:title andbutitle:@"添加车辆"];
    self.nullview.delegate = self;
    [self.view addSubview:self.nullview];
}
-(void)NullViewMenumehod{
    [self performSegueWithIdentifier:@"Editcar" sender:nil];
}
- (void)addcartostoptongzhi:(NSNotification *)text{
    [self Usercarforhttp];
}
//MD5加密
-(NSString *)md5:(NSString *)str {
    const char *cStr = [str UTF8String];//转换成utf-8
    unsigned char result[16];//开辟一个16字节（128位：md5加密出来就是128位/bit）的空间（一个字节=8字位=8个二进制数）
    CC_MD5( cStr, strlen(cStr), result);
    /*
     extern unsigned char *CC_MD5(const void *data, CC_LONG len, unsigned char *md)官方封装好的加密方法
     把cStr字符串转换成了32位的16进制数列（这个过程不可逆转） 存储到了result这个空间中
     */
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
    /*
     x表示十六进制，%02X  意思是不足两位将用0补齐，如果多余两位则不影响
     NSLog("%02X", 0x888);  //888
     NSLog("%02X", 0x4); //04
     */
}
-(void)Usercarforhttp{
    [self delayView];
    
    NSUserDefaults* userinfo = [NSUserDefaults standardUserDefaults];
    NSString* session = [NSString stringWithFormat:@"%@",[userinfo objectForKey:@"session"]];
    NSDictionary*  parameter = @{@"page":[NSString stringWithFormat:@"%d",self.page]};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameter options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString* code = [NSString stringWithFormat:@"parameter=%@%@",jsonString,session];
    
    
    NSString* md5code = [self md5:code];
    NSString* lowercode = [md5code lowercaseString];
    NSDictionary* getcodejson = @{@"sign_type":@"MD5",@"sign":lowercode,@"parameter":jsonString,@"session":session};
    NSString *url = [NSString stringWithFormat:@"%@/member/cars",BaseUrl];
    NSLog(@"加密前：%@",code);
    NSLog(@"加密后：%@",getcodejson);
    [self.manager POST:url parameters:getcodejson success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *response = responseObject;
        NSError* error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&error];
        NSLog(@"commonArea%@",json);
        if ([[json objectForKey:@"status"] intValue] == 0) {
            NSArray* cars = [[[json objectForKey:@"datas"] objectForKey:@"cars"] objectForKey:@"content"];
            if (cars.count>0) {
                for (NSDictionary* carinfo in cars) {
                    Carinfo* car = [[Carinfo alloc]init];
                    car.brand_id = [NSString stringWithFormat:@"%@",[carinfo objectForKey:@"engineNumber"]];
                    car.code = [NSString stringWithFormat:@"%@",[carinfo objectForKey:@"commonAreaCode"]];
                    car.common_area = [NSString stringWithFormat:@"%@",[carinfo objectForKey:@"commonArea"]];
                    car.redpaper = [NSString stringWithFormat:@"%@",[Checkshuju checkshuju:[carinfo objectForKey:@"money"]]];
                    car.car_id = [NSString stringWithFormat:@"%@",[carinfo objectForKey:@"id"]];
                    car.insurance_end = [NSString stringWithFormat:@"%@",[carinfo objectForKey:@"insuranceEnd"]];
                    car.owner_name = [NSString stringWithFormat:@"%@",[carinfo objectForKey:@"ownerName"]];
                    car.license_plate = [NSString stringWithFormat:@"%@",[carinfo objectForKey:@"platesNumber"]];
                    car.vehicle_ldentification_n = [NSString stringWithFormat:@"%@",[carinfo objectForKey:@"vehicleLdentificationNumber"]];
                    car.car_id = [NSString stringWithFormat:@"%@",[carinfo objectForKey:@"id"]];
                    [self.carinfos addObject:car];
                }
            }else{
                self.page--;
            }

            if (self.carinfos.count == 0) {
                [self addpopview:@"车库没有车哦~"];
            }else{
                [self.nullview removeFromSuperview];
            }
            // (最好在刷新表格后调用)调用endRefreshing可以结束刷新状态
            [self.tableView footerEndRefreshing];
            [self.tableView reloadData];
            [self deleteView];
        }else if([[json objectForKey:@"status"] intValue] == -6){
            [self deleteView];
            UIAlertView* al = [[UIAlertView alloc]initWithTitle:@"" message:@"请重新登录" delegate:self cancelButtonTitle:@"回到首页" otherButtonTitles:@"取消", nil];
                        al.delegate =self;
            [al show];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        // (最好在刷新表格后调用)调用endRefreshing可以结束刷新状态
        [self.tableView footerEndRefreshing];
        [self deleteView];
    }];

}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        NSUserDefaults* userinfo = [NSUserDefaults standardUserDefaults];
        [userinfo removeObjectForKey:@"logincode"];
        [userinfo removeObjectForKey:@"session"];
        [userinfo synchronize];
        AppDelegate *appdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appdelegate.carlist removeAllObjects];

        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

//回退
- (IBAction)back:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
//返回tabeview头的高度
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return Screen.bounds.size.height/35;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {


    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  self.carinfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MycarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (self.carinfos.count>0) {
        // Configure the cell...
        Carinfo* carinfo = self.carinfos[indexPath.row];
        cell.carnumber.text = [NSString stringWithFormat:@"%@•%@",[carinfo.license_plate substringToIndex:2],[carinfo.license_plate substringFromIndex:2]];
        if ([carinfo.redpaper length]==0) {
            cell.carmoney.text = @"￥0.00";
        }else{
            cell.carmoney.text = [NSString stringWithFormat:@"￥%@",carinfo.redpaper];
        }
    }
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Carinfo* carinfo = self.carinfos[indexPath.row];
    [self performSegueWithIdentifier:@"Editcar" sender:carinfo];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        Carinfo* car = self.carinfos[indexPath.row];
//        [self delayView];
//        NSUserDefaults* userinfo = [NSUserDefaults standardUserDefaults];
//        NSString* code = [NSString stringWithFormat:@"%@",[userinfo objectForKey:@"session"]];
//        NSString* md5code = [self md5:code];
//        NSString* lowercode = [md5code lowercaseString];
//        NSDictionary* getcodejson = @{@"sign_type":@"MD5",@"sign":lowercode,@"session":code};
//        NSString *url = [NSString stringWithFormat:@"%@/member/car/del/%@",BaseUrl,car.car_id];
//        [self.manager POST:url parameters:getcodejson success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            NSData *response = responseObject;
//            NSError* error;
//            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&error];
//            NSLog(@"systems%@",json);
//            if ([[json objectForKey:@"status"] intValue] == 0) {
//                [self.carinfos removeObjectAtIndex:indexPath.row];
//                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//                //添加 字典，将label的值通过key值设置传递
//                NSDictionary *dict =[[NSDictionary alloc] initWithObjectsAndKeys:@"删除",@"del", nil];
//                //创建通知
//                NSNotification *notification =[NSNotification notificationWithName:@"deltongzhi" object:nil userInfo:dict];
//                //通过通知中心发送通知
//                [[NSNotificationCenter defaultCenter] postNotification:notification];
//                [self deleteView];
//            }
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"%@",error);
//            [self deleteView];
//        }];
//        // Delete the row from the data source
//
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }
//}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"Editcar"]) {
        WritecarinfoTableViewController* carinfovc = [segue destinationViewController];
        carinfovc.carinfo = sender;
    }
}


@end
