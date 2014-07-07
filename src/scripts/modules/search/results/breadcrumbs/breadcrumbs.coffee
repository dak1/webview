define (require) ->
  $ = require('jquery')
  router = require('cs!router')
  BaseView = require('cs!helpers/backbone/views/base')
  template = require('hbs!./breadcrumbs-template')
  require('less!./breadcrumbs')

  return class SearchResultsBreadcrumbsView extends BaseView
    template: template

    events:
      'click .remove': 'removeBreadcrumb'

    initialize: () ->
      super()
      @listenTo(@model, 'change:query', @render)

    removeBreadcrumb: (e) ->
      limits = @model.get('query').limits
      limits.splice($(e.currentTarget).parent().data('index'), 1)

      query = @formatQuery(limits)
      @search(query)

    search: (query) ->
      url = "#{window.location.pathname}?q=#{query}&"
      url += _.filter window.location.search.slice(1).split('&'), (query) ->
        return query.substr(0,2) isnt 'q=' and query.substr(0,5) isnt 'page='
      .join('&')

      router.navigate(url, {trigger: true})

    # Transform the query.limits object into the original query string
    formatQuery: (obj) ->
      format = (obj) ->
        _.map obj, (limit) ->
          # Values with spaces in them must have been surrounded by quote strings
          if /\s/g.test(limit.value) and not /"/g.test(limit.value)
            limit.value = "\"#{limit.value}\""

          return "#{limit.tag}:#{limit.value}" # Limit strings are in the format `limit:value`

      return _.compact(_.flatten(format(obj))).join(' ')
