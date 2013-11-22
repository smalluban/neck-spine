Neck.Controller.runners['list'] = class ListRunner extends Neck.Controller

  scope:
    items: '='
    filter: '='
    view: '='
    
  constructor: ->
    super

    throw 'No view defined' unless @scope.view

    @scope.watch 'items', =>
      if @scope.items
        if @controllers
          controller.release() for controller in @controllers

        @controllers = for item in @scope.items
          # Create item controller
          itemController = new ListItem context: @context, rootScope: @scope, item: item, itemName: @runAttr
          @append itemController
          itemController
        undefined

    timeout = null

    @scope.watch 'filter', =>
      clearTimeout timeout
      timeout = setTimeout =>
        if @controllers
          controller.checkFilter() for controller in @controllers
        undefined
      , 10

class ListItem extends Neck.Controller

  text: null
  view: -> @el = $(require("#{Neck.Controller.viewsPath}/#{@scope.view}")(@scope))
  visible: true

  constructor: ->
    super
  
    @scope[@itemName] = @item
    @render()
    @text = @el.text()

    # Listen to update event on spine models
    if @item instanceof Spine.Model
      @listenTo @item, 'update', @render
      @listenTo @item, 'destroy', => @release()

    @checkFilter()

  checkFilter: ->
    if !@scope.filter and !@visible
      @el.show()
      @visible = true
    else
      if @text.match(@scope.filter)
        unless @visible
          @el.show()
          @visible = true
      else
        if @visible
          @el.hide()
          @visible = false

