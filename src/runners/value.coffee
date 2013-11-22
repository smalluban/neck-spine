Neck.Controller.runners['value'] = class ValueRunner extends Neck.Controller

  constructor: ->
    super

    @scope.addProperty 'value', @runAttr 

    @scope.watch 'value', =>
      @el.html @scope.value or ''

