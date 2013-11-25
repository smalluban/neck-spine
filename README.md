# Neck

Neck is a library which adds number of features to [Spine](http://spinejs.com/) MVC framework. It includes:

* Simple routing system for controllers and views (Ruby on Rails convection, requires 'CommonJS require definition')
* Nested views (Android SDK activities inspirated)
* Full data bindings with scope object, inheritance and more ([Angular.js](http://angularjs.org/) [90%] and [Batman.js](http://batmanjs.org/) [10%] ideas)
* Two way access to scope - from templating engine and runners (angular.js directives) giving more control for developer

Neck change flow and usage of Spine but it's still not separate framework. 
To work with Neck you should read Spine [documentation](http://spinejs.com/docs/index) first.

It is on very early stage of development(no docs and tests yet). Consider not using it in production.

## Usage

### App skeleton - [Neck on brunch](https://github.com/smalluban/neck-on-brunch)

Library is dependent on CommonJS and paths logic and templating engines.
For best expirence use it with [neck-on-brunch](https://github.com/smalluban/neck-on-brunch) app skeleton. 

This skeleton has built in dependency to Neck with Bower, work with Jade [Templating Engine](http://jade-lang.com/) 
and [Stylus](http://learnboost.github.io/stylus/) for compiling CSS.

### Existing projects

If you would like to add Neck to your exisitng project use `bower install neck` command in project path 
or copy 'lib/neck.js' to your vendor folder. But then it still require Spine, jQuery/Zepto and CommonJS librares to work.

## Documentation

For documentation and examples go to [docs section](https://github.com/smalluban/neck/tree/master/docs).

## Background

In some projects I tried to move from Spine to other frameworks, especially to ones which support data binding (mostly Angular and Batman). 
After few days or weeks of working with them I always returned to Spine. Way? There is a lot of features that I like more than in other frameworks.
But I loved idea of data binding and other concepts of writing web apps. 

Below you can read some basic concepts of Neck Extension Pack.

### Routing and controlling views state

My idea was to create tool that replace routing with something easy to maintenance and extend(no file with static routes, controllers are push to heap 
with automaticly save state and work in background, etc..). It would work like android activities.

For example in angular.js (without ui-router module) you have no access to before state of app. It will be created once again when you push back button or goes
to that url in app (I mean scroll position, clickes on models created only in controller, not saved models from third API). However batman.js use caching views, but usually
I had blink with data (becouse of singleton controllers - they are init only once, then view are fill in with other data, for moment you see old ones). 

Also getting access to controllers and views should be easy and automaticly as it can be. Using RoR convention when you path your controller Neck will search for view in
corresponding path for view. It use CommonJS require method which is generated automaticly with skeleton tools like brunch.io. 

This ideas put me to build Neck routing tool. More information you will find in documentation.

For note: My expieriance with anglur and batman is not full and that frameworks sinse then can work better or even different.

### Data binding

Firstly I think only about create tool to automaticly bind helper controllers to DOM element and create them when view is rendered. They would do some work 
independent of controller. I added JavaScript interpreter to eval options from DOM data attributes. Controller was send to view as main object, so view has ability to read
properites. When it worked, suddenly I thought: way not do full data binging like is in angular.js... and I did it. 

Binding process is similar to angular.js but has some basic differents in concept. It use spine events, which are triggered only when some property really changed. 
In views runners (angular.js directives) you have always access to context (contoller). Creating child scopes don't cut access to father scopes. 

### Direct access to scope

Data binding in angular and batman also has big disadvantage: views are 100% static. You have no other choice than using binding to show data. When in your app
performance is not the most important goal it's ok. But when you have to show hundreds of complex models on one screen it will work slow because of all binding process. 
Of course you can say that is wrong to do that (UI design wrong) but there are still some project that require it. 

My proposal is give developer choice. Scope object can be accessed both ways - from runners and directly in view template. You can choose when you want to use
binding and where render data in view directly. 

Furthermore you can mix this approach. For example have runner for creating list, but item in list is rendered directly. When something change in list, 
item will be automaticly rerender again. But inside item there will be no complex binding wich would be long process (especially with very long lists).

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

