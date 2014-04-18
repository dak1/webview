define (require) ->
  $ = require('jquery')
  router = require('cs!router')
  linksHelper = require('cs!helpers/links')
  analytics = require('cs!helpers/handlers/analytics')
  BaseView = require('cs!helpers/backbone/views/base')
  template = require('hbs!./nav-template')
  require('less!./nav')

  return class MediaNavView extends BaseView
    template: template
    templateHelpers: () ->
      page = @model.getPageNumber()
      nextPage = @model.getNextPageNumber()
      previousPage = @model.getPreviousPageNumber()

      if page isnt nextPage
        next = linksHelper.getPath('contents', {model: @model, page: nextPage})
      if page isnt previousPage
        back = linksHelper.getPath('contents', {model: @model, page: previousPage})

      return {
        _hideProgress: @hideProgress
        book: @model.isBook()
        next: next
        back: back
        pages: if @model.get('loaded') then @model.getTotalPages() else 0
        page: if @model.get('loaded') then @model.getPageNumber() else 0
      }

    initialize: (options) ->
      super()
      @hideProgress = options.hideProgress

      @listenTo(@model, 'change:currentPage removeNode moveNode add:contents', @render)

    events:
      'click .next': 'nextPage'
      'click .back': 'previousPage'

    nextPage: (e) ->
      nextPage = @model.getNextPageNumber()
      # Show the next page if there is one
      @model.lookupAndSetPage(nextPage)
      @changePage(e)

    previousPage: (e) ->
      previousPage = @model.getPreviousPageNumber()
      # Show the previous page if there is one
      @model.lookupAndSetPage(previousPage)
      @changePage(e)

    changePage: (e) ->
      e.preventDefault()
      e.stopPropagation()
      href = $(e.currentTarget).attr('href')
      router.navigate href, {trigger: false}, () => @trackNav()
      @scrollToTop()

    trackNav: () ->
      analyticsID = @model.get('googleAnalytics')
      analytics.send(analyticsID) if analyticsID

    scrollToTop: () ->
      $mediaNav = $('.media-nav').first()
      maxY = $mediaNav.offset().top + $mediaNav.height()
      y = window.pageYOffset or document.documentElement.scrollTop

      window.scrollTo(0, maxY) if y > maxY
