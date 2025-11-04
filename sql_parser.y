%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

/* Node type definitions */
typedef enum {
    NODE_SELECT,
    NODE_FROM,
    NODE_WHERE,
    NODE_CONDITION,
    NODE_IDENTIFIER,
    NODE_NUMBER
} NodeType;

/* AST node structure */
typedef struct Node {
    NodeType type;
    char *strVal;
    int intVal;
    struct Node *left;
    struct Node *right;
} Node;

Node* makeNode(NodeType type, Node* left, Node* right);
Node* makeLeafStr(NodeType type, char* str);
Node* makeLeafNum(NodeType type, int num);
void printAST(Node* root, int depth);

Node* root = NULL;
%}

%union {
    char *str;
    int num;
    struct Node* node;
}

%token SELECT FROM WHERE EQ SEMICOLON
%token <str> IDENTIFIER
%token <num> NUMBER
%type <node> statement select_clause from_clause where_clause condition

%start statement

%%

statement:
      select_clause from_clause where_clause SEMICOLON {
          root = makeNode(NODE_SELECT, $1, makeNode(NODE_FROM, $2, $3));
          printf("\n--- AST for SQL Query ---\n");
          printAST(root, 0);
      }
;

select_clause:
      SELECT IDENTIFIER { $$ = makeLeafStr(NODE_IDENTIFIER, $2); }
;

from_clause:
      FROM IDENTIFIER   { $$ = makeLeafStr(NODE_IDENTIFIER, $2); }
;

where_clause:
      /* empty */       { $$ = NULL; }
    | WHERE condition   { $$ = $2; }
;

condition:
      IDENTIFIER EQ NUMBER {
          Node* left = makeLeafStr(NODE_IDENTIFIER, $1);
          Node* right = makeLeafNum(NODE_NUMBER, $3);
          $$ = makeNode(NODE_CONDITION, left, right);
      }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse Error: %s\n", s);
}

Node* makeNode(NodeType type, Node* left, Node* right) {
    Node* n = malloc(sizeof(Node));
    n->type = type;
    n->strVal = NULL;
    n->intVal = 0;
    n->left = left;
    n->right = right;
    return n;
}

Node* makeLeafStr(NodeType type, char* str) {
    Node* n = malloc(sizeof(Node));
    n->type = type;
    n->strVal = strdup(str);
    n->intVal = 0;
    n->left = n->right = NULL;
    return n;
}

Node* makeLeafNum(NodeType type, int num) {
    Node* n = malloc(sizeof(Node));
    n->type = type;
    n->intVal = num;
    n->strVal = NULL;
    n->left = n->right = NULL;
    return n;
}

void printAST(Node* root, int depth) {
    if (!root) return;
    for (int i = 0; i < depth; i++) printf("  ");

    switch (root->type) {
        case NODE_SELECT:    printf("SELECT\n"); break;
        case NODE_FROM:      printf("FROM\n"); break;
        case NODE_WHERE:     printf("WHERE\n"); break;
        case NODE_CONDITION: printf("CONDITION (=)\n"); break;
        case NODE_IDENTIFIER:printf("IDENTIFIER: %s\n", root->strVal); break;
        case NODE_NUMBER:    printf("NUMBER: %d\n", root->intVal); break;
        default:             printf("UNKNOWN NODE\n");
    }

    if (root->left) printAST(root->left, depth + 1);
    if (root->right) printAST(root->right, depth + 1);
}

int main() {
    printf("Enter SQL query (end with ;):\n");
    yyparse();
    return 0;
}
