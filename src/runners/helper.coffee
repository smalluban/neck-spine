Neck.Runner['helper'] = class HelperRunner

  constructor: (options)->
    helper = new (require("#{Neck.Config.paths.helper}/" + options.runAttr))(
      context: options.context
      el: options.el
      parentScope: options.parentScope
    )

    if helper.view or helper.template
      helper.render()
      options.el.html helper.el