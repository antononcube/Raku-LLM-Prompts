#!/usr/bin/env raku
use v6.d;

use LLM::Prompts;
use HTTP::Tiny;
use JSON::Fast;

ingest-prompt-data();

say llm-prompt-data(/^Ex/);

my %st = llm-prompt-stencil;

#my $url = 'https://raw.githubusercontent.com/danielmiessler/fabric/main/patterns/extract_wisdom';
my $url = 'https://raw.githubusercontent.com/danielmiessler/fabric/main/patterns/find_hidden_message';
my $promptText1 = HTTP::Tiny.new.get($url ~ '/system.md')<content>.decode;

my $res2 = HTTP::Tiny.new.get($url ~ '/user.md');

my $promptText2 = '';
if $res2<status> == 200 { $res2.<content>.decode; }

my $promptText = $promptText1 ~ "\n" ~ $promptText2;

my %prompt = %st;
#%prompt<Name> = "ExtractArticleWisdom";
#%prompt<Description> = 'Extracts wisdom from any text';
%prompt<Name> = "FindHiddenMessage";
%prompt<Description> = 'Finds propaganda in texts';

if $promptText.trim ~~ / ':' $ / {
    %prompt<PromptText> = "-> \$a='' \{\"" ~ $promptText ~ " \$a\"\}";
} else {
    %prompt<PromptText> = $promptText;
}

%prompt<Arity> = 1;
%prompt<ContributedBy> = 'Anton Antonov';
%prompt<URL> = $url;
%prompt<Keywords> = ['text', 'summary', 'quotes', 'extract'];
%prompt<Categories>{'Function Prompts'} = True;
%prompt<Topics>{'Text Analysis'} = True;
%prompt<Topics>{'Content Derived from Text'} = True;

say "Adding prompt:", llm-prompt-add(%prompt):replace:keep;

say llm-prompt-data(/^Ex/);
