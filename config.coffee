exports.config =

  modules:
    definition: false
    wrapper: false

  paths:
    public: "lib/"
    watched: ['src', 'test', 'vendor']

  sourceMaps: false

  files:
    javascripts:
      joinTo: 
        'neck.js': /^src/
        'test/vendor.js': /^(test(\/|\\)(?=vendor)|bower_components)/
        'test/test.js': /^test(\/|\\)spec/
      order:
        before: [
          'src/neck.coffee'
        ]

    stylesheets:
      joinTo: 
        'test/style.css': /^test/

