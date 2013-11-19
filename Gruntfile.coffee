module.exports = (grunt) -> 
	
	# Project configuration
	grunt.initConfig {
		pkg: grunt.file.readJSON 'package.json'

		uglify: {
			options: {
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
					'out/contentscript.js': 'res/coffee/contentscriptv2.coffee'
					'out/options.js': 'res/coffee/options.coffee'
					'out/tracker.js': 'res/coffee/tracker.coffee'
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
					{expand: true, flatten: true, src:['res/*'], dest: 'out/', filter: 'isFile'}
					{expand: true, flatten: true, src:['res/html/*'], dest: 'out/', filter: 'isFile'}
					{expand: true, flatten: true, src:['res/imgs/*'], dest: 'out/', filter: 'isFile'}
					{expand: true, flatten: true, src:['lib/*'], dest: 'out/', filter: 'isFile'}
				]
			}
		}

		clean: ['out/']

		build: {
			# Fill this out
		}
	}

	# Load uglify
	grunt.loadNpmTasks 'grunt-contrib-uglify'
	grunt.loadNpmTasks 'grunt-contrib-coffee'
	grunt.loadNpmTasks 'grunt-contrib-compass'
	grunt.loadNpmTasks 'grunt-contrib-copy'
	grunt.loadNpmTasks 'grunt-contrib-clean'
	grunt.registerTask 'default', ['clean', 'uglify', 'compass', 'coffee', 'copy']