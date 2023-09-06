use v6.d;

unit module LLM::Prompts;

use JSON::Fast;

#-----------------------------------------------------------
my %prompts;

#-----------------------------------------------------------
#| Ingest the prompts database.
sub ingest-prompt-records() is export {
    # It is expected that resource file "prompts.json" is an array of hashes.
    return from-json(slurp(%?RESOURCES<prompts.json>)).List;
}

#-----------------------------------------------------------
#| Get the prompts database as hash with the keys being the prompt titles.
sub get-prompts(-->Hash) is export {
    if !%prompts {
        %prompts = ingest-prompt-records.map({ $_<Title> => $_ }).Hash;
    }
    return %prompts;
}

#-----------------------------------------------------------
#| Create the prompt string or pure function for a given prompt name.
sub llm-prompt($name is copy) is export {

    my %ps = get-prompts;

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
        note "Unknown prompt name: ⎡$name⎦.";
        return Nil;
    }
}

