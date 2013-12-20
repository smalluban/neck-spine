class RouteRunner extends Neck.Controller

  scope: '='

  constructor: ->
    super

    options = {}
    options.params = {}

    for own key, value of @scope
      options.params[key] = value

    @scope.context.route @runAttr, options, @back
    @scope.release()

Neck.Runner['route'] = class Router 

  constructor: (options)->
    options.el.on 'click', (e)=>
      e.preventDefault()
      new RouteRunner options

Neck.Runner['route-back'] = class Router 

  constructor: (options)->
    options.el.on 'click', (e)=>
      e.preventDefault()
      options.back = true
      new RouteRunner options

  