# Daily joke via CLI

Following [Daily Jokes for your Command Line](https://github.com/rcmlz/daily-jokes):

```shell
openai-playground --max-tokens=1024 --format=json \
  'Tell a Computer Science joke!' \
  | jq '.choices.[0].message.content' \
  | sed -e 's/\\n/\n/g' -e 's/"//g' \
  | cowsay
```

The line above, though, requires to have the programs `cowsay` and `jq` installed.

But why the CLI program `cowsay` has to be used? Why not should have also been "outsoursed" to the LLM.

Here is an example:

```shell
openai-playground --model=gpt-4 $(echo "Tell a Computer Science joke and show it in the form of the program cowsay. $(llm-prompt 'NothingElse' 'ASCII art')")
```


Here is the retrieval of the prompt "NothingElse" and its evaluation with "ASCII art":

```shell
llm-prompt 'NothingElse' 'ASCII art'
```