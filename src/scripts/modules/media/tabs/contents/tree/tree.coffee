define (require) ->
  $ = require('jquery')
  _ = require('underscore')
  BaseView = require('cs!helpers/backbone/views/base')
  TocLeafView = require('cs!./leaf')
  template = require('hbs!./tree-template')
  require('less!./tree')

  return class TocTreeView extends BaseView
    template: template
    templateHelpers: editable: () -> @editable
    itemViewContainer: '> ul'

    events:
      'click > div > span > .subcollection': 'toggleSubcollection'
      'click > div > .remove': 'removeNode'

    initialize: (options = {}) ->
      @editable = options.editable
      @content = options.content
      @expanded = true
      @regions =
        container: @itemViewContainer

      super()
      @listenTo(@model, 'change:unit change:title change:subcollection', @render)

    onRender: () ->
      @regions.container.empty()

      nodes = @model.get('contents')?.models

      _.each nodes, (node) =>
        if node.get('subcollection')
          @regions.container.appendAs 'li', new TocTreeView
            model: node
            content: @content
            editable: @editable
        else
          @regions.container.appendAs 'li', new TocLeafView
            model: node
            content: @content
            editable: @editable
            collection: @model

    toggleSubcollection: (e) ->
      parent = $(e.currentTarget).parent().parent()

      if @expanded
        @expanded = false
        parent.find('.expand').html('&#9662;')
      else
        @expanded = true
        parent.find('.expand').html('&#9656;')

      parent.siblings('ul').toggle()

    removeNode: () ->
      @content.removeNode(@model)
