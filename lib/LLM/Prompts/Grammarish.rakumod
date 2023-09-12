role LLM::Prompts::Grammarish {
    rule prompt { <prompt-persona-spec> <prompt-body>? || <prompt-function-cell-spec> || <prompt-body> }
    rule prompt-body { <prompt-body-elem>+ }
    rule prompt-body-elem {
        || <prompt-function-spec>
        || <prompt-modifier-spec>
        || <prompt-word> }
    token prompt-persona-spec {
        '@' $<name>=(<.alnum>+) <prompt-param-list>?
    }
    token prompt-function-spec {
        ['!' | '&'] $<name>=(<.alnum>+) <prompt-param-list>?
    }
    token prompt-function-cell-spec {
        ^ \s* ['!' | '&'] $<name>=(<.alnum>+) <prompt-param-list>? [ [\h+ | '>']? $<cell-arg>=(.+)]?
    }
    token prompt-function-prior-spec {
        ^ \s* ['!' | '&'] $<name>=(<.alnum>+) $<pointer>=('^'+) \h* $
    }
    token prompt-modifier-spec {
        '#' $<name>=(<.alnum>+) <prompt-param-list>?
    }
    token prompt-word { \S+ }
    token prompt-ws { \s+ }
    token prompt-param-list {
        '|' <prompt-param>+ % '|'?
    }
    token prompt-param {
        || <prompt-param-quoted>
        || <prompt-param-simple>
    }
    token prompt-param-simple { \S+ { make $/.Str } }
    token prompt-param-quoted {
        || '\'' ~ '\'' $<pval>=<-[']>* { make $<pval>.Str }
        || '"' ~ '"' $<pval>=<-["]>*  { make $<pval>.Str }
    }
}