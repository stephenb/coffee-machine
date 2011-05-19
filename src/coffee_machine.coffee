root = exports ? window

# new CoffeeMachine
#   states:
#     stateName: 
#       active:  true/false (optional, the 1st state defaults to true)
#       onEnter: enterMethod (called when successfully entering the state)
#       onExit:  exitMethod (called when successfully exiting the state)
#       guard:   guardMethod (stops the change to this state if returns false)
#   events:
#     eventName:
#       from: fromState (should be a defined state, array of defined states, or "any")
#       to:   toState (should be a defined state)
#   onStateChange: changeMethod (called on any state change)
#
root.CoffeeMachine = class CoffeeMachine

  constructor: (@stateMachine = {states:{}, events:{}}) ->
    this.defineStateMachine(@stateMachine)
  
  defineStateMachine: (@stateMachine = {states:{}, events:{}}) ->
    # If array setup was used, translate it into the object setup
    if @stateMachine.states.constructor.toString().indexOf('Array') isnt -1
      states = @stateMachine.states
      @stateMachine.states = {}
      for state in states
        @stateMachine.states[state] = { active: (state is states[0]) }
    # Make sure an active state is properly set
    activeStates = (state for own state, stateDef of @stateMachine.states when stateDef.active)
    if activeStates.length is 0
      # Set the 1st state to active
      for own state, stateDef of @stateMachine.states
        stateDef.active = true
        break
    else if activeStates.length > 1
      # Set only the 1st active state to active
      for own state in activeStates
        continue if state is activeStates[0]
        stateDef.active = false
    # Define the event methods
    for event, eventDef of @stateMachine.events
      do(event, eventDef) =>
        this[event] = -> this.changeState(eventDef.from, eventDef.to, event)
  
  currentState: ->
    (state for own state, stateDef of @stateMachine.states when stateDef.active)[0]

  availableStates: ->
    state for own state of @stateMachine.states
    
  availableEvents: ->
    event for own event of @stateMachine.events
    
  changeState: (from, to, event=null) ->
    # If from is an array, and it contains the currentState, set from to currentState
    if from.constructor.toString().indexOf('Array') isnt -1
      if from.indexOf(this.currentState()) isnt -1
        from = this.currentState()
      else
        throw "Cannot change from states #{from.join(' or ')}; none are the active state!"
    # If using 'any', then set the from to whatever the current state is
    if from is 'any' then from = this.currentState()
    
    fromStateDef = @stateMachine.states[from]
    toStateDef = @stateMachine.states[to]
    
    throw "Cannot change to state '#{to}'; it is undefined!" if toStateDef is undefined
    throw "Cannot change from state '#{from}'; it is undefined!" if fromStateDef is undefined
    throw "Cannot change from state '#{from}'; it is not the active state!" if fromStateDef.active isnt true
    
    {onEnter: enterMethod, guard: guardMethod} = toStateDef
    {onExit: exitMethod} = fromStateDef
    
    args = {from: from, to: to, event: event}
    return false if guardMethod isnt undefined and guardMethod.call(this, args) is false
    exitMethod.call(this, args) if exitMethod isnt undefined
    enterMethod.call(this, args) if enterMethod isnt undefined
    @stateMachine.onStateChange.call(this, args) if @stateMachine.onStateChange isnt undefined
    fromStateDef.active = false
    toStateDef.active = true
    