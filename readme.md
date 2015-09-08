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
Or a package.xml without the first tag (<?xml version...?>).
Works with modern browser ;)

Installation
============
1. Configure the connected App Deployment to have the correct callback url (the callback url has to be like https://<your_node_instance>.salesforce.com/apex/deployment) : Setup => Create => Apps => (Connected App) Deployment.
2. Copy "Client ID" value, "Client secret" value and "Callback URL" value.
2. Put in the ApexPage Deployment the values previously copied "Client ID", "Client Secret" and "Callback URL" in the javascript variable "Oauth2AppConfig" (defined at the beginning of the page) : Setup => Develop => Page => Edit (Deployment).
    * Client ID : Search for the string "<cliendId>" and put your "Client ID" value
    * Client Secret : Search for the string "<clientSecret>" and put your "Client Secret" value
    * Callback URL : Search for the string "<callbackUrl>" and put your "Callback URL" value
3. you're done :)

How To
=======
1. Select the retrieve environment (where the metadata will be retrieved)
2. Select the deploy environment (where the metadata will be deployed)
3. Upload you elements file (csv like the example from your team change tracking or a package.xml) via the input or by dropping the file
4. Click on retrieve to retrieve the metadata. You will download the zip related file for archive purpose.
5. Click on deploy to deploy the metadata.

You can also drop a zip archive on the deploy button to instantly deploy already retrieved metadata (for flow deployment);