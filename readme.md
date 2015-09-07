Salesforce Metadata Online Deployment Tool
==========================

<a href="https://githubsfdeploy.herokuapp.com?owner=ForceComDeveloper&repo=sfdc-metadata-deployer">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

This Library
============
Allow to deploy from one org to another from a visualforce page.
Take in input a csv file formatted like the example elements.csv.
Or a package.xml without the first tag (<?xml version...?>)
Works with modern browser ;)

Installation
============
1. Configure the connected App Deployment to have the correct callback url (the callback url has to be like https://<your_node>.salesforce.com/apex/deployment)
2. put in the ApexPage Deployment the values "Client ID", "Client Secret" and "Callback URL" in the javascript variable "Oauth2AppConfig" (defined at the beginning of the page)
3. you're done

How To
=======
1. Select the retrieve environment (where the metadata will be retrieved)
2. Select the deploy environment (where the metadata will be deployed)
3. Upload you elements file (csv like the example from your team change tracking or a package.xml) via the input or by dropping the file
4. Click on retrieve to retrieve the metadata. You will download the zip related file for archive purpose.
5. Click on deploy to deploy the metadata.

Licence
=======
The MIT License (MIT)

Copyright (c) 2015 SCN-Consulting

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

You can also drop a zip archive on the deploy button to instantly deploy already retrieved metadata (for flow deployment);