Neck.Controller.runners['element'] = class ElementRunner
  
  constructor: (options)->
    options.parentScope["#{options.runAttr}"] = options.el
