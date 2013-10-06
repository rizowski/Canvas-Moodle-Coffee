# This needs a refactor. The first time writing this in Coffee I wasn't entirely 
# sure what I could do with it. Once released improvements will be made.

$(document).ready ->
  canvaskey = ""

  setkey = (item) =>
    canvaskey = item

  getcanvaskey = () =>
    chrome.storage.local.get 'canvaskey', (item) ->
      setkey(item.canvaskey)
      

  $.ajaxSetup
        cache: true
        # for the mean time, this is commented out due to problems with XSS the calendar
        # headers: { 
        #     "Authorization" : "Bearer " + canvaskey,
        #     "Access-Control-Allow-Origin" : "*"
        # }
        # dataType : "json"
        # dataFilter : (data, type) ->
        #   console.log type
        #   JSON.parse(data) if type == "json"
        statusCode: {
          401 : () ->
            notice = $('#notice')
            notice.html '<span style="color: red">You are not authorized. Make sure you have an Auth-Token saved.</span>'
            $('#notice-container').fadeIn 500
            console.log 'Auth token needed'
          404 : () ->
            console.log 'Page not found'
          500 : () ->
            console.log 'Server error'
        }

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

    parse_canvas_date : (date) ->
      return if date == null
      date_string = date.split('T')
      date = date_string[0].split('-')
      year = date[0]
      month = date[1]
      day = date[2]

      new Date(year, month, day)

    create_error : (message) ->
      "<span style='color: red'>#{message}</span>"

    # add assignments to courses when ittterating over the courses into your own object. ok :D
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
      $("aside#right-side").append '<div id="notice-container" style="display: none;">
            <h2>Canvas to Moodle Notice</h2>
            <div id="notice"></div>
            </div>'

      $("aside#right-side").append '<div class="calendar">
            <h2 style="display: none;">Calendar</h2>
            <div class="calendar-div">
              <img id="calload" style="display: block; margin: 0 auto;" src="images/ajax-reload-animated.gif"/>
            </div></div>'

      $("aside#right-side").append '<div class="courses">
            <h2>Current Courses</h2>
            <div class="course-summary-div">
              <img id="courseload" style="display: block; margin: 0 auto;" src="images/ajax-reload-animated.gif"/>
              <table id="course-table" style="display: none;">
                <thead>
                  <th>Code</th>
                  <th>Name</th>
                  <th>Grade</th>
                </thead>
                <tbody id="course-t-body"></tbody>
              </table>
            </div></div>'

      $("aside#right-side").append '<div class="assignments">
            <h2><a style="float: right; font-size: 10px; font-weight: normal;" class="icon-calendar-day standalone-icon" href="https://lms.neumont.edu/calendar">View Calendar</a>Upcoming Assignments</h2>
            <div class="assignment-summary-div">
              <img id="assignload" style="display: block; margin-left: auto; margin-right: auto" src="images/ajax-reload-animated.gif"/>
              <table id="assignment-table" style="display: none;">
                <thead>
                  <th>Date</th>
                  <th>Name</th>
                  <th>Worth</th>
                </thead>
                <tbody id="assign-t-body"></tbody>
              </table>
            </div></div>'

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
      $('#calload').show
      $('.calendar-div').clndr()
      $('#calload').hide()

      day = $('.day')
      table = $('.clndr-table')
      header = $('.header-day')
      month = $('.month')
      $('.clndr-control-button').hide()

      month_text = month.html()
      month.html "<h2>#{month_text}</h2>"
      month_header = $('.month>h2')
      month_header.css 'text-align', 'center'

      table.css 'width', '100%'
      header.css 'text-align', 'center'
      header.css 'background', '#eee'
      header.css 'font-weight', 'bold'
      day.css 'background', '#fff'
      day.css 'padding', '2px'
      day.css 'text-align', 'center'

  class Courses extends CanvasPlugin

    current_courses = []
    all_assignments = []
    hit_counter = 0

    assignment_sort: (obj1, obj2) ->
      obj1.due_date - obj2.due_date

    constructor : () ->
      @current_courses = []

    query_courses : () ->
      return $.ajax
        type: 'GET'
        crossDomain: true
        url: @course_apiurl
        headers: { 
                "Authorization" : "Bearer #{canvaskey}",
                "Access-Control-Allow-Origin" : "*"
            }
            dataType : "json"
            # dataFilter : (data, type) ->
            #   console.log type
            #   JSON.parse(data) if type == "json"
            statusCode: {
              401 : () ->
                console.log 'Course not visible'
              404 : () ->
                console.log 'Page not found'
              500 : () ->
                console.log 'Server error'
            }
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
        headers: {
          "Authorization" : "Bearer #{canvaskey}",
          "Access-Control-Allow-Origin" : "*"
        }
        dataType: 'json'
        statusCode: {
              401 : () ->
                console.log 'Course not visible'
              404 : () ->
                console.log 'Page not found'
              500 : () ->
                console.log 'Server error'
            }
        success: (data) =>
          @success_assignment(data)
        error: (xhr, status, error) =>
          console.log "QueryAssignments: #{status}, #{error}"
        complete: (xhr, status) =>
          console.log status
          $('#assignload').hide()

    success_assignment: (response) ->
      response = $(response)
      today = new Date()
      for item in response
        assignment = {}
        assignment.due_date = new Date(item.due_at)
        if assignment.due_date < today
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
          @all_assignments.push assignment
      @get_assignments

    success_course: (response) ->
      arr = []
      response = $(response)
      today = new Date()
      for item in response
        end_date = new Date(item.end_at)
        if end_date >= today
          course = {}
          course.id = item.id
          course.start_date = new Date(item.start_at)
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
        final_string += @tools.table_row ["[#{course.code}]", course_link, "(#{course.final_grade})"]
      table = $('#course-table')
      tbody = $('#course-t-body')

      tbody.html final_string

      table.css('margin', '0px auto')
      table.css('margin','0px')
      table.css('width', '100%')

      table.fadeIn 500
      console.log 'grade load'

    get_assignments: () ->
      final_string = ""
      summary = $('.assignment-summary-div')
      @hit_counter++
      if @current_course.length == hit_counter
        if @all_assignments.length > 0
          @all_assignments.sort(assignment_sort())
          for assignment in @all_assignments
            # if assignment.submission?
              # continue
            assignment_link = @tools.format_link(assignment.url, assignment.name)
            console.log assignment.submission?
            turned_in = (assignment.submission?)
            date = $.datepicker.formatDate('mm-dd-yyyy', assignment.due_date)
            final_string += @tools.table_row [date, assignment_link, turned_in]
          tbody = $('#assign-t-body')
          tbody.html final_string

          table = $('#assignment-table')
          table.css('margin', '0px auto')
          table.css('margin','0px')
          table.css('width', '100%')
        else
          summary.html final_string

      summary.fadeIn 500
      console.log 'assignments load'
      
  ( ->
    checkIfAssideHasLoaded = setInterval( ->
      if $('ul.events').length > 0
        config = new Config()
        cal = new Calendar()
        cour = new Courses()

        config.setup()
        cal.get_calendar()
        cour.query_courses()
        #cour.query_assignments(1096567) #1096492)

        clearInterval checkIfAssideHasLoaded
      undefined
    , 50)
    getcanvaskey()
  )()
