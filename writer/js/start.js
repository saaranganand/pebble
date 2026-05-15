var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
import { NarrativeEngine } from './engine.js';
import { lua_add_helpers } from "./lua_parser.js";
(() => __awaiter(void 0, void 0, void 0, function* () {
    lua_add_helpers();
    default_state();
    const engine = new NarrativeEngine();
    yield engine.init();
    yield engine.start('intro');
}))();
