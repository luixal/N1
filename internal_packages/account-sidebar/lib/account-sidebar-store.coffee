Reflux = require 'reflux'
_ = require 'underscore-plus'
{DatabaseStore, NamespaceStore, Actions, Tag, Thread} = require 'inbox-exports'

AccountSidebarStore = Reflux.createStore
  init: ->
    @_setStoreDefaults()
    @_registerListeners()
    @_populate()


  ########### PUBLIC #####################################################

  sections: ->
    @_sections

  unreadCounts: ->
    @_unreadCounts

  selectedId: ->
    @_selectedId


  ########### PRIVATE ####################################################

  _setStoreDefaults: ->
    @_sections = []
    @_unreadCounts = {}
    @_selectedId = null

  _registerListeners: ->
    @listenTo Actions.selectTagId, @_onSelectTagID
    @listenTo DatabaseStore, @_onDataChanged
    @listenTo NamespaceStore, @_onNamespaceChanged

  _populate: ->
    namespace = NamespaceStore.current()
    return unless namespace

    DatabaseStore.findAll(Tag, namespaceId: namespace.id).then (tags) =>
      # Collect the built-in tags we want to display, and the user tags
      # (which can be identified by having non-hardcoded IDs)
      mainTagIDs = ['inbox', 'important', 'drafts', 'sent', 'archive', 'trash']
      mainTags = _.filter tags, (tag) -> _.contains(mainTagIDs, tag.id)
      userTags = _.filter tags, (tag) -> tag.name != tag.id

      # Sort the main tags so they always appear in a standard order
      mainTags = _.sortBy mainTags, (tag) -> mainTagIDs.indexOf(tag.id)

      @_sections = [
        { label: namespace.emailAddress, tags: mainTags }
      ]
      @_populateUnreadCounts()
      @trigger(@)

  _populateUnreadCounts: ->
    namespace = NamespaceStore.current()
    @_sections.forEach (section) =>
      section.tags.forEach (tag) =>
        # Some tags don't have unread counts
        return if tag.id in ['archive', 'drafts', 'sent', 'trash']

        DatabaseStore.count(Thread, [
          Thread.attributes.namespaceId.equal(namespace.id),
          Thread.attributes.unread.equal(true),
          Thread.attributes.tags.contains(tag.id),
        ]).then (count) =>
          @_unreadCounts[tag.id] = count
          @trigger(@)

  # Unfortunately, the joins necessary to compute unread counts are expensive.
  # Rather than update unread counts every time threads change in the database,
  # we debounce aggressively and update only after changes have stopped.
  # Remove this when JOIN query speed is fixed!
  _populateUnreadCountsDebounced: _.debounce ->
    @_populateUnreadCounts()
  , 750

  _refetchFromAPI: ->
    namespace = NamespaceStore.current()
    return unless namespace

    # Trigger a request to the API
    atom.inbox.getCollection(namespace.id, 'tags')

  # Inbound Events

  _onNamespaceChanged: ->
    @_refetchFromAPI()
    @_populate()

  _onDataChanged: (change) ->
    if change.objectClass == Tag.name
      @_populate()
    if change.objectClass == Thread.name
      @_populateUnreadCountsDebounced()

  _onSelectTagID: (tagID) ->
    @_selectedId = tagID
    @trigger(@)

module.exports = AccountSidebarStore