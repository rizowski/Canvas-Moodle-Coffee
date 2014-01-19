
# Ignore certain courses
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
