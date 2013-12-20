Neck.Runner['class'] = class ClassRunner extends Neck.Controller
  
  constructor: ->
    super

    @scope.addProperty 'class', @runAttr
    throw "Class attribute has to be object" unless typeof @scope.class is 'object'

    @scope.watch 'class', =>
      for key, value of @scope.class
        if value
          @el.addClass key
        else
          @el.removeClass key
      undefined

