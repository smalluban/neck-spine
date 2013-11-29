describe 'Scope', ->

  scope = null
  context = {}

  beforeEach ->
    scope = new Neck.Scope context

  it 'throw error when no context given', ->
    assert.throws -> new Neck.Scope()

  it 'not throw error when context given', ->
    assert.doesNotThrow -> new Neck.Scope {}

  it 'have own properties', ->
    assert.ok scope.hasOwnProperty "_resolvers"
    assert.ok scope.hasOwnProperty "_childs"
    assert.ok scope.hasOwnProperty "_callbacks"
    assert.ok scope.hasOwnProperty "listeningTo"
    assert.ok scope.hasOwnProperty "listeningToOnce"
  
  it 'create child scope', ->
    child = scope.child()
    assert.equal child.parent, scope
    assert.include scope._childs, child

    assert.ok child.hasOwnProperty "_resolvers"
    assert.ok child.hasOwnProperty "_childs"
    assert.ok child.hasOwnProperty "_callbacks"
    assert.ok child.hasOwnProperty "listeningTo"
    assert.ok child.hasOwnProperty "listeningToOnce"

  it 'release self and children', ->
    scope.release()
    assert.isUndefined scope._childs
    assert.equal scope.listeningToOnce, undefined
    assert.equal scope.listeningTo, undefined
    assert.deepEqual scope._callbacks, {}

  describe 'Properties', ->

    it 'parse string for eval', ->
      testCases =
        "true": "true"
        "false": "false"
        "test" : "scope.test"
        "123": "123"
        "123.23": "123.23"
        "test1 + 123.23": "scope.test1 + 123.23"
        "test + test": "scope.test + scope.test"
        "test1 + 'test2 + test3'": "scope.test1 + 'test2 + test3'"
        "@test": "context.test"
        "test + @test": "scope.test + context.test"
        "testFunc(one + 'asdf / dsa' + @two)": "scope.testFunc(scope.one + 'asdf / dsa' + context.two)"
        "asd(dsa())": "scope.asd(scope.dsa())"
        "typeof asd !== 'dsa'": "typeof scope.asd !== 'dsa'"

      for key, value of testCases
        assert.equal scope._stringForEval(key), value

    it 'get unique properties array from eval string', ->
      testCases =
        "scope.asd": ['asd']
        "scope.asd.dsa": ['asd']
        "scope.asd + scope.dsa": ['asd', 'dsa']
        "scope.asd(scope.dsa())": ['asd', 'dsa']
        "scope.asd + scope.asd": ['asd']
        "scope.testFunc(scope.one + 'asdf / dsa' + context.two)": ['testFunc', 'one']

      for key, value of testCases
        assert.deepEqual scope._getPropertiesFromString(key), value

    it 'create hidden propery', ->
      scope.addHiddenProperty 'example', '123'
      assert.ok scope.hasOwnProperty 'example'
      assert.equal scope.example, '123'

      for own key of scope
        assert.notOk key == 'example', "Hidden property not be enumerable"

    it 'create own string property', ->
      scope.addProperty 'test', "'test'"
      assert.typeOf scope.test, 'string'
      assert.equal scope.test, "test"

    it 'create own number property', ->
      testCases =
        '123': 123
        '123.23': 123.23
      for key, value of testCases
        scope.addProperty 'test', key
        assert.typeOf scope.test, 'number'

    it 'create own eval (getter/setter) property', ->
      parentScope = new Neck.Scope({})
      for key, value of {
        testString1: 'asd'
        testString2: 'dsa'
        testNumber1: 10
        deepTest:
          testText: 'test text'
        method: ->
      }
        parentScope[key] = value

      scope.parent = parentScope

      # Property has value of parents
      scope.addProperty 'test1', "testString1"
      assert.equal scope.test1, 'asd'

      # After parent change still has right value
      parentScope.testString1 = 'dsa'
      assert.equal scope.test1, 'dsa'

      # Property which is not expression has SET ability
      scope.test1 = 'new value'
      assert.equal parentScope.testString1, 'new value'

      # Now create expression property - mixed parent properties
      scope.addProperty 'test2', "testString1 + ' ' + testString2 + ' ' + testNumber1"
      assert.equal scope.test2, "new value dsa 10"

      # We can't set this value, so it still has value of expression
      scope['test2'] = 'asd'
      assert.equal scope.test2, "new value dsa 10"

      # Deep property
      scope.addProperty 'test3', 'deepTest.testText'
      assert.equal scope.test3, 'test text'

      # Method property
      scope.addProperty 'test4', 'method() + testNumer1'

      # Scope create proper resolvers
      assert.deepEqual scope._resolvers['test1'][0], scope: parentScope, property: 'testString1'

      assert.deepEqual scope._resolvers['test2'][0], scope: parentScope, property: 'testString1'
      assert.deepEqual scope._resolvers['test2'][1], scope: parentScope, property: 'testString2'
      assert.deepEqual scope._resolvers['test2'][2], scope: parentScope, property: 'testNumber1'
      
      assert.deepEqual scope._resolvers['test3'][0], { scope: parentScope, property: 'deepTest' }

      # Method resolved to '?' becouse we don't know what property could change
      assert.deepEqual scope._resolvers['test4'][0], { scope: parentScope, property: '?' }
      assert.equal scope._resolvers['test4'].length, 1

    it 'return root scope', ->
      child1 = scope.child()
      child2 = child1.child()
      child3 = child2.child()

      assert.equal child3._root(), scope
      assert.equal scope._root(), scope

  describe 'Wachers', ->

    it 'watch parent property', ->
      callback = sinon.spy()
      scope.parent = parent = new Scope({})
      parent.test = 'asd'

      scope.addProperty 'myProperty', 'test'

      scope.watch 'myProperty', callback
      assert.ok callback.calledOnce 

      parent.apply 'test'
      assert.ok callback.calledTwice 

    it 'watch own property', ->
      callback = sinon.spy()

      scope['test'] = 'test'
      scope.watch 'test', callback
      assert.ok callback.calledOnce

      scope.apply 'test'
      assert.ok callback.calledTwice

    it 'apply changes to own scope', ->
      callback = sinon.spy()

      scope.on 'refresh:test', callback
      scope.apply 'test'

      assert.ok callback.calledOnce

    it 'apply changes to root scope', ->
      callback = sinon.spy()
      child = scope.child()
      scope.on 'refresh:?', callback
      child.apply()

      assert.ok callback.calledOnce

    it 'apply changes to reslovded scope', ->
      callback = sinon.spy()
      scope.test1 = 'test'
      scope.test2 = 'test'
      child = scope.child()
      child.addProperty 'childTest', 'test1 + test2'

      scope.on 'refresh:test1', callback
      scope.on 'refresh:test2', callback
      child.apply 'childTest'

      assert.ok callback.calledTwice





