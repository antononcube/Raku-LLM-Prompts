Clear[GetPromptTitle];
GetPromptTitle[nbExpr_] :=
    Cases[nbExpr, Cell[title_, "Title", ___] :> title, \[Infinity]][[1]];

Clear[GetPromptDescr];
GetPromptDescr[nbExpr_] :=
    Cases[nbExpr, {Cell[title_, "Title", ___], Cell[descr_, "Text", ___], ___} :> descr, \[Infinity]][[1]];

Clear[GetContributedBy];
GetContributedBy[nbExpr_] :=
    Block[{t},
      t = Cases[nbExpr, {Cell["Contributed By", ___], Cell[descr_, "Text", ___], ___} :> descr, \[Infinity]];
      If[Length[t] > 0, t[[1]], "Unknown"]
    ];

Clear[GetPromptText];
GetPromptText[nbExpr_] :=
    Block[{res},
      res = Cases[nbExpr, HoldPattern[_[___, _[___, CellTags -> {___, "Prompt Text", ___}, ___], ___]], \[Infinity]];
      res[[1, 2, 1]]
    ];

Clear[PromptTextToRaku];

PromptTextToRaku[prompt_String] :=
    <|"PositionalArgs" -> {},
      "NamedArgs" -> {},
      "Code" -> "'" <> prompt <> "'"|>;

PromptTextToRaku[prompt_TextData] :=
    Block[{aSlotToRakuRules, posArgs = {}, namedArgs = {}, args, t, code},

      aSlotToRakuRules = {
        Cell[BoxData[TemplateBox[{n_Integer, _, "Positional", ___}, "NotebookTemplateSlot"]], ___] :> (t = "$" <> CharacterRange["a", "z"][[n]];
        posArgs = Union@Append[posArgs, t]; t),
        Cell[BoxData[TemplateBox[{n_String, _, "Named", ___}, "NotebookTemplateSlot"]], ___] :> (t = "$" <> StringReplace[n, {StartOfString ~~ "\"" -> "", "\"" ~~ EndOfString -> ""}];
        namedArgs = Union@Append[namedArgs, t]; t)
      };


      If[FreeQ[prompt, _TemplateBox, \[Infinity]],
        "'" <> StringRiffle[prompt[[1]], ""] <> "'",
        (*ELSE*)
        code =
            "{\"" <> StringRiffle[prompt[[1]] //. aSlotToRakuRules, ""] <> "\"}";
        args = StringRiffle[Flatten@{posArgs, ":" <> # & /@ namedArgs}, ", "];
        code = "-> " <> args <> " " <> code;

        <|"PositionalArgs" -> posArgs,
          "NamedArgs" -> namedArgs,
          "Code" -> code|>
      ]
    ];

Clear[GetCategories];
GetCategories[nbExpr_] :=
    Block[{res, known, aRes},
      known = {"Function Prompts", "Modifier Prompts", "Personas"};
      res = Cases[nbExpr, _CheckboxBox, \[Infinity]];
      Association@Map[If[MemberQ[res, CheckboxBox[#, {False, #}]], # -> True, # -> False] &, known]
    ];

Clear[GetTopics];
GetTopics[nbExpr_] :=
    Block[{res, known},
      known = {"Advisor Bots", "Chats", "Education", "For Fun", "Linguistics",
        "Prompt Engineering", "Roles", "Text Generation", "Writers",
        "AI Guidance", "Computable Output", "Entertainment",
        "General Text Manipulation", "Output Formatting", "Purpose Based",
        "Special-Purpose Text Manipulation", "Text Styling", "Writing Genres",
        "Character Types", "Content Derived from Text", "Fictional Characters",
        "Historical Figures", "Personalization", "Real-World Actions",
        "Text Analysis", "Wolfram Language"};
      res = Cases[nbExpr, _CheckboxBox, \[Infinity]];
      Association@Map[If[MemberQ[res, CheckboxBox[#, {False, #}]], # -> True, # -> False] &, known]
    ];

urlWPR = "https://resources.wolframcloud.com/PromptRepository/resources/";

Clear[PromptNotebookToRecord];

PromptNotebookToRecord[fileName_String] :=
    Block[{nb},
      nb = NotebookOpen[fileName, Visible -> False];
      PromptNotebookToRecord[nb]
    ];

PromptNotebookToRecord[nb_NotebookObject] :=
    Block[{nbExpr, ptext, aRes},
      nbExpr = NotebookGet[nb];
      ptext = PromptTextToRaku@GetPromptText[nbExpr];
      aRes = <|
        "Title" -> GetPromptTitle[nbExpr],
        "Description" -> GetPromptDescr[nbExpr],
        "PromptText" -> ptext["Code"],
        "PositionalArguments" -> ptext["PositionalArgs"],
        "NamedArguments" -> ptext["NamedArgs"],
        "Arity" -> Length[Union@ptext["PositionalArgs"]],
        "Categories" -> GetCategories[nbExpr],
        "Topics" -> GetTopics[nbExpr],
        "ContributedBy" -> GetContributedBy[nbExpr],
        "URL" -> urlWPR <> GetPromptTitle[nbExpr]
      |>
    ];

lsFileNames = FileNames["*nb", promptDirName];
Echo[lsFileNames // Length, "Number of notebooks:"];

AbsoluteTiming[
  aPromptRecords = Map[(Echo[#]; PromptNotebookToRecord[#]) &, lsFileNames];
];

aPromptRecords2 = Select[aPromptRecords, StringQ@#["PromptText"] &];
Echo[aPromptRecords2 // Length, "Filtered count:"];

Export[FileNameJoin[{dirName, "JSON", "prompts_new.json"}], aPromptRecords2, "JSON"];
