%{
#include<stdio.h>
#include<stdlib.h>

#include<string>
#include<vector>
#include<string.h>

using namespace std;

extern int yylex(void);
void yyerror(const char *msg);
extern int currLine;

char *identToken;
int numberToken;

int  count_names = 0;
string currCode = "";
string beginCode = "";
vector<string> allLines;
int checkCommas = 0;
string backTrack = "";

enum Type { Integer, Array };
struct Symbol {
  std::string name;
  Type type;
};
struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};

std::vector <Function> symbol_table;


Function *get_function() {
  int last = symbol_table.size()-1;
  return &symbol_table[last];
}

bool find(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      return true;
    }
  }
  return false;
}

void add_function_to_symbol_table(std::string &value) {
  Function f; 
  f.name = value; 
  symbol_table.push_back(f);
}

void add_variable_to_symbol_table(std::string &value, Type t) {
  Symbol s;
  s.name = value;
  s.type = t;
  Function *f = get_function();
  f->declarations.push_back(s);
}

void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
    printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
    }
  }
  printf("--------------------\n");
}


%}


%union {
  char *op_val;
}

%define parse.error verbose
%start prog_start
%token BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY
%token FUNCTION 
%token INTEGER 
%token WRITE
%token SUB ADD MULT DIV MOD
%token SEMICOLON COLON COMMA ASSIGN
%token <op_val> NUMBER 
%token <op_val> IDENT
%type <op_val> symbol 

%%

prog_start: functions
{
  //
}

functions: 
/* epsilon */
{ 
  //
}
| function functions
{
  //
};

function: FUNCTION IDENT 
{
  // midrule:
  // add the function to the symbol table.
  std::string func_name = $2;
  add_function_to_symbol_table(func_name);
}
	SEMICOLON
	BEGIN_PARAMS declarations END_PARAMS
	BEGIN_LOCALS declarations END_LOCALS
	BEGIN_BODY statements END_BODY
{
  printf("function %s\n", $2);
  for(int i = 0; i < allLines.size(); ++i) {
    printf(allLines.at(i).c_str());
  }
  printf("endfunc\n");
  printf("\n");
};

declarations: 
/* epsilon */
{
  //
}
| declaration SEMICOLON declarations
{
  //
};

declaration: 
	IDENT COLON INTEGER
{
  currCode += (". ");
  currCode += ("%s", $1);
  currCode += ("\n");
  allLines.push_back(currCode);
  currCode = "";

  // add the variable to the symbol table.
  std::string value = $1;
  Type t = Integer;
  add_variable_to_symbol_table(value, t);
};

statements: 
statement SEMICOLON
{
  //
}
| statement SEMICOLON statements
{
  //
};

statement: 
IDENT ASSIGN symbol ADD symbol
{
  backTrack = $1;
  beginCode = (". temp");
  beginCode += ("\n");
  allLines.push_back(beginCode);
  beginCode = ("+ temp");
  beginCode += (", ");
  currCode = beginCode + currCode + "\n";
  allLines.push_back(currCode);
  currCode = "";
  beginCode = "";
}
| IDENT ASSIGN symbol SUB symbol
{
  backTrack = $1;
  beginCode = (". temp");
  beginCode += ("\n");
  allLines.push_back(beginCode);
  beginCode = ("- ");
  beginCode += ("temp");
  beginCode += (", ");
  currCode = beginCode + currCode + "\n";
  allLines.push_back(currCode);
  currCode = "";
}
| IDENT ASSIGN symbol MULT symbol
{
  backTrack = $1;
  beginCode = (". temp");
  beginCode += ("\n");
  allLines.push_back(beginCode);
  beginCode = ("* ");
  beginCode += ("temp");
  beginCode += (", ");
  currCode = beginCode + currCode + "\n";
  allLines.push_back(currCode);
  currCode = "";
}
| IDENT ASSIGN symbol DIV symbol
{
  backTrack = $1;
  beginCode = (". temp");
  beginCode += ("\n");
  allLines.push_back(beginCode);
  beginCode = ("/ ");
  beginCode += ("temp");
  beginCode += (", ");
  currCode = beginCode + currCode + "\n";
  allLines.push_back(currCode);
  currCode = "";
}
| IDENT ASSIGN symbol MOD symbol
{
  backTrack = $1;
  beginCode = (". temp");
  beginCode += ("\n");
  allLines.push_back(beginCode);
  beginCode = ("%% ");
  beginCode += ("temp");
  beginCode += (", ");
  currCode = beginCode + currCode + "\n";
  allLines.push_back(currCode);
  currCode = "";
}

| IDENT ASSIGN symbol
{
  beginCode = ("= ");
  beginCode += ("%s", $1);
  beginCode += (", ");
  currCode = beginCode + currCode + "\n";
  allLines.push_back(currCode);
  currCode = "";
}

| WRITE IDENT
{
  currCode += ("= " + backTrack + ", temp");
  currCode += ("\n");
  allLines.push_back(currCode);
  currCode = "";
  count_names++;
  currCode += (".> ");
  currCode += (backTrack);
  currCode += ("\n");
  allLines.push_back(currCode);
  currCode = "";
}


symbol: 
IDENT 
{
  currCode += ("%s", $1);
  if(checkCommas == 1) {
    checkCommas = 0;
  }
  else {
    checkCommas++;
    currCode += (", ");
  }
  $$ = $1; 
}
| NUMBER 
{
  currCode += ("%s", $1);
  checkCommas = 0;
  $$ = $1; 
}

%%

int main(int argc, char **argv)
{
   yyparse();
   print_symbol_table();
   return 0;
}

void yyerror(const char *msg)
{
   printf("** Line %d: %s\n", currLine, msg);
   exit(1);
}
