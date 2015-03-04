React = require 'react/addons'
moment = require 'moment'


module.exports =
ActivityBarLongPollItem = React.createClass
  displayName: 'ActivityBarLongPollItem'

  getInitialState: ->
    expanded: false

  render: ->
    if @state.expanded
      payload = JSON.stringify(@props.item)
    else
      payload = []

    itemId = @props.item.id
    itemVersion = @props.item.version || @props.item.attributes?.version
    itemId += " (version #{itemVersion})" if itemVersion

    timestamp = moment(@props.item.timestamp).format("h:mm:ss")

    <div className={"item"} onClick={ => @setState expanded: not @state?.expanded}>
      <div className="cursor">{@props.item.cursor}</div>
      {" #{timestamp}: #{@props.item.event} #{@props.item.object} #{itemId}"}
      <div className="payload" onClick={ (e) -> e.stopPropagation() }>
        {payload}
      </div>
    </div>
