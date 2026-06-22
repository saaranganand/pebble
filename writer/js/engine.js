var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
import { lua_evaluate, lua_interpolate } from "./lua_parser.js";
const html_content = document.getElementById("content");
export class NarrativeEngine {
    constructor() {
        this.nodes = new Map();
        this.current_file = "";
        this.progress = {
            node_choices: [],
            choice_group_index: 0,
            node_choice_index: 0,
            nodes: [],
            node_index: 0,
        };
    }
    init() {
        return __awaiter(this, void 0, void 0, function* () {
            // The manifest is a file that points to all active story YAML
            const manifest = yield fetch("./nodes/manifest.yaml")
                .then(r => r.text())
                .then(t => jsyaml.load(t));
            const nodes = (yield Promise.all(manifest.map((f) => fetch(`./nodes/${f}`)
                .then(r => r.text())
                .then(t => {
                const loaded = jsyaml.load(t);
                return loaded.map(node => (Object.assign(Object.assign({}, node), { file_name: f })));
            })))).flat();
            for (const node of nodes) {
                this.nodes.set(node.id, node);
            }
        });
    }
    start(id) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.loadNode(id);
        });
    }
    loadNode(id) {
        return __awaiter(this, void 0, void 0, function* () {
            const node = this.nodes.get(id);
            if (!node) {
                console.error(`Node not found: "${id}"`);
                return;
            }
            if (this.progress.node_index === this.progress.nodes.length) {
                this.progress.nodes.push(id);
                this.progress.node_choices.push([]);
            }
            this.progress.node_choice_index = 0;
            console.log(state.temporary_choices);
            if (this.current_file != node.file_name) {
                state.temporary_choices = [];
            }
            this.current_file = node.file_name;
            html_content.innerHTML = "";
            for (const item of node.items) {
                if (item.type === "choice") {
                    // We await choices to delay rendering of results
                    // call_anims is called in here, so we dont have to worry about the await not animating things
                    yield this.renderChoice(item.choice_id, item.options);
                }
                else if (item.type === "quote") {
                    this.renderQuote(item);
                }
                else {
                    this.renderItem(item);
                }
            }
            call_anims();
            this.renderNext(node);
        });
    }
    renderNext(node) {
        if (this.progress.node_index > 0) {
            const back_btn = document.createElement("button");
            back_btn.className = "back_btn";
            back_btn.textContent = "Back";
            back_btn.onclick = () => __awaiter(this, void 0, void 0, function* () {
                back_btn.disabled = true;
                //await this.advance(node)
                this.progress.node_index -= 1;
                this.progress.choice_group_index -= 1;
                yield this.loadNode(this.progress.nodes[this.progress.node_index]);
            });
            html_content.appendChild(back_btn);
        }
        // Display if the chain has reached the end
        if (!node.next) {
            const end = document.createElement("p");
            end.className = "end-marker";
            end.textContent = "[end]";
            html_content.appendChild(end);
            return;
        }
        // otherwise, we use this button to travel to the next node
        const btn = document.createElement("button");
        btn.className = "next_button";
        btn.textContent = "Next";
        btn.onclick = () => __awaiter(this, void 0, void 0, function* () {
            btn.disabled = true;
            this.progress.node_index += 1;
            this.progress.choice_group_index += 1;
            yield this.advance(node);
        });
        html_content.appendChild(btn);
    }
    renderItem(item) {
        // Quotes are done with blockquote items.
        // Subject to change
        const el = document.createElement("pre");
        el.innerHTML = lua_interpolate(item.content);
        el.className = "para";
        if (item.character) {
            el.classList.add(`quote_${item.character}_font`);
        }
        html_content.appendChild(el);
    }
    renderQuote(item) {
        const container = document.createElement("div");
        container.className = "quote";
        const el = document.createElement("pre");
        el.innerHTML = lua_interpolate(item.content);
        el.classList.add(`quote_${item.character}_font`);
        container.appendChild(quote_portait_element(item));
        const divider = document.createElement("div");
        divider.className = "quote_divider";
        container.appendChild(divider);
        container.appendChild(el);
        html_content.appendChild(container);
    }
    renderChoice(choice_id, options) {
        return new Promise(resolve => {
            const container = document.createElement("div");
            container.className = "choices";
            for (const option of options) {
                if (option.condition && !lua_evaluate(option.condition))
                    continue;
                const btn = document.createElement("button");
                // we are replaying
                if (this.progress.node_index != this.progress.node_choices.length - 1) {
                    if (this.progress.node_choices[this.progress.choice_group_index][this.progress.node_choice_index] === option.id) {
                        if (!state.temporary_choices.includes(option.id))
                            state.temporary_choices.push(option.id);
                        this.progress.node_choice_index += 1;
                        resolve();
                    }
                    btn.disabled = true;
                }
                if (option.character) {
                    btn.classList.add(`quote_${option.character}_font`);
                }
                //btn.textContent = option.label
                btn.innerHTML = option.label;
                btn.onclick = () => {
                    state.temporary_choices.push(option.id);
                    state.persistent_choices[choice_id] = option.id;
                    this.progress.node_choices[this.progress.choice_group_index].push(option.id);
                    if (option.mutations) {
                        apply_state_mutations(option.mutations);
                    }
                    container.querySelectorAll("button").forEach(b => b.disabled = true);
                    resolve();
                };
                container.appendChild(btn);
            }
            html_content.appendChild(container);
            call_anims();
        });
    }
    advance(node) {
        return __awaiter(this, void 0, void 0, function* () {
            for (const rule of node.next) {
                if (!rule.condition || lua_evaluate(rule.condition)) {
                    yield this.loadNode(rule.id);
                    return;
                }
            }
            // no rule matched means end or missing fallback
            const end = document.createElement("p");
            end.className = "end-marker";
            end.textContent = "[end]";
            html_content.appendChild(end);
        });
    }
}
