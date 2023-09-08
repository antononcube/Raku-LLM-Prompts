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
.say for |llm-prompt-data<FTFY>;
```
```
# NamedArguments => []
# Name => FTFY
# Description => Use Fixed That For You to quickly correct spelling and grammar mistakes
# Keywords => [Spell check Grammar Check Text Assistance]
# ContributedBy => Wolfram Staff
# Categories => (Function Prompts)
# Arity => 1
# URL => https://resources.wolframcloud.com/PromptRepository/resources/FTFY
# Topics => (General Text Manipulation)
# PositionalArguments => {$a => }
# PromptText => -> $a='' {"Find and correct grammar and spelling mistakes in the following text.
# Response with the corrected text and nothing else.
# Provide no context for the corrections, only correct the text.
# $a"}
```

Make an LLM function from the prompt named "FTFY":

```perl6
my &f = llm-function(llm-prompt('FTFY'));
```
```
# -> **@args, *%args { #`(Block|5798092430648) ... }
```

Use the LLM function to correct the grammar of sentence:

```perl6
&f('Where does he works now?')
```
```
# Where does he work now?
```

-----

## Prompt data

Here is how the prompt data can be obtained:

```perl6
llm-prompt-data.elems
```
```
# 118
```

Here is a breakdown of the prompts categories:

```perl6
use Data::Reshapers;
use Data::Summarizers;
use Data::Translators;

select-columns(llm-prompt-dataset, <Variable Value>).grep({ $_<Variable> eq 'Categories' }) ==> records-summary
```
```
# +-------------------+------------------------+
# | Variable          | Value                  |
# +-------------------+------------------------+
# | Categories => 118 | Personas         => 55 |
# |                   | Function Prompts => 50 |
# |                   | Modifier Prompts => 13 |
# +-------------------+------------------------+
```

Here are all modifier prompts in compact format:

```perl6
llm-prompt-dataset():modifiers:compact ==> to-pretty-table(field-names => <Name Description Categories>, align => 'l')
```
```
# +-----------------+-------------------------------------------------------+-----------------------------------+
# | Name            | Description                                           | Categories                        |
# +-----------------+-------------------------------------------------------+-----------------------------------+
# | ELI5            | Explain like I'm five                                 | Function Prompts Modifier Prompts |
# | TargetAudience  | Word your response for a target audience              | Modifier Prompts                  |
# | Moodified       | Modify an answer to express a certain mood            | Modifier Prompts                  |
# | Translated      | Write the response in a specified language            | Modifier Prompts                  |
# | YesNo           | Responds with Yes or No exclusively                   | Modifier Prompts                  |
# | JSON            | Respond with JavaScript Object Notation format        | Modifier Prompts                  |
# | AphorismStyled  | Write the response as an aphorism                     | Modifier Prompts                  |
# | DatasetForm     | Convert text to a wolfram language Dataset            | Modifier Prompts                  |
# | Emojified       | Provide responses that include emojis within the text | Modifier Prompts                  |
# | BadGrammar      | Provide answers using incorrect grammar               | Modifier Prompts                  |
# | HaikuStyled     | Change responses to haiku form                        | Modifier Prompts                  |
# | EmojiTranslated | Get a response translated to emoji                    | Modifier Prompts                  |
# | LimerickStyled  | Receive answers in the form of a limerick             | Modifier Prompts                  |
# +-----------------+-------------------------------------------------------+-----------------------------------+
```

**Remark:** The adverbs `:functions`, `:modifiers`, and `:personas` mean 
that *only* the prompts with the corresponding categories will be returned.

**Remark:** The adverbs `:compact`, `:functions`, `:modifiers`, and `:personas` have the respective shortcuts `:c`, `:f`, `:m`, and `:p`.

-----

## Implementation notes

### Prompt DSL grammar and actions

The DSL:

- Prompt personas can be "addressed" with "@". For example:

```
@Yoda Life can be easy, but some people instist for to be difficult.
```

- One or several modifier prompts can be specified at the end of the prompt spec. For example:

```
Summer is over, school is coming soon. #HaikuStyled
```

```
Summer is over, school is coming soon. #HaikuStyled #Translated|Russian
```

Having a grammar is most likely not needed, and it is better to use "prompt expansion" (via regex-based substitutions.)

-----

## TODO

- [ ] TODO Implementation
  - [X] DONE Prompt retrieval adverbs
  - [X] DONE Prompt DSL grammar and actions
  - [ ] TODO Prompt spec expansion
  - [ ] TODO Addition of user/local prompts 
    - XDG data directory.
- [ ] TODO Add more prompts
  - [ ] TODO Google's Bard example prompts
  - [ ] TODO OpenAI's ChatGPT example prompts
- [ ] TODO Documentation
  - [X] TODO Querying (ingested) prompts
  - [ ] TODO Prompt format
  - [ ] TODO Prompt DSL
  - [ ] TODO On hijacking prompts
  - [ ] TODO Diagrams
    - [ ] Typical usage
    - [ ] Chatbook usage 


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


