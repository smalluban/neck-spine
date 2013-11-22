Neck.Controller.runners['element'] = class ElementRunner
  
  constructor: (options)->
    options.rootScope["#{options.runAttr}"] = options.el
