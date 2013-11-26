Neck.Controller.runners['repeat'] = class RepeatRunner extends Neck.Controller

  scope:
    filter: '='
    view: '@'
    
  constructor: ->
    super

    unless @scope.view
      @scope.template = @el.html()
      
    # Clear runner body
    @el.empty()

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

    @checkFilter()

  view: ->
    if @scope.view
      @el = $(require("#{Neck.Controller.viewsPath}/#{@scope.view}")(@scope))
    else
      @el = $(@scope.template)

  checkFilter: ->
    if !@scope.filter and !@visible
      @el.show()
      @visible = true
    else
      if @item.toString().match new RegExp(@scope.filter, 'gi')
        unless @visible
          @el.show()
          @visible = true
      else
        if @visible
          @el.hide()
          @visible = false

