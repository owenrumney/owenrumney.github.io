---
layout: post
title: Leveraging Annotations in Go
date: 2022-09-26 00:00:00
image: "/assets/img/owen.png"
description: An introduction to using annotations on structs in Go
tags: [go, programming]
categories: [Programming]
twitter_text: Introduction to using type annotations in Go
---

In [defsec](https://github.com/aquasecurity/defsec){:target="\_blank"}, we have a large number of Go objects which represent real world Cloud entities. A documented schema is required, but due to the number, it would be nice to automate the generation.

In this post, I'm going to give a simplified introduction to Annotations that can be used with `text/template`in a struct to aid this.

### S3 Bucket example

Lets take the `S3 bucket` as an example. Regardless of how we create the bucket (Terraform, Ansible, CloudFormation etc), there are common attributes that reflect it.

Lets look at a simplified `defsec` object that represents an `S3 bucket`;

```go
package main

import (
	"github.com/liamg/iamgo"
)

type Bucket struct {
	Name              string
	PublicAccessBlock *PublicAccessBlock
	BucketPolicies    []Policy
	Encryption        Encryption
	Versioning        Versioning
	Logging           Logging
	ACL               string
}

type PublicAccessBlock struct {
	BlockPublicACLs       bool
	BlockPublicPolicy     bool
	IgnorePublicACLs      bool
	RestrictPublicBuckets bool
}

type Logging struct {
	Enabled      bool
	TargetBucket string
}

type Versioning struct {
	Enabled   bool
	MFADelete bool
}

type Encryption struct {
	Enabled   bool
	Algorithm string
	KMSKeyId  string
}

type Policy struct {
	Name     string
	Document Document
	Builtin  bool
}

type Document struct {
	Parsed   iamgo.Document
	IsOffset bool
	HasRefs  bool
}

```

This type has all the core attributes that we might want to check for any possible misconfigurations. We have written a comprehensive list of checks that can be applied to a bucket represented in this type - but what if you wanted to write your own Rego rule against the type? You might want to know what the properties mean?

## Annotations

If you have experience with Go, you likely know that you can use annotations to tell the `json` or `yaml` libraries how to you want the Type to look when rendered into `json` or `yaml`.

For example, you might have something like;

```go

type HairColour int

const (
    Brown HairColour = iota
    Blonde
    Grey
    Black
    Purple
)

type Person struct {
    Name string   `json:"name",yaml:"name"`
    Age int       `json:"age",yaml:"age"`
    HairColor int `json:"hair_colour",yaml:"hair_colour"`
}
```

We could then use the `json` library to display this;

```go
package main

func main() {

	person := Person{
		Name:      "Owen",
		Age:       40,
		HairColor: 2,
	}

	content, err = json.MarshalIndent(person, "", "  ")
	if err != nil {
		panic(err)
	}

	fmt.Println(string(content))
}
```

which would give us the output;

```json
{
  "name": "Owen",
  "age": 40,
  "hair_colour": 2
}
```

## Back to the Bucket

Returning to our bucket, if we wanted to support people writing Rego rules against this schema, we might want to use custom annotations with a description of what the property actually means.

Below, I've updated the `S3 Bucket` with additional documentation about what each attribute means;

```go
package main

import (
	"github.com/liamg/iamgo"
)

type Bucket struct {
	Name              string             `json:"name",doc:"The name of the bucket"`
	PublicAccessBlock *PublicAccessBlock `json:"public_access_block",doc:"The public access block configuration for the bucket"`
	BucketPolicies    []Policy           `json:"bucket_policies",doc:"The bucket policies for the bucket"`
	Encryption        Encryption         `json:"encryption",doc:"Is the S3 bucket encrypted?"`
	Versioning        Versioning         `json:"versioning",doc:"Is the S3 bucket versioning enabled?"`
	Logging           Logging            `json:"logging",doc:"Is the S3 bucket logging enabled?"`
	ACL               string             `json:"acl",doc:"The ACL for the bucket"`
}

type PublicAccessBlock struct {
	BlockPublicACLs       bool `json:"block_public_acls",doc:"Is the S3 bucket blocking public ACLs?"`
	BlockPublicPolicy     bool `json:"block_public_policy",doc:"Is the S3 bucket blocking public policies?"`
	IgnorePublicACLs      bool `json:"ignore_public_acls",doc:"Is the S3 bucket ignoring public ACLs?"`
	RestrictPublicBuckets bool `json:"restrict_public_buckets",doc:"Is the S3 bucket restricting public buckets?"`
}

type Logging struct {
	Enabled      bool   `json:"enabled",doc:"Is the S3 bucket logging enabled?"`
	TargetBucket string `json:"target_bucket",doc:"The target bucket for the S3 bucket logging"`
}

type Versioning struct {
	Enabled   bool `json:"enabled",doc:"Is the S3 bucket versioning enabled?"`
	MFADelete bool `json:"mfa_delete",doc:"Is the S3 bucket versioning MFA delete enabled?"`
}

type Encryption struct {
	Enabled   bool   `json:"enabled",doc:"Is the S3 bucket encrypted?"`
	Algorithm string `json:"algorithm",doc:"The encryption algorithm used"`
	KMSKeyId  string `json:"kms_key_id",doc:"The KMS key ID used"`
}

type Policy struct {
	Name     string   `json:"name",doc:"The name of the policy"`
	Document Document `json:"document",doc:"The policy document"`
	Builtin  bool     `json:"builtin",doc:"Is the policy a built-in policy"`
}

type Document struct {
	Parsed   iamgo.Document `json:"parsed",doc:"The parsed policy document"`
	IsOffset bool           `json:"is_offset",doc:"Is the policy document offset"`
	HasRefs  bool           `json:"has_refs",doc:"Does the policy document have references"`
}
```

We want to use this to generate some meaningful documentation for the user so they can quickly see what is expected of them.

We start with an example bucket for the docs

```go
bucket := Bucket{
	Name: "example-bucket",
	PublicAccessBlock: &PublicAccessBlock{
		BlockPublicACLs:       false,
		BlockPublicPolicy:     false,
		IgnorePublicACLs:      false,
		RestrictPublicBuckets: false,
	},
	BucketPolicies: []Policy{},
	Encryption: Encryption{
		Enabled:   false,
		Algorithm: "AE256",
		KMSKeyId:  "",
	},
	Versioning: Versioning{
		Enabled:   false,
		MFADelete: false,
	},
	Logging: Logging{
		Enabled: false,
	},
	ACL: "false",
}

exampleJson, err := json.MarshalIndent(bucket, "", "  ")
if err != nil {
	panic(err)
}
```

This gives us a `[]byte` of the `json` representation in a pretty-printed format.

We're not done yet, we're wanting to print this as documentation so people can work out what the attributes are for. To do this, we can make use of the extra annotation we have added.

```go
Name string `json:"name",doc:"The name of the bucket"`
```

To access the annotation, we need to use the `reflect` package to get the fields and read their annotations.

Lets start with a `doc` object to hold the attribute name and docString and make a `Map` to hold our objects in

```go
type doc struct {
	AttributeName string
	DocString     string
}

docs := make(map[string][]doc)
```

Next, we use reflection to get the type and iterate over the fields extracting the doc using a simple lookup on the `Tag` value

```go
docString, ok := field.Tag.Lookup("doc")
if !ok {
	continue
}
```

Which gives us a whole function of

```go
func processTypeForDocs(t reflect.Type, docs map[string][]doc, key string) {
	for i := 0; i < t.NumField(); i++ {
		field := t.Field(i)
		docString, ok := field.Tag.Lookup("doc")
		if !ok {
			continue
		}
		switch field.Type.Kind() {
		case reflect.String, reflect.Bool, reflect.Int, reflect.Float64:
			docs[key] = append(docs[key], doc{
				AttributeName: field.Name,
				DocString:     docString,
			})
		case reflect.Ptr:
			docs[key] = append(docs[key], doc{
				AttributeName: field.Name,
				DocString:     docString,
			})
			processTypeForDocs(field.Type.Elem(), docs, field.Name)
		case reflect.Struct:
			docs[key] = append(docs[key], doc{
				AttributeName: field.Name,
				DocString:     docString,
			})
			processTypeForDocs(field.Type, docs, field.Name)
		}
	}
}
```

Now we have a populated map, we can pass that to our documentation Template to generate the docs.

{% raw %}
var docTemplate = `# S3 Bucket

    ## Example S3 Bucket JSON

    ` + "```json" + `
    {{ .ExampleJSON }}
    ` + "```" + `
    {{ range $key, $value := .Docs }}### {{ $key }}

    | Attribute Name     | Description          |
    | ------------------ | -------------------- |
    | {{ range $value }} | {{ .AttributeName }} | {{ .DocString }} |
    {{ end }}
    {{end}}
    `

{% endraw %}

Using the templated string above, we can use Go Templates to generate our documentation

```go

docs := make(map[string][]doc)
docs["Bucket"] = []doc{}

processTypeForDocs(reflect.TypeOf(bucket), docs, "Bucket")

tmplt, _ := template.New("doc").Parse(docTemplate)

tmplt.Execute(os.Stdout, map[string]nterface{}{
	"ExampleJSON": string(exampleJson),
	"Docs":        docs,
})
```

Here we are creating a `Map` with the attributes required in the template, some example `json` and the `doc` objects we created.

When we run it in the terminal, we get the Markdown below written out.

````markdown
# S3 Bucket

## Example S3 Bucket JSON

```json
{
  "name": "example-bucket",
  "public_access_block": {
    "block_public_acls": false,
    "block_public_policy": false,
    "ignore_public_acls": false,
    "restrict_public_buckets": false
  },
  "bucket_policies": [],
  "encryption": {
    "enabled": false,
    "algorithm": "AE256",
    "kms_key_id": ""
  },
  "versioning": {
    "enabled": false,
    "mfa_delete": false
  },
  "logging": {
    "enabled": false,
    "target_bucket": ""
  },
  "acl": "false"
}
 ` ``
### Bucket

| Attribute Name    | Description                                          |
| ----------------- | ---------------------------------------------------- |
| Name              | The name of the bucket                               |
| PublicAccessBlock | The public access block configuration for the bucket |
| Encryption        | Is the S3 bucket encrypted?                          |
| Versioning        | Is the S3 bucket versioning enabled?                 |
| Logging           | Is the S3 bucket logging enabled?                    |
| ACL               | The ACL for the bucket                               |

### Encryption

| Attribute Name | Description                   |
| -------------- | ----------------------------- |
| Enabled        | Is the S3 bucket encrypted?   |
| Algorithm      | The encryption algorithm used |
| KMSKeyId       | The KMS key ID used           |

### Logging

| Attribute Name | Description                                 |
| -------------- | ------------------------------------------- |
| Enabled        | Is the S3 bucket logging enabled?           |
| TargetBucket   | The target bucket for the S3 bucket logging |

### PublicAccessBlock

| Attribute Name        | Description                                  |
| --------------------- | -------------------------------------------- |
| BlockPublicACLs       | Is the S3 bucket blocking public ACLs?       |
| BlockPublicPolicy     | Is the S3 bucket blocking public policies?   |
| IgnorePublicACLs      | Is the S3 bucket ignoring public ACLs?       |
| RestrictPublicBuckets | Is the S3 bucket restricting public buckets? |

### Versioning

| Attribute Name | Description                                     |
| -------------- | ----------------------------------------------- |
| Enabled        | Is the S3 bucket versioning enabled?            |
| MFADelete      | Is the S3 bucket versioning MFA delete enabled? |

```
````

<br />

## Actual Rendered Output

<br />

# S3 Bucket

## Example S3 Bucket JSON

```json
{
  "name": "example-bucket",
  "public_access_block": {
    "block_public_acls": false,
    "block_public_policy": false,
    "ignore_public_acls": false,
    "restrict_public_buckets": false
  },
  "bucket_policies": [],
  "encryption": {
    "enabled": false,
    "algorithm": "AE256",
    "kms_key_id": ""
  },
  "versioning": {
    "enabled": false,
    "mfa_delete": false
  },
  "logging": {
    "enabled": false,
    "target_bucket": ""
  },
  "acl": "false"
}
```

### Bucket

| Attribute Name    | Description                                          |
| ----------------- | ---------------------------------------------------- |
| Name              | The name of the bucket                               |
| PublicAccessBlock | The public access block configuration for the bucket |
| Encryption        | Is the S3 bucket encrypted?                          |
| Versioning        | Is the S3 bucket versioning enabled?                 |
| Logging           | Is the S3 bucket logging enabled?                    |
| ACL               | The ACL for the bucket                               |

### Encryption

| Attribute Name | Description                   |
| -------------- | ----------------------------- |
| Enabled        | Is the S3 bucket encrypted?   |
| Algorithm      | The encryption algorithm used |
| KMSKeyId       | The KMS key ID used           |

### Logging

| Attribute Name | Description                                 |
| -------------- | ------------------------------------------- |
| Enabled        | Is the S3 bucket logging enabled?           |
| TargetBucket   | The target bucket for the S3 bucket logging |

### PublicAccessBlock

| Attribute Name        | Description                                  |
| --------------------- | -------------------------------------------- |
| BlockPublicACLs       | Is the S3 bucket blocking public ACLs?       |
| BlockPublicPolicy     | Is the S3 bucket blocking public policies?   |
| IgnorePublicACLs      | Is the S3 bucket ignoring public ACLs?       |
| RestrictPublicBuckets | Is the S3 bucket restricting public buckets? |

### Versioning

| Attribute Name | Description                                     |
| -------------- | ----------------------------------------------- |
| Enabled        | Is the S3 bucket versioning enabled?            |
| MFADelete      | Is the S3 bucket versioning MFA delete enabled? |
