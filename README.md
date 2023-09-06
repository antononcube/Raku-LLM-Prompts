# LLM::Prompts

## In brief

This repository is for a Raku (data) package facilitating the creation, storage, retrieval, and curation of LLM prompts.

----

## Installation

From Zef' ecosystem:

```
zef install LLM::Prompts
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-LLM-Prompts.git
```

-----

## Usage examples

Load the packages "LLM::Prompts", [AAp1], and "LLM::Functions", [AAp2]:

```perl6
use LLM::Prompts;
use LLM::Functions;
```
```
# (Any)
```

Show the record of the prompt named "FTFY":

```perl6
.say for |get-prompts<FTFY>;
```
```
# Title => FTFY
# Description => Use Fixed That For You to quickly correct spelling and grammar mistakes
# Topics => {AI Guidance => False, Advisor Bots => False, Character Types => False, Chats => False, Computable Output => False, Content Derived from Text => False, Education => False, Entertainment => False, Fictional Characters => False, For Fun => False, General Text Manipulation => True, Historical Figures => False, Linguistics => False, Output Formatting => False, Personalization => False, Prompt Engineering => False, Purpose Based => False, Real-World Actions => False, Roles => False, Special-Purpose Text Manipulation => False, Text Analysis => False, Text Generation => False, Text Styling => False, Wolfram Language => False, Writers => False, Writing Genres => False}
# Categories => {Function Prompts => True, Modifier Prompts => False, Personas => False}
# NamedArguments => []
# PromptText => -> $a {"Find and correct grammar and spelling mistakes in the following text.
# Response with the corrected text and nothing else.
# Provide no context for the corrections, only correct the text.
# $a"}
# PositionalArguments => [$a]
```

Make an LLM function from the prompt named "FTFY":

```perl6
my &f = llm-function(llm-prompt('FTFY'));
```
```
# -> **@args, *%args { #`(Block|2767823585240) ... }
```

Use the LLM function to correct the grammar of sentence:

```perl6
&f('Where does he works now?')
```
```
# Where does he work now?
```

-----

## References

### Articles

[AA1] Anton Antonov,
["Workflows with LLM functions"](https://rakuforprediction.wordpress.com/2023/08/01/workflows-with-llm-functions/),
(2023),
[RakuForPrediction at WordPress](https://rakuforprediction.wordpress.com).

[SW1] Stephen Wolfram,
["The New World of LLM Functions: Integrating LLM Technology into the Wolfram Language"](https://writings.stephenwolfram.com/2023/05/the-new-world-of-llm-functions-integrating-llm-technology-into-the-wolfram-language/),
(2023),
[Stephen Wolfram Writings](https://writings.stephenwolfram.com).

[SW2] Stephen Wolfram,
["Prompts for Work & Play: Launching the Wolfram Prompt Repository"](https://writings.stephenwolfram.com/2023/06/prompts-for-work-play-launching-the-wolfram-prompt-repository/),
(2023),
[Stephen Wolfram Writings](https://writings.stephenwolfram.com).

### Packages, paclets, repositories

[AAp1] Anton Antonov,
[LLM::Prompts Raku package](https://github.com/antononcube/Raku-LLM-Prompts),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp2] Anton Antonov,
[LLM::Functions Raku package](https://github.com/antononcube/Raku-LLM-Functions),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[WRIr1] Wolfram Research, Inc.,
[Wolfram Prompt Repository](https://resources.wolframcloud.com/PromptRepository)


