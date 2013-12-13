describe 'Screen', ->

  describe 'constructor', ->

    it 'throw error when no path given', ->
      assert.throw -> new Neck.Screen()

    it 'define view as path when no view given', ->
      s = new Neck.Screen path: 'example'
      assert.ok s.view is s.path

    it 'not change view when is given', ->
      s = new Neck.Screen path: 'example', view: 'newView'
      assert.ok s.view isnt s.path

    it 'add path releated classes to DOM element', ->
      s = new Neck.Screen path: "example/path"
      assert.ok s.el.hasClass 'example'
      assert.ok s.el.hasClass 'path'

    it 'return the same instance for singleton option', ->
      Neck.Screen.prototype.singleton = true
      s1 = new Neck.Screen path: 'test'
      s2 = new Neck.Screen path: 'test'
      assert.equal s1, s2
      Neck.Screen.prototype.singleton = false

  describe 'render', ->

    s = null

    beforeEach ->
      s = new Neck.Screen 
        path: 'example'
        template: '<div><h1>Text</h1><div ui-yield="ui-yield"></div></div>'
        parent: $('body')

    it 'not replace element', ->
      sEl = s.el
      s.render()
      assert.equal s.el, sEl

    it 'set yield from view', ->
      s.render()
      assert.isObject s.yield

      s.template = "<div></div>"
      s.render()
      assert.isUndefined s.yield

    it 'append view/template to screen element', ->
      s.render()
      assert.equal s.el.html(), s.template

    describe 'private', ->

      it '_inDOM: check if element is already in DOM', ->
        s = new Neck.Screen path: 'example'
        assert.notOk s._inDOM()
        $('body').append s.el
        assert.ok s._inDOM()

  describe 'append', ->

    it 'render element to yield', ->
      s = new Neck.Screen 
        path: 'example'
        template: '<div ui-yield></div>'

      s.render()
      s.append el = $('<p>asd</p>')
      assert.ok s.yield.innerHTML, el.html()

    it 'render controller to yield', ->
      s = new Neck.Screen 
        path: 'example'
        template: '<div ui-yield></div>'

      newScreen = new Neck.Screen path: 'asd', template: '<p>asd</p>'
      s.render()
      s.append newScreen
      assert.ok s.yield.innerHTML, newScreen.template

    it 'call parent append method when no yield', ->
      spy = sinon.spy()
      s = new Neck.Screen
        path: 'example'
        template: '<div></div>'

      s.render()
      s.parent = append: spy
      s.append '<p>asd</p>'
      assert.ok spy.calledOnce

  describe 'activate', ->

    parent = s = child = null

    beforeEach ->
      el = $('<div>').appendTo $('body')
      parent = new Neck.Screen path: 'root', template: '<div ui-yield></div>', el: el
      parent.zIndex = 1
      parent.render()

      s = new Neck.Screen path: 'example', template: '<div></div>', parent: parent
      s.activate()

      child = new Neck.Screen path: 'child', template: '<div></div>', parent: s

    afterEach ->
      parent.release()

    it 'remove references with children and release them', ->
      child.activate()
      s.activate()

      assert.isNull child.el[0].parentNode
      assert.isUndefined child.parent
      assert.isUndefined s.child

    it 'adds "active" class to DOM element', ->
      assert.ok s.el.hasClass 'active'

    it 'adds z-index with one up than parent', ->
      assert.equal s.zIndex, parent.zIndex + 1

    it 'trigger "activate" event on screen', ->
      callback = sinon.spy()
      s.on "activate", callback
      s.activate()
      assert.ok callback.calledOnce

    it 'deactivate parent when is normal screen', ->
      assert.notOk parent.el.hasClass 'active'

    it 'not deactivate parent when screen is popup', ->
      child.popup = true
      child.activate()
      assert.ok s.el.hasClass 'active'

    it 'set parent child to activated screen', ->
      assert.ok parent.child is s
      child.activate()
      assert.ok s.child is child

    it 'render screen', ->
      assert.ok parent.yield.innerHTML, s.template

  describe 'deactivate', ->

    s = null

    beforeEach ->
      s = new Neck.Screen path: 'root', template: '<div></div>'
      s.activate()

    afterEach ->
      s.release()

    it 'remove "active" class', ->
      s.deactivate()
      assert.notOk s.el.hasClass 'active'

    it 'trigger "deactivate" event on screen', ->
      callback = sinon.spy()
      s.on "deactivate", callback
      s.deactivate()
      assert.ok callback.calledOnce

  describe 'route', ->

    s = null

    beforeEach ->
      s = new Neck.Screen path: 'root', template: '<div></div>'
      class TestScreen extends Neck.Screen
        path: 'test'
        template: ''
      window.require = -> TestScreen

    afterEach ->
      window.require = undefined

    it 'activate controller already in screen scope', ->
      s.child = child = new Neck.Screen path: 'test1', template: '<div class="test"></div>', parent: s
      child.child = nextChild = new Neck.Screen path: 'test2', template: '<div class="test"></div>', parent: child
      
      # going up
      callback = sinon.spy()
      nextChild.on 'activate', callback
      s.route 'test2'
      assert.ok callback.calledOnce

      # going down
      callback = sinon.spy()
      child.on 'activate', callback
      nextChild.route 'test1'
      assert.ok callback.calledOnce

    describe 'new controller', ->
      
      it 'release child instance when option "reloadSelf" is on', ->
        child = s.child = new Neck.Screen path: 'test', template: '', reloadSelf: true
        child.release = sinon.spy()

        s.route 'test'
        assert.ok child.release.calledOnce

        # And of
        child = s.child = new Neck.Screen path: 'test', template: ''
        child.release = sinon.spy()

        s.route 'test'
        assert.notOk child.release.calledOnce

      it 'create new controller and puts it to child', ->
        assert.isUndefined s.child
        s.route 'test'
        assert.instanceOf s.child, window.require()

      it 'connect parent property to child', ->
        s.route 'test'
        assert.equal s.child.parent, s

      it 'puts new controller on leaf of screen scope', ->
        s.child = child = new Neck.Screen path: 'test', template: '', parent: s
        child.child = nextChild = new Neck.Screen path: 'test2', template: '', parent: s

        class Popup extends Neck.Screen
          path: 'popup'
          template: ''
          popup: true

        window.require = -> Popup

        s.route 'popup'
        assert.equal s.child, child
        assert.equal child.child, nextChild
        assert.instanceOf nextChild.child, Popup

      it 'go up in scope when back is set true and replace self', ->
        s.child = child = new Neck.Screen path: 'test1', template: '', parent: s
        child.release = sinon.spy()
        child.route 'test2', {}, true

        assert.notEqual s.child, child
        assert.ok child.release.calledOnce
        assert.instanceOf s.child, window.require()

      it 'trigger "route" event on root and self', ->
        callback1 = sinon.spy()
        callback2 = sinon.spy()

        s.child = child = new Neck.Screen path: 'test1', template: '', parent: s
        s.on 'route', callback1
        child.on 'route', callback2
        child.route 'test2'

        assert.ok callback1.calledOnce
        assert.ok callback2.calledOnce
        assert.ok callback1.calledWith child.child
        assert.ok callback2.calledWith child.child

    describe 'private', ->
      it '_leaf: return last child in screen scopes', ->
        s.child = child = new Neck.Screen path: 'test1', template: '', parent: s
        child.child = nextChild = new Neck.Screen path: 'test2', template: '', parent: child

        assert.equal nextChild, s._leaf()

      it '_root: return root in screen scopes', ->
        s.child = child = new Neck.Screen path: 'test1', template: '', parent: s
        child.child = nextChild = new Neck.Screen path: 'test2', template: '', parent: child

        assert.equal s, s._root()

      it '_childWithPath: check if any child has given path', ->
        s.child = child = new Neck.Screen path: 'test1', template: '', parent: s
        child.child = nextChild = new Neck.Screen path: 'test2', template: '', parent: child

        assert.ok s._childWithPath 'test1'
        assert.ok s._childWithPath 'test2'
        assert.notOk s._childWithPath 'test3'

  describe 'release', ->

    s = null

    beforeEach ->
      s = new Neck.Screen path: 'test', template: ''

    it 'release childs', ->
      s.child = child = new Neck.Screen path: 'test2'
      child.release = sinon.spy()
      s.release()
      assert.ok child.release.calledOnce

    it 'clear parent connection', ->
      s.parent = {}
      s.release()
      assert.isUndefined s.parent

    it 'only deactivate and reset zIndex on singleton', ->
      $('body').append s.el
      
      s.singleton = true
      s.activate()
      s.release()

      assert.isUndefined s.zIndex
      assert.equal s.el.css('zIndex'), 'auto'
      assert.ok s.el[0].parentNode?
