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
proto sub llm-prompt-dataset() is export {*}

multi sub llm-prompt-dataset() {
    my @recs = llm-prompt-data.values;

    my @pivotCols = <Topics Categories Keywords PositionalArguments NamedArguments>;
    my $idCols = @recs.head.keys (-) @pivotCols;

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

    return @res.sort(*<Name Variable Value>);
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

#============================================================
# Optimization
#============================================================
BEGIN {
    ingest-prompt-data()
}
