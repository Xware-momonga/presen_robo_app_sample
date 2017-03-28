//
//  PageViewController.h
//  MiniPeppre
//
//  Created by y-kawashima on 2017/02/07.
//  Copyright © 2017年 Xware Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  ページ画面のコントローラ
 */
@interface PageViewController : UIViewController

/**
 *  ページの指定
 *
 *  プレゼンID, ページID で指定します。指定された ID から画像ファイルのパスを生成し、クラス変数に保存します。
 *
 *  @param presenID プレゼンID
 *  @param pageID   ページID
 */
- (void)openPresen:(NSString *)presenID page:(NSString *)pageID;

@end
