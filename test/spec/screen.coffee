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

    it 'return the same instance for singleton option', ->
      Neck.Screen.prototype.singleton = true
      screen1 = new Neck.Screen path: 'test'
      screen2 = new Neck.Screen path: 'test'
      assert.equal screen1, screen2
      Neck.Screen.prototype.singleton = false

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

    describe 'private', ->

      it '_inDOM: check if element is already in DOM', ->
        screen = new Neck.Screen path: 'example'
        assert.notOk screen._inDOM()
        $('body').append screen.el
        assert.ok screen._inDOM()

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
      parent.zIndex = 1
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
      assert.equal screen.zIndex, parent.zIndex + 1

    it 'trigger "activate" event on screen', ->
      callback = sinon.spy()
      screen.on "activate", callback
      screen.activate()
      assert.ok callback.calledOnce

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

  describe 'deactivate', ->

    screen = null

    beforeEach ->
      screen = new Neck.Screen path: 'root', template: '<div></div>'
      screen.activate()

    afterEach ->
      screen.release()

    it 'remove "active" class', ->
      screen.deactivate()
      assert.notOk screen.el.hasClass 'active'

    it 'trigger "deactivate" event on screen', ->
      callback = sinon.spy()
      screen.on "deactivate", callback
      screen.deactivate()
      assert.ok callback.calledOnce

  describe 'route', ->

    screen = null

    beforeEach ->
      screen = new Neck.Screen path: 'root', template: '<div></div>'
      class TestScreen extends Neck.Screen
        path: 'test'
        template: ''
      window.require = -> TestScreen

    afterEach ->
      screen.release()
      window.require = undefined

    it 'activate controller already in screen scope', ->
      screen.child = child = new Neck.Screen path: 'test1', template: '<div class="test"></div>', parent: screen
      child.child = nextChild = new Neck.Screen path: 'test2', template: '<div class="test"></div>', parent: child
      
      # going up
      callback = sinon.spy()
      nextChild.on 'activate', callback
      screen.route 'test2'
      assert.ok callback.calledOnce

      # going down
      callback = sinon.spy()
      child.on 'activate', callback
      nextChild.route 'test1'
      assert.ok callback.calledOnce

    describe 'new controller', ->
      
      it 'release child instance when option "reloadSelf" is on', ->
        child = screen.child = new Neck.Screen path: 'test', template: '', reloadSelf: true
        child.release = sinon.spy()

        screen.route 'test'
        assert.ok child.release.calledOnce

        # And of
        child = screen.child = new Neck.Screen path: 'test', template: ''
        child.release = sinon.spy()

        screen.route 'test'
        assert.notOk child.release.calledOnce

      it 'create new controller and puts it to child', ->
        assert.isUndefined screen.child
        screen.route 'test'
        assert.instanceOf screen.child, window.require()

      it 'connect parent property to child', ->
        screen.route 'test'
        assert.equal screen.child.parent, screen

      it 'puts new controller on leaf of screen scope', ->
        screen.child = child = new Neck.Screen path: 'test', template: '', parent: screen
        child.child = nextChild = new Neck.Screen path: 'test2', template: '', parent: screen

        class Popup extends Neck.Screen
          path: 'popup'
          template: ''
          popup: true

        window.require = -> Popup

        screen.route 'popup'
        assert.equal screen.child, child
        assert.equal child.child, nextChild
        assert.instanceOf nextChild.child, Popup

      it 'go up in scope when back is set true and replace self', ->
        screen.child = child = new Neck.Screen path: 'test1', template: '', parent: screen
        child.release = sinon.spy()
        child.route 'test2', {}, true

        assert.notEqual screen.child, child
        assert.ok child.release.calledOnce
        assert.instanceOf screen.child, window.require()

      it 'trigger "route" event on root and self', ->
        callback1 = sinon.spy()
        callback2 = sinon.spy()

        screen.child = child = new Neck.Screen path: 'test1', template: '', parent: screen
        screen.on 'route', callback1
        child.on 'route', callback2
        child.route 'test2'

        assert.ok callback1.calledOnce
        assert.ok callback2.calledOnce
        assert.ok callback1.calledWith child.child
        assert.ok callback2.calledWith child.child

    describe 'private', ->
      it '_leaf: return last child in screen scopes', ->
        screen.child = child = new Neck.Screen path: 'test1', template: '', parent: screen
        child.child = nextChild = new Neck.Screen path: 'test2', template: '', parent: child

        assert.equal nextChild, screen._leaf()

      it '_root: return root in screen scopes', ->
        screen.child = child = new Neck.Screen path: 'test1', template: '', parent: screen
        child.child = nextChild = new Neck.Screen path: 'test2', template: '', parent: child

        assert.equal screen, screen._root()

      it '_childWithPath: check if any child has given path', ->
        screen.child = child = new Neck.Screen path: 'test1', template: '', parent: screen
        child.child = nextChild = new Neck.Screen path: 'test2', template: '', parent: child

        assert.ok screen._childWithPath 'test1'
        assert.ok screen._childWithPath 'test2'
        assert.notOk screen._childWithPath 'test3'

  describe 'release', ->

    screen = new Neck.Screen path: 'test'

    it 'release childs', ->
      screen.child = child = new Neck.Screen path: 'test2'
      child.release = sinon.spy()
      screen.release()
      assert.ok child.release.calledOnce

    it 'clear parent connection', ->
      screen.parent = {}
      screen.release()
      assert.isUndefined screen.parent

    it 'deactivate and reset zIndex on singleton screen', ->
      screen.singleton = true
      screen.deactivate = sinon.spy()
      screen.release()

      assert.equal screen.zIndex, 0
      assert.equal screen.el.css('zIndex'), 0
      assert.ok screen.deactivate.calledOnce
