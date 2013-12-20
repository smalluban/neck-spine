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
          'test/vendor/jquery-2.0.3.js'
          'test/vendor/mocha-1.14.0.js'
          'src/neck.coffee'
          'src/modules/scope.coffee'
          'src/modules/controller.coffee'
          'src/modules/screen.coffee'
          'src/modules/app.coffee'
        ]

    stylesheets:
      joinTo: 
        'test/style.css': /^test/

