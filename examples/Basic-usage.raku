#!/usr/bin/env raku
use v6.d;

use LLM::Prompts;
use LLM::Functions;


say llm-prompt('FTFY');

my &f = llm-function(llm-prompt('FTFY'));

say &f('Where does he works now?');