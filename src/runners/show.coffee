Neck.Controller.runners['show'] = class ShowRunner extends Neck.Controller

  constructor: ->
    super

    @scope.addProperty 'show', @runAttr 

    @scope.watch 'show', =>
      if @scope.show
        @el.show()
      else
        @el.hide()

