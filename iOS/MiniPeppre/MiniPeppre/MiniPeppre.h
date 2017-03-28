//
//  MiniPeppre.h
//  MiniPeppre
//
//  Created by y-kawashima on 2017/02/07.
//  Copyright © 2017年 Xware Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  アプリで使用する共通メソッドを定義
 */
@interface MiniPeppre : NSObject

/**
 *  コンテンツの保存先ディレクトリ
 *
 *  @return フルパス
 */
+ (NSString *)contentsDirectory;

@end
