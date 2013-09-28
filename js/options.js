$('#canvaskey').val(localStorage["canvaskey"]);
$('#canvaskey').change(function(){
	var field = $(this);
	$.when(field.focusout()).then(function(){
		localStorage["canvaskey"] = this.val();
		$('#notification').html('<span style="color: green;">Settings Saved</span>');
	});
});
