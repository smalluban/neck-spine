Neck.Controller.runners['helper'] = class HelperRunner

  constructor: (options)->
    new (require("#{Neck.Globals.helpersPath}/" + options.runAttr))(
      context: options.context
      el: options.el
      parentScope: options.parentScope
    )