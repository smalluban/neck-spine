# Initialize Neck global object
window.Neck = Neck = {}

Neck.Scope = class Scope extends Spine.Module
  @include Spine.Events

  constructor: (options)->
    throw "Context required" unless options.context

    for key, value of options
      @addHiddenProperty key, value

    for property in [
      ["_resolvers", {}]
      ["_dirties", []]
      ["_childs", []]
      ["_callbacks", {}]
      ["listeningTo", []]
      ["listeningToOnce", []]
    ]
      @addHiddenProperty.apply @, property

  child: (options)->
    @_childs.push child = Object.create(@)

    for key, value of options
      child.addHiddenProperty key, value

    for property in [
      ["parent", @]
      ["_resolvers", {}]
      ["_dirties", []]
      ["_childs", []]
      ["_callbacks", {}]
      ["listeningTo", []]
      ["listeningToOnce", []]
    ]
      child.addHiddenProperty.apply child, property

    child

  ### PROPERTIES ###

  _stringForEval: (string, scope = 'scope', context = 'context')->
    string = string.trim()
    texts = string.match /\'[^\']+\'/g
    reservedKeywords = new RegExp """
      (^|\\ )#{scope}\\.(do|if|in|for|let|new|try|var|case|else|enum|eval|false|null|this|true|
      void|with|break|catch|class|const|super|throw|while|yield|delete|export|import|public|
        return|static|switch|typeof|default|extends|finally|package|private|continue|debugger|
        function|arguments|interface|protected|implements|instanceof|undefined|window)""", "g"
    contextRegex = new RegExp "\\@#{scope}\\.([a-zA-Z$_][^\ ]+)", "g"

    string.replace(/\'[^\']+\'/g, (text)-> "###")
      .replace(/([a-zA-Z$_][^\ \(\)\{\}]*)/g, "#{scope}.\$1")
      .replace(reservedKeywords, (text)-> text.replace('scope.', ''))
      .replace(contextRegex, "#{context}.\$1")
      .replace(/###/g, ()-> texts.shift())

  _getPropertiesFromString: (string)->
    string = string.replace /\'[^\']+\'/g, (text)-> "###"
    result = []

    for item in string.match /scope\.([a-zA-Z$_][^\ \(\)\{\}\;]*)/g
      if result.indexOf(property = item.replace('scope.','')) is -1
        result.push property.split('.')[0]

    result

  addHiddenProperty: (key, value)->
    Object.defineProperty @, key,
      value: value
      enumerable: false
      configurable: false

  addProperty: (name, string, scope = @parent, context = @context)->
    # Match string, ex: "'Text'"
    if string.match /^\'.+\'$/
      @[name] = string.replace(/^\'/,'').replace(/\'$/,'')
    # Match Number, ex: 12.34
    else if string.match /^[0-9]+((\.|\,)?[0-9]+)*$/
      @[name] = Number string.replace(/\,/g, '.')
    # Anything else we need eval
    else
      string = @_stringForEval string
      # For check we need string without texts
      checkString = string.replace /\'[^\']+\'/g, (text, index)-> "###"
      resolvers = []

      unless checkString.match /[-+=\(\)\{\}\:]+/
        resolvers.push string.split('.')[1]

        Object.defineProperty @, name, 
          get: -> eval string
          set: (val)-> 
            model = string.split('.')
            property = model.pop()
            model = eval model.join('.')

            model[property] = val
      else
        if checkString.match /\:/
          string = "(" + string + ")"

        Object.defineProperty @, name, 
          get: -> 
            eval string

        unless checkString.match /\(/
          resolvers = @_getPropertiesFromString checkString
        else
          resolvers.push '?'

      @_resolvers[name] = []

      # set Resolver
      for resolver in resolvers
        if resolver is '?'
          @_resolvers[name].push { scope: scope._root(), property: '?' }
        else if parentResolver = scope._resolvers[resolver]
          for resolve in parentResolver
            @_resolvers[name].push resolve
        else
          if scope.hasOwnProperty(resolver) or !scope.parent
            @_resolvers[name].push { scope: scope, property: resolver }

      undefined

  #### WATCHERS ###

  _root: ->
    @parent?._root() or @

  watch: (args...)->
    callback = args.pop()
    properties = args

    if properties.length
      for property in properties
        if @_resolvers[property] 
          for resolver in @_resolvers[property] 
            @listenTo resolver.scope, "refresh:#{resolver.property}", callback
        else if @hasOwnProperty(property) or !@parent
          @bind "refresh:#{property}", callback
        else
          scope = @
          while parentScope = scope.parent
            if parentScope._resolvers[property]
              for resolver in parentScope._resolvers[property] 
                @listenTo resolver.scope, "refresh:#{resolver.property}", callback
              break
    else
      @listenTo @_root(), "refresh:?", callback

    # Initial call
    callback.call @

  apply: (dirties...)->
    root = @_root()
    root._applies or= 0
    root._applies += 1

    for dirty in dirties     
      if @_resolvers[dirty]
        for resolver in @_resolvers[dirty]
          resolver.scope.trigger "refresh:#{resolver.property}"
      else
        @.trigger "refresh:#{dirty}"

    unless --root._applies
      root.trigger 'refresh:?'

  releaseChilds: ->
    for child in @_childs
      child.releaseChilds()
      child.stopListening()
    undefined

  release: ->
    @releaseChilds()

    @stopListening()
    @unbind()

Neck.Controller = class Controller extends Spine.Controller

  # Global setup
  @viewsPath: 'views'
  @controllersPath: 'controllers'
  @helpersPath: 'helpers'

  # Runners list
  @runners: []

  scope: true
  inheritScope: true

  constructor: ->
    super

    unless @parentScope
      @scope = new Scope context: @
    else 
      if @scope
        if @inheritScope
          childScope = @parentScope.child()
        else
          childScope = new Scope context: @
        if typeof @scope is 'object'
          for key, value of @scope
            if string = @el[0].dataset[key]
              switch @scope[key]
                when '@' then childScope.addProperty key, "'#{string}'", @parentScope
                when '=' then childScope.addProperty key, string, @parentScope
            else 
              childScope[key] = if @scope[key] isnt '=' and @scope[key] isnt '@' then @scope[key] else undefined
        else if @scope is '@'
          for key, value of @el[0].dataset
            childScope.addProperty key, "'#{value}'", @parentScope
        else if @scope is '='
          for key, value of @el[0].dataset
            childScope.addProperty key, value, @parentScope

        @scope = childScope

  append: (controller)->
    @yield or= @el.find('[ui-yield]')[0] or @el[0]
    $(@yield).append controller.el or controller

  parse: (node = @el[0])->
    el = null

    @parse child for child in node.childNodes

    if node.attributes
      for attribute in node.attributes
        continue unless attribute.nodeName?.substr(0, 3) is "ui-"
        name = attribute.nodeName.substr(3)

        if Neck.Controller.runners[name]
          el or= $(node)
          runner = new Neck.Controller.runners[name](el: el, parentScope: @scope, runAttr: attribute.value)
      
    undefined

  render: ->
    if @view
      # Clear childs scopes
      @scope.releaseChilds()

      if typeof @view is 'function'
        @view.call @
      else
        @el.html (require("#{Neck.Controller.viewsPath}/#{@view}"))(@scope) 
        
      @parse() if @el[0]

  release: ->
    super

    if @scope
      @scope.release()
      @scope = undefined


Neck.Screen = class Screen extends Neck.Controller
  className: 'screen'

  # For default screen clear scope of parent screen 
  # and only can inherit values gives to ui-route runner
  inheritScope: false

  # Type of screen (normal/popup)
  # Popups always are placed after leaf and not deactive 
  # this leaf - their parent
  popup: false 
  
  # loading same path trigger refresh controller
  # Can be useful when new params goes to the same view
  reloadSelf: false 

  constructor: ->
    super

    throw "No path defined" unless @path

    # Add to el path classes
    @el.addClass @path.replace /\//gi, ' '

    # Creating view path from path
    @view = @path unless @view

  ### RENDERING / VIEW ###

  _inDOM: -> 
    @el[0].parentNode?

  render: ->
    super

    # Try to find yield
    @yield = @el.find('[ui-yield]')[0]

    # Connecting view parent element 
    # should be done only once
    unless @_inDOM()
      @parent?.append @

  append: (controller)->
    if @yield
      $(@yield).append controller.el or controller
    else
      @parent.append controller

  activate: ->
    # Try to release child
    @child?.release()
    @child = null

    # Deactivate parent
    @parent?.deactivate() unless @popup
    @parent?.child = @

    # Set DOM changes
    @el.addClass 'active'
    @el.css 'zIndex', @zIndex = @parent?.zIndex + 1 or 1

    @trigger 'activate'

    # Render controller view
    @render() unless @_inDOM()

    @

  deactivate: ->
    @el.removeClass 'active' unless @yield
    @trigger 'deactivate'

  ### ROUTING ###

  _leaf: ->
    @child?._leaf() or @

  _childWithPath: (path)->
    if @child
      if @child.path is path
        @child
      else
        @child._childWithPath path
    else
      false

  route: (path, options = {}, back = false)->
    controller = @root._childWithPath path

    # New controller instance is created if there is
    # no controller in scope or if it is direct child
    # and it has 'reloadSelf' property turn on (true)
    if (controller is false) or (controller is @child and controller.reloadSelf)
      @child.release() if controller is @child

      controller = require("#{Neck.Controller.controllersPath}/#{path}")

      # Popup always are put on top of controllers scope
      parent = if controller::popup then @_leaf() else @

      # If controller are in back, @parent should be parent
      # Back means that we want to go up in scope instead of going down
      if back and @parent
        options.parent = @parent
        options.parentScope = @parent.scope
        @release()
      else
        options.parent = parent
        options.parentScope = @scope

      options.path = path
      options.root = @root

      # Set child of parent controller
      controller = new controller(options)

    # Finally activate controller
    controller.activate()

    # Send route event to app controller
    @root.trigger 'route', controller

  ### SINGLETON ###

  singleton: -> 
    unless @constructor._instance
      @constructor._instance = @
      return false
    else
      return @constructor._instance

  _isSingleton: ->
    @constructor._instance isnt undefined

  ### RELEASE ###

  release: ->
    # Firstly release child screens 
    @child?.release()
    @child = undefined

    unless @_isSingleton()
      super
    else
      @el.css 'zIndex', @zIndex = 0
      @deactivate()


Neck.App = class App extends Neck.Screen

  # Path is required by Screen controller and is translate 
  # to view property so for defualt view has path 'app'
  path: 'app' 

  ### OPTIONS ###

  hashRoute: false
  historyApi: false

  constructor: ->
    super

    # App Controller is root of screens scope
    @root = @

    # History API can be used when Browser support it
    @historyApi = @historyApi and window.history

    # Push route to hash
    @on 'route', @_pushRoute if @hashRoute

    # This call should be triggered in your app controller
    # by @trigger 'run' when your calls and setup is done
    @one 'run', ->
      @render()
      @_evaluateRoute() if @hashRoute

  _pushRoute: ->
    hash = []

    screen = @child
    while screen 
      if (screen.child and screen.yield) or (!screen.child)
        params = []
        for param, value of screen.params
          if typeof value is 'string'
            params.push "#{param}='#{value}'"
          else
            params.push "#{param}=#{value}"
        hash.push if params.length then screen.path + "[#{params.join('&')}]" else screen.path
      screen = screen.child
    if @historyApi
      window.history.replaceState null, '', hash.join(':')
    else
      window.location.hash = "!/#{ hash.join(':') }"
    
  _evaluateRoute: ->
    # get path
    if @historyApi and window.history
      path = window.location.pathname
      path = '/' + path if path.substr(0,1) isnt '/'
    else
      path = window.location.hash
      path = path.replace(/^#(!\/)?/, '')

    if path = path.match /[^\:]+((\'[^\']*\')?[^\:]+)+/g
      screen = @
      for routePath, i in path
        routePath = routePath.replace /^\+/, -> screen.path + '/'
        options = params: {}
        routePath = routePath.match /[^\[\]]+/g

        for param in (routePath[1] or '').match(/[a-zA-Z$_][a-zA-Z$_0-9\-]+\=(\'[^\']*\'|[A-Za-z]+|[0-9]+((\.|\,)?[0-9]+)*)/g) or []
          param = param.match /^([a-zA-Z$_][a-zA-Z$_0-9\-]+)(?:\=)(.+)/
          options.params[param[1]] = eval param[2]

        try
          screen = screen.route(routePath[0], options)
        catch e
          # Clear hash
          window.location.hash = "!/"
          return @root.activate()