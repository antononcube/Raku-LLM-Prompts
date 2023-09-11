unit module LLM::Prompts::DSL;

use LLM::Prompts::Grammarish;
use LLM::Prompts::Actionish;

grammar PromptsDSL does LLM::Prompts::Grammarish {
    rule TOP { <prompt>  }
}

class PromptsArray does LLM::Prompts::Actionish {
    method TOP($/) { make $<prompt>.made; }
}

#| Parse specs of prompt functions, modifiers, and personas
our sub llm-prompts-parse(Str $spec) is export {
    return PromptsDSL.parse($spec);
}

#| Sub-parse specs of prompt functions, modifiers, and personas
our sub llm-prompts-subparse(Str $spec) is export {
    return PromptsDSL.subparse($spec);
}

#| Interpret prompt functions, modifiers, and personas
our sub llm-prompts-interpret(Str $spec) is export {
    return PromptsDSL.parse($spec, actions => PromptsArray.new).made;
}
