define (require) ->
  $ = require('jquery')
  _ = require('underscore')
  linksHelper = require('cs!helpers/links')
  router = require('cs!router')
  searchResults = require('cs!models/search-results')
  BaseView = require('cs!helpers/backbone/views/base')
  AddPageSearchResultsView = require('cs!./results/results')
  template = require('hbs!./add-page-template')
  require('less!./add-page')
  require('bootstrapModal')

  return class AddPageModal extends BaseView
    template: template

    _checkedCounter: 0

    regions:
      results: '.add-page-search-results'

    events:
      'click .new-page': 'newPage'
      'click .search-pages': 'onSearch'
      'submit form': 'onSubmit'
      'change form': 'onChange'
      'keyup .page-title': 'onKeyUpSearch'
      'focus .page-title': 'onFocusSearch'
      'blur .page-title': 'onUnfocusSearch'
      'keypress .page-title': 'onEnter'

    initialize: () ->
      super()
      @validate = @initializeValidations()

    onRender: () ->
      @$el.off('shown.bs.modal') # Prevent duplicating event listeners
      @$el.on 'shown.bs.modal', () => @$el.find('.page-title').focus()

    # Update the Search/Submit buttons to make the button that will
    # respond to 'Enter' to be styled as primary
    onFocusSearch: (e) ->
      @$el.find('.search-pages').addClass('btn-primary').removeClass('btn-plain')
      @$el.find('.btn-submit').addClass('btn-plain').removeClass('btn-primary')

    onUnfocusSearch: (e) ->
      @$el.find('.search-pages').addClass('btn-plain').removeClass('btn-primary')
      @$el.find('.btn-submit').addClass('btn-primary').removeClass('btn-plain')

    onKeyUpSearch: (e) ->
      if @validations.searchTitle.hasError
        @validations.searchTitle.validate()

      if @validations.addPage.hasError
        @validations.addPage.validate()


    # Intelligently determine if the user intended to search or add pages
    # when hitting the 'enter' key
    onEnter: (e) ->
      if e.keyCode is 13
        e.preventDefault()
        e.stopPropagation()

        $input = @$el.find('.page-title')

        if $input.is(':focus')
          @search($input.val())
        else
          @$el.find('form').submit()

    onChange: (e) ->
      $target = $(e.target)

      # Use a counter to determine how many check boxes are selected
      # rather than looping through and counting them every time,
      # since there could be a huge number of check boxes.
      if $target.attr('type') is 'checkbox'
        if $target.is(':checked')
          @_checkedCounter++
        else
          @_checkedCounter--

      if @_checkedCounter is 0
        @$el.find('.btn-submit').text('Create New Page')
      else if @_checkedCounter is 1
        @$el.find('.btn-submit').text('Add Selected Page')
      else
        @$el.find('.btn-submit').text('Add Selected Pages')

      if @validations.addPage.hasError
        @validations.addPage.validate()

      if @validations.searchTitle.hasError
        @validations.searchTitle.hide()

    onSearch: (e) ->
      title = @$el.find('.page-title').val()
      @search(title)

    search: (title) ->
      if @validations.searchTitle.validate(title)
        @_checkedCounter = 0
        title = encodeURIComponent(title)
        results = searchResults.config().load({query: "?q=title:%22#{title}%22%20type:page"})
        @regions.results.show(new AddPageSearchResultsView({model: results}))

    initializeValidations: () ->
      @validations =
        addPage:
          hasError: false
          check: @_canAddPage
          show: @_showAddPageError
          hide: @_hideAddPageError
        searchTitle:
          hasError: false
          check: @_isSearchTitleValid
          show: @_showSearchTitleError
          hide: @_hideSearchTitleError

      validate = (title...) ->
        if @check.apply(arguments)
          if @hasError
            @hide()
        else if not @hasError
          @show()

        not @hasError

      @validations.addPage.validate = validate
      @validations.searchTitle.validate = validate

      # Returns validate function that validates both search title and add page
      (title...) ->
        @validations.searchTitle.validate(title)
        @validations.addPage.validate()

        not (@validations.searchTitle.hasError and @validations.addPage.hasError)

    _isSearchTitleValid: (title) =>
      title = if title then title else @$el.find('.page-title').val()
      title.trim().length > 0

    _canAddPage: () =>
      (@_checkedCounter > 0) or @validations.searchTitle.check()

    _showSearchTitleError: () =>
      @validations.searchTitle.hasError = true
      @$el.find('.page-title').parents('.form-group').addClass('has-error')
      @$el.find('.search-pages').attr('disabled', true).addClass('btn-danger')
      @$el.find('.page-title').parents('.form-group').find('.help-block').removeClass('hide')

    _hideSearchTitleError: () =>
      @validations.searchTitle.hasError = false
      @$el.find('.page-title').parents('.form-group').removeClass('has-error')
      @$el.find('.search-pages').attr('disabled', false).removeClass('btn-danger')
      @$el.find('.page-title').parents('.form-group').find('.help-block').addClass('hide')

    _hideAddPageError: () =>
      @validations.addPage.hasError = false
      @$el.find('.btn-submit').attr('disabled', false).removeClass('btn-danger')
      @$el.find('.page-title').parents('.form-group').removeClass('has-error')
      @$el.find('.modal-footer').removeClass('has-error').find('.help-block').addClass('hide')

    _showAddPageError: () =>
      @validations.addPage.hasError = true
      @$el.find('.btn-submit').attr('disabled', true).addClass('btn-danger')
      @$el.find('.page-title').parents('.form-group').addClass('has-error')
      @$el.find('.modal-footer').addClass('has-error').find('.help-block').removeClass('hide')

    updateUrl: () ->
      # Update the url bar path
      href = linksHelper.getPath 'contents',
        model: @model
        page: @model.getPageNumber()
      router.navigate(href, {trigger: false, analytics: true})

    onSubmit: (e) ->
      e.preventDefault()

      data = $(e.originalEvent.target).serializeArray()

      if @validations.searchTitle.hasError
        @validations.searchTitle.hide()

      if not @validations.addPage.validate()
        return

      @$el.modal('hide')

      if data.length is 1
        @newPage(data[0].value)
      else
        _.each data, (input) =>
          if input.name isnt 'title'
            @model.add({id: input.name, title: input.value})
            @model.setPage(input.name)
            @updateUrl()

      $('.modal-backdrop').remove() # HACK: Ensure bootstrap modal backdrop is removed

    newPage: (title) ->
      options =
        success: (model) =>
          @model.setPage(model)
          @updateUrl()

      @model.create({title: title}, options)
