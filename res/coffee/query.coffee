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

        today = moment("0:0:0.0", "H:m:s.SSS")
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