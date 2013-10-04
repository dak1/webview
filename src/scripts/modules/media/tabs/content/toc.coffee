define (require) ->
  $ = require('jquery')
  _ = require('underscore')
  BaseView = require('cs!helpers/backbone/views/base')
  TocNodeView = require('cs!./node')
  template = require('hbs!./toc-template')
  require('less!./toc')

  return class TocTreeView extends BaseView
    template: template
    itemViewContainer: '> ul'

    events:
      'click > div > .subcollection': 'toggleSubcollection'

    initialize: (options = {}) ->
      @expanded = true
      @regions =
        container: @itemViewContainer

      super()
      @listenTo(@model, 'change:unit change:title change:subcollection', @render)

    onRender: () ->
      @regions.container.empty()

      _.each @model.get('contents').models, (node) =>
        if node.get('subcollection')
          @regions.container.appendAs('li', new TocTreeView({model: node}))
        else
          @regions.container.appendAs('li', new TocNodeView({model: node}))

    toggleSubcollection: (e) ->
      parent = $(e.currentTarget).parent()

      if @expanded
        @expanded = false
        parent.find('.expand').html('&#9662;')
      else
        @expanded = true
        parent.find('.expand').html('&#9656;')

      parent.siblings('ul').toggle()
