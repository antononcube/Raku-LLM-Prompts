unit module LLM::Prompts;

use JSON::Fast;
use XDG::BaseDirectory :terms;

#-----------------------------------------------------------
my @records;
my @record-fields;
my @topics;
my @categories;

#-----------------------------------------------------------
my %promptStencil;

#| Ingests the prompt stencil.
sub ingest-prompt-stencil() is export {
    %promptStencil = from-json(slurp(%?RESOURCES<prompt-stencil.json>));
    return %promptStencil;
}

#-----------------------------------------------------------
#| Gives the prompt stencil.
sub llm-prompt-stencil(-->Hash) is export {
    return %promptStencil.clone>>.clone.Hash;
}

#-----------------------------------------------------------
#| Verifies is the argument a valid prompt.
sub llm-prompt-verify(%prompt) is export {

#    note %prompt.keys.sort;
#    note llm-prompt-stencil.keys.sort;
#    note [keys => (%prompt.keys ⊆ llm-prompt-stencil.keys),
#          Name =>(%prompt<Name> ~~ Str),
#          Description => (%prompt<Description> ~~ Str),
#          PromptText => (%prompt<PromptText> ~~ Str),
#          PositionalArguments => (%prompt<PositionalArguments> ~~ Hash),
#          Categories => (%prompt<Categories> ~~ Hash),
#          Topics => (%prompt<Topics> ~~ Hash) ,
#          Keywords => (%prompt<Keywords> ~~ Iterable)];

    return (%prompt.keys ⊆ llm-prompt-stencil.keys) &&
            (%prompt<Name> ~~ Str) &&
            (%prompt<Description> ~~ Str) &&
            (%prompt<PromptText> ~~ Str) &&
            (%prompt<PositionalArguments> ~~ Hash) &&
            (%prompt<Categories> ~~ Hash) &&
            (%prompt<Topics> ~~ Hash) &&
            (%prompt<Keywords> ~~ Iterable);
}

#-----------------------------------------------------------
#| Ingest the prompts database.
proto sub ingest-prompt-data(|) is export {*}

multi sub ingest-prompt-data($fileName) {
    # It is expected that resource file "prompts.json" is an array of hashes.
    my @records = from-json(slurp($fileName)).List;

    my @record-fields = @records.map({ $_.keys }).flat.unique.sort;
    my @categories = @records.map({ $_<Categories>.keys }).flat.unique.sort;
    my @topics = @records.map({ $_<Topics>.keys }).flat.unique.sort;

    @records .= map({
        $_<Categories> = $_<Categories>.grep(*.value)>>.key.List;
        $_<Topics> = $_<Topics>.grep(*.value)>>.key.List;
        $_
    });

    return %(:@records, :@record-fields, :@categories, :@topics);
}

multi sub ingest-prompt-data('module') {
    my %prompts = ingest-prompt-data(%?RESOURCES<prompts.json>);
    @records = |%prompts<records>;
    @record-fields = |%prompts<record-fields>;
    @topics = |%prompts<topics>;
    @categories = |%prompts<categories>;

    return %prompts;
}

multi sub ingest-prompt-data('user', Bool :a(:$append) = False) {

    my $dirName = data-home.Str ~ '/raku/LLM/Prompts';

    my @userPrompts;
    if $dirName.IO.d {
        my @fnames = dir($dirName).grep({ $_.parts.Hash<basename> ~~ / '.json' $ / });
        for @fnames -> $fname {
            my %prompt = from-json(slurp($fname));
            if llm-prompt-verify(%prompt) {
                @userPrompts.push(%prompt);
            } else {
                warn "The file $fname is not valid LLM prompt.";
            }
        }
    }

    if $append { @records.append(@userPrompts); }

    return %( records => @userPrompts, :@record-fields, :@categories, :@topics);
}

multi sub ingest-prompt-data() {

    ingest-prompt-data('module');

    my %res = ingest-prompt-data('user');

    @records.append(|%res<records>);

    return %(:@records, :@record-fields, :@categories, :@topics);
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
#| Adds an user prompt.
#| C<:$keep> -- if True a JSON file corresponding to the prompt is put in the local prompt directory.
#| C<:$replace> -- If True if an existing prompt has the same name then it is replaced.
sub llm-prompt-add(%prompt, Bool :$replace = False, :$keep = False) is export {
    if !llm-prompt-verify(%prompt) {
        die "Invalid prompt.";
    }

    if $keep {
        my $dirName = data-home.Str ~ '/raku/LLM/Prompts';
        my $fname = $dirName ~ '/' ~ %prompt<Name> ~ '.json';

        if not $dirName.IO.e {
            my $path = IO::Path.new($dirName);
            if not mkdir($path) {
                die "Cannot create the directory: $dirName."
            }
        }

        if $fname.IO.e {
            note "An LLM prompt file with the name {$fname.IO.parts.Hash<basename>} already exists.";
        }

        # Write to a JSON file in the local resources directory
        spurt($fname, to-json(%prompt));
    }

    if %prompt<Name> ∉ @records.map(*<Name>) {
        @records.append([%prompt,]);
    } else {
        if $replace {
            note "Replacing an existing prompt with name ⎡{%prompt<Name>}⎦.";
            @records.append([%prompt, ]);
        } else {
            note "A prompt with the name, ⎡{%prompt<Name>}⎦, already exists.";
            return False;
        }
    }

    return True;
}

#-----------------------------------------------------------
#| Get the prompts database as hash with the keys being the prompt titles.
#| C<$name> -- Str:D or Regex used to retrieve the prompts by name.
#| C<$fields> -- Fields to provide in the result.
proto sub llm-prompt-data(| -->Hash) is export {*}

multi sub llm-prompt-data(Bool:D :p(:$pairs) = True -->Hash) {
    if ! @records { ingest-prompt-data; }
    my %resPrompts = do if $pairs {
        @records.map({ $_<Name> => $_.clone });
    } else {
        @records.map({ $_<Name> => $_{|@record-fields} });
    }
    return %resPrompts;
}

multi sub llm-prompt-data($name, $fields, Bool:D :p(:$pairs) = False -->Hash) {
    return llm-prompt-data($name, :$fields, :$pairs);
}

multi sub llm-prompt-data(:$fields! is copy, Bool:D :p(:$pairs) = False) {
    my %res = llm-prompt-data;

    if $fields.isa(Whatever) { $fields = ['Description',]; }
    if $fields ~~ Str:D { $fields = [$fields,]; }

    die "The argument \$fields is expected to be Whatever, one of the strings \"{@record-fields.join('", "')}\", or a list of those strings."
    unless $fields ~~ Iterable && ($fields (&) @record-fields).elems > 0;

    if $fields.elems == 1 {
        return %res.map({ $_.key => $_.value{$fields.head} }).Hash;
    }
    return do if $pairs {
        %res.map({ $_.key => ( $fields.Array Z=> $_.value{|$fields} ).Hash }).Hash;
    } else {
        %res.map({ $_.key => $_.value{|$fields} }).Hash;
    }
}

multi sub llm-prompt-data(Str:D $name, :$fields = Whatever, Bool:D :p(:$pairs) = False) {
    my %res = llm-prompt-data(:$fields, :$pairs);
    return %res.grep({ $_.key eq $name }).Hash;
}

multi sub llm-prompt-data(Regex $name, :$fields = Whatever, Bool:D :p(:$pairs) = False) {
    my %res = llm-prompt-data(:$fields, :$pairs);
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
#| C<$name> -- Name of the prompt.
#| C<:$warn> -- Should a warning be issued if the prompt is not found or not?
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
my regex pmt-param-simple { $<param-simple>=(<-[\s^|=]>*)  }
my regex pmt-param-qouted { $<param-quoted>=('"' ~ '"' <-["]>+ || '\'' ~ '\'' <-[']>+ )  }
my regex pmt-param { $<param>=(<pmt-param-qouted> || <pmt-param-simple>)  }

#| Sequence of parameters
my regex pmt-list-of-params { <pmt-param>+ % '|' }

#| Persona
my regex pmt-persona { ^ \s* '@' $<name>=(<.alnum>+) ['|' <pmt-list-of-params> '|'? ]? $<end>=(<?before $>)? }

#| Modifier
my regex pmt-modifier { '#' $<name>=(<.alnum>+) [ '|' <pmt-list-of-params> '|'? ]? $<end>=(<?before $>)?  }

#| Function with params
my regex pmt-function { ['!' | '&'] $<name>=(<.alnum>+) '|' <pmt-list-of-params> '|'? $<end>=(<?before $>)? }

#| Function over cell
my regex pmt-function-cell { ^ \s* ['!' | '&'] $<name>=(<.alnum>+) [ '|' <pmt-list-of-params> '|'? ]? [ [\h+ | '>']? $<cell-arg>=(.+)]? }

#| Function over prior
my regex pmt-function-prior { ^ \s* ['!' | '&'] $<name>=(<.alnum>+) [ '|' <pmt-list-of-params> '|'? ]? $<pointer>=('^'+) \s* $ }

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

    my $end = $sep;
    if $m<end> || $<pmt-function-prior> || $<pmt-function-cell> {
        $end = '';
    }

    without $p {
        return $/.Str;
    }

    my @args ;

    with $m<pmt-list-of-params> {
        @args = $m<pmt-list-of-params>.Str.split('|', :skip-empty);
        @args .= map({ to-unquoted($_) });
    }

    with $m<cell-arg> {
        @args.push($m<cell-arg>.Str);
    }

    with $m<pointer> {
        given (@messages.elems > 0, $m<pointer>.Str) {
            when (True, '^') { @args.push(@messages.tail); }
            when (True, '^^') { @args.push(@messages.join($sep)); }
        }
    }

    if $p ~~ Callable {
        if $p.count > @args.elems {
            @args.append('' xx ($p.arity - @args.elems));
        }
        @args = @args.head($p.count);
        return $p.(|@args) ~ $end;
    } else {
        return $p ~ $end;
    }
}

#-----------------------------------------------------------
#| Expand prompt DSL spec.
#| C<$input> -- Input.
#| C<:@messages> -- Messages to use in the expansion.
#| C<:$sep> -- Separator between the prompts.
proto sub llm-prompt-expand(Str:D, :@messages = Empty, :$sep = "\n") is export {*}

multi sub llm-prompt-expand(Str:D $input, :@messages = Empty, :$sep = "\n") {
    return $input.subst(&pmt-any, { prompt-function-spec($/, :@messages, :$sep) }, :g).chomp;
}


#============================================================
# Optimization
#============================================================
BEGIN {
    ingest-prompt-stencil();
    ingest-prompt-data();
}
