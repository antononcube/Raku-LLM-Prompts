use v6.d;

unit module LLM::Prompts;

use JSON::Fast;

#-----------------------------------------------------------
my @records;
my @record-fields;
my @topics;
my @categories;

#-----------------------------------------------------------
#| Ingest the prompts database.
sub ingest-prompt-data() is export {
    # It is expected that resource file "prompts.json" is an array of hashes.
    @records = from-json(slurp(%?RESOURCES<prompts.json>)).List;

    @record-fields = @records.map({ $_.keys }).flat.unique.sort;
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
proto sub llm-prompt-data(| -->Hash) is export {*}

multi sub llm-prompt-data(-->Hash) {
    if ! @records { ingest-prompt-data; }
    my %resPrompts = @records.map({ $_<Name> => $_.clone }).Hash;
    return %resPrompts;
}

multi sub llm-prompt-data(:$fields! is copy) {
    my %res = llm-prompt-data;

    if $fields.isa(Whatever) { $fields = ['Description',]; }
    if $fields ~~ Str:D { $fields = [$fields,]; }

    die "The argument \$fields is expected to be Whatever, one of the strings \"{@record-fields.join('", "')}\", or a list of those strings."
    unless $fields ~~ Iterable && ($fields (&) @record-fields).elems > 0;

    if $fields.elems == 1 {
        return %res.map({ $_.key => $_.value{$fields.head} }).Hash;
    }
    return %res.map({ $_.key => $_.value{|$fields} }).Hash;
}

multi sub llm-prompt-data(Regex $name, :$fields = 'Description') {
    my %res = llm-prompt-data(:$fields);
    return %res.grep({ $_.key ~~ $name }).Hash;
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
        @recs = @recs.map({ $_.grep({ $_.key ∈ <Name Description Categories> }).Hash }).sort({ $_<Name> }).Array;
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
proto sub llm-prompt($name, Bool :$warn = True) is export {*}

multi sub llm-prompt($name is copy, Bool :$warn = True) is export {

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
my regex pmt-persona { ^ \s* '@' $<name>=(<.alnum>+) }

#| Modifier
my regex pmt-modifier { '#' $<name>=(<.alnum>+) [ '|' <pmt-list-of-params> '|'? ]? }

#| Function with params
my regex pmt-function { '!' $<name>=(<.alnum>+) '|' <pmt-list-of-params> '|'? }

#| Function over cell
my regex pmt-function-cell { ^ \s* '!' $<name>=(<.alnum>+) [ [\h+ | '>']? $<cell-arg>=(.+)]? }

#| Function over prior
my regex pmt-function-prior { ^ \s* '!' $<name>=(<.alnum>+) $<pointer>=('^'+) \h* $ }

#| Any prompt
my regex pmt-any {
    || <pmt-persona>
    || <pmt-function-prior>
    || <pmt-function>
    || <pmt-function-cell>
    || <pmt-modifier> }

#-----------------------------------------------------------
sub to-unquoted(Str $ss is copy) {
    if $ss ~~ / ^ '\'' (.*) '\'' $ / { return ~$0; }
    if $ss ~~ / ^ '"' (.*) '"' $ / { return ~$0; }
    if $ss ~~ / ^ '⎡' (.*) '⎦' $ / { return ~$0; }
    return $ss;
}

#-----------------------------------------------------------
sub prompt-function-spec($/, :@messages = Empty, Str :$sep = "\n") {

    my $m = $<pmt-persona> // $<pmt-function-prior> // $<pmt-function-cell> // $<pmt-function> // $<pmt-modifier>;
    my $p = llm-prompt($m<name>.Str);

    without $p {
        return $/.Str;
    }

    my @args ;

    with $m<pmt-list-of-params> {
        @args = $m<pmt-list-of-params>.Str.split('|', :skip-empty);
        @args .= map({ to-unquoted($_) });
    }

    with $m<cell-arg> {
        @args = [$m<cell-arg>.Str,];
    }

    with $m<pointer> {
        given (@messages.elems > 0, $m<pointer>.Str) {
            when (True, '^') { @args = @messages.tail; }
            when (True, '^^') { @args = @messages.join($sep); }
        }
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
proto sub llm-prompt-expand(Str:D, :@messages = Empty, :$sep = "\n") is export {*}

multi sub llm-prompt-expand(Str:D $input, :@messages = Empty, :$sep = "\n") {
    return $input.subst(&pmt-any, { prompt-function-spec($/, :@messages, :$sep) }):g;
}


#============================================================
# Optimization
#============================================================
BEGIN {
    ingest-prompt-data()
}
