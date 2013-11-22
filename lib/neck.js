var App, Controller, Neck, Scope, Screen,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

window.Neck = Neck = {};

Neck.Scope = Scope = (function(_super) {
  __extends(Scope, _super);

  Scope.include(Spine.Events);

  function Scope(options) {
    var key, property, value, _i, _len, _ref;
    if (!options.context) {
      throw "Context required";
    }
    for (key in options) {
      value = options[key];
      this.addHiddenProperty(key, value);
    }
    _ref = [["_resolvers", {}], ["_dirties", []], ["_childs", []], ["_callbacks", {}], ["listeningTo", []], ["listeningToOnce", []]];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      property = _ref[_i];
      this.addHiddenProperty.apply(this, property);
    }
  }

  Scope.prototype.child = function(options) {
    var child, key, property, value, _i, _len, _ref;
    this._childs.push(child = Object.create(this));
    for (key in options) {
      value = options[key];
      child.addHiddenProperty(key, value);
    }
    _ref = [["parent", this], ["_resolvers", {}], ["_dirties", []], ["_childs", []], ["_callbacks", {}], ["listeningTo", []], ["listeningToOnce", []]];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      property = _ref[_i];
      child.addHiddenProperty.apply(child, property);
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
    reservedKeywords = new RegExp("(^|\\ )" + scope + "\\.(do|if|in|for|let|new|try|var|case|else|enum|eval|false|null|this|true|\nvoid|with|break|catch|class|const|super|throw|while|yield|delete|export|import|public|\n  return|static|switch|typeof|default|extends|finally|package|private|continue|debugger|\n  function|arguments|interface|protected|implements|instanceof|undefined|window)", "g");
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
    var item, property, result, _i, _len, _ref;
    string = string.replace(/\'[^\']+\'/g, function(text) {
      return "###";
    });
    result = [];
    _ref = string.match(/scope\.([a-zA-Z$_][^\ \(\)\{\}\;]*)/g);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      if (result.indexOf(property = item.replace('scope.', '')) === -1) {
        result.push(property);
      }
    }
    return result;
  };

  Scope.prototype.addHiddenProperty = function(key, value) {
    return Object.defineProperty(this, key, {
      value: value,
      enumerable: false,
      configurable: false
    });
  };

  Scope.prototype.addProperty = function(name, string, scope, context) {
    var checkString, model, parentResolver, property, resolve, resolver, resolvers, _i, _j, _len, _len1;
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
        model = string.split('.');
        resolvers.push(model[1]);
        property = model.pop();
        model = eval(model.join('.'));
        Object.defineProperty(this, name, {
          get: function() {
            return eval(string);
          },
          set: function(val) {
            return model[property] = val;
          }
        });
      } else {
        if (checkString.match(/\:/)) {
          string = "(" + string + ")";
        }
        Object.defineProperty(this, name, {
          get: function() {
            return eval(string);
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
    var args, callback, parentScope, properties, property, resolver, scope, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
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
          this.bind("refresh:" + property, callback);
        } else {
          scope = this;
          while (parentScope = scope.parent) {
            if (parentScope._resolvers[property]) {
              _ref1 = parentScope._resolvers[property];
              for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
                resolver = _ref1[_k];
                this.listenTo(resolver.scope, "refresh:" + resolver.property, callback);
              }
              break;
            }
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

  Scope.prototype.clearSelf = function() {
    return this.stopListening();
  };

  Scope.prototype.clearChilds = function() {
    var child, _i, _len, _ref;
    _ref = this._childs;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      child = _ref[_i];
      child.clearChilds();
      child.clearSelf();
    }
    return void 0;
  };

  Scope.prototype.release = function() {
    this.unbind();
    this.clearChilds();
    return this.clearSelf();
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

  function Controller() {
    var childScope, key, string, value, _ref, _ref1, _ref2;
    Controller.__super__.constructor.apply(this, arguments);
    if (!this.rootScope) {
      this.scope = new Scope({
        context: this
      });
    } else {
      if (this.scope) {
        if (this.inheritScope) {
          childScope = this.rootScope.child();
        } else {
          childScope = new Scope({
            context: this
          });
        }
        if (typeof this.scope === 'object') {
          _ref = this.scope;
          for (key in _ref) {
            value = _ref[key];
            if (string = this.el[0].dataset[key]) {
              switch (this.scope[key]) {
                case '@':
                  childScope.addProperty(key, "'" + string + "'", this.rootScope);
                  break;
                case '=':
                  childScope.addProperty(key, string, this.rootScope);
              }
            } else {
              childScope[key] = this.scope[key];
            }
          }
        } else if (this.scope === '@') {
          _ref1 = this.el[0].dataset;
          for (key in _ref1) {
            value = _ref1[key];
            childScope.addProperty(key, "'" + value + "'", this.rootScope);
          }
        } else if (this.scope === '=') {
          _ref2 = this.el[0].dataset;
          for (key in _ref2) {
            value = _ref2[key];
            childScope.addProperty(key, value, this.rootScope);
          }
        }
        this.scope = childScope;
      }
    }
  }

  Controller.prototype.append = function(controller) {
    this["yield"] || (this["yield"] = this.el.find('[ui-yield]')[0] || this.el[0]);
    return $(this["yield"]).append(controller.el || controller);
  };

  Controller.prototype.parse = function(node) {
    var attribute, child, el, name, runner, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    if (node == null) {
      node = this.el[0];
    }
    el = null;
    _ref = node.childNodes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      child = _ref[_i];
      this.parse(child);
    }
    if (node.attributes) {
      _ref1 = node.attributes;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        attribute = _ref1[_j];
        if (((_ref2 = attribute.nodeName) != null ? _ref2.substr(0, 3) : void 0) !== "ui-") {
          continue;
        }
        name = attribute.nodeName.substr(3);
        if (Neck.Controller.runners[name]) {
          el || (el = $(node));
          runner = new Neck.Controller.runners[name]({
            el: el,
            rootScope: this.scope,
            runAttr: attribute.value
          });
        }
      }
    }
    return void 0;
  };

  Controller.prototype.render = function() {
    if (this.view) {
      this.scope.clearChilds();
      if (typeof this.view === 'function') {
        this.view.call(this);
      } else {
        this.el.html((require("" + Neck.Controller.viewsPath + "/" + this.view))(this.scope));
      }
      return this.parse();
    }
  };

  Controller.prototype.release = function() {
    Controller.__super__.release.apply(this, arguments);
    if (this.scope !== this.rootScope) {
      this.scope.release();
    }
    return this.scope = void 0;
  };

  return Controller;

})(Spine.Controller);

Neck.Screen = Screen = (function(_super) {
  __extends(Screen, _super);

  Screen.prototype.className = 'screen';

  Screen.prototype.inheritScope = false;

  Screen.prototype.popup = false;

  Screen.prototype.reloadSelf = false;

  function Screen() {
    Screen.__super__.constructor.apply(this, arguments);
    if (!this.path) {
      throw "No path defined";
    }
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
    var _ref;
    Screen.__super__.render.apply(this, arguments);
    this["yield"] = this.el.find('[ui-yield]')[0];
    if (!this._inDOM()) {
      return (_ref = this.parent) != null ? _ref.append(this) : void 0;
    }
  };

  Screen.prototype.append = function(controller) {
    if (this["yield"]) {
      return $(this["yield"]).append(controller.el || controller);
    } else {
      return this.parent.append(controller);
    }
  };

  Screen.prototype.activate = function() {
    var _ref, _ref1, _ref2, _ref3;
    if ((_ref = this.child) != null) {
      _ref.release();
    }
    this.child = null;
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
    if (!this._inDOM()) {
      this.render();
    }
    return this;
  };

  Screen.prototype.deactivate = function() {
    if (!this["yield"]) {
      this.el.removeClass('active');
    }
    return this.trigger('deactivate');
  };

  /* ROUTING*/


  Screen.prototype._leaf = function() {
    var _ref;
    return ((_ref = this.child) != null ? _ref._leaf() : void 0) || this;
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

  Screen.prototype.route = function(path, options, back) {
    var controller, parent;
    if (options == null) {
      options = {};
    }
    if (back == null) {
      back = false;
    }
    controller = this.root._childWithPath(path);
    if ((controller === false) || (controller === this.child && controller.reloadSelf)) {
      if (controller === this.child) {
        this.child.release();
      }
      controller = require("" + Neck.Controller.controllersPath + "/" + path);
      parent = controller.prototype.popup ? this._leaf() : this;
      if (back && this.parent) {
        options.parent = this.parent;
        options.rootScope = this.parent.scope;
        this.release();
      } else {
        options.parent = parent;
        options.rootScope = this.scope;
      }
      options.path = path;
      options.root = this.root;
      controller = new controller(options);
    }
    controller.activate();
    return this.root.trigger('route', controller);
  };

  /* SINGLETON*/


  Screen.prototype.singleton = function() {
    if (!this.constructor._instance) {
      this.constructor._instance = this;
      return false;
    } else {
      return this.constructor._instance;
    }
  };

  Screen.prototype._isSingleton = function() {
    return this.constructor._instance !== void 0;
  };

  /* RELEASE*/


  Screen.prototype.release = function() {
    var _ref;
    if ((_ref = this.child) != null) {
      _ref.release();
    }
    this.child = void 0;
    if (!this._isSingleton()) {
      return Screen.__super__.release.apply(this, arguments);
    } else {
      this.el.css('zIndex', this.zIndex = 0);
      return this.deactivate();
    }
  };

  return Screen;

})(Neck.Controller);

Neck.App = App = (function(_super) {
  __extends(App, _super);

  App.prototype.path = 'app';

  /* OPTIONS*/


  App.prototype.hashRoute = false;

  App.prototype.historyApi = false;

  function App() {
    App.__super__.constructor.apply(this, arguments);
    this.root = this;
    this.historyApi = this.historyApi && window.history;
    if (this.hashRoute) {
      this.on('route', this._pushRoute);
    }
    this.one('run', function() {
      this.render();
      if (this.hashRoute) {
        return this._evaluateRoute();
      }
    });
  }

  App.prototype._pushRoute = function() {
    var hash, param, params, screen, value, _ref;
    hash = [];
    screen = this.child;
    while (screen) {
      if ((screen.child && screen["yield"]) || (!screen.child)) {
        params = [];
        _ref = screen.params;
        for (param in _ref) {
          value = _ref[param];
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
      return window.history.replaceState(null, '', hash.join(':'));
    } else {
      return window.location.hash = "!/" + (hash.join(':'));
    }
  };

  App.prototype._evaluateRoute = function() {
    var e, i, options, param, path, routePath, screen, _i, _j, _len, _len1, _ref;
    if (this.historyApi && window.history) {
      path = window.location.pathname;
      if (path.substr(0, 1) !== '/') {
        path = '/' + path;
      }
    } else {
      path = window.location.hash;
      path = path.replace(/^#(!\/)?/, '');
    }
    if (path = path.match(/[^\:]+((\'[^\']*\')?[^\:]+)+/g)) {
      screen = this;
      for (i = _i = 0, _len = path.length; _i < _len; i = ++_i) {
        routePath = path[i];
        routePath = routePath.replace(/^\+/, function() {
          return screen.path + '/';
        });
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
          window.location.hash = "!/";
          return this.root.activate();
        }
      }
    }
  };

  return App;

})(Neck.Screen);

;var BindRunner,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller.runners['bind'] = BindRunner = (function(_super) {
  __extends(BindRunner, _super);

  BindRunner.prototype.events = {
    "keyup": "update",
    "change": "update",
    "search": "update"
  };

  function BindRunner() {
    var _this = this;
    BindRunner.__super__.constructor.apply(this, arguments);
    this.scope.addProperty('bind', this.runAttr);
    if (this.scope.bind) {
      this.el.val(this.scope.bind);
    }
    this.scope.watch('bind', function() {
      return _this.el.val(_this.scope.bind ? _this.scope.bind : '');
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
    this.scope.bind = this.calculateValue(this.el.val()) || void 0;
    return this.scope.apply('bind');
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
    options.rootScope["" + options.runAttr] = options.el;
  }

  return ElementRunner;

})();

;/* LIST OF EVENTS TO TRIGGER*/

var ER, Event, EventList, EventRunner, ev, eventRunner, _i, _len, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

EventList = ["click", "dblclick", "mouseenter", "mouseleave", "mouseout", "mouseover", "mousedown", "mouseup", "drag", "dragstart", "dragenter", "dragleave", "dragover", "dragend", "drop", "load", "focus", "focusin", "focusout", "select", "blur", "submit", "scroll", "touchstart", "touchend", "touchmove", "touchenter", "touchleave", "touchcancel"];

EventRunner = (function(_super) {
  __extends(EventRunner, _super);

  function EventRunner() {
    EventRunner.__super__.constructor.apply(this, arguments);
    this.scope.addProperty('method', this.runAttr);
    if (typeof this.scope.method === 'function') {
      this.scope.method.call(this.scope.context, this.scope, this.e);
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
    new (require(("" + Neck.Globals.helpersPath + "/") + options.runAttr))({
      context: options.context,
      el: options.el,
      rootScope: options.rootScope
    });
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

;var ListItem, ListRunner,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller.runners['list'] = ListRunner = (function(_super) {
  __extends(ListRunner, _super);

  ListRunner.prototype.scope = {
    items: '=',
    filter: '=',
    view: '='
  };

  function ListRunner() {
    var timeout,
      _this = this;
    ListRunner.__super__.constructor.apply(this, arguments);
    if (!this.scope.view) {
      throw 'No view defined';
    }
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
            itemController = new ListItem({
              context: this.context,
              rootScope: this.scope,
              item: item,
              itemName: this.runAttr
            });
            this.append(itemController);
            _results.push(itemController);
          }
          return _results;
        }).call(_this);
        return void 0;
      }
    });
    timeout = null;
    this.scope.watch('filter', function() {
      clearTimeout(timeout);
      return timeout = setTimeout(function() {
        var controller, _i, _len, _ref;
        if (_this.controllers) {
          _ref = _this.controllers;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            controller = _ref[_i];
            controller.checkFilter();
          }
        }
        return void 0;
      }, 10);
    });
  }

  return ListRunner;

})(Neck.Controller);

ListItem = (function(_super) {
  __extends(ListItem, _super);

  ListItem.prototype.text = null;

  ListItem.prototype.view = function() {
    return this.el = $(require("" + Neck.Controller.viewsPath + "/" + this.scope.view)(this.scope));
  };

  ListItem.prototype.visible = true;

  function ListItem() {
    var _this = this;
    ListItem.__super__.constructor.apply(this, arguments);
    this.scope[this.itemName] = this.item;
    this.render();
    this.text = this.el.text();
    if (this.item instanceof Spine.Model) {
      this.listenTo(this.item, 'update', this.render);
      this.listenTo(this.item, 'destroy', function() {
        return _this.release();
      });
    }
    this.checkFilter();
  }

  ListItem.prototype.checkFilter = function() {
    if (!this.scope.filter && !this.visible) {
      this.el.show();
      return this.visible = true;
    } else {
      if (this.text.match(this.scope.filter)) {
        if (!this.visible) {
          this.el.show();
          return this.visible = true;
        }
      } else {
        if (this.visible) {
          this.el.hide();
          return this.visible = false;
        }
      }
    }
  };

  return ListItem;

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