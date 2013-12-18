Neck.Controller.runners['repeat'] = class RepeatRunner extends Neck.Controller

  innerTemplate: true

  scope:
    filter: '='
    view: '@'
    
  constructor: ->
    super

    # run attribute should pass regexp "'item_name in items_name"
    unless @runAttr.match /^[a-zA-Z$_][^\ \(\)\{\}]*\ in\ [a-zA-Z$_][^\ \(\)\{\}]*$/
      throw 'Wrong list definition'

    # Get item and items
    @runAttr = @runAttr.split(' in ')

    # Set items property
    @scope.addProperty 'items', @runAttr[1]

    @scope.watch 'items', =>
      if @scope.items
        if @controllers
          controller.release() for controller in @controllers

        @controllers = for item in @scope.items
          # Create item controller
          itemController = new RepeatItem 
            context: @context
            parentScope: @scope
            item: item
            itemName: @runAttr[0]
            template: @template
            view: @scope.view

          @append itemController
          itemController
        undefined

    if @scope.hasOwnProperty 'filter'
      timeout = null
      @scope.watch 'filter', =>
        clearTimeout timeout
        timeout = setTimeout =>
          if @controllers
            @checkFilter(controller) for controller in @controllers
          undefined
        , 10

  checkFilter: (c)->
    if @scope.filter isnt undefined
      if typeof @scope.filter is 'function'
        match = @scope.filter(c.item)
      else
        match = c.item.toString()?.match new RegExp(@scope.filter, 'gi')
      if match then c.el.show() else c.el.hide()
    else
      c.el.show()

class RepeatItem extends Neck.Controller

  visible: true

  constructor: ->
    super
  
    @scope[@itemName] = @item
    @render()

    # Listen to update event on spine models
    if @item instanceof Spine.Model
      @listenTo @item, 'update', @render
      @listenTo @item, 'destroy', => @release()