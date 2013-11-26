Neck.Controller.runners['bind'] = class BindRunner extends Neck.Controller

  events: 
    "keydown": "update"
    "change": "update"
    "search": "update"

  constructor: ->
    super

    @scope.addProperty 'bind', @runAttr

    # Set default value
    @el.val(@scope.bind or '') if @scope.bind

    @scope.watch 'bind', =>
      unless @_updatedFlag
        @el.val(@scope.bind or '') 

  calculateValue: (value)->
    if value.match /^[0-9]+((\.|\,)?[0-9]+)*$/
      Number value
    else
      value

  update: ->
    # Timeout is need for 'keydown' event
    # When timeout is not present value is always 
    # one character behind
    setTimeout =>
      @scope.bind = @calculateValue(@el.val()) or undefined
      @_updatedFlag = true
      @scope.apply 'bind'
      @_updatedFlag = false