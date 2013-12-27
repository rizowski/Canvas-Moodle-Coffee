class CanvasExtension
  canvaskey : null
  settings : {}

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
          gradeFormat : 1
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
        today = moment().subtract('days',15)
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
                  item.grade = "#{item.enrollments[0].computed_current_grade} (#{item.enrollments[0].computed_current_score})"
                else if item.enrollments[0].computed_current_grade
                  item.grade = item.enrollments[0].computed_current_grade
                else if item.enrollments[0].computed_current_score
                  item.grade = item.enrollments[0].computed_current_score
                else
                  item.grade = "NA"
            # TODO Set everything to Grade (Display format) So that way Logic is done in formatting
          if end_date <= today
            item.end_at = end_date
            courses.previous.push item
          else
            courses.current.push item
        _callback courses
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
        assignments = {
          submitted:[],
          late:[],
          today:[],
          soon:[]
        }
        response = $(data)
        today = moment().subtract('days', 25)
        for item in response
          item.due_at = moment(item.due_at)
          if item.due_at < today
            if item.submission
              assignments.submitted.push item
            else
              assignments.late.push item
          else if item.due_at == today
            assignments.today.push item
          else
            assignments.soon.push item
            # Finds out if the assignment has been added before and ignores if it has
            # added = $.grep @all_assignments, (assign) ->
            #   assign.id == assignment.id
            # if added.length <= 0
            #   @allAssignments.push assignment
        _callback assignments
      error: (xhr, status, error) =>
        console.log "QueryAssignments: #{status}"
      complete: (xhr, status) =>
        $('#assignload').hide()

class Display # extends CanvasExtension
  HTML_RED : "#FF9999"
  # tools : null

  constructor : () ->
    @setup()

  preRemove : () ->
    $('aside#right-side').children('div').remove()
    $("aside#right-side").children('h2').remove()
    $("aside#right-side").children('ul').remove()

  addDivs : () ->
    $("aside#right-side").append "<div id='notice-container' class='notice-container'>
      <h2>Canvas to Moodle Notice</h2>
      <div id='notice' class='notice'></div>
      </div>"

    $("aside#right-side").append "<div class='calendar'>
      <h2 style='display: none;'>Calendar</h2>
      <img id='calload' style='display: block; margin: 0 auto;' src='images/ajax-reload-animated.gif'/>
      <div id='calendar-div' class='calendar-div'> 
      </div></div>"

    $("aside#right-side").append "<div class='courses'>
        <h2>Current Courses</h2>
        <div id='course-content' class='course-summary-div'>
          <img id='courseload' style='display: block; margin: 0 auto;' src='images/ajax-reload-animated.gif'/>
        </div>
      </div>"

    $("aside#right-side").append "<div class='assignments'>
      <h2><a style='float: right; font-size: 10px; font-weight: normal;' class='icon-calendar-day standalone-icon' href='/calendar'>View Calendar</a>Upcoming Assignments</h2>
      <div class='assignment-summary-div'>
        <img id='assignload' style='display: block; margin-left: auto; margin-right: auto' src='images/ajax-reload-animated.gif'/>
      </div></div>"

  events : () ->
    $('.assignments>h2').click () ->
      $('.assignment-summary-div').toggle()
    $('.courses>h2').click () ->
      $('.course-summary-div').toggle()

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


  #  Needs to be set so that it will display without the loop.
  formatAssignment: (assignment) ->
    link = @tools.createlink assignment.url, "#{assignment.worth} pts"
    "<div id='#{assignemnt.id}'>
      <h3>#{assignemnt.name}</h3> #{link}
      <div style='display: none;'>
        <h4></h4>
        <span>
          #{assignment.description}
        </span>
      </div>
    </div>"
  displayAssignment : (assignments) ->
    final_string = ""
    summary = $('.assignment-summary-div')

    if assignemnts.lenght > 0
      assignments.sort a, b ->
        a.due_date - b.due_date
      displayRange = moment().add 'days', 7
      today = moment()
      for assignment in assignments
        date = null
        style = ""
        if assignemnt.due_date <= displayRange && not assignment.submission #|| showLate && not assignment.submission # TODO
          final_string = @formatAssignment assignment
    
    tbody = $('#assign-t-body')
    assign_points = $('.assign-points')
    row = $('.assign-row')
    table = $('#assignment-table')
    tbody.html final_string
    table.fadeIn 500

    summary.fadeIn 500

  insertCourse : (course) ->
    finalString = "<div>"
    url = @createLink course.url, course.course_code
    arrow = chrome.extension.getURL "arrow-24.png"
    img = "<img id='arrow#{course.id}' class='arrow' src='#{arrow}'/>"
    finalString += "<h6>#{img} #{course.grade} | #{course.name}</h6>"
    finalString += "<div id='#{course.id}' style='display:none;'>
                      <div class='course-grade'>#{url}</div>
                      <div class='course-features'>More features to come!</div>
                    </div>"
    finalString += "</div>"

    $("#course-content").append finalString

    $("#arrow#{course.id}").click () ->
      $(@).toggleClass "down-arrow"
      $("##{course.id}").toggle()
  # displayCourse : (course) ->
  #   final_string = ""
  #   console.log "#{course.id}) #{course.name}"
  #   course_link = @tools.createlink(course.url, course.name)
  #   course_grade = ""
  #   if grades == "1"
  #     if course.current_grade
  #       course_grade = "#{course.current_grade}"
  #     else if course.current_score
  #       course_grade = "#{course.current_score}"
  #     else if course.current_grade && course.current_score
  #       course_grade = "#{course.current_grade} (#{course.current_score})"
  #     else
  #       course_grade = ""
  #   else if grades == "2"
  #     if course.current_score
  #       course_grade = "#{course.current_score}"
  #     else if course.current_grade
  #       course_grade = "#{course.current_grade}"
  #     else if course.current_grade && course.current_score
  #       course_grade = "#{course.current_grade} (#{course.current_score})"
  #     else
  #       course_grade = ""
  #   else if grades == "3"
  #     if course.current_grade && course.current_score
  #       course_grade = "#{course.current_grade} (#{course.current_score})"
  #     else if course.current_grade
  #       course_grade = "#{course.current_grade}"
  #     else if course.current_score
  #       course_grade = "#{course.current_score}"
  #     else
  #       course_grade = ""
  #   else
  #     if course.current_grade
  #       course_grade = "#{course.current_grade}"
  #     else if course.current_score
  #       course_grade = "#{course.current_score}"
  #     else if course.current_grade && course.current_score
  #       course_grade = "#{course.current_grade} (#{course.current_score})"
  #     else
  #       course_grade = ""
  #   final_string += "<tr id='#{course.id}' ><td class='class-code'>[#{course.code}]</td><td class='class-link'>#{course_link}</td><td class='class-grade'>#{course_grade}</td></tr>"
  #   table = $('#course-table')
  #   tbody = $('#course-t-body')

  #   tbody.html final_string

  #   table.fadeIn 500

  createLink : (url, text) ->
    "<a href='#{url}'>#{text}</a>"

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

  displayCourses : (courses) ->
    for course in courses
      @displayCourse course

  displayAssignments : (assignments) ->

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
            if key != ""
              $('#notice-container').fadeOut(500)
              location.reload()
      query.queryCourses (courses) ->
        console.log courses
        _.each courses.current, (course) ->
          display.insertCourse course
          #TODO Create new Div structure for courses.
          query.queryAssignments course.id, (assignments) ->
            console.log assignments
            _.each assignments.soon, (assignment) ->
              console.log assignment
            #TODO create new div structure for assignments


$(document).ready ->
  ( ->
    checkIfAssideHasLoaded = setInterval( ->
      if $('ul.events').length > 0
        startup()
        clearInterval checkIfAssideHasLoaded
      undefined
    , 50)
  )()