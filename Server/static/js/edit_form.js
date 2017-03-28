$('#add-page').on('click', function() {

	var count = $('#page-rows tr').length;

	var $table = $('#page-rows');
	var $singleRow = $('<tr>');

	//項目作成
	var $pageNo = $('<td>'+count+'</td>');
	var $fileSelect = $('<td><input type="file" name="uploadfile_'+count+'" /></td>');
	var $scriptInput = $('<td><textarea class="form-control" form="pages-form" name="saytext"></textarea></td>');

	$singleRow
		.append($pageNo)
		.append($fileSelect)
		.append($scriptInput);
	$table.append($singleRow);
});