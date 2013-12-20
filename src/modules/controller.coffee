Neck.Controller = class Controller extends Spine.Controller

  # Global setup
  @viewsPath: 'views'
  @controllersPath: 'controllers'
  @helpersPath: 'helpers'

  # Runners list
  @runners: []

  scope: true
  inheritScope: true

  # When true controller will take innerHTML 
  # of element and set it as template
  innerTemplate: false

  constructor: ->
    super

    if @scope
      unless @parentScope
        childScope = new Scope @
      else if @inheritScope
        childScope = @parentScope.child()
      else
        childScope = new Scope @

      if typeof @scope is 'object'
        for key, value of @scope
          if string = @el[0].dataset[key]
            switch @scope[key]
              when '@' then childScope.addProperty key, "'#{string}'", @parentScope
              when '=' then childScope.addProperty key, string, @parentScope
              else childScope.addOwnProperty key, @scope[key]
          else 
            if @scope[key] isnt '=' and @scope[key] isnt '@'
              childScope.addOwnProperty key, @scope[key] 
            else
              childScope.addOwnProperty key, undefined
      else if @scope is '@'
        for key, value of @el[0].dataset
          childScope.addProperty key, "'#{value}'", @parentScope
      else if @scope is '='
        for key, value of @el[0].dataset
          childScope.addProperty key, value, @parentScope

      @scope = childScope
    else
      @scope = undefined

    if @innerTemplate
      if(template = @el.html()) isnt ''
        @template = template
        @el.empty()

  append: (controller)->
    @yield or= @el.find('[ui-yield]')[0] or @el[0]
    $(@yield).append controller.el or controller

  parse: (node = @el[0])->
    if node.attributes
      el = null
      for attribute in node.attributes
        continue unless attribute.nodeName?.substr(0, 3) is "ui-"
        name = attribute.nodeName.substr(3)

        if Neck.Runner[name]
          el or= $(node)
          runner = new Neck.Runner[name](el: el, parentScope: @scope, runAttr: attribute.value)
          breakParse = true if runner.innerTemplate
    
    @parse child for child in node.childNodes unless breakParse
    undefined

  render: ->
    if @view or @template
      # Clear childs scopes
      @scope?.releaseChilds()

      if typeof @template is 'string'
        @el = $(@template)
      else if typeof @template is 'function'
        @el = $(@template.call(@))
      else
        @el = $((require("#{Neck.Config.paths.view}/#{@view}"))(@scope))
      
      @parse(el) for el in @el
      undefined

  release: ->
    super

    if @scope
      @scope.release()
      @scope = undefined