describe 'Screen', ->

  describe 'when screen is constructed', ->

    it 'throw error when no path given', ->
      assert.throw -> new Neck.Screen()

    it 'define view as path when no view given', ->
      screen = new Neck.Screen path: 'example'
      assert.ok screen.view is screen.path

    it 'not change view when is given', ->
      screen = new Neck.Screen path: 'example', view: 'newView'
      assert.ok screen.view isnt screen.path

    it 'add path releated classes to DOM element', ->
      screen = new Neck.Screen path: "example/path"
      assert.ok screen.el.hasClass 'example'
      assert.ok screen.el.hasClass 'path'

  describe 'private methods', ->
    screen = null
    beforeEach -> screen = new Neck.Screen path: 'example'
    afterEach -> screen.release()

    it 'check if element is already in DOM', ->
      assert.notOk screen._inDOM()
      $('body').append screen.el
      assert.ok screen._inDOM()

  describe 'render', ->

    screen = null

    beforeEach ->
      screen = new Neck.Screen 
        path: 'example'
        template: '<div><h1>Text</h1><div ui-yield="ui-yield"></div></div>'
        parent: $('body')

    it 'not replace element', ->
      screenEl = screen.el
      screen.render()
      assert.equal screen.el, screenEl

    it 'set yield from view', ->
      screen.render()
      assert.isObject screen.yield

      screen.template = "<div></div>"
      screen.render()
      assert.isUndefined screen.yield

    it 'append view/template to screen element', ->
      screen.render()
      assert.equal screen.el.html(), screen.template

  describe 'append', ->

    it 'render element to yield', ->
      screen = new Neck.Screen 
        path: 'example'
        template: '<div ui-yield></div>'

      screen.render()
      screen.append el = $('<p>asd</p>')
      assert.ok screen.yield.innerHTML, el.html()

    it 'render controller to yield', ->
      screen = new Neck.Screen 
        path: 'example'
        template: '<div ui-yield></div>'

      newScreen = new Neck.Screen path: 'asd', template: '<p>asd</p>'
      screen.render()
      screen.append newScreen
      assert.ok screen.yield.innerHTML, newScreen.template

    it 'call parent append method when no yield', ->
      spy = sinon.spy()
      screen = new Neck.Screen
        path: 'example'
        template: '<div></div>'
        

      screen.render()
      screen.parent = append: spy
      screen.append '<p>asd</p>'
      assert.ok spy.calledOnce






