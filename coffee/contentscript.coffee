$(document).ready ->
	$.ajaxSetup({
		cache: true
    })
	class CanvasPlugin
		assignment_url : "https://lms.neumont.edu/api/v1/courses?include[]=total_scores"
		canvas_courses_url : "https://lms.neumont.edu/courses/"

		constructor : () ->


	class Config extends CanvasPlugin
		constructor : () ->

		setup : () ->
			$('aside#right-side').children('div').remove()
			$("aside#right-side").children('h2').remove()
			$("aside#right-side").children('ul').remove()
			$("aside#right-side").prepend '<div class="assignments"><h2><a style="float: right; font-size: 10px; font-weight: normal;" class="event-list-view-calendar small-calendar" href="https://lms.neumont.edu/calendar">View Calendar</a>Upcoming Assignments</h2><div class="assignment-summary-div"><img id="assignload" style="display: block; margin-left: auto; margin-right: auto" src="images/ajax-reload-animated.gif"></img></div></div>'
			$("aside#right-side").prepend '<div class="events_list"><h2>Grade Summary</h2><div class="grade-summary-div"><img id="gradeload" style="display: block;margin-left: auto; margin-right: auto" src="images/ajax-reload-animated.gif"></img></div></div>'
			$("aside#right-side").prepend '<div class="calendar"><h2>Calendar</h2><div class="calendar-div"><img id="calload" style="display: block; margin-left: auto; margin-right: auto" src="images/ajax-reload-animated.gif"></img></div></div>'

	class Tools extends CanvasPlugin
		constructor : () ->

		format_link: (url, text) ->
			"<a href='" + url + "'>" + text + "</a>"

		format_table: (headers, contents_arr) ->
			return if headers.length != contents_arr.length

			final_string = ""
			final_string = "<table>"
			final_string += "<thead>"
			for header in headers
				final_string += "<th>"
				final_string += header
				final_string += "</th>"
			final_string += "</thead>"
			final_string += "<tbody>"
			for content_items in contents_arr
				final_string += "<tr>"
				for content in content_items
					final_string += "<td>"
					final_string += content
					final_string += "</td>"
				final_string += "</tr>"
			final_string += "</tbody>"
			final_string += "</table>"

			final_string

		parse_canvas_date : (date) ->
			date_string = date.split('T')
			date = date_string[0].split('-')
			year = date[0]
			month = date[1]
			day = date[2]

			new Date(year, month, day)

		create_error : (message) ->
			"<span style='color: red'>" + message + "</span>"

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
					error = new Tools()
					$('.calendar-div').html error.create_error("Error Retrieving your calendar.")
				complete: () ->
					$('.calendar-div').fadeIn 500

	class Courses extends CanvasPlugin
		constructor : () ->

		query_courses : () ->
			return if localStorage.canvaskey == null
			return $.ajax
				type: 'GET'
				url: @assignment_url
				headers: { "Authorization" : "Bearer 1~7sbODArZOvxR9wlRt42ORJgTgqBG2m6OxTJlOMdphBwnhv4KOSjXVLZh3eIvahxw" } # + localStorage["canvaskey"] }

		get_courses: () ->
			data = null
			@query_courses().success (response) ->
				current_courses = []
				console.log reponse
				for item in response
					continue if item == null
					today = new Date()
					tools = new Tools()
					end_date = tools.parse_canvas_date(item.end_at)

					console.log end_date >= today

					if end_date >= today
						course = {}
						course.id = item.id
						course.start_date = tools.parse_canvas_date(item.start_at)
						course.end_date = end_date
						course.current_grade = item.enrollments[0].computed_current_grade
						course.current_score = item.enrollments[0].computed_current_score
						course.final_grade = item.enrollments[0].computed_final_grade
						course.final_score = item.enrollments[0].computed_final_score
						course.url = @canvas_courses_url + course.id
						current_courses.push course
				data = current_courses
			return data

		get_grades: () ->
			$('gradeload').show()

		get_assignments: () ->
			$('#assignload').show()
			courses = @get_courses()

	( ->
		checkIfAssideHasLoaded = setInterval( ->
			if $('ul.events').length > 0
				config = new Config()
				cal = new Calendar()
				cour = new Courses()

				config.setup()
				cal.get_calendar()
				cour.get_grades()
				cour.get_assignments()

				# config = new Config()
		    	# cal = new Calendar()
		      	# cour = new Courses()

		      	# config.setup()
		      	# cal.get_calendar()
		      	# cour.getGrades()
		      	# cour.getAssignments()

				clearInterval checkIfAssideHasLoaded
		, 50)
	)()
