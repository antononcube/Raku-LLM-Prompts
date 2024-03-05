#!/usr/bin/env raku
use v6.d;

use LLM::Prompts;
use HTTP::Tiny;
use JSON::Fast;

ingest-prompt-data();

say llm-prompt-data(/^Ex/);

my %st = llm-prompt-stencil;

my @specs = [
    { URL => 'https://raw.githubusercontent.com/danielmiessler/fabric/main/patterns/extract_wisdom',
      Name => "ExtractArticleWisdom",
      Description => 'Extracts wisdom from any text' }
    { URL => 'https://raw.githubusercontent.com/danielmiessler/fabric/main/patterns/find_hidden_message',
      Name =>"FindHiddenMessage",
      Description => 'Finds hidden (propaganda) in texts'
    }
];

for @specs -> %spec {
    my $url = %spec<URL>;
    my $promptText1 = HTTP::Tiny.new.get($url ~ '/system.md')<content>.decode;

    my $res2 = HTTP::Tiny.new.get($url ~ '/user.md');

    my $promptText2 = '';
    if $res2<status> == 200 { $res2.<content>.decode; }

    my $promptText = $promptText1 ~ "\n" ~ $promptText2;

    my %prompt = %st;
    %prompt<Name> = %spec<Name>;
    %prompt<Description> = %spec<Description>;

    if $promptText.trim ~~ / ':' $ / {
        %prompt<PromptText> = "-> \$a='' \{\"" ~ $promptText ~ " \$a\"\}";
        %prompt<Arity> = 1;
        %prompt<PositionalArguments> = %('$a' => '');
        %prompt<Categories>{'Function Prompts'} = True;
    } else {
        %prompt<PromptText> = $promptText;
        %prompt<Arity> = 0;
        %prompt<PositionalArguments> = %();
        %prompt<Categories>{'Personas'} = True;
    }

    %prompt<ContributedBy> = 'Anton Antonov';
    %prompt<URL> = $url;
    %prompt<Keywords> = ['text', 'summary', 'quotes', 'extract'];
    %prompt<Topics>{'Text Analysis'} = True;
    %prompt<Topics>{'Content Derived from Text'} = True;

    say "Adding prompt:", llm-prompt-add(%prompt):replace:keep;
}

say llm-prompt-data(/^Ex/);
say llm-prompt-data(/^Find/);
