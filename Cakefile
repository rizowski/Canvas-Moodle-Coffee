{log} = require 'sys'
{spawn} = require 'child_process'

task 'build', 'Build extension code into js', ->
	ps = spawn 'coffee', ["-o", "js/", "-c", "coffee/"]
	ps.stdout.on('data', log)
	ps.stderr.on('data', log)
	ps.on 'exit', (code) ->
		if code != 0
			console.log 'failed'