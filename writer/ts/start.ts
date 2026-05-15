import { NarrativeEngine } from './engine.js'
import { lua_add_helpers } from "./lua_parser.js"


(async () => {
    lua_add_helpers()
    default_state()

    const engine = new NarrativeEngine()
    await engine.init()
    await engine.start('intro')
})()