---
layout: post
title: Databricks Single SignOn with Azure Active Directory
description: Step by step instructions for configuring Azure Active Directory to work with Databricks for Single SignOn
tags: [platform, azure, databrick, authentication, saml]
category: Spark
---

## Overview

At my current workplace we are using Databricks with much success. Having recently activated the Security Operations Package I was keen to implement the Single SignOn (SSO) functionality.

The documentation provided by Databricks doesn't seem to cover integrating with Azure Active Directory as a SAML 2.0 Identity Provider and it took some effort to work out how to do it.

## Simple Steps

1. Log into Azure Portal and from the menu on the left, select `Azure Active Directory` then `Enterprise applications` from the secondary menu.
   ![Azure Active Directory - Enterprise Apps]({{ site.baseurl }}/images/azure_ad_enterprise_apps.png)

2. Select `New Application` to create a new Enterprise application
   ![Azure Active Directory - New App]({{ site.baseurl }}/images/azure_ad_new_app.png)

3) Databricks isn't one of the Gallery Applications at the time of writing, so select `Non-Gallery Application` from the available list.
   ![Azure Active Directory - Non Gallery Application]({{ site.baseurl }}/images/azure_ad_non_gallery.png)

4. This is where the Databricks instructions is unclear, you need to use your Databricks URL as the `Identity Provider Entity ID`.
   ![Azure Active Directory - Basic SAML Settings]({{ site.baseurl }}/images/azure_ad_basic_saml.png)

5. When you've completed and saved the basic settings, you'll be able to download the x.509 certificate and have access to the Login URL to use in the Databricks Admin Console. Download the cert and open with a text editor to extract the certificate content
   ![Azure Active Directory - Cert and Login]({{ site.baseurl }}/images/azure_ad_cert_and_login.png)

6. You can now take these details over to the Databricks admin console to configure SSO. Enter the details into the Single Sign On tab in the `Admin Console` page. Your `Identity Provider Entity ID` is the root of your Databricks cloud URL.

![Databricks Admin Console - SSO]({{ site.baseurl }}/images/databricks_single_signon.png)

7. You can now log out, then log in using Single SignOn through Azure which should get you straight back in.
   ![Databricks Admin Console - SSO Login]({{ site.baseurl }}/images/databricks_single_signon_login.png)

### A Note on Allow User Creation

If you enable `Allow auto user creation`, when a user logs in, it will create the user for them automatically. This is fine if you've configured Azure Active Directory to specify users who have a Role to use the `Enterprise Application`. For our use case, I've gone with this option disabled and enabled open access at the Active Directory end. This means that unknown (from a Databricks perspective) but otherwise authenticated users don't have access to the environment
