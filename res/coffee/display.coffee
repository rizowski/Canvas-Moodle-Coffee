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