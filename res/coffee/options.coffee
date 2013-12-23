# set this up on forms instead of individual fields
class CanvasExtensionSettings

  sync : null
  local : null

  settings : null

  keyLocation : "canvaskey"
  settingsLocation : "settings"

  constructor : () ->
    @sync = chrome.storage.sync
    @local = chrome.storage.local

  saveSettings : (settings) ->
    @sync.set settings

  saveCanvasKey : (key) ->
    that = @
    if key
      key = key.replace /\s+/g, ''

    mykeyobj = {}
    mykeyobj[@keyLocation] = key

    @local.set(mykeyobj)

    @local.get @keyLocation, (item) ->
      if item.canvaskey == key
        that.notiMsg "Canvas Key Settings Saved"
      else
        that.notiMsg "Unable to save key", "error"

  getSettings : (_callback) ->
    that = @
    @sync.get @settingsLocation, (item) ->
      item.settings ?= {
        assignments : {
          color: false,
          displayLate : false,
          displayRange: "7 days"
        },
        courses : {
          gradeFormat : 1
        }
      }
      that.saveSettings item.settings
      _callback item.settings

  getCanvasKey : (_callback) ->
    @local.get @keyLocation, (item) ->
      _callback item.canvaskey

  notiMsg : (msg, type) ->
    type ?= "ok"
    noti = $('#notification')
    if type == "ok"
      noti.html("<span style=\'color: green\'>#{msg}</span>")
    else
      noti.html("<span style=\'color: red\'>#{msg}</span>")

$(document).ready () ->
  keyinput = $('#canvaskey')
  canvas = new CanvasExtensionSettings()

  canvas.getSettings (settings) ->
    # set values in input fields
    $('#grades').val settings.courses.gradeFormat
    # $('#range').val ?= ""
    
    console.log settings

  canvas.getCanvasKey (key) ->
    keyinput.val(key)

  keyinput.keyup () ->
    canvas.saveCanvasKey $(@).val()


# localKey = ""
# localColors = true
# localRange = ""
# localLate = true

# keyLocation = 'canvaskey'
# keyLocations = ['colors', 'grades', 'assignRange', 'late']

# keyfield = $('#canvaskey')
# colors = $('#colors')
# grades = $('#grades')
# range = $('#range')
# noti = $('#notification')
# late = $('#late')

# localStorage = chrome.storage.local
# syncStorage = chrome.storage.sync

# mykeyobj = {}
# colorsobj = {}
# gradesobj = {}
# assignRangeobj = {}
# lateobj = {}

# $(document).ready () ->
#   chrome.storage.local.get keyLocation, (item) ->
#     localKey = item.canvaskey
#     keyfield.val localKey

#   chrome.storage.sync.get keyLocations, (items) ->
#     colors.prop 'checked', items.colors
#     grades.val items.grades
#     range.val items.assignRange
#     late.prop 'checked', items.late

# notiMsg = (msg, type) ->
#   type ?= "ok"
#   if type == "ok"
#     noti.html("<span style=\'color: green\'>#{msg}</span>")
#   else
#     noti.html("<span style=\'color: red\'>#{msg}</span>")

# saveKey = () ->
#   if keyfield.val()?
#     localKey = keyfield.val()
#     localKey = localKey.replace /\s+/g, ''
  
#   mykeyobj[keyLocation] = localKey

#   chrome.storage.local.set(mykeyobj)

#   chrome.storage.local.get keyLocation, (item) ->
#     if item.canvaskey == localKey
#       notiMsg "Canvas Key Settings Saved"
#     else
#       notiMsg "Unable to save key", "error"

# saveColors = () ->
#   colorsobj['colors'] = colors.prop 'checked'

#   localColors = colorsobj['colors']

#   chrome.storage.sync.set colorsobj

#   chrome.storage.sync.get 'colors', (item) ->
#     if item.colors == localColors
#       notiMsg "Color Settings Saved"
#     else
#       notiMsg "Unable to save Colors", "error"

# saveGrade = () ->
#   gradesobj['grades'] = grades.val()

#   localGrades = gradesobj.grades

#   syncStorage.set gradesobj

#   syncStorage.get 'grades', (item) ->
#     if item.grades == localGrades
#       notiMsg "Grade Settings Saved"
#     else
#       notiMsg 'Unable to save Grades.', "error"

# saveAssignRange = () ->
#   input = range.val().toLowerCase()
#   if input != ""
#     valid_range = /\d (days|weeks|months)/i.test input
#     if not valid_range
#       notiMsg "Be sure to specify a number and then the measurement in time (3 days)", "error"
#       return 
#   assignRangeobj['assignRange'] = range.val()
#   localRange = assignRangeobj.assignRange

#   syncStorage.set assignRangeobj

#   syncStorage.get 'assignRange', (item) ->
#     if item.assignRange == localRange
#       notiMsg "Assignment Range Saved"
#     else
#       notiMsg "Unable to save Range", "error"

# saveLate = () ->
#   lateobj['late'] = late.prop 'checked'

#   localLate = lateobj['late']

#   syncStorage.set lateobj

#   chrome.storage.sync.get 'late', (item) ->
#     if item.late == localLate
#       notiMsg "Late Assignments Saved"
#     else
#       notiMsg "Unable to save Late assignment setting", "error"

# keyfield.focusout saveKey
# keyfield.keyup saveKey
# colors.change saveColors
# grades.change saveGrade

# range.focusout saveAssignRange
# range.keyup saveAssignRange

# late.change saveLate


