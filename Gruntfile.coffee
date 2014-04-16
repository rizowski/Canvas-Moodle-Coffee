module.exports = (grunt) ->

	# Project configuration
	grunt.initConfig {
		pkg: grunt.file.readJSON 'package.json'

		uglify: {
			options: {
				sourceMap: '<% filename %>.map'
				banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
			}
		}

		coffee: {
			options: {
				sourceMap: true
				bare:  true
			}
			compile: {
				files: {
					'out/contentscript.js': ['res/coffee/canvasextension.coffee', 'res/coffee/display.coffee', 'res/coffee/query.coffee', 'res/coffee/grinder.coffee']
					'out/options.js': 'res/coffee/options.coffee'
					'out/tracker.js': 'res/coffee/tracker.coffee'
					'tests/src/contentscript.js': ['res/coffee/canvasextension.coffee', 'res/coffee/display.coffee', 'res/coffee/query.coffee', 'res/coffee/grinder.coffee']
				}
			}
		}

		compass:{
			dist:{
				options:{
					sassDir: 'res/style/'
					cssDir: 'out/'
				}
			}
		}

		copy: {
			main: {
				files: [
					{expand: true, flatten: true, src:['res/*'],			dest: 'out/', filter: 'isFile'}
					{expand: true, flatten: true, src:['res/html/*'], dest: 'out/', filter: 'isFile'}
					{expand: true, flatten: true, src:['res/imgs/*'], dest: 'out/', filter: 'isFile'}
					{expand: true, flatten: true, src:['lib/*'],			dest: 'out/', filter: 'isFile'}
				]
			}
		}

		clean: ['out/', 'tests/src/']

		build: {
			# Fill this out
		}

		jasmine: {
			'src': ['out/contentscript.js', 'out/options.js', 'out/tracker.js'],
			'options.helpers': ['out/jquery.min.js', 'out/jquery-ui.min.js', 'jquery.tinysort.min.js', 'moment.min.js'],
			'options.styles': 'out/style.css'
		}
	}

	# Load uglify
	grunt.loadNpmTasks 'grunt-contrib-uglify'
	grunt.loadNpmTasks 'grunt-contrib-coffee'
	grunt.loadNpmTasks 'grunt-contrib-compass'
	grunt.loadNpmTasks 'grunt-contrib-jasmine'
	grunt.loadNpmTasks 'grunt-contrib-copy'
	grunt.loadNpmTasks 'grunt-contrib-clean'
	grunt.registerTask 'default', ['clean', 'uglify', 'compass', 'coffee', 'copy']
