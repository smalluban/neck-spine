describe 'App', ->

  describe 'constructor', ->

    it 'can work with history API', ->
      app = new Neck.App historyApi: true
      assert.ok app.historyApi

    it 'can disable history API', ->
      app = new Neck.App historyApi: false
      assert.notOk app.historyApi

    it 'set callback to route event', ->
      _oldRoute = Neck.App.prototype.pushRoute
      Neck.App.prototype.pushRoute = sinon.spy()
      app = new Neck.App hashRoute: true
      app.trigger 'route'
      assert.ok app.pushRoute.calledOnce
      Neck.App.prototype.pushRoute = _oldRoute

  describe 'on run', ->

    it 'call render', ->
      app = new Neck.App
      app.render = sinon.spy()
      app.trigger 'run'
      assert.ok app.render.calledOnce

    it 'can evaluate route', ->
      app = new Neck.App template: '', hashRoute: true
      app.evaluateRoute = sinon.spy()
      app.trigger 'run'
      assert.ok app.evaluateRoute.calledOnce

  describe 'push route', ->

    it 'can replace hash with current screen scopes', ->
      app = new Neck.App template: ''
      app.child = 
        path: 'noInTest'
        child:
          path: 'test1'
          yield: true
          params:
            test1: 'asd'
            test2: 123.321
          child:
            path: 'test2'
            params:
              test1: 'dsa'
              test2: 321.123

      app.pushRoute()
      assert.equal window.location.hash, "#!/test1[test1='asd'&test2=123.321]:test2[test1='dsa'&test2=321.123]"
      window.location.hash = ''

    it 'can replace state in history with current screen scopes', ->
      app = new Neck.App historyApi: true, template: ''
      app.child = 
        path: 'noInTest'
        child:
          path: 'test1'
          yield: true
          params:
            test1: 'asd'
            test2: 123.321
          child:
            path: 'test2'
            params:
              test1: 'dsa'
              test2: 321.123
      
      old_state = window.location.pathname
      app.pushRoute()

      assert.equal window.location.pathname, "/test1[test1='asd'&test2=123.321]:test2[test1='dsa'&test2=321.123]"
      window.history.replaceState null, '', old_state

  describe 'evalute route', ->

    it 'can get path from history Api', ->
      app = new Neck.App historyApi: true, template: ''
      oldPath = window.location.pathname
      window.history.replaceState null, '', "/test1[param1='asd'&param2=123.321]:test2[param1='dsa'&param2=321.123]"
      spy = null
      stub = sinon.stub app, 'route', -> 
        spy = sinon.spy()
        return { route: spy }

      app.evaluateRoute()
      window.history.replaceState null, '', oldPath

      assert.ok stub.calledOnce
      assert.equal stub.firstCall.args[0], 'test1'
      assert.deepEqual stub.firstCall.args[1], params: param1: 'asd', param2: 123.321

      assert.ok spy.calledOnce
      assert.equal spy.firstCall.args[0], 'test2'
      assert.deepEqual spy.firstCall.args[1], params: param1: 'dsa', param2: 321.123

    it 'can get path from hash', ->
      app = new Neck.App template: ''
      window.location.hash = "/test1[param1='asd'&param2=123.321]:test2[param1='dsa'&param2=321.123]"
      spy = null
      stub = sinon.stub app, 'route', -> 
        spy = sinon.spy()
        return { route: spy }

      app.evaluateRoute()
      window.location.hash = ''

      assert.ok stub.calledOnce
      assert.equal stub.firstCall.args[0], 'test1'
      assert.deepEqual stub.firstCall.args[1], params: param1: 'asd', param2: 123.321

      assert.ok spy.calledOnce
      assert.equal spy.firstCall.args[0], 'test2'
      assert.deepEqual spy.firstCall.args[1], params: param1: 'dsa', param2: 321.123

    describe 'on error', ->

      it 'can redirect to root', ->
        app = new Neck.App hashRoute: true, template: ''
        spy = app.activate = sinon.spy()

        window.location.hash = '/test'
        app.evaluateRoute()
        window.location.hash = ''
        assert.ok spy.calledOnce

        old_path = window.location.pathname
        app.historyApi = true
        app.evaluateRoute()
        window.history.replaceState null, '', old_path
        assert.ok spy.calledTwice

      it 'can redirect to error route', ->
        app = new Neck.App hashRoute: true, template: '', errorRoute:
          url: 'error'
          params: 
            test: 'test'

        window.location.hash = '/test'
        stub = sinon.stub app, 'route', (url)-> if url is 'test' then throw 'error'
        app.evaluateRoute()
        window.location.hash = ''

        assert.ok stub.calledTwice
        assert.equal stub.secondCall.args[0], 'error'
        assert.deepEqual stub.secondCall.args[1], errorCode: 404, test: 'test'






