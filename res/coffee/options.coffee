# set this up on forms instead of individual fields
localKey = ""
localColors = false

keyLocation = 'canvaskey'
keyLocations = ['colors', 'grades']

keyfield = $('#canvaskey')
colors = $('#colors')
grades = $('#grades')
noti = $('#notification')

localStorage = chrome.storage.local
syncStorage = chrome.storage.sync

mykeyobj = {}
colorsobj = {}
gradesobj = {}

$(document).ready () ->
  chrome.storage.local.get keyLocation, (item) ->
    localKey = item.canvaskey
    keyfield.val localKey

  chrome.storage.sync.get keyLocations, (items) ->
    colors.prop 'checked', items.colors
    grades.val items.grades


saveKey = () ->
  if keyfield.val()?
    localKey = keyfield.val()
    localKey = localKey.replace /\s+/g, ''
  
  mykeyobj[keyLocation] = localKey

  chrome.storage.local.set(mykeyobj)

  chrome.storage.local.get keyLocation, (item) ->
    if item.canvaskey == localKey
      noti.html('<span style=\'color: green\'>Settings Saved.</span>')
    else
      noti.html('<span style=\'color: red\'>Unable to save key.</span>')

saveColors = () ->
  colorsobj['colors'] = colors.prop 'checked'

  localColors = colorsobj['colors']

  chrome.storage.sync.set colorsobj

  chrome.storage.sync.get 'colors', (item) ->
    if item.colors == localColors
      noti.html('<span style=\'color: green\'>Settings Saved.</span>')
    else
      noti.html('<span style=\'color: red\'>Unable to save Colors.</span>')

saveGrade = () ->
  gradesobj['grades'] = grades.val()

  localGrades = gradesobj.grades

  syncStorage.set gradesobj

  syncStorage.get 'grades', (item) ->
    if item.grades == localGrades
      noti.html('<span style=\'color: green\'>Settings Saved.</span>')
    else
      noti.html('<span style=\'color: red\'>Unable to save Grades.</span>')
    
keyfield.focusout saveKey
keyfield.keyup saveKey
colors.change saveColors
grades.change saveGrade

$(document).keypress (e) ->
  if e.which == 13
    saveKey
