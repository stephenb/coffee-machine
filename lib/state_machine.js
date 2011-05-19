(function() {
  var StateMachine, root;
  var __hasProp = Object.prototype.hasOwnProperty, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  root = typeof exports !== "undefined" && exports !== null ? exports : window;
  root.StateMachine = StateMachine = (function() {
    function StateMachine(stateMachine) {
      this.stateMachine = stateMachine != null ? stateMachine : {
        states: {},
        events: {}
      };
      this.defineStateMachine(this.stateMachine);
    }
    StateMachine.prototype.defineStateMachine = function(stateMachine) {
      var activeStates, event, eventDef, state, stateDef, states, _i, _j, _len, _len2, _ref, _ref2, _results;
      this.stateMachine = stateMachine != null ? stateMachine : {
        states: {},
        events: {}
      };
      if (this.stateMachine.states.constructor.toString().indexOf('Array') !== -1) {
        states = this.stateMachine.states;
        this.stateMachine.states = {};
        for (_i = 0, _len = states.length; _i < _len; _i++) {
          state = states[_i];
          this.stateMachine.states[state] = {
            active: state === states[0]
          };
        }
      }
      activeStates = (function() {
        var _ref, _results;
        _ref = this.stateMachine.states;
        _results = [];
        for (state in _ref) {
          if (!__hasProp.call(_ref, state)) continue;
          stateDef = _ref[state];
          if (stateDef.active) {
            _results.push(state);
          }
        }
        return _results;
      }).call(this);
      if (activeStates.length === 0) {
        _ref = this.stateMachine.states;
        for (state in _ref) {
          if (!__hasProp.call(_ref, state)) continue;
          stateDef = _ref[state];
          stateDef.active = true;
          break;
        }
      } else if (activeStates.length > 1) {
        for (_j = 0, _len2 = activeStates.length; _j < _len2; _j++) {
          state = activeStates[_j];
          if (state === activeStates[0]) {
            continue;
          }
          stateDef.active = false;
        }
      }
      _ref2 = this.stateMachine.events;
      _results = [];
      for (event in _ref2) {
        eventDef = _ref2[event];
        _results.push(__bind(function(event, eventDef) {
          return this[event] = function() {
            return this.changeState(eventDef.from, eventDef.to, event);
          };
        }, this)(event, eventDef));
      }
      return _results;
    };
    StateMachine.prototype.currentState = function() {
      var state, stateDef;
      return ((function() {
        var _ref, _results;
        _ref = this.stateMachine.states;
        _results = [];
        for (state in _ref) {
          if (!__hasProp.call(_ref, state)) continue;
          stateDef = _ref[state];
          if (stateDef.active) {
            _results.push(state);
          }
        }
        return _results;
      }).call(this))[0];
    };
    StateMachine.prototype.availableStates = function() {
      var state, _ref, _results;
      _ref = this.stateMachine.states;
      _results = [];
      for (state in _ref) {
        if (!__hasProp.call(_ref, state)) continue;
        _results.push(state);
      }
      return _results;
    };
    StateMachine.prototype.availableEvents = function() {
      var event, _ref, _results;
      _ref = this.stateMachine.events;
      _results = [];
      for (event in _ref) {
        if (!__hasProp.call(_ref, event)) continue;
        _results.push(event);
      }
      return _results;
    };
    StateMachine.prototype.changeState = function(from, to, event) {
      var args, enterMethod, exitMethod, fromStateDef, guardMethod, toStateDef;
      if (event == null) {
        event = null;
      }
      if (from.constructor.toString().indexOf('Array') !== -1) {
        if (from.indexOf(this.currentState()) !== -1) {
          from = this.currentState();
        } else {
          throw "Cannot change from states " + (from.join(' or ')) + "; none are the active state!";
        }
      }
      fromStateDef = this.stateMachine.states[from];
      toStateDef = this.stateMachine.states[to];
      if (toStateDef === void 0) {
        throw "Cannot change to state '" + to + "'; it is undefined!";
      }
      enterMethod = toStateDef.onEnter, guardMethod = toStateDef.guard;
      if (from !== 'any') {
        if (fromStateDef === void 0) {
          throw "Cannot change from state '" + from + "'; it is undefined!";
        }
        if (fromStateDef.active !== true) {
          throw "Cannot change from state '" + from + "'; it is not the active state!";
        }
      }
      if (from === 'any') {
        fromStateDef = this.stateMachine.states[this.currentState()];
      }
      exitMethod = fromStateDef.onExit;
      args = {
        from: from,
        to: to,
        event: event
      };
      if (guardMethod !== void 0 && guardMethod.call(this, args) === false) {
        return false;
      }
      if (exitMethod !== void 0) {
        exitMethod.call(this, args);
      }
      if (enterMethod !== void 0) {
        enterMethod.call(this, args);
      }
      if (this.stateMachine.onStateChange !== void 0) {
        this.stateMachine.onStateChange.call(this, args);
      }
      fromStateDef.active = false;
      return toStateDef.active = true;
    };
    return StateMachine;
  })();
}).call(this);
