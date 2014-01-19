_gaq = _gaq || []
_gaq.push ['_setAccount', 'UA-40060353-1']
_gaq.push ['_trackPageview']

(() -> 
  ga = document.createElement 'script'
  ga.type = 'text/javascript' 
  ga.async = true
  ga.src = '//ssl.google-analytics.com/ga.js'
  s = document.getElementsByTagName('script')[0]
  s.parentNode.insertBefore ga, s
)()