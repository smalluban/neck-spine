var App, Controller, Neck, Scope, Screen,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

window.Neck = Neck = {};

Neck.Scope = Scope = (function(_super) {
  __extends(Scope, _super);

  Scope.include(Spine.Events);

  function Scope(context) {
    var key, value, _ref;
    this.context = context;
    if (!this.context) {
      throw "Context is required";
    }
    _ref = {
      "_resolvers": {},
      "_childs": [],
      "_callbacks": {},
      "listeningTo": [],
      "listeningToOnce": []
    };
    for (key in _ref) {
      value = _ref[key];
      this.addHiddenProperty(key, value);
    }
  }

  Scope.prototype.child = function() {
    var child, key, value, _ref;
    this._childs.push(child = Object.create(this));
    _ref = {
      "parent": this,
      "_resolvers": {},
      "_childs": [],
      "_callbacks": {},
      "listeningTo": [],
      "listeningToOnce": []
    };
    for (key in _ref) {
      value = _ref[key];
      child.addHiddenProperty(key, value);
    }
    return child;
  };

  /* PROPERTIES*/


  Scope.prototype._stringForEval = function(string, scope, context) {
    var contextRegex, reservedKeywords, texts;
    if (scope == null) {
      scope = 'scope';
    }
    if (context == null) {
      context = 'context';
    }
    string = string.trim();
    texts = string.match(/\'[^\']+\'/g);
    reservedKeywords = new RegExp("(^|\\ )" + scope + "\\.(do|if|in|for|let|new|try|var|case|else|enum|eval|false|null|this|true|\nvoid|with|break|catch|class|const|super|throw|while|yield|delete|export|import|public|\n  return|static|switch|typeof|default|extends|finally|package|private|continue|debugger|\n  function|arguments|interface|protected|implements|instanceof|undefined|window)(\\ |$)", "g");
    contextRegex = new RegExp("\\@" + scope + "\\.([a-zA-Z$_][^\ ]+)", "g");
    return string.replace(/\'[^\']+\'/g, function(text) {
      return "###";
    }).replace(/([a-zA-Z$_][^\ \(\)\{\}]*)/g, "" + scope + ".\$1").replace(reservedKeywords, function(text) {
      return text.replace('scope.', '');
    }).replace(contextRegex, "" + context + ".\$1").replace(/###/g, function() {
      return texts.shift();
    });
  };

  Scope.prototype._getPropertiesFromString = function(string) {
    var item, matches, property, result, _i, _len;
    string = string.replace(/\'[^\']+\'/g, function(text) {
      return "###";
    });
    result = [];
    if ((matches = string.match(/scope\.([a-zA-Z$_][^\ \(\)\{\}\;]*)/g)) instanceof Array) {
      for (_i = 0, _len = matches.length; _i < _len; _i++) {
        item = matches[_i];
        if (result.indexOf(property = item.replace('scope.', '')) === -1) {
          result.push(property.split('.')[0]);
        }
      }
    }
    return result;
  };

  Scope.prototype.addHiddenProperty = function(key, value) {
    return Object.defineProperty(this, key, {
      value: value,
      enumerable: false,
      configurable: false,
      writable: true
    });
  };

  Scope.prototype.addOwnProperty = function(key, value) {
    return Object.defineProperty(this, key, {
      value: value,
      enumerable: true,
      configurable: false,
      writable: true
    });
  };

  Scope.prototype.addProperty = function(name, string, scope, context) {
    var checkString, parentResolver, resolve, resolver, resolvers, _i, _j, _len, _len1;
    if (scope == null) {
      scope = this.parent;
    }
    if (context == null) {
      context = this.context;
    }
    if (string.match(/^\'.+\'$/)) {
      return this[name] = string.replace(/^\'/, '').replace(/\'$/, '');
    } else if (string.match(/^[0-9]+((\.|\,)?[0-9]+)*$/)) {
      return this[name] = Number(string.replace(/\,/g, '.'));
    } else {
      string = this._stringForEval(string);
      checkString = string.replace(/\'[^\']+\'/g, function(text, index) {
        return "###";
      });
      resolvers = [];
      if (!checkString.match(/[-+=\(\)\{\}\:]+/)) {
        resolvers.push(string.split('.')[1]);
        Object.defineProperty(this, name, {
          get: function() {
            var e;
            try {
              return eval(string);
            } catch (_error) {
              e = _error;
              return void 0;
            }
          },
          set: function(val) {
            var e, model, property;
            model = string.split('.');
            property = model.pop();
            try {
              model = eval(model.join('.'));
              return model[property] = val;
            } catch (_error) {
              e = _error;
              return void 0;
            }
          }
        });
      } else {
        if (checkString.match(/\:/)) {
          string = "(" + string + ")";
        }
        Object.defineProperty(this, name, {
          get: function() {
            var e;
            try {
              return eval(string);
            } catch (_error) {
              e = _error;
              return void 0;
            }
          }
        });
        if (!checkString.match(/\(/)) {
          resolvers = this._getPropertiesFromString(checkString);
        } else {
          resolvers.push('?');
        }
      }
      this._resolvers[name] = [];
      for (_i = 0, _len = resolvers.length; _i < _len; _i++) {
        resolver = resolvers[_i];
        if (resolver === '?') {
          this._resolvers[name].push({
            scope: scope._root(),
            property: '?'
          });
        } else if (parentResolver = scope._resolvers[resolver]) {
          for (_j = 0, _len1 = parentResolver.length; _j < _len1; _j++) {
            resolve = parentResolver[_j];
            this._resolvers[name].push(resolve);
          }
        } else {
          if (scope.hasOwnProperty(resolver) || !scope.parent) {
            this._resolvers[name].push({
              scope: scope,
              property: resolver
            });
          }
        }
      }
      return void 0;
    }
  };

  Scope.prototype._root = function() {
    var _ref;
    return ((_ref = this.parent) != null ? _ref._root() : void 0) || this;
  };

  Scope.prototype.watch = function() {
    var args, callback, properties, property, resolver, scope, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    callback = args.pop();
    properties = args;
    if (properties.length) {
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        property = properties[_i];
        if (this._resolvers[property]) {
          _ref = this._resolvers[property];
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            resolver = _ref[_j];
            this.listenTo(resolver.scope, "refresh:" + resolver.property, callback);
          }
        } else if (this.hasOwnProperty(property) || !this.parent) {
          this.on("refresh:" + property, callback);
        } else {
          scope = this;
          while (scope = scope.parent) {
            if (scope._resolvers[property]) {
              _ref1 = scope._resolvers[property];
              for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
                resolver = _ref1[_k];
                this.listenTo(resolver.scope, "refresh:" + resolver.property, callback);
              }
              break;
            }
          }
          if (!scope) {
            this.listenTo(this._root(), "refresh:" + property, callback);
          }
        }
      }
    } else {
      this.listenTo(this._root(), "refresh:?", callback);
    }
    return callback.call(this);
  };

  Scope.prototype.apply = function() {
    var dirties, dirty, resolver, root, _i, _j, _len, _len1, _ref;
    dirties = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    root = this._root();
    root._applies || (root._applies = 0);
    root._applies += 1;
    for (_i = 0, _len = dirties.length; _i < _len; _i++) {
      dirty = dirties[_i];
      if (this._resolvers[dirty]) {
        _ref = this._resolvers[dirty];
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          resolver = _ref[_j];
          resolver.scope.trigger("refresh:" + resolver.property);
        }
      } else {
        this.trigger("refresh:" + dirty);
      }
    }
    if (!--root._applies) {
      return root.trigger('refresh:?');
    }
  };

  Scope.prototype.releaseChilds = function() {
    var child, _i, _len, _ref;
    _ref = this._childs;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      child = _ref[_i];
      child.releaseChilds();
      child.stopListening();
    }
    return this._childs = [];
  };

  Scope.prototype.release = function() {
    this.releaseChilds();
    this.stopListening();
    return this.unbind();
  };

  return Scope;

})(Spine.Module);

Neck.Controller = Controller = (function(_super) {
  __extends(Controller, _super);

  Controller.viewsPath = 'views';

  Controller.controllersPath = 'controllers';

  Controller.helpersPath = 'helpers';

  Controller.runners = [];

  Controller.prototype.scope = true;

  Controller.prototype.inheritScope = true;

  Controller.prototype.innerTemplate = false;

  function Controller() {
    var childScope, key, string, template, value, _ref, _ref1, _ref2;
    Controller.__super__.constructor.apply(this, arguments);
    if (this.scope) {
      if (!this.parentScope) {
        childScope = new Scope(this);
      } else if (this.inheritScope) {
        childScope = this.parentScope.child();
      } else {
        childScope = new Scope(this);
      }
      if (typeof this.scope === 'object') {
        _ref = this.scope;
        for (key in _ref) {
          value = _ref[key];
          if (string = this.el[0].dataset[key]) {
            switch (this.scope[key]) {
              case '@':
                childScope.addProperty(key, "'" + string + "'", this.parentScope);
                break;
              case '=':
                childScope.addProperty(key, string, this.parentScope);
                break;
              default:
                childScope.addOwnProperty(key, this.scope[key]);
            }
          } else {
            if (this.scope[key] !== '=' && this.scope[key] !== '@') {
              childScope.addOwnProperty(key, this.scope[key]);
            } else {
              childScope.addOwnProperty(key, void 0);
            }
          }
        }
      } else if (this.scope === '@') {
        _ref1 = this.el[0].dataset;
        for (key in _ref1) {
          value = _ref1[key];
          childScope.addProperty(key, "'" + value + "'", this.parentScope);
        }
      } else if (this.scope === '=') {
        _ref2 = this.el[0].dataset;
        for (key in _ref2) {
          value = _ref2[key];
          childScope.addProperty(key, value, this.parentScope);
        }
      }
      this.scope = childScope;
    } else {
      this.scope = void 0;
    }
    if (this.innerTemplate) {
      if ((template = this.el.html()) !== '') {
        this.template = template;
        this.el.empty();
      }
    }
  }

  Controller.prototype.append = function(controller) {
    this["yield"] || (this["yield"] = this.el.find('[ui-yield]')[0] || this.el[0]);
    return $(this["yield"]).append(controller.el || controller);
  };

  Controller.prototype.parse = function(node) {
    var attribute, breakParse, child, el, name, runner, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    if (node == null) {
      node = this.el[0];
    }
    if (node.attributes) {
      el = null;
      _ref = node.attributes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attribute = _ref[_i];
        if (((_ref1 = attribute.nodeName) != null ? _ref1.substr(0, 3) : void 0) !== "ui-") {
          continue;
        }
        name = attribute.nodeName.substr(3);
        if (Neck.Controller.runners[name]) {
          el || (el = $(node));
          runner = new Neck.Controller.runners[name]({
            el: el,
            parentScope: this.scope,
            runAttr: attribute.value
          });
          if (runner.innerTemplate) {
            breakParse = true;
          }
        }
      }
    }
    if (!breakParse) {
      _ref2 = node.childNodes;
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        child = _ref2[_j];
        this.parse(child);
      }
    }
    return void 0;
  };

  Controller.prototype.render = function() {
    var el, _i, _len, _ref, _ref1;
    if (this.view || this.template) {
      if ((_ref = this.scope) != null) {
        _ref.releaseChilds();
      }
      if (typeof this.template === 'string') {
        this.el = $(this.template);
      } else if (typeof this.template === 'function') {
        this.el = $(this.template.call(this));
      } else {
        this.el = $((require("" + Neck.Controller.viewsPath + "/" + this.view))(this.scope));
      }
      _ref1 = this.el;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        el = _ref1[_i];
        this.parse(el);
      }
      return void 0;
    }
  };

  Controller.prototype.release = function() {
    Controller.__super__.release.apply(this, arguments);
    if (this.scope) {
      this.scope.release();
      return this.scope = void 0;
    }
  };

  return Controller;

})(Spine.Controller);

Neck.Screen = Screen = (function(_super) {
  __extends(Screen, _super);

  Screen.prototype.className = 'screen';

  Screen.prototype.inheritScope = false;

  Screen.prototype.popup = false;

  Screen.prototype.reloadSelf = false;

  Screen.prototype.singleton = false;

  function Screen(options) {
    if (this.singleton) {
      if (!this.constructor._instance) {
        this.constructor._instance = this;
      } else {
        return this.constructor._instance;
      }
    }
    Screen.__super__.constructor.apply(this, arguments);
    this.el.addClass(this.path.replace(/\//gi, ' '));
    if (!this.view) {
      this.view = this.path;
    }
  }

  /* RENDERING / VIEW*/


  Screen.prototype._inDOM = function() {
    return this.el[0].parentNode != null;
  };

  Screen.prototype.render = function() {
    var container, _ref;
    container = this.el;
    Screen.__super__.render.apply(this, arguments);
    this.el = container.html(this.el);
    this["yield"] = this.el.find('[ui-yield]')[0];
    if (!this._inDOM()) {
      return (_ref = this.parent) != null ? _ref.append(this) : void 0;
    }
  };

  Screen.prototype.append = function(controller) {
    var _ref;
    if (this["yield"]) {
      return $(this["yield"]).append(controller.el || controller);
    } else {
      return (_ref = this.parent) != null ? _ref.append(controller) : void 0;
    }
  };

  Screen.prototype.activate = function() {
    var _ref, _ref1, _ref2, _ref3;
    if ((_ref = this.child) != null) {
      _ref.release();
    }
    this.child = void 0;
    if (!this.popup) {
      if ((_ref1 = this.parent) != null) {
        _ref1.deactivate();
      }
    }
    if ((_ref2 = this.parent) != null) {
      _ref2.child = this;
    }
    this.el.addClass('active');
    this.el.css('zIndex', this.zIndex = ((_ref3 = this.parent) != null ? _ref3.zIndex : void 0) + 1 || 1);
    this.trigger('activate');
    this._root().trigger('activate:change', this);
    if (!this._inDOM()) {
      this.render();
    }
    return this;
  };

  Screen.prototype.deactivate = function() {
    if (!this["yield"]) {
      this.el.removeClass('active');
      this.el.css('zIndex', '');
      this.zIndex = void 0;
    }
    return this.trigger('deactivate');
  };

  /* ROUTING*/


  Screen.prototype._leaf = function() {
    var _ref;
    return ((_ref = this.child) != null ? _ref._leaf() : void 0) || this;
  };

  Screen.prototype._root = function() {
    var _ref;
    return ((_ref = this.parent) != null ? _ref._root() : void 0) || this;
  };

  Screen.prototype._childWithPath = function(path) {
    if (this.child) {
      if (this.child.path === path) {
        return this.child;
      } else {
        return this.child._childWithPath(path);
      }
    } else {
      return false;
    }
  };

  Screen.prototype.route = function(path, options, back, noEvents) {
    var controller, parent, _ref;
    if (options == null) {
      options = {};
    }
    if (back == null) {
      back = false;
    }
    if (noEvents == null) {
      noEvents = false;
    }
    controller = this._root()._childWithPath(path);
    if ((controller === false) || (controller === this.child && controller.reloadSelf)) {
      controller = require("" + Neck.Controller.controllersPath + "/" + path);
      if (!controller.prototype.popup) {
        if ((_ref = this.child) != null) {
          _ref.release();
        }
      }
      parent = controller.prototype.popup ? this._leaf() : this;
      if (back && this.parent) {
        options.parent = this.parent;
        options.parentScope = this.parent.scope;
        this.release();
      } else {
        options.parent = parent;
        options.parentScope = this.scope;
      }
      options.path = path;
      controller = new controller(options);
    }
    controller.activate();
    if (!noEvents) {
      this._root().trigger('route', controller);
      return this.trigger('route', controller);
    }
  };

  /* RELEASE*/


  Screen.prototype.release = function() {
    var _ref, _ref1;
    if ((_ref = this.child) != null) {
      _ref.release();
    }
    this.child = void 0;
    if ((_ref1 = this.parent) != null) {
      _ref1.child = void 0;
    }
    this.parent = void 0;
    this.deactivate();
    if (!this.singleton) {
      return Screen.__super__.release.apply(this, arguments);
    }
  };

  return Screen;

})(Neck.Controller);

Neck.App = App = (function(_super) {
  __extends(App, _super);

  App.prototype.path = 'app';

  /* OPTIONS*/


  App.prototype.hashRoute = false;

  App.prototype.errorRoute = false;

  App.prototype.historyApi = false;

  function App() {
    App.__super__.constructor.apply(this, arguments);
    this.historyApi = this.historyApi && window.history;
    if (this.hashRoute) {
      this.on('activate:change', this.pushRoute);
    }
    this.one('run', function() {
      this.render();
      if (this.hashRoute) {
        return this.evaluateRoute();
      }
    });
  }

  App.prototype.pushRoute = function() {
    var hash, param, params, screen, value, _ref, _ref1;
    hash = [];
    screen = this.child;
    while (screen) {
      if ((screen.child && screen["yield"]) || (!screen.child) || ((_ref = screen.child) != null ? _ref.popup : void 0)) {
        params = [];
        _ref1 = screen.params;
        for (param in _ref1) {
          value = _ref1[param];
          if (typeof value === 'string') {
            params.push("" + param + "='" + value + "'");
          } else {
            params.push("" + param + "=" + value);
          }
        }
        hash.push(params.length ? screen.path + ("[" + (params.join('&')) + "]") : screen.path);
      }
      screen = screen.child;
    }
    if (this.historyApi) {
      return window.history.replaceState(null, '', '/' + hash.join(':'));
    } else {
      return window.location.hash = "!/" + (hash.join(':'));
    }
  };

  App.prototype.evaluateRoute = function() {
    var e, i, options, param, path, routePath, screen, _i, _j, _len, _len1, _ref;
    if (this.historyApi) {
      path = window.location.pathname;
    } else {
      path = window.location.hash;
      path = path.replace(/^#(!\/)?/, '');
    }
    path = path.replace(/^\//, '');
    if (path = path.match(/[^\:]+((\'[^\']*\')?[^\:]+)+/g)) {
      screen = this;
      for (i = _i = 0, _len = path.length; _i < _len; i = ++_i) {
        routePath = path[i];
        options = {
          params: {}
        };
        routePath = routePath.match(/[^\[\]]+/g);
        _ref = (routePath[1] || '').match(/[a-zA-Z$_][a-zA-Z$_0-9\-]+\=(\'[^\']*\'|[A-Za-z]+|[0-9]+((\.|\,)?[0-9]+)*)/g) || [];
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          param = _ref[_j];
          param = param.match(/^([a-zA-Z$_][a-zA-Z$_0-9\-]+)(?:\=)(.+)/);
          options.params[param[1]] = eval(param[2]);
        }
        try {
          screen = screen.route(routePath[0], options);
        } catch (_error) {
          e = _error;
          if (!this.errorRoute) {
            if (!this.historyApi) {
              window.location.hash = "!/";
            }
            return this.activate();
          } else {
            this.route(this.errorRoute.url, $.extend({
              errorCode: 404
            }, this.errorRoute.params));
          }
        }
      }
    }
  };

  return App;

})(Neck.Screen);

;var AttrRunner,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller.runners['attr'] = AttrRunner = (function(_super) {
  __extends(AttrRunner, _super);

  function AttrRunner() {
    var _this = this;
    AttrRunner.__super__.constructor.apply(this, arguments);
    this.scope.addProperty('attr', this.runAttr);
    if (typeof this.scope.attr !== 'object') {
      throw "'attr' attribute has to be object";
    }
    this.scope.watch('attr', function() {
      var key, returnedValue, value, _ref;
      _ref = _this.scope.attr;
      for (key in _ref) {
        value = _ref[key];
        if (returnedValue = value) {
          _this.el.attr(key, returnedValue === true ? key : returnedValue);
        } else {
          _this.el.removeAttr(key);
        }
      }
      return void 0;
    });
  }

  return AttrRunner;

})(Neck.Controller);

;var BindRunner,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller.runners['bind'] = BindRunner = (function(_super) {
  __extends(BindRunner, _super);

  BindRunner.prototype.events = {
    "keydown": "update",
    "change": "update",
    "search": "update"
  };

  function BindRunner() {
    var _this = this;
    BindRunner.__super__.constructor.apply(this, arguments);
    this.scope.addProperty('bind', this.runAttr);
    if (this.scope.bind) {
      this.el.val(this.scope.bind || '');
    }
    this.scope.watch('bind', function() {
      if (!_this._updatedFlag) {
        return _this.el.val(_this.scope.bind || '');
      }
    });
  }

  BindRunner.prototype.calculateValue = function(value) {
    if (value.match(/^[0-9]+((\.|\,)?[0-9]+)*$/)) {
      return Number(value);
    } else {
      return value;
    }
  };

  BindRunner.prototype.update = function() {
    var _this = this;
    return setTimeout(function() {
      _this.scope.bind = _this.calculateValue(_this.el.val()) || void 0;
      _this._updatedFlag = true;
      _this.scope.apply('bind');
      return _this._updatedFlag = false;
    });
  };

  return BindRunner;

})(Neck.Controller);

;var ClassRunner,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller.runners['class'] = ClassRunner = (function(_super) {
  __extends(ClassRunner, _super);

  function ClassRunner() {
    var _this = this;
    ClassRunner.__super__.constructor.apply(this, arguments);
    this.scope.addProperty('class', this.runAttr);
    if (typeof this.scope["class"] !== 'object') {
      throw "Class attribute has to be object";
    }
    this.scope.watch('class', function() {
      var key, value, _ref;
      _ref = _this.scope["class"];
      for (key in _ref) {
        value = _ref[key];
        if (value) {
          _this.el.addClass(key);
        } else {
          _this.el.removeClass(key);
        }
      }
      return void 0;
    });
  }

  return ClassRunner;

})(Neck.Controller);

;var ElementRunner;

Neck.Controller.runners['element'] = ElementRunner = (function() {
  function ElementRunner(options) {
    options.parentScope["" + options.runAttr] = options.el;
  }

  return ElementRunner;

})();

;/* LIST OF EVENTS TO TRIGGER*/

var ER, Event, EventList, EventRunner, ev, eventRunner, _i, _len, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

EventList = ["click", "dblclick", "mouseenter", "mouseleave", "mouseout", "mouseover", "mousedown", "mouseup", "drag", "dragstart", "dragenter", "dragleave", "dragover", "dragend", "drop", "load", "focus", "focusin", "focusout", "select", "blur", "submit", "scroll", "touchstart", "touchend", "touchmove", "touchenter", "touchleave", "touchcancel", "keyup", "keydown", "keypress"];

EventRunner = (function(_super) {
  __extends(EventRunner, _super);

  function EventRunner() {
    EventRunner.__super__.constructor.apply(this, arguments);
    this.scope.addProperty('method', this.runAttr);
    if (typeof this.scope.method === 'function') {
      this.scope.method.call(this.scope.context, this.parentScope, this.e);
    } else {
      this.scope.apply('method');
    }
    this.scope.release();
  }

  return EventRunner;

})(Neck.Controller);

Event = (function() {
  function Event(options) {
    var _this = this;
    options.el.on(this.eventType, function(e) {
      e.preventDefault();
      options.e = e;
      return new EventRunner(options);
    });
  }

  return Event;

})();

/* INIT ALL EVENTS*/


for (_i = 0, _len = EventList.length; _i < _len; _i++) {
  ev = EventList[_i];
  eventRunner = ER = (function(_super) {
    __extends(ER, _super);

    function ER() {
      _ref = ER.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return ER;

  })(Event);
  eventRunner.prototype.eventType = ev;
  Neck.Controller.runners["event-" + ev] = eventRunner;
}

;var HelperRunner;

Neck.Controller.runners['helper'] = HelperRunner = (function() {
  function HelperRunner(options) {
    var helper;
    helper = new (require(("" + Neck.Controller.helpersPath + "/") + options.runAttr))({
      context: options.context,
      el: options.el,
      parentScope: options.parentScope
    });
    if (helper.view || helper.template) {
      helper.render();
      options.el.html(helper.el);
    }
  }

  return HelperRunner;

})();

;var HideRunner,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller.runners['hide'] = HideRunner = (function(_super) {
  __extends(HideRunner, _super);

  function HideRunner() {
    var _this = this;
    HideRunner.__super__.constructor.apply(this, arguments);
    this.scope.addProperty('hide', this.runAttr);
    this.scope.watch('hide', function() {
      if (_this.scope.hide) {
        return _this.el.hide();
      } else {
        return _this.el.show();
      }
    });
  }

  return HideRunner;

})(Neck.Controller);

;var RepeatItem, RepeatRunner,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller.runners['repeat'] = RepeatRunner = (function(_super) {
  __extends(RepeatRunner, _super);

  RepeatRunner.prototype.innerTemplate = true;

  RepeatRunner.prototype.scope = {
    filter: '=',
    view: '@'
  };

  function RepeatRunner() {
    var timeout,
      _this = this;
    RepeatRunner.__super__.constructor.apply(this, arguments);
    if (!this.runAttr.match(/^[a-zA-Z$_][^\ \(\)\{\}]*\ in\ [a-zA-Z$_][^\ \(\)\{\}]*$/)) {
      throw 'Wrong list definition';
    }
    this.runAttr = this.runAttr.split(' in ');
    this.scope.addProperty('items', this.runAttr[1]);
    this.scope.watch('items', function() {
      var controller, item, itemController, _i, _len, _ref;
      if (_this.scope.items) {
        if (_this.controllers) {
          _ref = _this.controllers;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            controller = _ref[_i];
            controller.release();
          }
        }
        _this.controllers = (function() {
          var _j, _len1, _ref1, _results;
          _ref1 = this.scope.items;
          _results = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            item = _ref1[_j];
            itemController = new RepeatItem({
              context: this.context,
              parentScope: this.scope,
              item: item,
              itemName: this.runAttr[0],
              template: this.template,
              view: this.scope.view
            });
            this.append(itemController);
            _results.push(itemController);
          }
          return _results;
        }).call(_this);
        return void 0;
      }
    });
    if (this.scope.hasOwnProperty('filter')) {
      timeout = null;
      this.scope.watch('filter', function() {
        clearTimeout(timeout);
        return timeout = setTimeout(function() {
          var controller, _i, _len, _ref;
          if (_this.controllers) {
            _ref = _this.controllers;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              controller = _ref[_i];
              _this.checkFilter(controller);
            }
          }
          return void 0;
        }, 10);
      });
    }
  }

  RepeatRunner.prototype.checkFilter = function(c) {
    var match, _ref;
    if (this.scope.filter !== void 0) {
      if (typeof this.scope.filter === 'function') {
        match = this.scope.filter(c.item);
      } else {
        match = (_ref = c.item.toString()) != null ? _ref.match(new RegExp(this.scope.filter, 'gi')) : void 0;
      }
      if (match) {
        return c.el.show();
      } else {
        return c.el.hide();
      }
    } else {
      return c.el.show();
    }
  };

  return RepeatRunner;

})(Neck.Controller);

RepeatItem = (function(_super) {
  __extends(RepeatItem, _super);

  RepeatItem.prototype.visible = true;

  function RepeatItem() {
    var _this = this;
    RepeatItem.__super__.constructor.apply(this, arguments);
    this.scope[this.itemName] = this.item;
    this.render();
    if (this.item instanceof Spine.Model) {
      this.listenTo(this.item, 'update', this.render);
      this.listenTo(this.item, 'destroy', function() {
        return _this.release();
      });
    }
  }

  return RepeatItem;

})(Neck.Controller);

;var RouteRunner, Router,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

RouteRunner = (function(_super) {
  __extends(RouteRunner, _super);

  RouteRunner.prototype.scope = '=';

  function RouteRunner() {
    var key, options, value, _ref;
    RouteRunner.__super__.constructor.apply(this, arguments);
    options = {};
    options.params = {};
    _ref = this.scope;
    for (key in _ref) {
      if (!__hasProp.call(_ref, key)) continue;
      value = _ref[key];
      options.params[key] = value;
    }
    this.scope.context.route(this.runAttr, options, this.back);
    this.scope.release();
  }

  return RouteRunner;

})(Neck.Controller);

Neck.Controller.runners['route'] = Router = (function() {
  function Router(options) {
    var _this = this;
    options.el.on('click', function(e) {
      e.preventDefault();
      return new RouteRunner(options);
    });
  }

  return Router;

})();

Neck.Controller.runners['route-back'] = Router = (function() {
  function Router(options) {
    var _this = this;
    options.el.on('click', function(e) {
      e.preventDefault();
      options.back = true;
      return new RouteRunner(options);
    });
  }

  return Router;

})();

;var ShowRunner,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller.runners['show'] = ShowRunner = (function(_super) {
  __extends(ShowRunner, _super);

  function ShowRunner() {
    var _this = this;
    ShowRunner.__super__.constructor.apply(this, arguments);
    this.scope.addProperty('show', this.runAttr);
    this.scope.watch('show', function() {
      if (_this.scope.show) {
        return _this.el.show();
      } else {
        return _this.el.hide();
      }
    });
  }

  return ShowRunner;

})(Neck.Controller);

;var ValueRunner,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller.runners['value'] = ValueRunner = (function(_super) {
  __extends(ValueRunner, _super);

  function ValueRunner() {
    var _this = this;
    ValueRunner.__super__.constructor.apply(this, arguments);
    this.scope.addProperty('value', this.runAttr);
    this.scope.watch('value', function() {
      return _this.el.html(_this.scope.value || '');
    });
  }

  return ValueRunner;

})(Neck.Controller);

;