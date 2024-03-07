#!/usr/bin/env raku
use v6.d;

#`[

In this script:

 1. We form a list of _three_ specifications for the prompts from [DMr1]:
    "ExtractArticleWisdom", "FindHiddenMessage", and "CheckAgreement"
 2. We ingest and file the prompts using a loop

The procedure is general -- the rest of prompts (or patterns) in [DMr1] can be ingested and filed with the same code.

[DMr1] Daniel Miessler,
[Fabric](https://github.com/danielmiessler/fabric),
(2024),
[GitHub/danielmiessler](https://github.com/danielmiessler).

]

use LLM::Prompts;
use HTTP::Tiny;
use JSON::Fast;

# Make sure most recent prompts are ingested
ingest-prompt-data();

# Preliminary check
say llm-prompt-data(/^Extract | ^Find/);

# Declare a hash variable %st and assign it the result of the function llm-prompt-stencil
my %st = llm-prompt-stencil;

# Declare an array of hashes @specs, each hash contains information about a specific URL
my @specs = [
    { URL => 'https://raw.githubusercontent.com/danielmiessler/fabric/main/patterns/extract_wisdom',
      Name => "ExtractArticleWisdom",
      Description => 'Extracts ideas, quotes, and references from any text' },
    { URL => 'https://raw.githubusercontent.com/danielmiessler/fabric/main/patterns/find_hidden_message',
      Name =>"FindHiddenMessage",
      Description => 'Finds hidden (propaganda) messages in texts'
    },
    { URL => 'https://raw.githubusercontent.com/danielmiessler/fabric/main/patterns/check_agreement',
      Name => 'CheckAgreement',
      Description => 'Analyzes agreements and looks for gotchas'
    }
];

# Loop over each hash in the @specs array
for @specs -> %spec {

    # Extract the URL from the current spec
    my $url = %spec<URL>;

    # Make a GET request to the URL and decode the content
    my $promptText1 = HTTP::Tiny.new.get($url ~ '/system.md')<content>.decode;

    # Make another GET request to a different URL
    my $res2 = HTTP::Tiny.new.get($url ~ '/user.md');

    # Initialize an empty string
    my $promptText2 = '';

    # If the status of the GET request is 200, decode the content (if it is defined)
    note (:$res2);
    if $res2<status> == 200 && $res2<content>.defined {
        $promptText2 = $res2<content>.decode;
    }

    # Concatenate the two decoded contents
    my $promptText = $promptText1 ~ "\n" ~ $promptText2;

    # Copy the %st hash into %prompt
    my %prompt = %st;

    # Update the Name and Description fields in the %prompt hash
    %prompt<Name> = %spec<Name>;
    %prompt<Description> = %spec<Description>;

    # Check if the promptText ends with a colon
    if $promptText.trim ~~ / ':' $ / {
        # If it does, update the PromptText, Arity, PositionalArguments, and Categories fields in the %prompt hash
        %prompt<PromptText> = "-> \$a='' \{\"" ~ $promptText ~ " \$a\"\}";
        %prompt<Arity> = 1;
        %prompt<PositionalArguments> = %('$a' => '');
        %prompt<Categories>{'Function Prompts'} = True;
    } else {
        # If it doesn't, update the PromptText, Arity, PositionalArguments, and Categories fields in the %prompt hash
        %prompt<PromptText> = $promptText;
        %prompt<Arity> = 0;
        %prompt<PositionalArguments> = %();
        %prompt<Categories>{'Personas'} = True;
    }

    # Update the ContributedBy, URL, Keywords, and Topics fields in the %prompt hash
    %prompt<ContributedBy> = 'Anton Antonov';
    %prompt<URL> = $url;
    %prompt<Keywords> = ['text', 'summary', 'quotes', 'extract'];
    %prompt<Topics>{'Text Analysis'} = True;
    %prompt<Topics>{'Content Derived from Text'} = True;

    # Print a message and the result of the function llm-prompt-add
    say "Adding prompt:", llm-prompt-add(%prompt):replace:keep;
}

say llm-prompt-data(/^Ex/);
say llm-prompt-data(/^Find/);
say llm-prompt-data(/^Check/);
