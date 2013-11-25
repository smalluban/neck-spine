Neck.Controller.runners['repeat'] = class RepeatRunner extends Neck.Controller

  scope:
    items: '='
    filter: '='
    view: '@'
    
  constructor: ->
    super

    unless @scope.view
      @scope.view = html: @el.html()
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
            rootScope: @scope
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

  view: -> 
    if typeof @scope.view is 'object'
      @scope.view.html
    else
      @el = $(require("#{Neck.Controller.viewsPath}/#{@scope.view}")(@scope))

  visible: true
  text: null

  constructor: ->
    super
  
    @scope[@itemName] = @item
    @render()

    # Text is used for comparing filter
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

