---
layout: post
author: Owen Rumney
title: Client side encryption using Boto3 and AWS KMS
tags: [aws, boto3, encryption]
categories: [Amazon Web Services, Programming]

---

Towards the end of 2014 Amazon released the KMS service to provide a cheaper cut down offering for [Key Management Services](http://aws.amazon.com/kms/) than those provided with the CloudHSM solutions (although it still uses hardware HSM underneath).

KMS service can be accessed through IAM service at the bottom option on the left side menu is **Encryption Keys**. May sure you change the region filter to the correct region before creating or trying to view your customer keys.

To create the customer key click the **Create Key** button and follow through the instructions to create a new master key - take a note of the **Key ID** then you're ready to go.

You need a couple of libraries before you start, for testing I use [virtualenv](https://pypi.python.org/pypi/virtualenv)

```text
bin/pip install boto3

bin/pip install pycrypto
```

##Encrypting

I'm using [PyCrypto](https://pypi.python.org/pypi/pycrypto/2.6.1) library for no other reason than it appeared in the most results when I was looking for a library.

I won't go into much detail on the code because I don't know much about encryption so I cobbled this together from the information in the pycrypto page.

The key that is going to be supplied is the data key generated from the AWS key management service.

```python
from Crypto import Random
from Crypto.Cipher import AES

def pad(s):
    return s + b"/0" *(AES.block_size - len(s) % AES.block_size)

def encrypt(message, key, key_size=256):
    message = pad(message)
    iv = Random.new().read(AES.block_size)
    cipher = AES.new(key, AES.MODE_CBC, iv)
    return iv + cipher.encrypt(message)

def decrypt(ciphertext, key):
    iv = ciphertext[:AES.block_size]
    cipher = AES.new(key, AES.MODE_CBC, iv)
    plaintext = cipher.decrypt(ciphertext[AES.block_size:])
    return plaintext.rstrip(b"\0")

def encrypt_file(file_name, key):
    with open(file_name, 'rb') as fo:
        plaintext = fo.read()
    enc = encrypt(plaintext, key)
    with open(file_name + ".enc", 'wb') as fo:
        fo.write(enc)

def decrypt_file(file_name, key):
    with open(file_name, 'rb') as fo:
        ciphertext = fo.read()
    dec = decrypt(ciphertext, key)
    with open(file_name[:-4], 'wb') as fo:
        fo.write(dec)
```

##Creating the data key to encrypt

For each item I want to encrypt I am going to create a new data key - this is a key that is generated in the KMS and the master key for the customer is used to encrypt it.

The call to the api returns the plaintext key and the cipher version for storage with the encrypted file (in the case of S3 you could upload the base64 encoded version to a metadata flag)

In this code, customer_key is the KeyId from the AWS console for the key you created at the start - its a guid.

```python
import boto3

kms = boto3.client('kms')
data_key_req = kms.generate_data_key(KeyId=customer_key, KeySpec='AES_256')
data_key = data_key_req['Plaintext']
data_key_ciphered = data_key_req['CiphertextBlob']

encrypt_file(filepath, data_key)

```

This will create a new encrypted file for file `test.txt` it would create a new file `test.txt.enc`

if you were going to upload to s3, you might use something like;

```python
import base64

s3 = boto3.client('s3')
s3.put_object(Bucket='mybucketname', Body=open('test.txt.enc', 'r'),
Key='test.txt', Metadata={'encryption-key': base64.b64encode(data_key_ciphered)})

```
