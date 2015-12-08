//
//  StockPlayerManager.h
//  StockListener
//
//  Created by Guozhen Li on 11/29/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSAudioController.h"
#import <AVFoundation/AVFoundation.h>
#import "GetStockValueTask.h"

@class StockInfo;

@protocol StockPlayerDelegate <NSObject>
-(void) onPlaying:(StockInfo*)info;
-(void) onPLayPaused;
@end

@interface StockPlayerManager : NSObject <FSAudioControllerDelegate, GetStockValueDoneDelegate, AVSpeechSynthesizerDelegate> {

    FSStreamConfiguration *_configuration;
}

@property (nonatomic, strong) NSArray* stockPlayList;

@property (nonatomic, assign) id <StockPlayerDelegate> delegate;

-(void) play;

-(void) pause;

-(BOOL) isPlaying;

-(void) next;

-(void) pre;

-(int) getCurrentPlayIndex;
@end
