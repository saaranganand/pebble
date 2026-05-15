declare const fengari: any
const { lua, lauxlib, lualib, to_luastring } = fengari

const L = lauxlib.luaL_newstate()
lualib.luaL_openlibs(L)

function toJS(L: any): any {
    switch (lua.lua_type(L, -1)) {
        case lua.LUA_TNUMBER:  return lua.lua_tonumber(L, -1)
        case lua.LUA_TBOOLEAN: return lua.lua_toboolean(L, -1)
        case lua.LUA_TSTRING:  return lua.lua_tojsstring(L, -1)
        default:               return null
    }
}

function value_to_lua(v: LuaValue): string {
    if (Array.isArray(v))
        return `{${v.map(i => JSON.stringify(i)).join(', ')}}`
    if (typeof v === 'object')
        return `{${Object.entries(v).map(([k, val]) => `${k} = ${JSON.stringify(val)}`).join(', ')}}`
    return JSON.stringify(v)
}

function state_to_lua(): string {
    const entries = Object.entries(state)
        .map(([k, v]) => `  ${k} = ${value_to_lua(v)}`)
        .join(',\n')
    return `state = {\n${entries}\n}`
}

export function lua_add_helpers() {
    const helpers = `function contains(t, val)
        for _, v in ipairs(t) do
            if v == val then return true end
        end
        return false
    end`

    lauxlib.luaL_dostring(L, to_luastring(helpers))
}

export function lua_evaluate(expr: string): any {
    lauxlib.luaL_dostring(L, to_luastring(state_to_lua()))
    lauxlib.luaL_dostring(L, to_luastring(`return ${expr}`))

    return toJS(L)
}

// This one is for lua used within actual text.
// Implemented to make flavourful differences in dialouge feasible.
// For example if someone is calling the names of the characters present,
// And who is present is variable based on trivial or many choices,
// Then this is miles easier than creating a node for each and every possiblity
export function lua_interpolate(content: string): string {
    // regex hell
    return content.replace(/\{\{(.+?)\}\}/g, (_, expr) => {
        const result = lua_evaluate(expr.trim())

        if (result != null) return String(result)
        else return ""
    })
}