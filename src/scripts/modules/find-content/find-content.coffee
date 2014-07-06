define (require) ->
  $ = require('jquery')
  Backbone = require('backbone')
  router = require('cs!router')
  subjects = require('cs!collections/subjects')
  BaseView = require('cs!helpers/backbone/views/base')
  template = require('hbs!./find-content-template')
  require('less!./find-content')
  require('bootstrapDropdown')

  return class FindContentView extends BaseView
    template: template
    collection: subjects

    events:
      'click .dropdown-menu > li': 'selectSubject'
      'keyup input': 'triggerSearch'

    initialize: () ->
      super()
      @listenTo(@collection, 'reset', @render)

    onRender: () ->
      @updateSearchBar()

    selectSubject: (e) ->
      e.preventDefault()

      @search("subject:\"#{$(e.currentTarget).text()}\"")

    triggerSearch: (e) ->
      if e.keyCode is 13
        @search($(e.currentTarget).val())

    search: (query) ->
      router.navigate("search?q=#{query}", {trigger: true})

    updateSearchBar: () ->
      query = ''
      url = Backbone.history.fragment.match(/^(search)(\?q=.*)?/)

      if url and url.length is 3 and url[1] is 'search'
        query = _.filter decodeURIComponent(url[2]).slice(1).split('&'), (fragment) ->
          return fragment.substr(0,2) is 'q='

        query = query[0].slice(2) if typeof query[0] is 'string'

      @$el.find('.find').val(query)
