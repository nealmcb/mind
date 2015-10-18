class share.UpvotableItemComponent extends UIComponent
  onCreated: ->
    super

    @canUpvote = new ComputedField =>
      Meteor.userId() and @data() and Meteor.userId() isnt @data().author._id and Meteor.userId() not in _.pluck(_.pluck(@data().upvotes or [], 'author'), '_id')

    @canRemoveUpvote = new ComputedField =>
      Meteor.userId() and @data() and Meteor.userId() isnt @data().author._id and Meteor.userId() in _.pluck(_.pluck(@data().upvotes or [], 'author'), '_id')

  events: ->
    super.concat
      'click .upvote': @onUpvote
      'click .remove-upvote': @onRemoveUpvote

  methodPrefix: ->
    throw new Error "Not implemented"

  onUpvote: (event) ->
    event.preventDefault()

    Meteor.call "#{@methodPrefix()}.upvote", @data()._id, (error, result) =>
      console.error "Upvote error", error if error

  onRemoveUpvote: (event) ->
    event.preventDefault()

    Meteor.call "#{@methodPrefix()}.removeUpvote", @data()._id, (error, result) =>
      return console.error "Remove upvote error", error if error
