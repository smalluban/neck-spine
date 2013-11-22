Neck.Controller.runners['hide'] = class HideRunner extends Neck.Controller

  constructor: ->
    super

    @scope.addProperty 'hide', @runAttr

    @scope.watch 'hide', =>
      if @scope.hide
        @el.hide()
      else
        @el.show()

