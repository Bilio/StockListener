//
//  DatabaseHelper.h
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SH_STOCK @"sh000001"
#define SZ_STOCK @"sz399001"
#define CY_STOCK @"sz399006"

@protocol OnStockListChangedDelegate <NSObject>
-(void)onStockListChanged;
@end

@class StockInfo;
@class OrgnizedItem;

@interface DatabaseHelper : NSObject

@property (nonatomic, assign) id <OnStockListChangedDelegate> delegate;

@property (atomic, strong) NSMutableArray* stockList;
@property (atomic, strong) NSMutableArray* dapanList;
@property (atomic, strong) NSMutableArray* orgnizedList;

-(void) reloadStockList;

-(void) addStockBySID:(NSString*)sid;
-(void) removeStockBySID:(NSString*)sid;
-(void) startRefreshStock;
-(void) stopRefreshStock;
-(BOOL) isRefreshing;

-(StockInfo*)getInfoById:(NSString*)sid;
-(StockInfo*)getDapanInfoById:(NSString*)sid;

+(DatabaseHelper*) getInstance;

-(void) saveToStockDB;
-(void) saveToOrgnizedDB;

-(void) clearStoredPriceData;

-(void) addOrgnizedItem:(OrgnizedItem*)item;
-(void) removeOrgnizedItemByIndex:(NSInteger)index;
@end
