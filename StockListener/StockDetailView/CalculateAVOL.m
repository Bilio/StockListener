//
//  CalculateAVOL.m
//  StockListener
//
//  Created by Guozhen Li on 1/18/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "CalculateAVOL.h"
#import "StockInfo.h"
#import "ConfigHelper.h"

@implementation CalculateAVOL{
    StockInfo* neededNewInfo;
}

-(id) initWithStockInfo:(StockInfo*)info{
    if ((self = [super init]) != nil) {
        neededNewInfo = info;
        _averageVolDic = [[NSMutableDictionary alloc] init];
        self.endIndex = 1000000;
    }
    return self;
}

-(void) calculateAP {
    NSArray* volArray = nil;
    NSArray* priceArray = nil;
    if (self.sourceType == CalculateAVOLTypeHistory) {
        if ([ConfigHelper getInstance].avolCalType == AVOL_CAL_WEEKS) {
            volArray = neededNewInfo.weeklyVOL;
            priceArray = neededNewInfo.weeklyPrice;
        }
        else if ([ConfigHelper getInstance].avolCalType == AVOL_CAL_5_DAYS) {
            volArray = self.fiveDayVOL;
            priceArray = self.fiveDayPrice;
        } else {
            volArray = neededNewInfo.hundredDaysVOL;
            priceArray = neededNewInfo.hundredDaysPrice;
        }
        if (self.endIndex != 1000000) {
            if (self.calType == AVOL_CAL_WEEKS) {
                volArray = neededNewInfo.weeklyVOL;
                priceArray = neededNewInfo.weeklyPrice;
            } else if (self.calType == AVOL_CAL_5_DAYS) {
                volArray = self.fiveDayVOL;
                priceArray = self.fiveDayPrice;
            } else {
                volArray = neededNewInfo.hundredDaysVOL;
                priceArray = neededNewInfo.hundredDaysPrice;
            }
        }
        [self calculateAPForHistory:priceArray andVol:volArray];
    } else if (self.sourceType == CalculateAVOLTypeToday) {
        volArray = neededNewInfo.todayVOLByMinutes;
        priceArray = neededNewInfo.todayPriceByMinutes;
        [self calculateAPForToday:priceArray andVol:volArray];
    }
}

-(void) calculateAPForHistory:(NSArray*)priceArray andVol:(NSArray*)volArray {
    if ([volArray count] != [priceArray count] || [priceArray count] == 0) {
        return;
    }
    
    NSInteger endIndex = 0;
    if (self.endIndex > [priceArray count]) {
        endIndex = [priceArray count];
    } else {
        endIndex = _endIndex;
    }
    
    float lowest = 100000;
    float delta = 0.01;
    for (int i=0; i<endIndex; i++) {
        NSArray* array = [priceArray objectAtIndex:i];
        if ([array count] != 4) {
            continue;
        }
        float l = [[array objectAtIndex:3] floatValue];
        if (l < lowest) {
            lowest = l;
        }
    }
    if (lowest < 3) {
        delta = 0.001;
    }
    if (lowest > 1000) {
        delta = 1;
    }
    [self.averageVolDic removeAllObjects];
    for (int i=0; i<endIndex; i++) {
        NSArray* array = [priceArray objectAtIndex:i];
        //        NSArray* preArr = [neededNewInfo.hundredDaysPrice objectAtIndex:i-1];
        if ([array count] != 4) {
            continue;
        }
        NSInteger h = [[array objectAtIndex:1] floatValue] / delta;
        NSInteger l = [[array objectAtIndex:3] floatValue] / delta;
        NSInteger vol = [[volArray objectAtIndex:i] integerValue];
        
        //        NSInteger c = [[array objectAtIndex:1] floatValue] / delta;
        //        NSInteger pc = [[preArr objectAtIndex:1] floatValue] / delta;
        //        if (c < pc) {
        //            vol = -1*vol;
        //        }
        if (vol < 0) {
            vol *=-1;
        }
        NSInteger count = h - l;
        if (count == 0) {
            NSString* key = [NSString stringWithFormat:@"%ld", h];
            NSInteger preVol = [[self.averageVolDic objectForKey:key] integerValue];
            [self.averageVolDic setValue:[NSNumber numberWithInteger:preVol+vol] forKey:key];
        } else {
            NSInteger average = vol/count;
            for (NSInteger j=0; j<count; j++) {
                NSString* key = [NSString stringWithFormat:@"%ld", l+j];
                NSInteger preVol = [[self.averageVolDic objectForKey:key] integerValue];
                [self.averageVolDic setValue:[NSNumber numberWithInteger:preVol+average] forKey:key];
            }
        }
    }
}

-(void) calculateAPForToday:(NSArray*)priceArray andVol:(NSArray*)volArray {
    if ([volArray count] != [priceArray count] || [priceArray count] == 0) {
        return;
    }
    
    float lowest = 100000;
    float delta = 0.01;
    for (int i=0; i<[priceArray count]; i++) {
        NSNumber* number = [priceArray objectAtIndex:i];
        float l = [number floatValue];
        if (l < lowest) {
            lowest = l;
        }
    }
    if (lowest < 3) {
        delta = 0.001;
    }
    if (lowest > 1000) {
        delta = 1;
    }
    [self.averageVolDic removeAllObjects];
    float prePrice = neededNewInfo.lastDayPrice;
    for (int i=0; i<[priceArray count]; i++) {
        float curPrice = [[priceArray objectAtIndex:i] floatValue];
        NSInteger h;
        NSInteger l;
        if (prePrice > curPrice) {
            h = prePrice / delta;
            l = curPrice / delta;
        } else {
            h = curPrice / delta;
            l = prePrice / delta;
        }
        prePrice = curPrice;
        
        NSInteger vol = [[volArray objectAtIndex:i] integerValue];

        NSInteger count = h - l;
        if (count == 0) {
            NSString* key = [NSString stringWithFormat:@"%ld", h];
            NSInteger preVol = [[self.averageVolDic objectForKey:key] integerValue];
            [self.averageVolDic setValue:[NSNumber numberWithInteger:preVol+vol] forKey:key];
        } else {
            NSInteger average = vol/count;
            for (NSInteger j=0; j<count; j++) {
                NSString* key = [NSString stringWithFormat:@"%ld", l+j];
                NSInteger preVol = [[self.averageVolDic objectForKey:key] integerValue];
                [self.averageVolDic setValue:[NSNumber numberWithInteger:preVol+average] forKey:key];
            }
        }
    }
}

-(void) run {
    [self calculateAP];
    if (self.onCompleteBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.onCompleteBlock(self.averageVolDic);
        });
    }
}

@end
