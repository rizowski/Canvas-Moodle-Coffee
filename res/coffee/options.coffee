# set this up on forms instead of individual fields
localKey = ""
localColors = false
localRange = ""

keyLocation = 'canvaskey'
keyLocations = ['colors', 'grades', 'assignRange']

keyfield = $('#canvaskey')
colors = $('#colors')
grades = $('#grades')
range = $('#range')
noti = $('#notification')

localStorage = chrome.storage.local
syncStorage = chrome.storage.sync

mykeyobj = {}
colorsobj = {}
gradesobj = {}
assignRangeobj = {}

$(document).ready () ->
  chrome.storage.local.get keyLocation, (item) ->
    localKey = item.canvaskey
    keyfield.val localKey

  chrome.storage.sync.get keyLocations, (items) ->
    colors.prop 'checked', items.colors
    grades.val items.grades
    range.val items.assignRange

notiMsg = (msg, type) ->
  type ?= "ok"
  if type == "ok"
    noti.html("<span style=\'color: green\'>#{msg}</span>")
  else
    noti.html("<span style=\'color: red\'>#{msg}</span>")

saveKey = () ->
  if keyfield.val()?
    localKey = keyfield.val()
    localKey = localKey.replace /\s+/g, ''
  
  mykeyobj[keyLocation] = localKey

  chrome.storage.local.set(mykeyobj)

  chrome.storage.local.get keyLocation, (item) ->
    if item.canvaskey == localKey
    	notiMsg "Settings Saved"
    else
    	notiMsg "Unable to save key", "error"

saveColors = () ->
  colorsobj['colors'] = colors.prop 'checked'

  localColors = colorsobj['colors']

  chrome.storage.sync.set colorsobj

  chrome.storage.sync.get 'colors', (item) ->
    if item.colors == localColors
      notiMsg "Settings Saved"
    else
      notiMsg "Unable to save Colors", "error"

saveGrade = () ->
  gradesobj['grades'] = grades.val()

  localGrades = gradesobj.grades

  syncStorage.set gradesobj

  syncStorage.get 'grades', (item) ->
    if item.grades == localGrades
      notiMsg "Settings Saved"
    else
      notiMsg 'Unable to save Grades.', "error"

saveAssignRange = () ->
  input = range.val().toLowerCase()
  valid_range = /\d (days|weeks|months)/i.test input
  if not valid_range
  	notiMsg "Be sure to specify a number and then the measurement in time (3 days)", "error"
  	return 
  assignRangeobj['assignRange'] = range.val()
  localRange = assignRangeobj.assignRange

  syncStorage.set assignRangeobj

  syncStorage.get 'assignRange', (item) ->
    if item.assignRange == localRange
      notiMsg "Settings Saved"
    else
      notiMsg "Unable to save Range", "error"

saveLate = () ->

keyfield.focusout saveKey
keyfield.keyup saveKey
colors.change saveColors
grades.change saveGrade

range.focusout saveAssignRange
range.keyup saveAssignRange

$(document).keypress (e) ->
  if e.which == 13
    saveKey
