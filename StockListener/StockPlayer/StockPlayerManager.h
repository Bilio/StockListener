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

#define STOCK_PLAYER_STETE_NOTIFICATION @"STOCK_PLAYER_STETE_NOTIFICATION"

@class StockInfo;
@class DatabaseHelper;

//@protocol StockPlayerDelegate <NSObject>
//-(void) onPlaying:(StockInfo*)info;
//-(void) onPLayPaused;
//@end

@interface StockPlayerManager : NSObject <FSAudioControllerDelegate, AVSpeechSynthesizerDelegate> {

//    FSStreamConfiguration *_configuration;
}

//@property (nonatomic, assign) id <StockPlayerDelegate> delegate;

@property (nonatomic, assign) BOOL isAudoChoose;

-(void) play;

-(void) pause;

-(BOOL) isPlaying;

-(void) next;

-(void) pre;

-(void) playByIndex:(int)index;

+(StockPlayerManager*) getInstance;

-(StockInfo*) getCurrentPlayingInfo;

-(void) setAllowMixing:(BOOL)enable;

@end
