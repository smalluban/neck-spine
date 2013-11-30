# Neck

Neck is a library which adds number of features to [Spine](http://spinejs.com/) MVC framework. It includes:

* Simple routing system for controllers and views (Ruby on Rails convection, requires 'CommonJS require definition')
* Nested views (Android SDK activities inspirated)
* Full data bindings with scope object, inheritance and more ([Angular.js](http://angularjs.org/) [90%] and [Batman.js](http://batmanjs.org/) [10%] ideas)
* Two way access to scope - from templating engine and runners (angular.js directives) giving more control for developer

Neck change flow and usage of Spine but it's still not separate framework. 
To work with Neck you should read Spine [documentation](http://spinejs.com/docs/index) first.

It is on very early stage of development(no docs and tests yet). Consider not using it in production.

[![Build Status](https://travis-ci.org/smalluban/neck.png?branch=master)](https://travis-ci.org/smalluban/neck)

## Getting started

Creating flexible and responsive apps with Neck is very easy. For example, see how can be write a part of Tasks manager:

### Model

```coffee
class Task extends Spine.Model
  @configure 'Task', 'text', 'done'
  @extend Spine.Model.Local
```

### View

```jade
h1 Tasks
ul(ui-repeat="task in tasks")
  li(ui-class="{'done': task.done}")
    span(ui-value="task.text")
    button(ui-event-click="task.done = !task.done") done
p
  input(type="text", ui-bind="text")
  button(ui-event-click="@addTask") add task
```

### Controller

```coffee
class TaskList extends Neck.Screen
  constructor: ->
    super
    Task.on 'update refresh', =>
      @scope.tasks = Task.all()
      @scope.apply 'tasks'

    Task.fetch()

  addTask: ->
    if @scope.text
      (new Task(text: @scope.text)).save()
      @scope.text = null
      @scope.apply 'text'
```

For documentation and examples go to [docs section](https://github.com/smalluban/neck/wiki).

## Setup

### App skeleton - [Neck on brunch](https://github.com/smalluban/neck-on-brunch)

Library is dependent on CommonJS and paths logic and templating engines.
For best expirence use it with [neck-on-brunch](https://github.com/smalluban/neck-on-brunch) app skeleton. 

This skeleton has built in dependency to Neck with Bower, work with Jade [Templating Engine](http://jade-lang.com/) 
and [Stylus](http://learnboost.github.io/stylus/) for compiling CSS.

### Existing projects

If you would like to add Neck to your exisitng project use `bower install neck` command in project path 
or copy 'lib/neck.js' to your vendor folder. But then it still require Spine, jQuery/Zepto and CommonJS librares to work.

## Contribution

Feel free to contribute project. For developing, clone project and run:

```
npm install
bower install
```

Use `npm start` and go to your browser `http://localhost:3333/test/` for check tests. 
Write some changes, update tests and do pull request to this repository.

## License

Neck is released under the [MIT License](https://raw.github.com/smalluban/neck/master/LICENSE)

