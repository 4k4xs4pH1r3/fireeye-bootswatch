define (require) ->

    Backbone = require 'backbone'
    Marionette = require 'marionette'
    vent = require 'uac/common/vent'

    templates = require 'alerts/ejs/templates'

    # Debug
    vent.on 'all', (event_name) ->
        console.debug "Event: #{event_name}"


    AlertsBreadcrumbView = require 'alerts/views/AlertsBreadcrumbView'
    AlertsSearchView = require 'alerts/views/AlertsSearchView'

    AlertsSummaryCollection = require 'alerts/models/AlertSummaryCollection'
    AlertsSummaryTableView = require 'alerts/views/AlertsSummaryTableView'
    AlertsSummaryListView = require 'alerts/views/AlertsSummaryListView'


    #
    # Layout for displaying the main alert template.
    #
    class AlertsLayout extends Backbone.Marionette.Layout
        template: templates['alerts-layout.ejs'],
        regions:
            breadcrumbs_region: '#alerts-breadcrumbs'
            filters_region: '#alerts-filters'
            filters_content_region: '#alerts-filters-content'
            list_region: '#alerts-lists'
            summary_list_region: '#alerts-summary-list'
            details_list_region: '#alerts-details-list'
            details_region: '#alert-details'
            details_content_region: '#alert-details-content'

        #
        # Listen to global events and show and hide regions accordingly.
        #
        initialize: ->
            vent.on 'alerts:search', =>
                @show_alerts_selection()

            vent.on 'alerts:select_alert', =>
                @show_alerts_details()

            vent.on 'breadcrumb:alerts_filters', =>
                @show_alerts_filters()

            vent.on 'breadcrumb:alerts_selection', =>
                @show_alerts_selection()

            vent.on 'breadcrumb:alerts_details', =>
                @show_alerts_details()

        #
        # Bring the alerts filters to focus.
        #
        show_alerts_filters: ->
            $(@list_region.el).fadeOut(0).hide()
            $(@details_region.el).fadeOut(0).hide()
            $(@filters_region.el).fadeIn('slow').show()

        #
        # Bring the alerts selection lists to focus.
        #
        show_alerts_selection: ->
            $(@filters_region.el).fadeOut(0).hide()
            $(@details_region.el).fadeOut(0).hide()
            $(@list_region.el).fadeIn('slow').show()

        #
        # Bring the alerts details into focus.
        #
        show_alerts_details: ->
            $(@filters_region.el).fadeOut(0).hide()
            $(@list_region.el).fadeOut(0).hide()
            $(@details_region.el).fadeIn('slow').show()


    #
    # Alerts application instance.
    #
    AlertsApp = new Backbone.Marionette.Application()

    #
    # The main region.
    #
    AlertsApp.addRegions
        content_region: '#content'

    #
    # Initialize the alerts application.
    #
    AlertsApp.addInitializer ->
        # Create and display the main page layout.
        @layout = new AlertsLayout()
        @content_region.show @layout

        # Show/hide the default regions.
        @layout.show_alerts_filters()

        # Create the breadcrumbs view.
        @breadcrumbs_view = new AlertsBreadcrumbView()
        @layout.breadcrumbs_region.show @breadcrumbs_view

        # Create the filters view.
        @filters_view = new AlertsSearchView()
        @layout.filters_content_region.show @filters_view

        # Handle searching for alerts summaries.
        vent.on 'alerts:search', (params) =>
            # Create the summary list table.
            unless @summary_list_view
                @alerts_summary_collection = new AlertsSummaryCollection()
                @summary_list_view = new AlertsSummaryTableView
                    id: 'alerts-summary-table'
                    collection: @alerts_summary_collection
                @layout.summary_list_region.show @summary_list_view

            # Fetch the summary list data.
            data = {}
            data.tag = params.tags if params.tags
            data.client_uuid = params.clients if params.clients and params.clients.length > 0
            data.alert_type = params.types if params.types and params.types.length > 0
            data.begin = moment(params.from).unix() if params.from
            data.end = moment(params.to).unix() if params.to
            @alerts_summary_collection.fetch
                data: data


    # Export the alerts application.
    AlertsApp