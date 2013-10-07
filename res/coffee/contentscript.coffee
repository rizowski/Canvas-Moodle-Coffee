# This needs a refactor. The first time writing this in Coffee I wasn't entirely 
# sure what I could do with it. Once released improvements will be made.

$(document).ready ->
  canvaskey = null

  setkey = (item) =>
    canvaskey = item

  getcanvaskey = () =>
    chrome.storage.local.get 'canvaskey', (item) ->
      setkey item.canvaskey 
      

  $.ajaxSetup
        cache: true
        headers: { 
            "Authorization" : "Bearer #{canvaskey}",
            "Access-Control-Allow-Origin" : "*"
        }
        dataType : "json"

  class Tools

    constructor : () ->
    
    format_link: (url, text) ->
      "<a href='#{url}'>#{text}</a>"

    table_row: (contents) ->
      result = "<tr>"
      for content in contents
        result += "<td>#{content}</td>"
      result += "</tr>"

    format_table: (headers, contents_arr) ->
      headers ?= []
      contents_arr ?= []
      return if headers.length != contents_arr.length

      final_string = "<table><thead>"
      for header in headers
        final_string += "<th>#{header}</th>"
      final_string += "</thead><tbody>"
      for content_items in contents_arr
        @table_row content_items
      final_string += "</tbody></table>"

      final_string

    create_error : (message) ->
      "<span style='color: red'>#{message}</span>"

    parse_assignment: (assignment) ->
      "<tr><td>#{assignment.due_date}</td><td>#{@format_link assignment.url, assignment.name}</td><td>#{assignment.points_possible}</td></tr>"

  class CanvasPlugin
    course_apiurl : "/api/v1/courses?include[]=total_scores&state[]=available"
    canvas_courses_url : "/courses/"

    assignments_apiurl : (_courseId) ->
      return "/api/v1/courses/#{_courseId}/assignments?include[]=submission"

    tools : (new Tools())

    constructor : ->

  class Config 
    constructor : ->

    remove : () ->
      $('aside#right-side').children('div').remove()
      $("aside#right-side").children('h2').remove()
      $("aside#right-side").children('ul').remove()
      
    add_divs : () ->
      $("aside#right-side").append "<div id='notice-container' style='display: none;'>
            <h2>Canvas to Moodle Notice</h2>
            <div id='notice'></div>
            </div>"

      $("aside#right-side").append "<div class='calendar'>
            <h2 style='display: none;'>Calendar</h2>
            <img id='calload' style='display: block; margin: 0 auto;' src='images/ajax-reload-animated.gif'/>
            <div class='calendar-div' style='display: none;'>
              
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

    prettyfy : () ->
      notice = $('#notice-container')
      notice.css('background', 'white')
      notice.css('border', '1px solid #bbb')
      notice.css('padding', '10px')

    setup : () ->
      @remove()
      @add_divs()
      @prettyfy()

  class Calendar extends CanvasPlugin
    constructor : () ->

    get_calendar : () ->
      loading = $('#calload')
      loading.show
      calendar = $('.calendar-div')
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

  class Courses extends CanvasPlugin

    current_courses = null
    all_assignments : null
    hit_counter = 0
    error_hit_counter = 0

    constructor : () ->
      @current_courses = []
      @all_assignments = []
      @hit_counter = 0
      @error_hit_counter = 0

    assignment_sort: (obj1, obj2) ->
      if not obj1
        return -1
      if not obj2
        return -1

    query_courses : () ->
      return $.ajax
        type: 'GET'
        crossDomain: true
        url: @course_apiurl
        headers: 
          "Authorization" : "Bearer #{canvaskey}",
          "Access-Control-Allow-Origin" : "*"
        statusCode: 
          401 : () ->
            console.log 'Course not visible'
          404 : () ->
            console.log 'Page not found'
          500 : () ->
            console.log 'Server error'
        success: (data) =>
          @success_course(data)
          undefined
        complete: (xhr, status) =>
          $('#courseload').hide()

    query_assignments : (_courseId) ->
      return $.ajax
        type: 'GET'
        crossDomain: true
        url: @assignments_apiurl(_courseId)
        headers:
          "Authorization" : "Bearer #{canvaskey}",
          "Access-Control-Allow-Origin" : "*"
        statusCode:
          401 : () ->
            console.log 'Assignment not visible'
          404 : () ->
            console.log 'Page not found'
          500 : () ->
            console.log 'Server error'
        success: (data) =>
          @hit_counter++
          @success_assignment(data)
        error: (xhr, status, error) =>
          @error_hit_counter++
        complete: (xhr, status) =>
          $('#assignload').hide()
          

    success_assignment: (response) ->
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
            @all_assignments.push assignment
      counter = @hit_counter + @error_hit_counter
      if counter = @current_courses.length
        @get_assignments()

    success_course: (response) ->
      arr = []
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
          course.url = @canvas_courses_url + course.id
          @current_courses.push course
          arr.push course
          @query_assignments(course.id)
      @get_courses(arr)

    get_courses: (courses) ->
      final_string = ""
      for course in courses
        @query_assignments(course.id)
        course_link = @tools.format_link(course.url, course.name)
        course_grade = ""
        if course.start_date >= moment()
          if course.current_grade
            course_grade = "#{course.current_grade}"
          else if course.current_score
            course_grade = "#{course.current_score}"
          else if course.final_grade
            course_grade = "#{course.final_grade}"
          else if course.final_score
            course_grade = "#{course.final_score}"
          else
            course_grade = "NA"
        final_string += @tools.table_row ["[#{course.code}]", course_link, "(#{course_grade})"]
      table = $('#course-table')
      tbody = $('#course-t-body')

      tbody.html final_string

      table.css('margin', '0px auto')
      table.css('margin','0px')
      table.css('width', '100%')

      table.fadeIn 500
      #console.log 'grade load'

    get_assignments: () ->
      final_string = ""
      summary = $('.assignment-summary-div')
      if @all_assignments.length > 0
        @all_assignments.sort (a, b) ->
          a.due_date - b.due_date
        seventh_day = moment().add('days', 7)
        
        for assignment in @all_assignments
          if assignment.due_date <= seventh_day
            assignment_link = @tools.format_link(assignment.url, assignment.name)
            turned_in = (assignment.submission?)
            date = null
            if(assignment.due_date == moment())
              date = assignment.due_date.format("[Today at] h:m a ")
            else
              date = assignment.due_date.format("dd DD")
            final_string += "<tr><td class='assign-date'>#{date}</td><td class='assign-name'>#{assignment_link}</td><td class='assign-points'>#{assignment.points_possible}</td></tr>"
        tbody = $('#assign-t-body')

        tbody.html final_string

        assign_date = $('.assign-date')
        assign_name = $('.assign-name')
        assign_points = $('.assign-points')

        assign_date.css 'width', '20%'
        assign_date.css 'text-align', 'center'

        assign_name.css 'width', '60%'

        assign_points.css 'width', '20%'
        assign_points.css 'text-align', 'center'

        table = $('#assignment-table')
        table.css('margin', '0px auto')
        table.css('margin','0px')
        table.css('width', '100%')
        table.fadeIn 500

      summary.fadeIn 500
  
  startup = () =>
    config = new Config()
    cal = new Calendar()
    cour = new Courses()

    config.setup()
    cal.get_calendar()
    cour.query_courses()
    if canvaskey == undefined || canvaskey == null || canvaskey == ""
      notice = $('#notice')
      url = $('.user_name>a').attr("href")
      notice.html "<span style='color: red'>
        Auth Token Required.
        <br/>
        Make sure you have an Auth-Token saved.</span>
        <br/><br/>
        <ol>
          <li>Create a token here: <a href='#{url}'>Create Token</a></li>
          <li>Scroll down to the bottom of the page and click \"New Access Token\"</li>
          <li>Copy the token which will look like 1~iocGw2co</li>
          <li>Open your <a href='chrome://extensions/'>extensions</a> page and find the options link under the Canvas to Moodle Plugin.</li>
          <li>Paste the token in the specified location.</li>
          <li>Enjoy!</li>
        </ol>"
      $('.calendar').hide()
      $('.courses').hide()
      $('.assignments').hide()
      $('#notice-container').fadeIn 500

  ( ->
    checkIfAssideHasLoaded = setInterval( ->
      if $('ul.events').length > 0
        startup()
        clearInterval checkIfAssideHasLoaded
      undefined
    , 50)
    getcanvaskey()
  )()
