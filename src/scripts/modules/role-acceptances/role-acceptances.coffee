define (require) ->
  $ = require('jquery')
  _ = require('underscore')
  settings = require('settings')
  BaseView = require('cs!helpers/backbone/views/base')
  RoleAcceptances = require('cs!models/role-acceptances')
  template = require('hbs!./role-acceptances-template')
  require('less!./role-acceptances')

  AUTHORING = "#{location.protocol}//#{settings.cnxauthoring.host}:#{settings.cnxauthoring.port}"

  return  class RoleAcceptanceView extends BaseView
    template: template
    pageTitle: 'Role Acceptance'

    templateHelpers:
      licenseRequired: () -> @licenseRequired()
      id: () -> @model.contentId

    events:
      'submit form': 'onSubmit'
      'click .accept': 'acceptRole'
      'click .reject': 'rejectRole'
      'change .license-accept': 'toggleLicense'

    initialize: () ->
      id = location.pathname.replace('/users/role-acceptance/', '')
      @model = new RoleAcceptances({id: id})
      @listenTo(@model, 'change:roles', @render)
      @listenTo(@model, 'change:roles', @disableOrEnableSubmit)

    acceptRole: (e) ->
      role = @model.get('roles')[$(e.currentTarget).data('role')]
      if role.hasAccepted is true then role.hasAccepted = null else role.hasAccepted = true
      @render()
      @disableOrEnableSubmit()

    rejectRole: (e) ->
      role = @model.get('roles')[$(e.currentTarget).data('role')]
      if role.hasAccepted is false then role.hasAccepted = null else role.hasAccepted = false
      @render()
      @disableOrEnableSubmit()

    toggleLicense: (e) ->
      licenseAccepted = @$el.find('.license-accept').is(':checked')
      @model.set('license', licenseAccepted)

    onSubmit: (e) ->
      e.preventDefault()

      $alert = @$el.find('.alert')
      licenseAccepted = @$el.find('.license-accept').is(':checked')

      @model.set('license', licenseAccepted)

      $alert.get(0).className = 'alert hidden'

      if licenseAccepted or not @licenseRequired()
        @model.save()
        .error () ->
          $alert.addClass('alert-danger')
          .html('<strong>Error.</strong> Your changes have not been saved.').removeClass('hidden')
        .success () ->
          $alert.addClass('alert-success')
          .html('<strong>Success.</strong> Your new role settings have been saved.').removeClass('hidden')

      else
        alert('You must accept the license')

    licenseRequired: () -> !!_.findWhere(@model.get('roles'), {hasAccepted: true})

    disableOrEnableSubmit: () ->
      submit = @$el.find('.submit')
      roles = @model.get('roles')
      role = _.pluck(roles, 'hasAccepted')
      if _.contains(role, null)
        submit.prop('disabled', true)
      else
        submit.prop('disabled', false)
