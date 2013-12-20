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

  # Screen can be singleton class, which means
  # constructor will always return one instance
  singleton: false

  constructor: (options)->
    if @singleton
      unless @constructor._instance
        @constructor._instance = @
      else
        return @constructor._instance

    super

    # Add to el path classes
    @el.addClass @path.replace /\//gi, ' '

    # Creating view path from path
    @view = @path unless @view

  ### RENDERING / VIEW ###

  _inDOM: -> 
    @el[0].parentNode?

  render: ->
    container = @el
    super

    @el = container.html @el

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
      @parent?.append controller

  activate: ->
    # Try to release child
    @child?.release()
    @child = undefined

    # Deactivate parent
    @parent?.deactivate() unless @popup
    @parent?.child = @

    # Set DOM changes
    @el.addClass 'active'
    @el.css 'zIndex', @zIndex = @parent?.zIndex + 1 or 1

    @trigger 'activate'
    @_root().trigger 'activate:change', @

    # Render controller view
    @render() unless @_inDOM()

    @

  deactivate: ->
    unless @yield
      @el.removeClass 'active' 
      @el.css 'zIndex', ''
      @zIndex = undefined
    @trigger 'deactivate'

  ### ROUTING ###

  _leaf: ->
    @child?._leaf() or @

  _root: ->
    @parent?._root() or @

  _childWithPath: (path)->
    if @child
      if @child.path is path
        @child
      else
        @child._childWithPath path
    else
      false

  route: (path, options = {}, back = false, noEvents = false)->
    controller = @_root()._childWithPath path

    # New controller instance is created if there is
    # no controller in scope or if it is direct child
    # and it has 'reloadSelf' property turn on (true)
    if (controller is false) or (controller is @child and controller.reloadSelf)
      try
        controller = require("#{Neck.Config.paths.controller}/#{path}")
      catch e
        if Neck.Config.screen
          controller = Neck.Config.screen
        else
          throw e
      
      # Release child to replace it with new controller
      # Only when its popup we leave child and put popup on top of it
      @child?.release() unless controller::popup

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
      controller = new controller(options)

    # Finally activate controller
    controller.activate()

    # Send route events
    unless noEvents
      @_root().trigger 'route', controller
      @.trigger 'route', controller

    controller

  back: ->
    if @parent
      @parent.activate()
    else
      false

  ### RELEASE ###

  release: ->
    # Firstly release child screens 
    @child?.release()
    @child = undefined

    # Delete parent reference
    @parent?.child = undefined
    @parent = undefined

    @deactivate()

    unless @singleton
      super