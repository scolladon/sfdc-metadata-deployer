// TODO
/*
  allow giving github repo to see
*/
jQuery.noConflict();
jQuery(function(){
  var retrieve_config,
      deploy_config,
      accessToken_query = jQuery.getUrlVar('access_token'),
      instanceUrl_query = jQuery.getUrlVar('instance_url'),
      state = jQuery.getUrlVar('state');
  window.history.pushState(null, "Salesforce Metadata Deployment", "/apex/deployment");
  if(typeof accessToken_query !== 'undefined'
  && typeof instanceUrl_query !== 'undefined'){
    if(typeof state === 'undefined') {
      retrieve_config = new Oauth2Settings(decodeURIComponent(instanceUrl_query),decodeURIComponent(accessToken_query));
    } else {
      deploy_config = new Oauth2Settings(decodeURIComponent(instanceUrl_query),decodeURIComponent(accessToken_query));
      var state = JSON.parse(decodeURIComponent(state));
      retrieve_config = new Oauth2Settings(state.instanceUrl,state.accessToken);
    }
  }
  if(!retrieve_config) {
    jQuery('#retrieve-setup-button').click(function(){
      var url = 'https://'+(jQuery('#retrieve-prod').is(':checked') ? 'login' : 'test') + '.salesforce.com/services/oauth2/authorize?response_type=token&client_id='+Oauth2AppConfig.clientId+'&redirect_uri='+Oauth2AppConfig.redirectUri+'&prompt=login&display=popup';
      window.open(url,'_self')
    });
    jQuery('.retrieve-setup').show(500);
  } else if(!deploy_config) {

    var url = 'https://'+(jQuery('#deploy-prod').is(':checked') ? 'login' : 'test') + '.salesforce.com/services/oauth2/authorize?response_type=token&client_id='+Oauth2AppConfig.clientId+'&redirect_uri='+Oauth2AppConfig.redirectUri+'&prompt=login&display=popup&state='+encodeURIComponent(JSON.stringify(retrieve_config));
    jQuery('#deploy-setup-button').click(function(){
      window.open(url,'_self')
    });
    jQuery('.deploy-setup').show(500);
  }
  // Add all evenment on the page
  else {
    var dep = new Deployment(retrieve_config,deploy_config);
    jQuery('#fileToUpload').change(function(){
        var input = jQuery(this),
            label = input.val().replace(/\\/g, '/').replace(/.*\//, '');
        var name = input.parents('.input-group').find(':text');
        name.val(label);
        dep.createPackage(input.prop('files')[0]);
        this.value = null;
    });
    jQuery('#retrieve-button').click(function(){
        dep.retrievePackage();
    });
    jQuery('#deploy-button').click(function(){
      var options = {};
      options.testLevel = jQuery('.radio :checked').val();
      options.rollbackOnError = jQuery('#rollback').is(':checked');
      options.checkOnly = jQuery('#check').is(':checked');
      dep.deployPackage(options);
    });

    // Drop handling :
    jQuery('.drop-zone').on('dragenter', function() {
      jQuery(this).css('border', '3px dashed #BBBBBB');
      return false;
    });

    jQuery('.drop-zone').on('dragover', function(e){
      e.preventDefault();
      e.stopPropagation();
      jQuery(this).css('border', '3px dashed #BBBBBB');
      return false;
    });

    jQuery('.drop-zone').on('dragleave', function(e) {
      e.preventDefault();
      e.stopPropagation();
      jQuery(this).css('border', '');
      return false;
    });

    jQuery('#deploy').on('drop', function(e) {
      if(e.originalEvent.dataTransfer){
        if(e.originalEvent.dataTransfer.files.length) {
           // Stop the propagation of the event
          e.preventDefault();
          e.stopPropagation();
           // Main function to upload
          var f = e.originalEvent.dataTransfer.files[0];
          var reader = new FileReader();
          reader.onload = function(){
            dep._zipContent = btoa(e.target.result);
            var options = {};
            options.testLevel = jQuery('.radio :checked').val();
            options.rollbackOnError = jQuery('#rollback').is(':checked');
            options.checkOnly = jQuery('#check').is(':checked');
            dep.deployPackage(options);
          };
          reader.readAsBinaryString(f);
        }
      }
      jQuery(this).css('border', '');
      return false;
    });

    jQuery('#upload').on('drop', function(e) {
      if(e.originalEvent.dataTransfer){
         if(e.originalEvent.dataTransfer.files.length) {
           // Stop the propagation of the event
           e.preventDefault();
           e.stopPropagation();
           // Main function to upload
           dep.createPackage(e.originalEvent.dataTransfer.files[0]);
         }
      }
      jQuery(this).css('border', '');
      return false;
    });
    jQuery('.process-form').show(500);
  }
});

var Oauth2Settings = function(instanceUrl,accessToken) {
  this.instanceUrl = instanceUrl;
  this.accessToken = accessToken;
}

/*
	Deployment class
*/
var Deployment = function(retrieve_config,deploy_config) {
  this._package = {};
  this._zipContent = {};
  this._tests = [];
  this._file;
  this.retrieveConn = new jsforce.Connection({
    instanceUrl : retrieve_config.instanceUrl,
    accessToken : retrieve_config.accessToken,
    proxyUrl : '/services/proxy'
  });
  this.retrieveConn.metadata.pollTimeout= 300000;
  this.deployConn = new jsforce.Connection({
    instanceUrl : deploy_config.instanceUrl,
    accessToken : deploy_config.accessToken,
    proxyUrl : '/services/proxy'
  });
  this.deployConn.metadata.pollTimeout= 300000;
}

Deployment.prototype = function(){

  // Private members
  var createPackageCSV = function(){
    var reader = new FileReader();
    var that = this;
    reader.readAsText(that._file);
    reader.onloadend = function(e){
      jQuery('#content-upload-info').html('<p>'+e.target.result+'</p>');
      jQuery('#content-upload-success').html('<p>File ok</p>');
      jQuery('#content-upload-info').show(500);
    }
    Papa.parse(that._file, {
      complete: function(results) {
        // init
        that._package = {}
        that._package.types = [];
        that._package.version = '34.0';
        that._tests = [];

        var types = that._package.types;
        results.data.shift();
        results.data.forEach(function(row,i){
          if(!row[0] && !row[1]){return;}
          var typename = row[0],
          member = row[1],
          type;
          var typeFound = types.filter(function (item) {
            return item.name === typename;
          });
          if(typeFound.length === 0){
            type = {};
            type.members = [];
            type.name = typename;
            types.push(type);
          } else {
            type = typeFound[0];
          }
          if(member &&
          type.members.indexOf(member) === -1)    {
          type.members.push(member);
            member = member.toLowerCase();
            if(typename === 'ApexClass' && member.indexOf("test") > -1){
              that._tests.push(member);
            }
          }
          jQuery('#content-retrieve-info').html('<p>' + JSON.stringify(that._package, null,1) + '</p>');
          jQuery('.retrieve-process').show(500);
        });
      }
    });
  },

  createPackageXML = function(){
    var that = this;
    var reader = new FileReader();
    reader.readAsText(that._file);
    reader.onloadend = function(e){
      var content = e.target.result;
      jQuery('#content-upload-info').html('<p>'+htmlSpecialChars(content)+'</p>').show(500);
      try{
        var package = getPropertyCaseInsensitive(jQuery.xml2json(content),'package');
        delete package.$;
        package.types.forEach(function(type){
          delete type.$;
          if(typeof type.members !== 'object') {
            type.members = [type.members];
          }
        })
        that._package = package;
      } catch(e){
        jQuery('#error-upload').html('<p>' + htmlSpecialChars(''+e) + '</p>').show(500);
        return;
      }
      jQuery('#content-upload-success').html('<p>File ok</p>');
      jQuery('#content-retrieve-info').html('<p>' + JSON.stringify(that._package, null,1) + '</p>');
      jQuery('.retrieve-process').show(500);
    };
  },

  // Public members
  createPackage = function(file){
    jQuery('#error-upload').html('');
    if (!file) {
        var error = 'No file selected';
        jQuery('#error-upload').html('<p>'+error+'</p>');
        return;
    }
    this._file = file;
    if(file.type === 'text/csv'){
      createPackageCSV.call(this);
    } else if(file.type === 'text/xml') {
      createPackageXML.call(this);
    }
  },

  retrievePackage = function() {
    var that = this;
    this.retrieveConn.metadata.retrieve({ unpackaged:this._package })
    .complete(function(err, result) {
      if (err) { jQuery('#error-retrieve').html('<p>'+err+'</p>'); return;}
      var a = document.createElement('a'); a.href = "data:application/zip;base64," + result.zipFile; a.download = (new Date()).toLocaleString()+'.zip'; a.click();
      that._zipContent = result.zipFile;
      jQuery('#content-retrieve-success').html("<p>Statut : "+result.status+'</p>');
      jQuery('.deployment-process').show(500);
    });
  },

  deployPackage = function(options) {
    var that = this;
    if(options.testLevel === 'RunSpecifiedTests') {
      options.runTests = this._tests;
    }
    this.deployConn.metadata.deploy(that._zipContent, options)
    .complete(function(err, result) {
      if (err) { jQuery('#error-deploy').html('<p>'+err+'</p>'); return;}
      jQuery('#content-deploy-success').html('<p>'+result.status+'</p>');
      jQuery('#content-deploy-info').html('<p>'+
          'done ? :' + result.done + ', \n'
      + 'success ? : ' + result.true + ', \n'
      + 'state : ' + result.state + ', \n'
      + 'component errors: ' + result.numberComponentErrors + ', \n'
      + 'components deployed: ' + result.numberComponentsDeployed + ', \n'
      + 'tests completed: ' + result.numberTestsCompleted
      +'</p>');
      jQuery('#content-deploy-info').show(500);
      that.deployConn.metadata.checkDeployStatus(result.id,true,function(error,res){
        if (err) { jQuery('#error-deploy').html('<p>'+error+'</p>'); return;}
        jQuery('#content-deploy-info').append('<p>'+JSON.stringify(res.details,null,1)+'</p>');
      })
    });
  };

  return {
    createPackage : createPackage,
    retrievePackage : retrievePackage,
    deployPackage : deployPackage
  };
}();

var getPropertyCaseInsensitive = function (obj, property) {
  if(typeof obj === 'object'){
    for (var i in obj) if (obj.hasOwnProperty(i)) {
      if(i.toLowerCase() === property.toLowerCase()) {
        return obj[i];
      }
    }
  }
  return "";
}

var htmlSpecialChars = function (unsafe) {
  return unsafe
  .replace(/&/g, "&amp;")
  .replace(/</g, "&lt;")
  .replace(/>/g, "&gt;")
  .replace(/"/g, "&quot;");
}

jQuery.extend({
  getUrlVars: function(){
    var vars = [];
    var hashes = window.location.href.slice(window.location.href.indexOf('#') + 1).split('&');
    hashes.forEach(function(hash){
      var parameter = hash.split('=');
      vars.push(parameter[0]);
      vars[parameter[0]] = parameter[1];
    });
    return vars;
  },
  getUrlVar: function(name){
    return jQuery.getUrlVars()[name];
  }
});