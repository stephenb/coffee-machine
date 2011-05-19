vows   = require 'vows'
assert = require 'assert'
{StateMachine} = require '../src/state_machine'

vow = vows.describe('StateMachine')
vow.addBatch
  'State setup using an array':
    topic: new StateMachine {
      states: ['state1', 'state2', 'state3']
    }
    
    'should have available states': (topic) ->
      assert.deepEqual topic.availableStates(), ['state1', 'state2', 'state3']
      
    'currentState should be the 1st state': (topic) ->
      assert.equal topic.currentState(), 'state1'
      
    'changeState should work': (topic) ->
      topic.changeState('state1','state2')
      assert.equal topic.currentState(), 'state2'
      
    'changeState should throw error if trying to change from inactive state': (topic) ->
      try
        topic.changeState('state1','state3')
      catch error
        assert.equal topic.currentState(), 'state2'

vow.addBatch
  'State setup using full object':
    topic: new StateMachine
      states:
        state1:
          onEnter: -> 'onEnter state1'
          guard: -> 'guard state1'
        state2:
          onExit: -> 'onExit state2'
        state3:
          active: true
          onEnter: -> 'onEnter state3'
      events:
        event1:
          from: 'state1'
          to:   'state2'

    'should have available states': (topic) ->
      assert.deepEqual topic.availableStates(), ['state1', 'state2', 'state3']

    'currentState should be state3': (topic) ->
      assert.equal topic.currentState(), 'state3'

    'changeState should work': (topic) ->
      topic.changeState('state3','state2')
      assert.equal topic.currentState(), 'state2'

    'changeState should throw error if trying to change from inactive state': (topic) ->
      try
        topic.changeState('state1','state3')
      catch error
        assert.equal topic.currentState(), 'state2'

vow.addBatch
  'onExit':
    topic: ->
      new StateMachine
        states:
          state1: 
            onExit: -> throw 'onExitCalled'
          state2: {}
    
    'should be setup properly': (topic) ->
      assert.isFunction topic.stateMachine.states.state1.onExit
      
    'onExit should get called on state change': (topic) ->
      try
        topic.changeState('state1', 'state2')
      catch e
        assert.equal e, 'onExitCalled'
        
  'onEnter':
    topic: ->
      new StateMachine
        states:
          state1: {}
          state2:
            onEnter: -> throw 'onEnterCalled'

    'should be setup properly': (topic) ->
      assert.isFunction topic.stateMachine.states.state2.onEnter

    'onEnter should get called on state change': (topic) ->
      try
        topic.changeState('state1', 'state2')
      catch e
        assert.equal e, 'onEnterCalled'
        
  'guard':
    topic: ->
      new StateMachine
        states:
          state1: {}
          state2:
            guard: -> false

    'should be setup properly': (topic) ->
      assert.isFunction topic.stateMachine.states.state2.guard

    'state should not change when guard returns false': (topic) ->
      topic.changeState('state1', 'state2')
      assert.equal topic.currentState(), 'state1'

  'onStatechange':
    topic: ->
      new StateMachine
        states:
          state1: {}
          state2: {}
        onStateChange: -> throw 'onStateChangeCalled'

    'should be setup properly': (topic) ->
      assert.isFunction topic.stateMachine.onStateChange

    'onStateChange should get called on state change': (topic) ->
      try
        topic.changeState('state1', 'state2')
      catch e
        assert.equal e, 'onStateChangeCalled'
    
  'Callbacks should contain state and event info':
    topic: ->
      new StateMachine
        states:
          state1:
            onExit: (args) -> this.returnedArgs = args
          state2: {}
          state3:
            onEnter: (args) -> this.returnedArgs = args
          state4:
            guard: (args) -> this.returnedArgs = args
        events:
          state2to3: {from: 'state2', to: 'state3'}
            
    'onExit': (topic) ->
      topic.changeState('state1', 'state2')
      assert.equal topic.returnedArgs.from, 'state1'
      assert.equal topic.returnedArgs.to, 'state2'
    
    'onEnter': (topic) ->
      topic.state2to3()
      assert.equal topic.returnedArgs.from, 'state2'
      assert.equal topic.returnedArgs.to, 'state3'
      assert.equal topic.returnedArgs.event, 'state2to3'
    
    'guard': (topic) ->
      topic.changeState('state3', 'state4')
      assert.equal topic.returnedArgs.from, 'state3'
      assert.equal topic.returnedArgs.to, 'state4'
      assert.equal topic.returnedArgs.event, null
      
vow.addBatch
  'Events':
    topic: ->
      new StateMachine
        states: ['state1', 'state2', 'state3']
        events:
          state1to2: {from:'state1', to:'state2'}
          state2to1: {from:'state2', to:'state1'}
          anyToState3: {from:'any', to:'state3'}
          state2or3toState1: {from:['state2', 'state3'], to:'state1'}
    
    'should properly change state': (topic) ->
      topic.state1to2()
      assert.equal topic.currentState(), 'state2'
      topic.state2to1()
      assert.equal topic.currentState(), 'state1'
      
    'should not change state if the from is different than the defition': (topic) ->
      try
        topic.state2to1()
        assert.equal 1, 2  # hrmmm... don't know how to test the error well
      catch e
        assert.equal e, "Cannot change from state 'state2'; it is not the active state!"
    
    'should change from any state if "any" is the from key': (topic) ->
      assert.equal topic.currentState(), 'state1' # We're in state1
      topic.anyToState3()
      assert.equal topic.currentState(), 'state3' # should change to state3
      topic.changeState('state3', 'state2')
      assert.equal topic.currentState(), 'state2' # We're now in state2
      topic.anyToState3()
      assert.equal topic.currentState(), 'state3' # should change to state3
      
    'should support an array in the from key': (topic) ->
      assert.equal topic.currentState(), 'state3' # We're in state3
      topic.state2or3toState1()
      assert.equal topic.currentState(), 'state1'
      topic.state1to2()
      assert.equal topic.currentState(), 'state2' # We're in state2
      topic.state2or3toState1()
      assert.equal topic.currentState(), 'state1' # We're in state1
      try
        topic.state2or3toState1()
        assert.equal 1, 2  # hrmmm... don't know how to test the error well
      catch e
        assert.equal e, "Cannot change from states state2 or state3; none are the active state!"

exports.test_utils = vow