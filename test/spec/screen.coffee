describe 'Screen', ->

  describe 'constructor', ->

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

  describe 'activate', ->

    parent = screen = child = null

    beforeEach ->
      el = $('<div>').appendTo $('body')
      parent = new Neck.Screen path: 'root', template: '<div ui-yield></div>', el: el
      parent.render()

      screen = new Neck.Screen path: 'example', template: '<div></div>', parent: parent
      screen.activate()

      child = new Neck.Screen path: 'child', template: '<div></div>', parent: screen

    afterEach ->
      parent.release()

    it 'remove references with children and release them', ->
      child.activate()
      screen.activate()

      assert.isNull child.el[0].parentNode
      assert.isUndefined child.parent
      assert.isUndefined screen.child

    it 'adds "active" class to DOM element', ->
      assert.ok screen.el.hasClass 'active'

    it 'adds z-index with one up than parent', ->

    it 'deactivate parent when is normal screen', ->
      assert.notOk parent.el.hasClass 'active'

    it 'not deactivate parent when screen is popup', ->
      child.popup = true
      child.activate()
      assert.ok screen.el.hasClass 'active'

    it 'set parent child to activated screen', ->
      assert.ok parent.child is screen
      child.activate()
      assert.ok screen.child is child

    it 'render screen', ->
      assert.ok parent.yield.innerHTML, screen.template

