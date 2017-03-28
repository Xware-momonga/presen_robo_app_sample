//
//  MiniPeppre.m
//  MiniPeppre
//
//  Created by y-kawashima on 2017/02/07.
//  Copyright © 2017年 Xware Corporation. All rights reserved.
//

#import "MiniPeppre.h"

/**
 *  アプリで使用する共通メソッドを定義
 */
@implementation MiniPeppre

/**
 *  コンテンツの保存先ディレクトリ
 *
 *  @return フルパス
 */
+ (NSString *)contentsDirectory {
    NSString *libraryDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString *destinationDirectory = [libraryDirectory stringByAppendingPathComponent:@"contents"];

    return destinationDirectory;
}
@end
