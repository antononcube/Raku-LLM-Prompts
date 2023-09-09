use v6.d;

use LLM::Prompts;

role LLM::Prompts::Actionish {
    method prompt($/) {
        my @res;

        @res.push($<prompt-persona-spec>.made) if $<prompt-persona-spec>;

        @res.push($<prompt-function-cell-spec>.made) if $<prompt-function-cell-spec>;

        with $<prompt-body> {
            @res.append($<prompt-body>.made);
        }

        make @res;
    }
    method prompt-persona-spec($/) {
        make llm-prompt($<name>.Str);
    }
    method prompt-body($/) {
        make $<prompt-body-elem>>>.made;
    }
    method prompt-body-elem($/) {
        make $/.values[0].made;
    }
    method prompt-function-spec($/) {
        my $p = llm-prompt($<name>.Str);

        my @args;

        with $<prompt-param-list> {
            @args = $<prompt-param-list>.made;
        }

        with $<cell-arg> {
            @args = [$<cell-arg>.Str,];
        }

        if $p ~~ Callable {
            if $p.count > @args.elems {
                @args.append('' xx ($p.count - @args.elems));
            }
            @args = @args.head($p.count);
            make $p.(|@args);
        } else {
            make $p;
        }
    }
    method prompt-function-cell-spec($/) {
        self.prompt-function-spec($/);
    }
    method prompt-modifier-spec($/) {
        self.prompt-function-spec($/);
    }
    method prompt-word($/) {
        make $/.Str;
    }
    method prompt-ws($/) {
        make $/.Str;
    }
    method prompt-param-list($/) {
        make $<prompt-param>>>.made;
    }
    method prompt-param($/) {
        make $/.values[0].made;
    }
    method prompt-param-simple($/) {
        make $/.Str
    }
    method prompt-param-quoted($/) {
        make $<pval>.Str;
    }
}