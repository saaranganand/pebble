type LuaValue = number | string | string[] | Record<string, string>

interface State {
    numeric: Record<string, number>,
    boolean: Record<string, boolean>,
    string: Record<string, string>,

    // choice records
    persistent_choices: Record<string, string>,
    temporary_choices: string[],
}

var state: State
function default_state() {
    state = {
        numeric: {},
        boolean: {},
        string: {},
        persistent_choices: {},
        temporary_choices: [],
    }
}

// A mutation object is just a defined operation on the state
interface Mutation {
    key: string
    op: 'add' | 'toggle' | 'set_number' | 'set_bool' | 'set_string'
    value: any
}

function apply_state_mutations(mutations: Mutation[]) {
    for (const m of mutations) {
        switch (m.op) {
        case 'set_number':
            state.numeric[m.key] = m.value
            break
        case 'set_bool':
            state.boolean[m.key] = m.value
            break
        case 'set_string':
            state.string[m.key] = m.value
            break
        case 'add':
            state.numeric[m.key] = (state.numeric[m.key] ?? 0) + m.value
            break
        case 'toggle':
            state.boolean[m.key] = !(state.numeric[m.key] ?? false)
            break
        }
    }
}