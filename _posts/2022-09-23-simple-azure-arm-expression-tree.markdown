---
layout: post
title: Parsing Azure ARM functions in Go
date: 2022-09-23 00:00:00
image: '/assets/img/owen.png'
description: A simplified guide to parsing function expressions in Azure ARM templates
tags: [scanning, expression trees, golang]
categories: [Scanning, Programming]
twitter_text: A simplified guide to parsing function expressions in Azure ARM templates
---

### An introduction

For those who don't know, I'm one of the original creators of [tfsec](https://tfsec.dev){:target="_blank"} and I now work on [Trivy](https://trivy.dev){:target="_blank"} as an open source engineer at [Aqua](https://aquasec.com){:target="_blank"}. Together with [@liam_galvin](https://twitter.com/liam_galvin){:target="_blank"} I am working on adding scanning support for `Azure ARM Templates` and ultimately `bicep` to Trivy.

`Azure ARM Templates` are written in JSON and define the infrastructure that is going to be applied when the template is applied to the Azure resource group. In the same way we scan Terraform and CloudFormation, we need to parse the template into our common objects from [defsec](https://github.com/aquasecurity/defsec){:target="_blank"}; these abstractions allow the same checks to be run on the object regardless of which language was used to define it.

#### An example

Take for example an `S3 Bucket`, the bucket has the concept of encryption and it is either encrypted or not so the common object might look something like;

```go
type Bucket struct {
    Encrypted      bool
    Versioned      bool
    LoggingEnabled bool
    // ... more attributes
}
```

It doesn't matter whether the source that was used to populate the object was Terraform;

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "example-bucket-encryption" {
   bucket = aws_s3_bucket.example-bucket.id
 
   rule {
     apply_server_side_encryption_by_default {
       kms_master_key_id = aws_kms_key.mykey.arn
       sse_algorithm     = "aws:kms"
     }
   }
}
```

or CloudFormation

```yaml
Resources:
  EncryptedBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - BucketKeyEnabled: true
            ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
    
```

The end result is the same and the check will work and the check can be applied;

```go
if bucket.Encrypted.IsFalse() {
	results.Add(&bucket, "Bucket does not have encryption enabled")
} else {
	results.AddPassed(&bucket, "Bucket encryption correctly configured")
}
```

### Azure ARM Template

Back to the Azure ARM template. Functions can be used in the Template for dynamic values - take for example this PostgreSQL Configuration option which uses the `format` function

```json
{
  "type": "Microsoft.DBforPostgreSQL/servers/configurations",
  "apiVersion": "2017-12-01",
  "name": "[format('{0}/{1}', 'myPostgreSQLServer', 'connection_throttling')]",
  "properties": {
    "value": "OFF"
  },
  "dependsOn": [
    "[resourceId('Microsoft.DBforPostgreSQL/servers', 'myPostgreSQLServer')]"
  ]
}
```

The name uses the `format` function to join two values together with a `/`. When parsing this block of template code, we need to be able to resolve the intent of the function so we can know at scan time the `name` for the `configuration` should be `myPostgreSQLServer/connection_throttling` to ensure it is applied to the correct parent resource.

### Parsing the Functions

Finally, we reach the point of the blog post. How do we write a parser/evaluator for the function.

> This code has been simplified in an attempt to keep it easy to follow

We need a number of parts;

#### A Lexer
The lexer is going to break the function into its constituent parts - lets call these `tokens`. Using our example from before;

```
format('{0]{1}', 'myPostgreSQLServer', 'connection_throttling')
```

this is made up of the following tokens;

|          part           | Token Type         |
| :---------------------: | ------------------ |
|         format          | TokenName          |
|            (            | TokenOpenParen     |
|        '{0}/{1}'        | TokenLiteralString |
|            ,            | TokenComma         |
|  'myPostgreSQLServer'   | TokenLiteralString |
|            ,            | TokenComma         |
| 'connection_throttling' | TokenLiteralString |
|            )            | TokenCloseParen    |


The lexer will read through the source string looking at each `Rune` and break down into logical tokens - core of the lexer just a loop over the runes

```golang
func (l *lexer) Lex() ([]Token, error) {
	var tokens []Token

	for {
		r, err := l.read()
		if err != nil {
			break
		}

		switch r {
		case ' ', '\t', '\r':
			continue
		case '\n':
			tokens = append(tokens, Token{Type: TokenNewLine})
		case '(':
			tokens = append(tokens, Token{Type: TokenOpenParen})
		case ')':
			tokens = append(tokens, Token{Type: TokenCloseParen})
		case ',':
			tokens = append(tokens, Token{Type: TokenComma})
		case '.':
			tokens = append(tokens, Token{Type: TokenDot})
		case '"', '\'':
            // lex string keeps walking the runes till it finds a closing quote
			token, err := l.lexString(r)
			if err != nil {
				return nil, fmt.Errorf("string parse error: %w", err)
			}
			tokens = append(tokens, token)
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
			l.unread()
			token, err := l.lexNumber()
			if err != nil {
				return nil, fmt.Errorf("number parse error: %w", err)
			}
			tokens = append(tokens, token)
		default:
			l.unread()
            // continue until the rune is not a alpha character
			tokens = append(tokens, l.lexKeyword())
		}
	}

	return tokens, nil
}
```

#### Token Walker

We now have a bunch of tokens that we need to turn into an evaluated result. We need to be able to traverse the tokens, looking at what they are.

```go
type tokenWalker struct {
	tokens          []Token
	currentPosition int
}

func newTokenWalker(tokens []Token) *tokenWalker {
	return &tokenWalker{
		tokens:          tokens,
		currentPosition: 0,
	}
}

// see what the next token is going to be without popping
func (t *tokenWalker) peek() Token {
	if t.currentPosition >= len(t.tokens) {
		return Token{}
	}
	return t.tokens[t.currentPosition]
}

func (t *tokenWalker) hasNext() bool {
	return t.currentPosition+1 < len(t.tokens)
}

// if pop has been called and we need to use the value we can 
// unpop to step back to the previous position
func (t *tokenWalker) unPop() {
	if t.currentPosition > 0 {
		t.currentPosition--
	}
}

func (t *tokenWalker) pop() *Token {
	if !t.hasNext() {
		return nil
	}

	token := t.tokens[t.currentPosition]
	t.currentPosition++
	return &token
}

```

This block of code holds the tokens and allows us to move back and forward on the them, looking at whats coming. 

#### Expression Tree

Now we are able to walk the tokens, we need to create the expression tree.

```go
func NewExpressionTree(code string) (Node, error) {
    // get the tokens using the lexer above
	tokens, err := lex(code)
	if err != nil {
		return nil, err
	}

	// create a walker for the nodes
	tw := newTokenWalker(tokens)

	// generate the root function
	return newFunctionNode(tw), nil
}

func newFunctionNode(tw *tokenWalker) Node {
	funcNode := &expression{
		name: tw.pop().Data.(string),
	}

	for tw.hasNext() {
		token := tw.pop()
		if token == nil {
			break
		}

        // depending on the TokenType we deal with each token differently
		switch token.Type {
		case TokenCloseParen:
			return funcNode
        
		case TokenName:
			if tw.peek().Type == TokenOpenParen {
                // this is a function so we need to go back a step and call the newFunctionNode
                // again to create the nested function tree
				tw.unPop()
				funcNode.args = append(funcNode.args, newFunctionNode(tw))
			}
		case TokenLiteralString, TokenLiteralInteger, TokenLiteralFloat:
			funcNode.args = append(funcNode.args, expressionValue{token.Data})
		}

	}
	return funcNode
}
```

This block takes the `code` - in this case the string with the function in it. The `code` is put through the lexer and we get the tokens that make it (see the table above for the tokens we have).

The walker is then stepped through looking at each token to see what type it is - if its a name followed by an open bracket we can say its the start of a function and we will stop at the next closing bracket and that is the bounds of the function. Anything in between that is a literal value is treated as a verbatim argument.


Our expression tree uses a `Node` interface with two types `expression` and `expressionValue` implementing the interface. The root `Node` will have each of its arguments `Evaluate` function called, if it is a literal value that will be returned verbatim, if it is an expression, it will be evaluated first; this allows us to nest the function calls.

```go
type Node interface {
	Evaluate() interface{}
}
```

The `Node` interface has a single function called `Evaluate` to return any value.

There are two types going to be used, both of these implement the interface. 

```go
type expression struct {
	name string
	args []Node
}

type expressionValue struct {
	val interface{}
}

// for each of the arguments we need to get the evaluated value
// either a verbatim value or the function result
func (f expression) Evaluate() interface{} {
	args := make([]interface{}, len(f.args))
	for i, arg := range f.args {
		args[i] = arg.Evaluate()
	}

	return functions[name](args...)
}


// if the expressionValue arg is a nested expression, we 
// need to evaluate that first
func (e expressionValue) Evaluate() interface{} {
	if f, ok := e.val.(expression); ok {
		return f.Evaluate()
	}
	return e.val
}
```

The last part of this is the call to `functions[name](args...)` which executes the function;

```go
var functions = map[string]func(args ...interface{}) interface{} {
    "format": Format
}

// The functions all have the same structure of accepting variadic options
// and returning an interface{}
func Format(args ...interface{}) interface{} {
	formatter := generateFormatterString(args...)

	return fmt.Sprintf(formatter, args[1:]...)
}

// the formatter string has the wrong style placeholders, so using the 
// args we can switch to the correct ones
func generateFormatterString(args ...interface{}) string {
	formatter, ok := args[0].(string)
	if !ok {
		return ""
	}
	for i, arg := range args[1:] {
		switch arg.(type) {
		case string:
			formatter = strings.ReplaceAll(formatter,"{"+i+"}", "%s")
		case int, int32, int64, uint, uint32, uint64:
			formatter = strings.ReplaceAll(formatter,"{"+i+"}", "%d")
		case float64, float32:
			formatter = strings.ReplaceAll(formatter,"{"+i+"}", "%f")
		}
	}
	return formatter
}
```

when `functions["format"](args...)` is called, it gets the function from the map, passing the args through to the function to return the result of a `fmt.Sprintf`

### A Test

Lets finish with a test to demonstrate

```go
func Test_resolveFormatFunc(t *testing.T) {

	tests := []struct {
		name     string
		expr     string
		expected string
	}{
		{
			name:     "simple format call",
			expr:     "format('{0}/{1}', 'myPostgreSQLServer', 'log_checkpoints')",
			expected: "myPostgreSQLServer/log_checkpoints",
		},
		{
			name:     "simple format call with numbers",
			expr:     "format('{0} + {1} = {2}', 1, 2, 3)",
			expected: "1 + 2 = 3",
		},
        {
			name:     "format with nested format",
			expr:     "format('{0} + {1} = {2}', format('{0}', 1), 2, 3)",
			expected: "1 + 2 = 3",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
            et, err := expressions.NewExpressionTree(tt.expr)
            require.NoError(t, err)

            evaluatedValue := et.Evaluate()
            assert.Equal(t, tt.expected, resolvedValue.(string))
		})
	}
}
```

### Wrapping Up

There is a lot more to it, and a lot more work to implement each of the functions supported by ARM, but the general structure is now there to get started.

Checkout [defsec](https://github.com/aquasecurity/defsec/tree/master/pkg/scanners){:target="_blank"} to learn more about how we parse `Terraform`, `CloudFormation`, `Dockerfile` `Kubernetes Manifests` and `Helm Charts` to name a few.