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

### Retrieval

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
# Keywords => [Spell check Grammar Check Text Assistance]
# ContributedBy => Wolfram Staff
# PositionalArguments => {$a => }
# NamedArguments => []
# URL => https://resources.wolframcloud.com/PromptRepository/resources/FTFY
# Topics => (General Text Manipulation)
# Arity => 1
# Description => Use Fixed That For You to quickly correct spelling and grammar mistakes
# PromptText => -> $a='' {"Find and correct grammar and spelling mistakes in the following text.
# Response with the corrected text and nothing else.
# Provide no context for the corrections, only correct the text.
# $a"}
# Categories => (Function Prompts)
# Name => FTFY
```

### LLM functions based on prompts

Make an LLM function from the prompt named "FTFY":

```perl6
my &f = llm-function(llm-prompt('FTFY'));
```
```
# -> **@args, *%args { #`(Block|4648886772936) ... }
```

Use the LLM function to correct the grammar of sentence:

```perl6
&f('Where does he works now?')
```
```
# Where does he work now?
```

### Prompt expansion

Prompt expansion using the chatbook prompt spec DSL described in [SW1] 
can be done using the function `llm-prompt-expand`:  

```perl6
llm-prompt-expand('What is an internal combustion engine? #ELI5')
```
```
# What is an internal combustion engine? Answer questions as if the listener is a five year old child.
```

Here we get the actual LLM answer:

```perl6
use Text::Utils :ALL;

'What is an internal combustion engine? #ELI5' 
        ==> llm-prompt-expand() 
        ==> llm-synthesize() 
        ==> wrap-paragraph() 
        ==> join("\n") 
```
```
# An internal combustion engine is a machine that uses gasoline or diesel to
# make a car, truck, or other vehicle go. Inside the engine, the gasoline or
# diesel is mixed with air and then burned. This burning makes a lot of energy
# which makes the car or truck move.
```

Here is another example using a persona and two modifiers:

```perl6
my $prmt = llm-prompt-expand("@SouthernBelleSpeak What is light travel distance to Mars? #ELI5 #Moodified|sad")
```
```
# You are Miss Anne. 
# You speak only using Southern Belle terminology and slang.
# Your personality is elegant and refined.
# Only return responses as if you were a Southern Belle.
# Never break the Southern Belle character.
# You speak with a Southern drawl. What is light travel distance to Mars? Answer questions as if the listener is a five year old child. Modify your response to convey a sad mood.
# Use language that conveys that emotion clearly.
# Do answer the question clearly and truthfully.
# Do not use language that is outside of the specified mood.
# Do not use racist, homophobic, sexist, or ableist language.
```

Here we get the actual LLM answer:

```perl6
$prmt 
        ==> llm-prompt-expand() 
        ==> llm-synthesize()
```
```
# Well, sugar, it's a mighty long way to Mars! Even if you took a spaceship, you'd be flying through the stars for a mightly long time. It's just too far for us to go, so I'm sorry to say that we'll never get to visit the Red Planet.
```

-----

## Prompt spec DSL

A more formal description of the Domain Specific Language (DSL) for specifying prompts
have the following elements: 

- Prompt personas can be "addressed" with "@". For example:

```
@Yoda Life can be easy, but some people instist for it to be difficult.
```

- One or several modifier prompts can be specified at the end of the prompt spec. For example:

```
Summer is over, school is coming soon. #HaikuStyled
```

```
Summer is over, school is coming soon. #HaikuStyled #Translated|Russian
```

- Functions can be specified to be applied "cell-wide" with "!" and placing the prompt spec at
  the start of the prompt spec to be expanded. For example:

```
!Translated|Portuguese Summer is over, school is coming soon
```

Here is a table of prompt expansion specs (a simpler version of the one in [SW1]):

| Spec               | Interpretation                                     |
|:-------------------|:---------------------------------------------------|
| @*name*            | Direct chat to a persona                           |
| #*name*            | Use modifier prompts                               |
| !*name*            | Use function prompt with the input of current cell |
| !*name*>           | *«same as above»*                                  |
| !*name*￨*param*... | Include parameters for prompts                     |

**Remark:** Prompt expansion make the usage of LLM-chatbooks much easier.
See "Jupyter::Chatbook", [AAp3].

-----

## Prompt data

Here is how the prompt data can be obtained:

```perl6
llm-prompt-data.elems
```
```
# 152
```

Here is retrieval prompt data with a regex that applied over the prompt names:

```perl6
.say for llm-prompt-data(/Em/, field => 'Description')
```
```
# EmailWriter => Generate an email based on a given topic
# EmojiTranslate => Translate text into an emoji representation
# Emojified => Provide responses that include emojis within the text
# EmojiTranslated => Get a response translated to emoji
# Emojify => Replace key words in text with emojis
```

In many cases it is better to have the prompt data -- or any data -- in long format.
Prompt data in long format can be obtained with the function `llm-prompt-dataset`:

```perl6
use Data::Reshapers;
use Data::Summarizers;

llm-prompt-dataset.pick(6) 
        ==> to-pretty-table(align => 'l', field-names => <Name Description Variable Value>)
```
```
#ERROR: Too few positionals passed to '<anon>'; expected 2 arguments but got 1 in sub-signature
# Nil
```

Here is a breakdown of the prompts categories:

```perl6
select-columns(llm-prompt-dataset, <Variable Value>).grep({ $_<Variable> eq 'Categories' }) ==> records-summary
```
```
# +-------------------+------------------------+
# | Variable          | Value                  |
# +-------------------+------------------------+
# | Categories => 151 | Function Prompts => 73 |
# |                   | Personas         => 59 |
# |                   | Modifier Prompts => 19 |
# +-------------------+------------------------+
```

Here are all modifier prompts in compact format:

```perl6
llm-prompt-dataset():modifiers:compact ==> to-pretty-table(field-names => <Name Description Categories>, align => 'l')
```
```
# +-----------------------+-------------------------------------------------------+-----------------------------------+
# | Name                  | Description                                           | Categories                        |
# +-----------------------+-------------------------------------------------------+-----------------------------------+
# | AphorismStyled        | Write the response as an aphorism                     | Modifier Prompts                  |
# | BadGrammar            | Provide answers using incorrect grammar               | Modifier Prompts                  |
# | CompleteSentence      | Answer a question in one complete sentence            | Modifier Prompts                  |
# | ComplexWordsPreferred | Modify text to use more complex words                 | Modifier Prompts                  |
# | DatasetForm           | Convert text to a wolfram language Dataset            | Modifier Prompts                  |
# | ELI5                  | Explain like I'm five                                 | Modifier Prompts Function Prompts |
# | EmojiTranslated       | Get a response translated to emoji                    | Modifier Prompts                  |
# | Emojified             | Provide responses that include emojis within the text | Modifier Prompts                  |
# | FictionQuestioned     | Generate questions for a fictional paragraph          | Modifier Prompts                  |
# | HaikuStyled           | Change responses to haiku form                        | Modifier Prompts                  |
# | JSON                  | Respond with JavaScript Object Notation format        | Modifier Prompts                  |
# | LimerickStyled        | Receive answers in the form of a limerick             | Modifier Prompts                  |
# | Moodified             | Modify an answer to express a certain mood            | Modifier Prompts                  |
# | NothingElse           | Give output in specified form, no other additions     | Modifier Prompts                  |
# | TSV                   | Convert text to a tab-separated-value formatted table | Modifier Prompts                  |
# | TargetAudience        | Word your response for a target audience              | Modifier Prompts                  |
# | Translated            | Write the response in a specified language            | Modifier Prompts                  |
# | Unhedged              | Rewrite a sentence to be more assertive               | Modifier Prompts                  |
# | YesNo                 | Responds with Yes or No exclusively                   | Modifier Prompts                  |
# +-----------------------+-------------------------------------------------------+-----------------------------------+
```

**Remark:** The adverbs `:functions`, `:modifiers`, and `:personas` mean 
that *only* the prompts with the corresponding categories will be returned.

**Remark:** The adverbs `:compact`, `:functions`, `:modifiers`, and `:personas` have the respective shortcuts `:c`, `:f`, `:m`, and `:p`.


-----

## Implementation notes

### Prompt collection

The original (for this package) collection of prompts was taken from 
[Wolfram Prompt Repository](https://resources.wolframcloud.com/PromptRepository/) (WPR), [SW2].
All prompts from WPR in the package have the corresponding contributors and URLs to the corresponding WPR pages.  

Example prompts from Google/Bard/PaLM and OpenAI/ChatGPT are added using the format of WPR. 

### Extending prompt collection

It is essential to have the ability to programmatically add new prompts.
(Not implemented yet -- see the TODO section below.)

Having a grammar is most likely not needed, and it is better to use "prompt expansion" (via regex-based substitutions.)

### Prompt expansion

The prompt specs can be "just expanded" instead of having a grammar parse and apply actions within.
Hence, the sub `llm-prompt-expand` was implemented. 

-----

## TODO

- [ ] TODO Implementation
  - [X] DONE Prompt retrieval adverbs
  - [X] DONE Prompt DSL grammar and actions
  - [X] DONE Prompt spec expansion
  - [ ] TODO Addition of user/local prompts 
    - XDG data directory.
- [X] DONE Add more prompts
  - [X] DONE Google's Bard example prompts
  - [C] TODO OpenAI's ChatGPT example prompts
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

[AAp3] Anton Antonov,
[Jupyter::Chatbook Raku package](https://github.com/antononcube/Raku-Jupyter-Chatbook),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[WRIr1] Wolfram Research, Inc.,
[Wolfram Prompt Repository](https://resources.wolframcloud.com/PromptRepository)


