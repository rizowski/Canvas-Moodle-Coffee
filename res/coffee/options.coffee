localKey = ""
keylocation = 'canvaskey'
keyfield = $('#canvaskey')
noti = $('#notification')
storage = chrome.storage.local
mykeyobj = {}

$(document).ready () ->
	storage.get(keylocation, (item) ->
		localKey = item.canvaskey
		keyfield.val localKey
		null
		)

saveKey = () ->
	if keyfield.val()?
		localKey = keyfield.val()
	
	mykeyobj[keylocation] = localKey

	storage.set(mykeyobj)

	storage.get(keylocation, (item) ->
		console.log item
		if item.canvaskey == localKey
			noti.html('<span style=\'color: green\'>Key has been saved.</span>')
		else
			noti.html('<span style=\'color: red\'>Unable to save key.</span>')
		)

keyfield.focusout saveKey
$(document).keypress (e) ->
	if e.which == 13
		saveKey
