class CanvasExtension
  canvaskey : null
  settings : {}
  assignments : null
  courses : {}

  sync : null
  local : null

  keyLocation : "canvaskey"
  settingsLocation : "settings"

  constructor : () ->
    @sync = chrome.storage.sync
    @local = chrome.storage.local

  $.ajaxSetup
    cache: true
    dataType : "json"
    statusCode:
      401 : () ->
        console.log 'Auth error'
      404 : () ->
        console.log 'Page not found'
      405 : () ->
        console.log 'Method not allowed'
      500 : () ->
        console.log 'Server error'
    headers: 
      "Access-Control-Allow-Origin" : "*"

  saveSettings : (settings) ->
    @settings = settings
    @sync.set settings

  saveCanvasKey : (key) ->
    that = @
    if key
      key = key.replace /\s+/g, ''

    mykeyobj = {}
    mykeyobj[@keyLocation] = key

    @local.set(mykeyobj)

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
          gradeFormat : 3
        }
      }
      that.saveSettings item.settings
      that.settings = item.settings
      _callback item.settings

  getCanvasKey : (_callback) ->
    that = @
    @local.get @keyLocation, (item) ->
      that.canvaskey = item.canvaskey
      _callback item.canvaskey