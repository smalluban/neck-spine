describe 'Controller', ->
    
  el = $(
    '''
      <div data-test="'test text'", data-number="2", data-property="test"/>
    '''
  )

  describe 'constructor', ->
    
    it 'not create scope when scope is false', ->
      c = new Neck.Controller
        scope: false

      assert.isUndefined c.scope

    it 'create child scope when inhertScope is true', ->
      parentScope = new Neck.Scope {}
      c = new Neck.Controller
        scope: true
        parentScope: parentScope

      assert.equal c.scope.parent, parentScope

    it 'not create child scope when inhertScope is false', ->
      parentScope = new Neck.Scope {}
      c = new Neck.Controller
        scope: true
        inheritScope: false
        parentScope: parentScope

      assert.notEqual c.scope.parent, parentScope

    it 'take dataset of DOM element and inject it to scope', ->
      c = new Neck.Controller
        el: el
        scope:
          test: "="
          number: "="
          property: "@"

      assert.equal c.scope.test, 'test text'
      assert.isString c.scope.test

      assert.equal c.scope.number, 2
      assert.isNumber c.scope.number

      assert.equal c.scope.property, 'test'
      assert.isString c.scope.property

      c2 = new Neck.Controller
        el: el
        parentScope: new Neck.Scope {}
        scope: 
          property: '='

      assert.ok c2.scope.hasOwnProperty 'property'
      assert.isUndefined c2.scope.property

    it 'move scope properties when not in dataset', ->
      c = new Neck.Controller
        el: el
        parentScope: new Neck.Scope {}
        scope:
          asdf: '='
          test: 'This is test text'
          myProperty: 'this is moved to scope'

      assert.isUndefined c.scope.asdf
      assert.equal c.scope.test, 'This is test text'
      assert.equal c.scope.myProperty, 'this is moved to scope'

    it 'take all dataset values are evaluated when scope is "="', ->
      c = new Neck.Controller 
        el: el
        parentScope: new Neck.Scope {}
        scope: '='

      assert.equal c.scope.test, 'test text'
      assert.equal c.scope.number, 2
      assert.isUndefined c.scope.property

    it 'take all dataset values are copied when scope is "@"', ->
      c = new Neck.Controller 
        el: el
        parentScope: new Neck.Scope {}
        scope: '@'

      assert.equal c.scope.test, "'test text'"
      assert.equal c.scope.number, '2'
      assert.equal c.scope.property, 'test'

  describe 'append', ->

    it 'append to self(el) when no yield element', ->
      c = new Neck.Controller
        el: $('<div></div>')
        scope: false

      c.append $('<p></p>')

      assert.lengthOf c.el.children('p'), 1

    it 'append to yield element when it is in el', ->
      c = new Neck.Controller
        el: $('<div><div ui-yield></div></div>')
        scope: false

      c.append $('<p></p>')
      assert.lengthOf c.el.find('[ui-yield]').children('p'), 1

  describe 'parse', ->

    it 'initialize runners for elements', ->
      c = new Neck.Controller
        el: $('<div><div ui-test ui-test2></div>')
        scope: false

      runner = Neck.Runner['test'] = sinon.spy()
      blackRunner = Neck.Runner['test2'] = sinon.spy()

      c.parse()
      assert.ok runner.calledOnce
      assert.ok blackRunner.calledOnce
      assert.ok blackRunner.calledAfter runner

  describe 'render', ->

    it 'release scope childs', ->
      c = new Neck.Controller
        el: $('<div></div>')
        scope: true
        template: '<div id="test"></div>'

      release = c.scope.releaseChilds = sinon.spy()
      c.render()

      assert.ok release.calledOnce


    it 'render by require view path', ->
      viewCallback = -> '<div id="test"></div>'
      window.require = sinon.stub().returns viewCallback

      c = new Neck.Controller
        el: $('<div></div>')
        scope: false
        view: 'exampleView'

      c.render()
      assert.ok c.el[0].outerHTML is '<div id="test"></div>'

      window.require = undefined

    it 'render by template string property', ->
      c = new Neck.Controller
        el: $('<div></div>')
        scope: false
        template: '<div id="test"></div>'

      c.render()
      assert.ok c.el[0].outerHTML is '<div id="test"></div>'

    it 'render by template function property', ->
      template = ->
        '<div id="test"></div>'

      c = new Neck.Controller
        el: $('<div></div>')
        scope: false
        template: template

      c.render()
      assert.ok c.el[0].outerHTML is '<div id="test"></div>'

    it 'render template over view when both are given', ->
      viewCallback = -> '<div id="test"></div>'
      window.require = sinon.stub().returns viewCallback

      c = new Neck.Controller
        el: $('<div></div>')
        scope: false
        view: 'exampleView'
        template: '<div id="test"></div>'

      c.render()
      assert.ok c.el[0].outerHTML is '<div id="test"></div>'

  describe 'release', ->

    it 'release scope', ->
      c = new Neck.Controller
        scope: true
        inhertScope: false

      spy = c.scope.release = sinon.spy()
      c.release()

      assert.ok spy.calledOnce
      assert.isUndefined c.scope




