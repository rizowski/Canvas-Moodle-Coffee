localKey = localStorage['canvaskey']
el = $('#canvaskey')
noti = $('#notification')
el.val localKey

saveKey = () ->
	if el.val()?
		localKey = el.val()
	console.log 'Saving key to localStorage', localKey
	localStorage['canvaskey'] = localKey
	noti.html('<span style=\'color: green\'>Key has been saved.</span>')

el.focusout saveKey
$(document).keypress (e) ->
	if e.which == 13
		saveKey
