localKey = localStorage['canvaskey']
el = $('#canvaskey')
el.val localKey

saveKey = () ->
	if el.val()?
		localKey = el.val()
	console.log 'Saving key to localStorage', localKey
	localStorage['canvaskey'] = localKey

el.focusout saveKey
$(document).keypress (e) ->
	if e.which == 13
		saveKey