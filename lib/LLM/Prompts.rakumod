use v6.d;

unit module LLM::Prompts;

use JSON::Fast;

#-----------------------------------------------------------
my @records;
my @topics;
my @categories;

#-----------------------------------------------------------
#| Ingest the prompts database.
sub ingest-prompt-data() is export {
    # It is expected that resource file "prompts.json" is an array of hashes.
    @records = from-json(slurp(%?RESOURCES<prompts.json>)).List;

    @categories = @records.map({ $_<Categories>.keys }).flat.unique.sort;
    @topics = @records.map({ $_<Topics>.keys }).flat.unique.sort;

    @records .= map({
        $_<Categories> = $_<Categories>.grep(*.value)>>.key.List;
        $_<Topics> = $_<Topics>.grep(*.value)>>.key.List;
        $_
    });

    return %(:@records, :@categories, :@topics);
}


#-----------------------------------------------------------
sub llm-prompt-categories() is export {
    return @categories;
}

#-----------------------------------------------------------
sub llm-prompt-topics() is export {
    return @topics;
}

#-----------------------------------------------------------
#| Get the prompts database as hash with the keys being the prompt titles.
proto sub llm-prompt-data(-->Hash) is export {*}

multi sub llm-prompt-data(-->Hash) {
    if ! @records { ingest-prompt-data; }
    my %resPrompts = @records.map({ $_<Name> => $_.clone }).Hash;
    return %resPrompts;
}

#-----------------------------------------------------------
#| Get the prompts database as hash with the keys being the prompt titles.
proto sub llm-prompt-dataset(:f(:$functions) = Whatever,
                             :m(:$modifiers) = Whatever,
                             :p(:$personas) = Whatever,
                             Bool :c(:$compact) = False) is export {*}

multi sub llm-prompt-dataset(:f(:$functions) is copy = Whatever,
                             :m(:$modifiers) is copy = Whatever,
                             :p(:$personas) is copy = Whatever,
                             Bool :c(:$compact) = False) {

    #------------------------------------------------------
    # Process options

    if $functions.isa(Whatever) { $functions = False; }
    if $modifiers.isa(Whatever) { $modifiers = False; }
    if $personas.isa(Whatever) { $personas = False; }

    #------------------------------------------------------
    my @recs = llm-prompt-data.values;

    my @pivotCols = <Topics Categories Keywords PositionalArguments NamedArguments>;
    my $idCols = @recs.head.keys (-) @pivotCols;

    if $functions { @recs .= grep({ 'Function Prompts' ∈ $_<Categories>} ); }
    if $modifiers { @recs .= grep({ 'Modifier Prompts' ∈ $_<Categories>} ); }
    if $personas  { @recs .= grep({ 'Personas'         ∈ $_<Categories>} ); }

    if $compact {
        @recs .= map({ $_.grep({ $_.key ∈ <Name Description Categories> }).Hash }).sort(*<Name>).Array;
        return @recs;
    }

    my @res;
    for @recs -> %record {
        my %coreRec = %record.grep({ $_.key ∈ $idCols });
        for @pivotCols -> $pc {
            for |%record{$pc} -> $val {
                my %h = %coreRec , %(Variable => $pc, Value => $val);
                @res.push(%h);
            }
        }
    }

    return @res.sort(*<Name Variable Value>).Array;
}

#-----------------------------------------------------------
#| Create the prompt string or pure function for a given prompt name.
sub llm-prompt($name is copy, Bool :$warn = True) is export {

    my %ps = llm-prompt-data;

    if $name.isa(Whatever) {
        $name = %ps.keys.pick;
    }

    die "The first argument is expected to be a string or Whatever."
    unless $name ~~ Str:D;

    if %ps{$name}:exists {

        my %promptRecord = %ps{$name};
        my $code = %promptRecord<PromptText>;

        return do given (%promptRecord<PositionalArguments>.elems, %promptRecord<NamedArguments>.elems) {
            when (0, 0) { $code }
            default {
                # I am not happy with this solution,
                # but it is easy and simple.
                use MONKEY-SEE-NO-EVAL;
                EVAL $code;
            }
        }

    } else {
        note "Unknown prompt name: ⎡$name⎦." if $warn;
        return Nil;
    }
}

#-----------------------------------------------------------

#| Prompt parameters
my regex pmt-param-simple { $<param-simple>=([<.alpha> | '.' | '_' | '-']+)  }
my regex pmt-param-qouted { $<param-quoted>=('"' ~ '"' <-["]>+ || '\'' ~ '\'' <-[']>+ )  }
my regex pmt-param { $<param>=(<pmt-param-qouted> || <pmt-param-simple>)  }

#| Sequence of parameters
my regex pmt-list-of-params { <pmt-param>+ % '|' }

#| Persona
my regex pmt-persona { ^ '@' $<name>=(<.alnum>+) }

#| Modifier
my regex pmt-modifier { '#' $<name>=(<.alnum>+) [ '|' <pmt-list-of-params> '|'? ]? }

#| Function
my regex pmt-function { '!' $<name>=(<.alnum>+) [ '|' <pmt-list-of-params> '|'? ]? }

#| Any prompt
my regex pmt-any { <pmt-persona> || <pmt-function> || <pmt-modifier> }

#-----------------------------------------------------------
sub to-unquoted(Str $ss is copy) {
    if $ss ~~ / ^ '\'' (.*) '\'' $ / { return ~$0; }
    if $ss ~~ / ^ '"' (.*) '"' $ / { return ~$0; }
    if $ss ~~ / ^ '⎡' (.*) '⎦' $ / { return ~$0; }
    return $ss;
}

#-----------------------------------------------------------
sub prompt-function-spec($/) {
    my $m = $<pmt-persona> // $<pmt-function> // $<pmt-modifier>;
    my $p = llm-prompt($m<name>.Str);

    without $p {
        return $/.Str;
    }

    my @args ;

    with $m<pmt-list-of-params> {
        @args = $m<pmt-list-of-params>.Str.split('|', :skip-empty);
        @args .= map({ to-unquoted($_) });
    }

    if $p ~~ Callable {
        if $p.count > @args.elems {
            @args.append('' xx ($p.arity - @args.elems));
        }
        @args = @args.head($p.count);
        return $p.(|@args);
    } else {
        return $p;
    }
}

#-----------------------------------------------------------
proto sub llm-prompt-expand(Str:D) is export {*}

multi sub llm-prompt-expand(Str:D $input) {
    return $input.subst(&pmt-any, &prompt-function-spec):g;
}


#============================================================
# Optimization
#============================================================
BEGIN {
    ingest-prompt-data()
}
