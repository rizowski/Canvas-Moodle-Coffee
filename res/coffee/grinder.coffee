startup = () =>
  display = new Display()
  query = new Query()

  query.getSettings (settings) ->
    query.getCanvasKey (key) ->
      if key is "" or not key
        url = $('.user_name>a').attr("href")
        #TODO: Turn this into an .html partial
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
          key = $(@).val()
          if key != "" && key.indexOf("1~") != -1
            query.saveCanvasKey key
            $('#notice-container').fadeOut(500)
            location.reload()
      else
        query.queryCourses (courses) ->
          _.each courses.current, (course) ->
            display.insertCourse course
            query.queryAssignments course.id, (assignments) ->
              _.each assignments.soon, (assignment, index) ->
                ranges = settings.assignments.displayRange.split(' ');
                date = moment('23:59:59.999', "H:m:s.SSS")
#                date.set('hour', 23)
#                date.set('minute', 59)
#                date.set('second', 59)
#                date.set('millisecond', 999)
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