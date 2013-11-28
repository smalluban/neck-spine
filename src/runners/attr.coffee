Neck.Controller.runners['attr'] = class AttrRunner extends Neck.Controller
  
  constructor: ->
    super

    @scope.addProperty 'attr', @runAttr
    throw "'attr' attribute has to be object" unless typeof @scope.attr is 'object'

    @scope.watch 'attr', =>
      for key, value of @scope.attr
        if returnedValue = value
          @el.attr key, if returnedValue is true then key else returnedValue
        else
          @el.removeAttr key
      undefined

