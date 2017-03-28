$(document).ready(function() {
	QiSession(function(session) {
		session.service('ALMemory').then(function(ALMemory){

			//プレゼン一覧を初期表示します
			initialiseList();

			//プレゼン一覧を更新するイベントを監視します。
			ALMemory.subscriber('mini_peppre/refresh_list').then(function(sub) {
				sub.signal.connect(function(){
					initialiseList();
					$('#loading').addClass('hidden');
					$('#main-table').removeClass('hidden');
				});
			});
			//エラーが発生した時のイベントを監視します。
			ALMemory.subscriber('mini_peppre/error').then(function(sub) {
				sub.signal.connect(function(text){
					alert(text);
				});
			});

			//プレゼン一覧のタッチ監視
			//複数タッチとタッチ移動ができないように作ります
			var touchMoveFlag;
			$('#main-table').on('touchstart', 'tr', function() {
				touchMoveFlag = false;
			}).on('touchmove', function() {
				touchMoveFlag = true;
			}).on('touchend', 'tr', function() {
				if (touchMoveFlag == false) {
					$('.success').removeClass('success');
					$(this).addClass('success');
				}
			});
			//再生ボタンで選択中のプレゼンを開始します。
			$('#play').on('touchend', function() {
				var id = $('.success').attr('id');
				ALMemory.raiseEvent('mini_peppre/play', id);
			});
			//更新ボタンでサーバーからプレゼンコンテンツの取得を開始するイベントを送信します。
			$('#update').on('touchend', function() {
				$('#main-table').addClass('hidden');
				$('#loading').removeClass('hidden');
				ALMemory.raiseEvent('mini_peppre/update', 0);
			});
			//終了ボタンでアプリを停止します。
			$('#close').on('touchend', function() {
				ALMemory.raiseEvent('mini_peppre/close', 0);
			});

			//プレゼン情報をメモリーから取得して一覧に表示します。
			function initialiseList() {
				$('#main-table').html('');
				ALMemory.getData('mini_peppre/all_presentations').then(function(list) {
					if (list.length > 0) {
						var presenList = JSON.parse(list);

						//プレゼンの一覧テーブルを作ります。
						var table = $('<table class="table">');
						for (presen in presenList) {
							var row = $('<tr id='+presen+'>');
							var cell = $('<td>'+presenList[presen].title+'</td>');
							row.append(cell);
							table.append(row);
						}
						$('#main-table').append(table);

						//Bootstrapのsuccessクラスで選択中のプレゼンを指定します。
						//更新後に1番目のプレゼンを選択します。
						$('tr').first().addClass('success');
					}
				});
			}
		});
	});
});