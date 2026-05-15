"use strict";
var state;
function default_state() {
    state = {
        numeric: {},
        boolean: {},
        string: {},
        persistent_choices: {},
        temporary_choices: [],
    };
}
function apply_state_mutations(mutations) {
    var _a, _b;
    for (const m of mutations) {
        switch (m.op) {
            case 'set_number':
                state.numeric[m.key] = m.value;
                break;
            case 'set_bool':
                state.boolean[m.key] = m.value;
                break;
            case 'set_string':
                state.string[m.key] = m.value;
                break;
            case 'add':
                state.numeric[m.key] = ((_a = state.numeric[m.key]) !== null && _a !== void 0 ? _a : 0) + m.value;
                break;
            case 'toggle':
                state.boolean[m.key] = !((_b = state.numeric[m.key]) !== null && _b !== void 0 ? _b : false);
                break;
        }
    }
}
