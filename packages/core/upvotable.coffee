class share.UpvotableDocument extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity on the comment
  # author:
  #   _id
  #   username
  #   avatar
  # discussion:
  #   _id
  # body: the latest version of the body
  # bodyAttachments: list of
  #   _id
  # bodyMentions: list of
  #   _id
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #     avatar
  #   body
  # upvotes: list of
  #   createdAt: timestamp of the upvote
  #   author: author of the upvote
  #     _id
  # upvotesCount

  @Meta
    abstract: true
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      discussion: @ReferenceField Discussion
      changes: [
        author: @ReferenceField User, User.REFERENCE_FIELDS(), false
      ]
      upvotes: [
        author: @ReferenceField User
      ]
      bodyAttachments: [
        @ReferenceField StorageFile
      ]
      bodyMentions: [
        @ReferenceField User
      ]
    generators: =>
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      body: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'body' of lastChange
        [fields._id, lastChange.body or '']
      bodyAttachments: [
        @GeneratedField 'self', ['body'], (fields) =>
          return [fields._id, []] unless fields.body
          [fields._id, ({_id} for _id in @extractAttachments fields.body)]
      ]
      bodyMentions: [
        @GeneratedField 'self', ['body'], (fields) =>
          return [fields._id, []] unless fields.body
          [fields._id, ({_id} for _id in @extractMentions fields.body)]
      ]
      upvotesCount: @GeneratedField 'self', ['upvotes'], (fields) =>
        [fields._id, fields.upvotes?.length or 0]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['changes']
      lastActivity: share.LastActivityTrigger ['upvotes']
      followMentionedUsers: share.MentionsTrigger 'bodyMentions', 'discussion._id', 'author'

  @PUBLISH_FIELDS: ->
    _.extend super,
      _id: 1
      createdAt: 1
      updatedAt: 1
      lastActivity: 1
      author: 1
      discussion: 1
      body: 1
      upvotesCount: 1
      upvotes:
        # We publish only an entry associated with the current user.
        $elemMatch:
          'author._id': Meteor.userId()
