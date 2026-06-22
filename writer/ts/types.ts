declare const jsyaml: {
    load(str: string): unknown,
    dump(obj: unknown): string,
}

// Choices have option conditions, so that certain choices are only available in certain scenarios
interface ChoiceOption {
    id: string,
    label: string,
    condition?: string,
    character?: string,
    mutations: Mutation[],
}

type ContentType = 'paragraph' | 'quote' | 'choice';

interface Item {
    type: ContentType,
    content?: string, // for paragraphs, quote
    character?: string,
    known?: boolean,
    hidden?: boolean,
    alternate?: string, // for character emotions
    choice_id?: string,
    options?: ChoiceOption[],
}

// condition is optional so that a rule can serve as a catch-all fallback
interface NextRule {
    condition?: string,
    id: string,
}
 
// A node is a collection of novel elements tied to an ID.
// The node is conditionally chosen, and groups together concurrent story events
interface Node {
    id: string,
    file_name: string,
    items: Item[],
    next: NextRule[],
}