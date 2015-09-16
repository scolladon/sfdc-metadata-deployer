Salesforce Metadata Online Deployment Tool
==========================

This Library
============
Allow to deploy from one org to another from a visualforce page.
Take in input a csv file formatted like the example elements.csv or a package.xml.
Works with modern browser ;)

Installation
============
1. Click the deploy button and follow the deploy process.
<a href="https://githubsfdeploy.herokuapp.com?owner=ForceComDeveloper&repo=sfdc-metadata-deployer">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>
2. Connect to the org where you deployed the tool.
3. Configure the connected App Deployment to have the correct callback url (the callback url has to be like https://<your_node_instance>.salesforce.com/apex/deployment) : Go to Setup => Create => Apps => (Connected App) Deployment.
4. Copy "Client ID" and "Callback URL" values.
5. Put in the javascript variable "ConnectedAppConfig" in the ApexPage Deployment the values previously copied (defined at the beginning of the page) : Setup => Develop => Page => Edit (Deployment).
    * Client ID : Search for the string *&lt;cliendId&gt;* and put your "Client ID" value
    * Callback URL : Search for the string *&lt;callbackUrl&gt;* and put your "Callback URL" value
6. you're done :)

How To Use
==========
1. Retrieve content by dropping CSV/XML file
2. Deploy content by dropping ZIP file

Version
=======
1.0.1

Tech
====

Here the open source project used:

* [jsforce] - Salesforce API Library for JavaScript applications
* [bootstrap] - the most popular HTML, CSS, and JS framework for developing responsive, mobile first projects on the web
* [pace] - an automatic web page progress bar
* [papaparse] - the powerful, in-browser CSV parser for big boys and girls
* [jQuery] - duh
* [xml2json] - a simple jQuery plugin that converts XML data
* [Gulp] - the streaming build system
* [lz-string] - JavaScript compression, fast!
