Neck.App = class App extends Neck.Screen

  # Path is required by Screen controller and is translate 
  # to view property so for defualt view has path 'app'
  path: 'app' 

  ### OPTIONS ###

  hashRoute: false
  errorRoute: false
  historyApi: false

  constructor: ->
    super

    # History API can be used when Browser support it
    @historyApi = @historyApi and window.history

    # Push route to hash
    @on 'activate:change', @pushRoute if @hashRoute

    # This call should be triggered in your app controller
    # by @trigger 'run' when your calls and setup is done
    @one 'run', ->
      @render()
      @evaluateRoute() if @hashRoute

  pushRoute: ->
    hash = []
    screen = @child
    while screen 
      if (screen.child and screen.yield) or (!screen.child) or screen.child?.popup
        params = []
        for param, value of screen.params
          if typeof value is 'string'
            params.push "#{param}='#{value}'"
          else
            params.push "#{param}=#{value}"
        hash.push if params.length then screen.path + "[#{params.join('&')}]" else screen.path
      screen = screen.child
    if @historyApi
      window.history.replaceState null, '', '/' + hash.join(':')
    else
      window.location.hash = "!/#{ hash.join(':') }"
    
  evaluateRoute: ->
    # get path
    if @historyApi
      path = window.location.pathname
    else
      path = window.location.hash
      path = path.replace(/^#(!\/)?/, '')

    path = path.replace /^\//, ''

    if path = path.match /[^\:]+((\'[^\']*\')?[^\:]+)+/g
      screen = @
      for routePath, i in path
        options = params: {}
        routePath = routePath.match /[^\[\]]+/g

        for param in (routePath[1] or '').match(/[a-zA-Z$_][a-zA-Z$_0-9\-]+\=(\'[^\']*\'|[A-Za-z]+|[0-9]+((\.|\,)?[0-9]+)*)/g) or []
          param = param.match /^([a-zA-Z$_][a-zA-Z$_0-9\-]+)(?:\=)(.+)/
          options.params[param[1]] = eval param[2]

        try
          screen = screen.route(routePath[0], options)
        catch e
          unless @errorRoute
            # Clear hash
            unless @historyApi
              window.location.hash = "!/"
            return @.activate()
          else
            @route @errorRoute.url, $.extend(errorCode: 404, @errorRoute.params)