Neck.Controller.runners['bind'] = class BindRunner extends Neck.Controller

  events: 
    "keyup": "update"
    "change": "update"
    "search": "update"

  constructor: ->
    super

    @scope.addProperty 'bind', @runAttr

    # Set default value
    @el.val(@scope.bind) if @scope.bind

    @scope.watch 'bind', =>
      @el.val(if @scope.bind then @scope.bind else '') 

  calculateValue: (value)->
    if value.match /^[0-9]+((\.|\,)?[0-9]+)*$/
      Number value
    else
      value

  update: ->
    @scope.bind = @calculateValue(@el.val()) or undefined
    @scope.apply 'bind'