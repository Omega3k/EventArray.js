if require? then b = require 'backwards' else b = window.backwards
throw new Error 'Could not find "backwards" module' if not b

forEach     = b.forEach
map         = b.map
indexOf     = b.indexOf

uid         = "__EventArrayHandlers-" + ( new Date() ).getTime()
doc         = window.document

returnTrue  = () -> true
returnFalse = () -> false
identity    = (x) -> x


either = (a, b, c) ->
  if c then a
  else b


fixEvent = (e) ->
  event = map identity, e

  # The event occurred on this element. 
  if not event.target
    event.target = event.srcElement or doc

  # Handle which other element the event is related to
  event.relatedTarget = either(
    event.toElement
    event.fromElement
    event.fromElement is event.target
    )

  # Stop the default browser action
  event.preventDefault = () ->
    event.returnValue        = false
    event.isDefaultPrevented = returnTrue
    undefined

  event.isDefaultPrevented = returnFalse

  # Stop the event from bubbling
  event.stopPropagation = () ->
    event.cancelBubble = true
    event.isPropagationStopped = returnTrue
    undefined

  event.isPropagationStopped = returnFalse

  # Stop the event from bubbling and executing other handlers
  event.stopImmediatePropagation = () ->
    @isImmediatePropagationStopped = returnTrue
    @.stopPropagation()
    undefined

  event.isImmediatePropagationStopped = returnFalse

  # Handle mouse position
  if event.clientX?
    doc  = doc.documentElement
    body = doc.body
    event.pageX = event.clientX + 
      ( doc and doc.scrollLeft or body and body.scrollLeft or 0 ) - 
      ( doc and doc.clientLeft or body and body.clientLeft or 0 )
    event.pageY = event.clientY + 
      ( doc and doc.scrollTop or body and body.scrollTop or 0 ) - 
      ( doc and doc.clientTop or body and body.clientTop or 0 )

  # Handle key presses
  event.which = event.charCode or event.keyCode

  # Fix button for mouse clicks
  # 0 is left
  # 1 is middle
  # 2 is right
  if event.button?
    if event.button and 1 then event.button = 0
    else if event.button and 4 then event.button = 1
    else if event.button and 2 then event.button = 2
    else event.button = 0

  event


addEventListener = (htmlElement, type, f) ->
  if htmlElement.addEventListener
    htmlElement.addEventListener type, f, false
  else
    htmlElement.attachEvent "on#{ type }", f


removeEventListener = (htmlElement, type, f) ->
  if htmlElement.removeEventListener
    htmlElement.removeEventListener type, f, false
  else
    htmlElement.detachEvent "on#{ type }", f


getEventArrayHandlers = (htmlElement, type) ->
  eventTypes = htmlElement[ uid ]
  eventTypes = htmlElement[ uid ] = {} if not eventTypes
  if not type
    handlers = eventTypes
  else
    handlers   = eventTypes[ type ]
    handlers   = eventTypes[ type ] = [] if not handlers
  handlers


removeEventArrayHandlers = (htmlElement, type) ->
  handlers = getEventArrayHandlers htmlElement, type
  return if not handlers
  try
    delete htmlElement[ uid ]
  catch error
    if htmlElement.removeAttribute
      htmlElement.removeAttribute uid
    else throw new Error error
  return


uberEventHandler = (e) ->
  e = fixEvent e or window.event if not e or not e.stopPropagation
  executeHandlers e, getEventArrayHandlers @, e.type


executeHandlers = (value, handlers) ->
  forEach (x) ->
    if x
      callback = x.callback
      children = x.children
      ctx      = x.ctx

      if callback
        x.value = callback.call ctx, value, x.iterations, ctx
      else x.value = value
      x.iterations++

      if children.length and x.value isnt undefined
        executeHandlers x.value, children
  , handlers


removeChild = (child) ->
  children = child.parent[ uid ].children
  index    = indexOf child, 0, children
  children.splice index, 1 if index > -1


class EventArray
  constructor: (type, htmlElement) ->
    if typeof type isnt 'string'
      children = type[ uid ].children
      parent   = type
      f        = htmlElement

    if typeof type is 'string'
      addEventListener htmlElement, type, uberEventHandler
      children = getEventArrayHandlers htmlElement, type
      parent   = htmlElement


    child =
      iterations: 0
      value     : null
      ctx       : @
      parent    : parent
      children  : []

    child.callback = f if f?
    children.push child
    @[ uid ] = children[ children.length - 1 ]

  map      : (f) -> new EventArray @, f
  filter   : (f) -> new EventArray @, __filterCallback f
  reduce   : (f, acc) -> new EventArray @, __reduceCallback f, acc
  publish  : (type, data) -> @
  subscribe: (f) -> new EventArray @, f

  unsubscribe: () ->
    removeChild @[ uid ]
    return undefined

  concat: (EventArrays...) ->
    @

  merge: @concat


__filterCallback = (f) ->
  (a, b, c) ->
    if f a, b, c then a
    else undefined


__reduceCallback = (f, acc) ->
  (a, b, c) ->
    acc = f acc, a, b, c
    acc


b.EventArray = EventArray

(( root, name, deps, f ) ->
  # Register as a named AMD module
  if define? and define.amd then define name, [], f
  # Register as a CommonJS-like module
  else if exports?
    if module? and module.exports then module.exports = f()
    else exports[name] = f()
  # Register as a global object on the window
  else window[name] = f()
  # else root[name] = f()
  return
)( this, 'EventArray', [], () -> EventArray )
