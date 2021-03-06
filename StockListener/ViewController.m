//
//  ViewController.m
//  StockListener
//
//  Created by Guozhen Li on 11/26/15.
//  Copyright (c) 2015 Guangzhen Li. All rights reserved.
//

#import "ViewController.h"
#import "KingdaWorker.h"
#import "DatabaseHelper.h"
#import "SearchStockController.h"
#import "StockInfo.h"
#import "StockTableItemViewController.h"
#import "StockRefresher.h"
#import "CERoundProgressView.h"

@interface ViewController () {
    NSInteger stockSelected;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic, strong) UISearchController *searchController;
@property(nonatomic, strong) DatabaseHelper* dbHelper;
@property (weak, nonatomic) IBOutlet UILabel *stockTitle;
@property(nonatomic, strong) SearchStockController* searchStockController;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property(nonatomic, strong) StockTableItemViewController* stockTableItemViewController;
@property (weak, nonatomic) IBOutlet CERoundProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *shValue;
@property (weak, nonatomic) IBOutlet UILabel *szValue;
@property (weak, nonatomic) IBOutlet UILabel *chuangValue;
@end

@implementation ViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//    }
//    return self;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    _searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    self.tableView.tableHeaderView = self.searchController.searchBar;
    _searchController.searchBar.placeholder = @"股票代码";
    
    // Init stock list
    _dbHelper = [DatabaseHelper getInstance];
    [_dbHelper setDelegate:self];
    
    player = [[StockPlayerManager alloc] init];
    [player setDelegate:self];
    
    _searchStockController = [[SearchStockController alloc] init];
    _stockTableItemViewController = [[StockTableItemViewController alloc] init];
    [_stockTableItemViewController setTableView:self.tableView];
    [_stockTableItemViewController setPlayer:player];
    [_stockTableItemViewController setDbHelper:self.dbHelper];
    [_stockTableItemViewController setViewController:self];

    stockSelected = -1;
    
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = view;
    
    UIColor *tintColor = [UIColor redColor];
    [[CERoundProgressView appearance] setTintColor:tintColor];
    self.progressView.trackColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    self.progressView.startAngle = (3.0*M_PI)/2.0;
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputDeviceChanged:)name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackgroundNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStockValueRefreshed)
                                                 name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                               object:nil];
}

-(void) viewDidUnload {
    [self setProgressView:nil];
    [super viewDidUnload];
}

- (void)outputDeviceChanged:(NSNotification *)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [player pause];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPause: /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlPlay:  /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if ([player isPlaying]) {
                    [player pause];
                } else {
                    [player play];
                }
                break;
            case UIEventSubtypeMotionShake:
            case UIEventSubtypeRemoteControlNextTrack:
                [player next];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [player pre];
                break;
            default:
                break;
        }
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.searchController.active) {
        return [self.searchStockController.searchList count];
    }else{
        return [self.dbHelper.stockList count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        return 44;
    } else {
        if (stockSelected == indexPath.row) {
            return 135;
        }
        return 60;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.searchController.active) {
        static NSString *flag=@"searchCellFlag";
        UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:flag];
        if (cell==nil) {
            cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:flag];
        }
        [cell.textLabel setText:self.searchStockController.searchList[indexPath.row]];
        return cell;
    }
    else{
        StockInfo* info = [self.dbHelper.stockList objectAtIndex:indexPath.row];
        BOOL selected = NO;
        if (indexPath.row == stockSelected) {
            selected = YES;
        }
        UITableViewCell* cell2 = [self.stockTableItemViewController getTableViewCell:tableView andInfo:info andSelected:selected];
        return cell2;
    }
    return nil;
}

-(void) reloadSelectedCell {
//    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:stockSelected inSection:0];
//    
//    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        if (indexPath.row >= [self.searchStockController.searchList count]) {
            return;
        }
        [self addBySID:[self.searchStockController.searchList objectAtIndex:indexPath.row]];
        [self.searchController setActive:NO];
    } else {
        [tableView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionNone];
        [tableView beginUpdates];
        if (stockSelected == indexPath.row) {
            stockSelected = -1;
            [self reloadSelectedCell];
            [tableView endUpdates];
            return;
        }
        
        stockSelected = indexPath.row;
        [self reloadSelectedCell];
        [tableView endUpdates];
    }
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if ([searchString length] == 0) {
        [self.searchStockController.searchList removeAllObjects];
        [self.tableView reloadData];
        return;
    }
    
    [self.searchStockController search:searchString];
    [self.tableView reloadData];
}

- (void) addBySID:(NSString*)sid {
    [self.dbHelper addStockBySID:sid];
}

-(void)onStockListChanged {
    if (!self.searchController.active) {
        [self.tableView reloadData];
    }
//    [player pause];
//    [player setStockPlayList:self.dbHelper.stockList];
}

- (IBAction)playButtonClicked:(id)sender {
    if (![player isPlaying]) {
        [player play];
    } else {
        [player pause];
    }
}

- (IBAction)preButtonClicked:(id)sender {
    [player pre];
}

- (IBAction)nextButtonClicked:(id)sender {
    [player next];
}

-(void) onPlaying:(StockInfo*)info {
    [self.stockTitle setText:info.name];
    self.playButton.selected = YES;
//    [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
    [self.stockTableItemViewController setNowPLayingSID:info.sid];
    [self.tableView reloadData];
}

-(void) onPLayPaused {
    [self.stockTitle setText:@"听股市"];
    self.playButton.selected = NO;
//    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.stockTableItemViewController setNowPLayingSID:nil];
    [self.tableView reloadData];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    if (![player isPlaying]) {
        [self.dbHelper stopRefreshStock];
        [self.dbHelper clearStoredPriceData];
    }
    [self.dbHelper saveToDB];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
    [self.dbHelper startRefreshStock];
}

- (void)onStockValueRefreshed {
    [self.tableView reloadData];
    
    //Da pan
    StockInfo* info = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    NSMutableString* str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.shValue setText:str];
    if (info.changeRate < 0) {
        [self.shValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.shValue setTextColor:[UIColor redColor]];
    }
    
    info = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.szValue setText:str];
    if (info.changeRate < 0) {
        [self.szValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.szValue setTextColor:[UIColor redColor]];
    }
    
    info = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.chuangValue setText:str];
    if (info.changeRate < 0) {
        [self.chuangValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.chuangValue setTextColor:[UIColor redColor]];
    }
}
- (IBAction)onAutoSwitchChanged:(id)sender {
    UISegmentedControl* control = (UISegmentedControl*)sender;
    if (control.selectedSegmentIndex == 0) {
        [player setIsAudoChoose:NO];
    } else {
        [player setIsAudoChoose:YES];
    }
}
@end
