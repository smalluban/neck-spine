Neck.Scope = class Scope extends Spine.Module
  @include Spine.Events

  constructor: (@context)->
    unless @context
      return throw "Context is required" 

    for key, value of {
      "_resolvers": {},
      "_childs": [],
      "_callbacks": {},
      "listeningTo": [],
      "listeningToOnce": []
    }
      @addHiddenProperty key, value

  child: ->
    @_childs.push child = Object.create(@)

    for key, value of {
      "parent": @
      "_resolvers": {},
      "_childs": [],
      "_callbacks": {},
      "listeningTo": [],
      "listeningToOnce": []
    }
      child.addHiddenProperty key, value

    child

  ### PROPERTIES ###

  _stringForEval: (string, scope = 'scope', context = 'context')->
    string = string.trim()
    texts = string.match /\'[^\']+\'/g
    reservedKeywords = new RegExp """
      (^|\\ )#{scope}\\.(do|if|in|for|let|new|try|var|case|else|enum|eval|false|null|this|true|
      void|with|break|catch|class|const|super|throw|while|yield|delete|export|import|public|
        return|static|switch|typeof|default|extends|finally|package|private|continue|debugger|
        function|arguments|interface|protected|implements|instanceof|undefined|window)(\\ |$)""", "g"
    contextRegex = new RegExp "\\@#{scope}\\.([a-zA-Z$_][^\ ]+)", "g"

    string.replace(/\'[^\']+\'/g, (text)-> "###")
      .replace(/([a-zA-Z$_][^\ \(\)\{\}]*)/g, "#{scope}.\$1")
      .replace(reservedKeywords, (text)-> text.replace('scope.', ''))
      .replace(contextRegex, "#{context}.\$1")
      .replace(/###/g, ()-> texts.shift())

  _getPropertiesFromString: (string)->
    string = string.replace /\'[^\']+\'/g, (text)-> "###"
    result = []

    if (matches = string.match /scope\.([a-zA-Z$_][^\ \(\)\{\}\;]*)/g) instanceof Array
      for item in matches
        if result.indexOf(property = item.replace('scope.','')) is -1
          result.push property.split('.')[0]

    result

  addHiddenProperty: (key, value)->
    Object.defineProperty @, key,
      value: value
      enumerable: false
      configurable: false
      writable: true

  addOwnProperty: (key, value)->
    Object.defineProperty @, key,
      value: value
      enumerable: true
      configurable: false
      writable: true

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
          get: -> 
            try
              eval string
            catch e
              undefined
          set: (val)-> 
            model = string.split('.')
            property = model.pop()
            try
              model = eval model.join('.')
              model[property] = val
            catch e
              undefined
      else
        if checkString.match /\:/
          string = "(" + string + ")"

        Object.defineProperty @, name, 
          get: -> 
            try
              eval string
            catch e
              undefined

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
          @on "refresh:#{property}", callback
        else
          scope = @
          while scope = scope.parent
            if scope._resolvers[property]
              for resolver in scope._resolvers[property] 
                @listenTo resolver.scope, "refresh:#{resolver.property}", callback
              break
          unless scope
            @listenTo @._root(), "refresh:#{property}", callback
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
    @_childs = []

  release: ->
    @releaseChilds()

    @stopListening()
    @unbind()