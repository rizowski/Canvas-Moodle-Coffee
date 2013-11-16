class CanvasExtension
  settings = {
    canvasKey : null,
    assignments : {
      color: false,
      displayLate : false,
      displayRange: "7 days",
      gradeFormat : 1
    }
  }

  tools = (new Tools())
  sync = chrome.storage.sync
  local = chrome.storage.local

  allAssignments : []
  allCourses : []

  constructor : () ->

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
      "Authorization" : "Bearer #{@settings.canvaskey}"
      "Access-Control-Allow-Origin" : "*"

  setKey : (item) ->
    settings.canvasKey = item

  # This needs to be modified to reflect settings changes top
  setKeys : (items) ->
    if items.hasOwnProperty 'canvasKey'
      console.log('TODO set key')
    if items.hasOwnProperty 'colors'
      console.log('TODO set colors')
      colors = items.colors
    if items.hasOwnProperty 'grades'
      console.log('TODO SET GRADES')
      grades = items.grades
    if items.hasOwnProperty 'assignRange'
      if items.assignRange != ""
        input = items.assignRange.split ' '
        assignRange = moment().add input[1], input[0]
    if items.hasOwnProperty 'late'
      display_late = items.late

  getSyncSettings : () ->
    sync.get ['settings'], (settings) ->
      setKeys settings

  saveSettings : (item) ->
    sync.set item

class Tools
  constructor : () ->

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
      success: (data) =>
        response = $(data)
        today = moment()
        for item in response
          end_date = moment(item.end_at)
          if end_date >= today
            course = {}
            course.id = item.id
            course.start_date = moment(item.start_at)
            course.end_date = end_date
            course.code = item.course_code
            course.name = item.name
            course.current_grade = item.enrollments[0].computed_current_grade
            course.current_score = item.enrollments[0].computed_current_score
            course.final_grade = item.enrollments[0].computed_final_grade
            course.final_score = item.enrollments[0].computed_final_score
            course.url = @canvasCoursesUrl + course.id
            @allCourses.push course
            @queryAssignments(course.id)
        _callback @allCourses
      complete: (xhr, status) =>
        $('#courseload').hide()

  queryAssignments : (_courseId, _callback) ->
    $.ajax
      type: 'GET'
      url: @assignmentUrl(_courseId)
      crossDomain: true
      success: (data) =>
        response = $(response)
        today = moment()
        for item in response
          assignment = {}
          assignment.due_date = moment(item.due_at)
          if assignment.due_date >= today
            assignment.id = item.id
            assignment.name = item.name
            assignment.description = item.description
            assignment.points_possible = item.points_possible
            assignment.url = item.html_url
            assignment.locked = item.locked_for_user
            assignment.unlock_at = item.unlock_at
            if item.hasOwnProperty 'submission'
              assignment.submission = true
              assignment.points_earned = item.submission.current_score
              assignment.grade = item.submission.grade
            added = $.grep @all_assignments, (assign) ->
              assign.id == assignment.id
            if added.length <= 0
              @allAssignments.push assignment
        _callback @allAssignments
        # @hit_counter++
        # @success_assignment(data)
      error: (xhr, status, error) =>
        # @error_hit_counter++
      complete: (xhr, status) =>
        $('#assignload').hide()

class Display
  HTML_RED : "#FF9999"

  constructor : () ->
    @setup()

  preRemove : () ->
    $('aside#right-side').children('div').remove()
    $("aside#right-side").children('h2').remove()
    $("aside#right-side").children('ul').remove()

  addDivs : () ->
    $("aside#right-side").append "<div id='notice-container' style='display: none;'>
      <h2>Canvas to Moodle Notice</h2>
      <div id='notice'></div>
      </div>"

    $("aside#right-side").append "<div class='calendar'>
      <h2 style='display: none;'>Calendar</h2>
      <img id='calload' style='display: block; margin: 0 auto;' src='images/ajax-reload-animated.gif'/>
      <div id='calendar-div' class='calendar-div' style='display: none;'> 
      </div></div>"

    $("aside#right-side").append "<div class='courses'>
      <h2>Current Courses</h2>
      <div class='course-summary-div'>
        <img id='courseload' style='display: block; margin: 0 auto;' src='images/ajax-reload-animated.gif'/>
        <table id='course-table' style='display: none;'>
          <thead>
            <th>Code</th>
            <th>Name</th>
            <th>Grade</th>
          </thead>
          <tbody id='course-t-body'></tbody>
        </table>
      </div></div>"

    $("aside#right-side").append "<div class='assignments'>
      <h2><a style='float: right; font-size: 10px; font-weight: normal;' class='icon-calendar-day standalone-icon' href='/calendar'>View Calendar</a>Upcoming Assignments</h2>
      <div class='assignment-summary-div'>
        <img id='assignload' style='display: block; margin-left: auto; margin-right: auto' src='images/ajax-reload-animated.gif'/>
        <table id='assignment-table' style='display: none;'>
          <thead>
            <th>Due Date</th>
            <th>Name</th>
            <th>Pts. Worth</th>
          </thead>
          <tbody id='assign-t-body'></tbody>
        </table>
      </div></div>"

  formatting : () ->
    notice = $('#notice-container')
    notice.css('background', 'white')
    notice.css('border', '1px solid #bbb')
    notice.css('padding', '10px')

  events : () ->
    $('.assignments>h2').click () ->
      $('.assignment-summary-div').toggle()
    $('.courses>h2').click () ->
      $('.course-summary-div').toggle()

  setup : () ->
    @remove()
    @add_divs()
    @prettyfy()
    @getCalendar()
    @events()

  getCalendar : () ->
    loading = $('#calload')
    loading.show
    calendar = $('#calendar-div')
    calendar.clndr()
    
    canvas_header = $('#header')

    day = $('.day')
    table = $('.clndr-table')
    table_header = $('.header-day')
    month = $('.month')
    today = $('.today')
    $('.clndr-control-button').hide()

    month_text = month.html()
    month.html "<h2>#{month_text}</h2>"
    month_header = $('.month>h2')
    month_header.css 'text-align', 'center'

    table.css 'width', '100%'
    
    table_header.css 'text-align', 'center'
    table_header.css 'background', '#eee'
    table_header.css 'font-weight', 'bold'
    
    day.css 'background', '#fff'
    day.css 'padding', '2px'
    day.css 'text-align', 'center'

    today.css 'background', canvas_header.css('background-color')

    loading.hide()
    calendar.fadeIn 500


#  Needs to be set so that it will display without the loop.
  displayAssignment : (assignment) ->
    final_string = ""
    summary = $('.assignment-summary-div')
    if @all_assignments.length > 0
      @all_assignments.sort (a, b) ->
        a.due_date - b.due_date
      range = moment().add 'days', 7
      if assignRange && assignRange != ""
        range = assignRange
        
      today = moment()
      for assignment in @all_assignments
        if assignment.due_date <= range
          if not assignment.submission
            assignment_link = @tools.format_link(assignment.url, assignment.name)
            date = null
            style = ""

            # @events.push {date: assignment.due_date.format('YYYY-DD-MM'), title: assignment.name, url: assignment.url}
            
            if assignment.due_date.get('date') == today.get('date')
              if colors
                style = "background: #FCDC3B;"
              date = assignment.due_date.format "[Today at] h:m a"
            else if assignment.due_date < today #&& display_late
              if colors
                style += "background: #{@HTML_RED};"
              date = assignment.due_date.format "dd DD h:m a"
            else if assignment.due_date.get('month') != today.get('month')
              date = assignment.due_date.format "MMM DD"
            else
              date = assignment.due_date.format "dd DD"

            final_string += "<tr id='#{assignment.id}' class='assign-row' style='#{style}'><td class='assign-date'>#{date}</td><td class='assign-name'>#{assignment_link}</td><td class='assign-points'>#{assignment.points_possible}</td></tr>"
      tbody = $('#assign-t-body')
      # clndr = $('#calendar-div').clndr();
      # clndr.setEvents(@events);

      tbody.html final_string

      assign_date = $('.assign-date')
      assign_name = $('.assign-name')
      assign_points = $('.assign-points')
      row = $('.assign-row')

      assign_date.css 'width', '20%'
      assign_date.css 'text-align', 'center'

      assign_name.css 'width', '60%'

      assign_points.css 'width', '20%'
      assign_points.css 'text-align', 'center'

      table = $('#assignment-table')
      table.css 'margin', '0px auto'
      table.css 'margin','0px'
      table.css 'width', '100%'
      table.fadeIn 500

    summary.fadeIn 500

  displayCourse : (course) ->
    final_string = ""
    console.log "#{course.id}) #{course.name}"
    course_link = @tools.createlink(course.url, course.name)
    course_grade = ""
    if grades == "1"
      if course.current_grade
        course_grade = "#{course.current_grade}"
      else if course.current_score
        course_grade = "#{course.current_score}"
      else if course.current_grade && course.current_score
        course_grade = "#{course.current_grade} (#{course.current_score})"
      else
        course_grade = ""
    else if grades == "2"
      if course.current_score
        course_grade = "#{course.current_score}"
      else if course.current_grade
        course_grade = "#{course.current_grade}"
      else if course.current_grade && course.current_score
        course_grade = "#{course.current_grade} (#{course.current_score})"
      else
        course_grade = ""
    else if grades == "3"
      if course.current_grade && course.current_score
        course_grade = "#{course.current_grade} (#{course.current_score})"
      else if course.current_grade
        course_grade = "#{course.current_grade}"
      else if course.current_score
        course_grade = "#{course.current_score}"
      else
        course_grade = ""
    else
      if course.current_grade
        course_grade = "#{course.current_grade}"
      else if course.current_score
        course_grade = "#{course.current_score}"
      else if course.current_grade && course.current_score
        course_grade = "#{course.current_grade} (#{course.current_score})"
      else
        course_grade = ""
    final_string += "<tr id='#{course.id}' ><td class='class-code'>[#{course.code}]</td><td class='class-link'>#{course_link}</td><td class='class-grade'>#{course_grade}</td></tr>"
    table = $('#course-table')
    tbody = $('#course-t-body')

    tbody.html final_string

    code = $('.class-code')
    link = $('.class-link')
    grade = $('.class-grade')

    code.css 'width', '20%'
    code.css 'text-align', 'center'

    link.css 'width', '60%'

    grade.css 'width', '20%'
    grade.css 'text-align', 'center'

    table.css 'margin', '0px auto'
    table.css 'margin','0px'
    table.css 'width', '100%'

    table.fadeIn 500

  displayCourses : (courses) ->
    for course in courses
      @displayCourse course

  displayAssignments : (assignments) ->


startup = () =>
  display = new Display()
  query = new Query()

  query.queryCourses (response) ->
    currentCourses = []
    response = $(response)
    today = moment()
    for item in response
      end_date = moment(item.end_at)
      if end_date >= today
        course = {}
        course.id = item.id
        course.start_date = moment(item.start_at)
        course.end_date = end_date
        course.code = item.course_code
        course.name = item.name
        course.current_grade = item.enrollments[0].computed_current_grade
        course.current_score = item.enrollments[0].computed_current_score
        course.final_grade = item.enrollments[0].computed_final_grade
        course.final_score = item.enrollments[0].computed_final_score
        course.url = query.canvasCourseUrl + course.id
        currentCourses.push course
        query.queryAssignments course.id, (response) ->
          
    @print_courses(arr)

      
  config.setup()
  # cal.get_calendar()
  # cour.query_courses()
  # if canvaskey == undefined || canvaskey == null || canvaskey == ""
  notice = $('#notice')
    # url = $('.user_name>a').attr("href")
  notice.html "<span style='color: red'>Canvas To Moddle has been disabled due to certain courses not displaying assignments. Instead of faulty data not being displayed, for a short durration the plugin will be disabled until an update is pushed.</span><br>Click here for progress on this issue: <a href='https://trello.com/c/oahSl8K3'>Click</a>"
  notice.css 'cursor', 'pointer'
    # notice.html "<span style='color: red'>
    #   Auth Token Required.
    #   <br/>
    #   Make sure you have an Auth-Token saved.</span>
    #   <br/><br/>
    #   <ol>
    #     <li>Create a token here: <a href='#{url}'>Create Token</a></li>
    #     <li>Scroll down to the bottom of the page and click \"New Access Token\"</li>
    #     <li>Copy the token which will look like 1~iocGw2co</li>
    #     <li>Open your <a href='chrome://extensions/'>extensions</a> page and find the options link under the Canvas to Moodle Plugin.</li>
    #     <li>Paste the token in the specified location.</li>
    #     <li>Enjoy!</li>
    #   </ol>"
    # $('.calendar').hide()
    # $('.courses').hide()
    # $('.assignments').hide()

$(docuemnt).ready ->
  ( ->
    checkIfAssideHasLoaded = setInterval( ->
      if $('ul.events').length > 0
        startup()
        clearInterval checkIfAssideHasLoaded
      undefined
    , 50)
    # getcanvaskey()
    # getSyncSettings()
  )()