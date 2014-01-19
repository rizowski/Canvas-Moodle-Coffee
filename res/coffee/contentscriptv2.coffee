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
          displayRange: "14 days"
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

class Query extends CanvasExtension
  courseUrl : "/api/v1/courses?include[]=total_scores&state[]=available"
  canvasCoursesUrl : "/courses/"
  
  assignmentUrl : (_courseId) ->
    "/api/v1/courses/#{_courseId}/assignments?include[]=submission"

  queryCourses : (_callback) ->
    $.ajax
      type: 'GET'
      url: @courseUrl
      crossDomain: true
      headers:
        "Authorization" : "Bearer #{@canvaskey}"
      success: (data) =>
        courses = {
          previous: [],
          current: []
        }
        response = $(data)
        today = moment()
        for item in response
          item.url = @canvasCoursesUrl + item.id
          end_date = moment(item.end_at)
          if item.enrollments
            switch @settings.courses.gradeFormat
              when 1
                if item.enrollments[0].computed_current_grade
                  item.grade = item.enrollments[0].computed_current_grade
                else if item.enrollments[0].computed_current_score 
                  item.grade = item.enrollments[0].computed_current_score
                else
                  item.grade = "NA"
              when 2
                if item.enrollments[0].computed_current_score 
                  item.grade = item.enrollments[0].computed_current_score
                else if item.enrollments[0].computed_current_grade
                  item.grade = item.enrollments[0].computed_current_grade
                else
                  item.grade = "NA"
              when 3
                if item.enrollments[0].computed_current_score && item.enrollments[0].computed_current_grade
                  item.grade = "#{item.enrollments[0].computed_current_grade} (#{item.enrollments[0].computed_current_score}%)"
                else if item.enrollments[0].computed_current_grade
                  item.grade = item.enrollments[0].computed_current_grade
                else if item.enrollments[0].computed_current_score
                  item.grade = item.enrollments[0].computed_current_score
                else
                  item.grade = "NA"
          if end_date <= today
            item.end_at = end_date
            courses.previous.push item
          else
            courses.current.push item
          # @courses[item.id] = {}
          # @courses[item.id] = item
        @courses = courses
        _callback @courses
      complete: (xhr, status) =>
        $('#courseload').hide()

  queryAssignments : (_courseId, _callback) ->
    $.ajax
      type: 'GET'
      url: @assignmentUrl(_courseId)
      crossDomain: true
      headers:
        "Authorization" : "Bearer #{@canvaskey}"
      success: (data) ->
        @assignments ?= {
          submitted:[],
          late:[],
          today:[],
          soon:[]
        }
        response = $(data)

        today = moment()
        today.set('hour', 0)
        today.set('minute', 0)
        today.set('second', 0)
        today.set('millisecond', 0)
        for item in response
          item.due_at = moment(item.due_at)
          if item.due_at < today
            if item.submission
              @assignments.submitted.push item
            else
              @assignments.late.push item
          else if item.due_at == today
            @assignment.today.push item
          else
            @assignments.soon.push item

        if @assignments.submitted.length > 0
          @assignments.submitted.sort (a, b) ->
            a.due_at - b.due_at
        if @assignments.late.length > 0
          @assignments.late.sort (a, b) ->
            a.due_at - b.due_at
        if @assignments.today.length > 0
          @assignments.today.sort (a, b) ->
            a.due_at - b.due_at
        if @assignments.soon.length > 0
          @assignments.soon.sort (a, b) ->
            a.due_at - b.due_at

        # @assignments = assignments
        _callback @assignments
      error: (xhr, status, error) =>
        console.log "QueryAssignments: #{status}"
      complete: (xhr, status) =>
        $('#assignload').hide()

class Display extends CanvasExtension
  HTML_RED : "#FF9999"
  # tools : null

  constructor : () ->
    @setup()

  preRemove : () ->
    $('aside#right-side').children('div').remove()
    $("aside#right-side").children('h2').remove()
    $("aside#right-side").children('ul').remove()

  addDivs : () ->
    right = $("aside#right-side")
    gearImg = @createImg {
      id: "canvas-settings"
      url: chrome.extension.getURL "gear-24.png"
      class: "gear"
    }
    options = chrome.extension.getURL "options.html"
    right.append "<div id='notice-container' class='notice-container'>
      <h2>Canvas to Moodle Notice</h2>
      <div id='notice' class='notice'></div>
      </div>"

    right.append "<div id='canvas-settings' class='canvas-settings' style='display: none;'>
        #{gearImg}
      </div>"

    right.append "<div class='calendar'>
      <h2 style='display: none;'>Calendar</h2>
      <img id='calload' style='display: block; margin: 0 auto;' src='images/ajax-reload-animated.gif'/>
      <div id='calendar-div' class='calendar-div'> 
      </div></div>"

    right.append "<div class='courses'>
        <h2>Current Courses</h2>
        <div id='course-content' class='course-summary-div'>
          <img id='courseload' style='display: block; margin: 0 auto;' src='images/ajax-reload-animated.gif'/>
        </div>
      </div>"

    right.append "<div class='assignments'>
      <h2><a style='float: right; font-size: 10px; font-weight: normal;' class='icon-calendar-day standalone-icon' href='/calendar'>View Calendar</a>Upcoming Assignments</h2>
      <div id='assignment-content' class='assignment-summary-div'>
        <img id='assignload' style='display: block; margin-left: auto; margin-right: auto' src='images/ajax-reload-animated.gif'/>
      </div></div>"

  events : () ->
    $('.assignments>h2').click () ->
      $('.assignment-summary-div').toggle()
    $('.courses>h2').click () ->
      $('.course-summary-div').toggle()
    $("#canvas-settings").click () ->
      chrome.tabs.create "options.html"

  setup : () ->
    @preRemove()
    @addDivs()
    @getCalendar()
    @events()

  getCalendar : () ->
    loading = $('#calload')
    loading.show
    calendar = $('#calendar-div')
    calendar.clndr()
    
    canvas_header = $('#header')

    # day = $('.day')
    table = $('.clndr-table')
    table_header = $('.header-day')
    month = $('.month')
    today = $('.today')
    $('.clndr-control-button').hide()

    month_text = month.html()
    month.html "<h2>#{month_text}</h2>"

    today.css 'background', canvas_header.css('background-color')

    loading.hide()
    calendar.fadeIn 500

  insertCourse : (course) ->
    finalString = "<div>"
    code_url = @createLink course.url, course.course_code
    course_url = @createLink course.url, course.name
    arrow = chrome.extension.getURL "arrow-24.png"
    # img = "<img id='arrow#{course.id}' class='arrow' src='#{arrow}'/>"
    finalString += "<h6>#{course_url}<div class='course-sub'>#{course.grade} [#{course.course_code}]</div></h6>"
    finalString += "<div id='#{course.id}'>
                      
                    </div>"
    finalString += "</div><hr/>"

    $("#course-content").append finalString

    $("#arrow#{course.id}").click () ->
      $(@).toggleClass "down-arrow"
      $("##{course.id}").toggle()

  insertAssignment : (assignment) ->
    finalString = "<div id='assignment' date='#{assignment.due_at}' class='assignment'>"
    assign_url = @createLink assignment.html_url, assignment.name
    arrow = @createImg {
      id: "img#{assignment.id}"
      url: chrome.extension.getURL "arrow-24.png"
      class: "assignment-arrow arrow"
    }
    assignment.description ?= "No description provided."

    finalString += "#{arrow} <h6>#{assignment.points_possible} pts | #{assign_url}<div>Due On: #{assignment.due_at.format("MM[/]DD[/]YYYY")}</div></h6>"
    finalString += "<div id='#{assignment.id}' class='assignment-contents'>
      <div class='assignment-desc'>#{assignment.description}</div>
      </div>"
    finalString += "<hr/></div>"
    $("#assignment-content").append finalString
    $("#assignment-content>#assignment").tsort({attr: "date"})

    $("#img#{assignment.id}").click () ->
      $(@).toggleClass "down-arrow"
      $("##{assignment.id}").toggle()

  createLink : (url, text) ->
    "<a href='#{url}'>#{text}</a>"
  createImg : (obj) ->
    "<img id='#{obj.id}' src='#{obj.url}' class='#{obj.class}' />"

  tableRow : (contents) ->
    result = "<tr>"
    for content in contents
      result += "<td>#{content}</td>"
    result += "</tr>"

  createTable : (headers, contents) ->
    headers ?= []
    contents ?= []
    return if headers.length != contents.length

    final_string = "<table><thead>"
    for header in headers
      final_string += "<th>#{header}</th>"
    final_string += "</thead><tbody>"
    for content_items in contents
      @table_row content_items
    final_string += "</tbody></table>"

    final_string

  assignmentSort : (obj1, obj2) ->
    if not obj1
      return -1
    if not obj2
      return -1

  notiMsg : (msg, type) ->
    type ?= "ok"
    noti = $('#notice')
    container = $('#notice-container')
    if type == "ok"
      noti.html("<span style=\'color: green\'>#{msg}</span>")
    else if type == "error"
      noti.html("<span style=\'color: red\'>#{msg}</span>")
    else
      noti.html("<span>#{msg}</span>")
    container.fadeIn(500)


startup = () =>
  display = new Display()
  query = new Query()

  query.getSettings (settings) ->
    query.getCanvasKey (key) ->
      if key == "" or not key
        url = $('.user_name>a').attr("href")
        display.notiMsg "Auth Token Required.
        <br/>
        Make sure you have an Auth-Token saved.</span>
        <br/><br/>
        <ol>
          <li>Create a token here: <a href='#{url}'>Create Token</a></li>
          <li>Scroll down to the bottom of the page and click \"New Access Token\"</li>
          <li>Copy the token which will look like 1~iocGw2co</li>
          <li>Paste it in this field: <input id='token' type='password' /></li>
          <li>Enjoy!</li>
        </ol>", "error"

        $('#token').keyup () ->
          query.saveCanvasKey $(@).val()
          query.getCanvasKey (key) ->
            if key != "" && key.indexOf("1~") != -1
              $('#notice-container').fadeOut(500)
              location.reload()
      else
        query.queryCourses (courses) ->
          _.each courses.current, (course) ->
            display.insertCourse course
            query.queryAssignments course.id, (assignments) ->
              _.each assignments.soon, (assignment, index) ->
                ranges = settings.assignments.displayRange.split(' ');
                date = moment()
                date.set('hour', 23)
                date.set('minute', 59)
                date.set('second', 59)
                date.set('millisecond', 999)
                date.add(ranges[1], parseInt(ranges[0],10))
                if assignment.due_at.unix() <= date.unix()
                  display.insertAssignment assignment


$(document).ready ->
  ( ->
    checkIfAssideHasLoaded = setInterval( ->
      if $('ul.events').length > 0
        startup()
        clearInterval checkIfAssideHasLoaded
      undefined
    , 50)
  )()