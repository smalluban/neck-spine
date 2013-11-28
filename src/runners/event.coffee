### LIST OF EVENTS TO TRIGGER ###

EventList = [
  # Mouse events
  "click", "dblclick"
  "mouseenter", "mouseleave", "mouseout"
  "mouseover", "mousedown", "mouseup"
  "drag", "dragstart", "dragenter", "dragleave", "dragover", "dragend", "drop"
  # General
  "load"
  "focus", "focusin", "focusout", "select", "blur"
  "submit"
  "scroll"
  # Touch events
  "touchstart", "touchend", "touchmove", "touchenter", "touchleave", "touchcancel"
  # Keys events
  "keyup", "keydown", "keypress"
]

class EventRunner extends Neck.Controller

  constructor: ->
    super

    @scope.addProperty 'method', @runAttr
    if typeof(@scope.method) is 'function'
      @scope.method.call @scope.context, @parentScope, @e
    else
      @scope.apply 'method'

    @scope.release()

class Event

  constructor: (options)->
    options.el.on @eventType, (e)=>
      e.preventDefault()
      options.e = e
      new EventRunner options

### INIT ALL EVENTS ###

for ev in EventList
  eventRunner = class ER extends Event
  eventRunner::eventType = ev
  Neck.Controller.runners["event-#{ev}"] = eventRunner
