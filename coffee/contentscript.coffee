$(document).ready ->
	canvaskey = ""

	setkey = (item) =>
		canvaskey = item
	getcanvaskey = () =>
		chrome.storage.local.get('canvaskey', (item) ->
			setkey(item.canvaskey)
			)

	$.ajaxSetup
        cache: true
        # for the mean time, this is commented out due to problems with XSS the calendar
        # headers: { 
        #     "Authorization" : "Bearer " + canvaskey,
        #     "Access-Control-Allow-Origin" : "*"
        # }
        # dataType : "json"
        # dataFilter : (data, type) ->
        # 	console.log type
        # 	JSON.parse(data) if type == "json"
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
			"<a href='" + url + "'>" + text + "</a>"

		table_row: (contents) ->
			result = "<tr>"
			for content in contents
				result += "<td>"
				result += content
				result += "</td>"
			result += "</tr>"

		format_table: (headers, contents_arr) ->
			headers ?= []
			contents_arr ?= []
			return if headers.length != contents_arr.length

			final_string = "<table>"
			final_string += "<thead>"
			for header in headers
				final_string += "<th>"
				final_string += header
				final_string += "</th>"
			final_string += "</thead>"
			final_string += "<tbody>"
			for content_items in contents_arr
				@table_row content_items
			final_string += "</tbody>"
			final_string += "</table>"

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
			"<span style='color: red'>" + message + "</span>"

	class CanvasPlugin
		course_apiurl : "/api/v1/courses?include[]=total_scores&state[]=available"
		canvas_courses_url : "/courses/"

		tools : (new Tools())

		constructor : ->

	class Config extends CanvasPlugin
		constructor : ->

		remove : () ->
			$('aside#right-side').children('div').remove()
			$("aside#right-side").children('h2').remove()
			$("aside#right-side").children('ul').remove()
			
		add_divs : () ->
			$("aside#right-side").prepend '<div class="assignments"><h2><a style="float: right; font-size: 10px; font-weight: normal;" class="event-list-view-calendar small-calendar" href="https://lms.neumont.edu/calendar">View Calendar</a>Upcoming Assignments</h2><div class="assignment-summary-div"><img id="assignload" style="display: block; margin-left: auto; margin-right: auto" src="images/ajax-reload-animated.gif"></img></div></div>'
			$("aside#right-side").prepend '<div class="courses"><h2>Current Courses</h2><div class="course-summary-div"><img id="courseload" style="display: block;margin-left: auto; margin-right: auto" src="images/ajax-reload-animated.gif"></img></div></div>'
			$("aside#right-side").prepend '<div class="calendar"><h2>Calendar</h2><div class="calendar-div"><img id="calload" style="display: block; margin-left: auto; margin-right: auto" src="images/ajax-reload-animated.gif"></img></div></div>'
			$("aside#right-side").prepend '<div id="notice-container" style="display: none;"><h2>Canvas to Moodle Notice</h2><div id="notice"></div></div>'

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
			$.ajax
				type: 'GET'
				url: '/calendar'
				success: (data) ->
					response = $(data)
					cal = response.find ".mini_month"
					cal.find('img').css 'display', 'none'
					$('.calendar-div').html(cal).hide
				error: (data) ->
					resp = $(data)
					$('.calendar-div').html @tools.create_error("Error Retrieving your calendar.")
				complete: () ->
					$('.calendar-div').fadeIn 500

	class Courses extends CanvasPlugin
		constructor : () ->

		query_courses : () ->
			console.log canvaskey
			return $.ajax
				type: 'GET'
				crossDomain: true
				url: @course_apiurl
				headers: { 
		            "Authorization" : "Bearer " + canvaskey,
		            "Access-Control-Allow-Origin" : "*"
		        }
		        dataType : "json"
		        # dataFilter : (data, type) ->
		        # 	console.log type
		        # 	JSON.parse(data) if type == "json"
		        success: (data) =>
		        	@success(data)
		        	undefined

		success: (response) ->
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
					arr.push course
			@get_assignments(arr)

		get_assignments: () ->
			# $('gradeload').show()
			console.log 'grade load'

		get_assignments: (courses) ->
			$('#assignload').show()
			
			final_string = ""
			for course in courses
				final_string = "<table class='course-table'><thead><th></th><th></th><th></th></thead><tbody>"
				course_link = @tools.format_link(course.url, course.name)
				final_string += @tools.table_row ["["+course.code+"]", course_link, "("+course.final_grade+")"]
				final_string += "</tbody></table>"

			$('.course-summary-div').html(final_string).hide
			$('.course-table').css('margin', '0px auto')
			table = $('.course-table')
			table.css('margin','0px')
			table.css('width', '100%')
			$('.course-summary-div').fadeIn 500
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

				clearInterval checkIfAssideHasLoaded
			undefined
		, 50)
		getcanvaskey()
	)()
