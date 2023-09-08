use v6.d;

use LLM::Prompts;

role LLM::Prompts::Grammarish {
    rule prompt { <prompt-persona-spec> <prompt-body>? | <prompt-body> }
    rule prompt-body { <prompt-body-elem>+ }
    rule prompt-body-elem {
        || <prompt-function-spec>
        || <prompt-modifier-spec>
        || <prompt-word> }
    token prompt-persona-spec {
        '@' $<name>=(<.alnum>+) <?{ so llm-prompt($<name>.Str) }>
    }
    token prompt-function-spec {
        '!' $<name>=(<.alnum>*) <?{ so llm-prompt($<name>.Str) }> <prompt-param-list>?
    }
    token prompt-modifier-spec {
        '#' $<name>=(<.alnum>*) <?{ so llm-prompt($<name>.Str) }> <prompt-param-list>?
    }
    token prompt-word { \S+ }
    token prompt-ws { \s+ }
    token prompt-param-list {
        '|' <prompt-param>+ % '|'?
    }
    token prompt-param {
        || <prompt-param-simple>
        || <prompt-param-quoted>
    }
    token prompt-param-simple { \S+ { make $/.Str } }
    token prompt-param-quoted {
        || '\'' ~ '\'' $<pval>=<-[']>* { make $<pval>.Str }
        || '"' ~ '"' $<pval>=<-["]>*  { make $<pval>.Str }
    }
}