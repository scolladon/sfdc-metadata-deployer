// TODO
/*
  allow giving github repo to see
  change environment
*/
jQuery.noConflict();
  var retrieve_config,
  deploy_config;
jQuery(function(){
      var accessToken_query = jQuery.getUrlVar('access_token'),
      instanceUrl_query = jQuery.getUrlVar('instance_url'),
      state = jQuery.getUrlVar('state'),
      dep = new Deployment();
  //window.history.pushState(null, "Salesforce Metadata Deployment", "/apex/deployment");
  if(typeof accessToken_query !== 'undefined'
  && typeof instanceUrl_query !== 'undefined'){
    if(typeof state !== 'undefined') {
      state = JSON.parse(decodeURIComponent(state));
      if(state.status === '0') {
        retrieve_config = new Oauth2Settings(decodeURIComponent(instanceUrl_query),decodeURIComponent(accessToken_query));
        dep = new Deployment(retrieve_config,deploy_config);
        var package = JSON.parse(sessionStorage.getItem('package'));
        console.log(JSON.stringify(package));
        console.log('package');
        dep.doRetrieve(package);
      } else if(state.status === '1') {
        deploy_config = new Oauth2Settings(decodeURIComponent(instanceUrl_query),decodeURIComponent(accessToken_query));
        retrieve_config = new Oauth2Settings(state.instanceUrl,state.accessToken);
        dep = new Deployment(retrieve_config,deploy_config);
        // TODO store options :(
        var options = {};
        options.testLevel = jQuery('.radio :checked').val();
        options.rollbackOnError = jQuery('#rollback').is(':checked');
        options.checkOnly = jQuery('#check').is(':checked');
        dep.deployPackage(options);
      }
    }
  }
  // Add all evenment on the page
  jQuery('.deploy').on('drop', function(e) {
    sessionStorage.removeItem('package');
    if(e.originalEvent.dataTransfer){
      if(e.originalEvent.dataTransfer.files.length) {
         // Stop the propagation of the event
        e.preventDefault();
        e.stopPropagation();
         // Main function to upload
        var file = e.originalEvent.dataTransfer.files[0];
        var reader = new FileReader();
        reader.onload = function(){
          sessionStorage.setItem('zip', btoa(e.target.result));
          // TODO check if it is a zip file
          var options = {};
          options.testLevel = jQuery('.radio :checked').val();
          options.rollbackOnError = jQuery('#rollback').is(':checked');
          options.checkOnly = jQuery('#check').is(':checked');
          dep.deployPackage(options);
        };
        reader.readAsBinaryString(file);
      }
    }
    jQuery(this).css('border', '');
    return false;
  });

  jQuery('.retrieve').on('drop', function(e) {
    console.log('dropped');
    console.log(e);
    if(e.originalEvent.dataTransfer){
       if(e.originalEvent.dataTransfer.files.length) {
         // Stop the propagation of the event
         e.preventDefault();
         e.stopPropagation();
         dep.retrievePackage(e.originalEvent.dataTransfer.files[0]);
       }
    }
    jQuery(this).css('border', '');
    return false;
  });

  jQuery(".drop-zone").on("dragover", function(event) {
    event.preventDefault();
    event.stopPropagation();
    jQuery(this).addClass('drop');
  });

  jQuery(".drop-zone").on("dragleave", function(event) {
    event.preventDefault();
    event.stopPropagation();
    jQuery(this).removeClass('drop');
  });
});

var Oauth2Settings = function(instanceUrl,accessToken) {
  this.instanceUrl = instanceUrl;
  this.accessToken = accessToken;
}

/*
  Deployment class
*/
var Deployment = function(retrieve_config,deploy_config) {
  this._tests = [];
  this.retrieveConn;
  this.deployConn;
  if(typeof retrieve_config !== 'undefined'){
    this.retrieveConn = new jsforce.Connection({
      instanceUrl : retrieve_config.instanceUrl,
      accessToken : retrieve_config.accessToken,
      proxyUrl : '/services/proxy'
    });
    this.retrieveConn.metadata.pollTimeout= 3000000;
  }
  if(typeof deploy_config !== 'undefined'){
    this.deployConn = new jsforce.Connection({
      instanceUrl : deploy_config.instanceUrl,
      accessToken : deploy_config.accessToken,
      proxyUrl : '/services/proxy'
    });
    this.deployConn.metadata.pollTimeout= 3000000;
  }
}

Deployment.prototype = function(){

  // Private members
  var createPackageCSV = function(file){
    var that = this;
    Papa.parse(file, {
      complete: function(results) {
        // init
        var package = {}
        package.types = [];
        package.version = '34.0';
        that._tests = [];

        var types = package.types;
        results.data.shift();
        results.data.forEach(function(row){
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
        });
        doRetrieve.call(that, package);
      }
    });
  },

  createPackageXML = function(file){
    var that = this;
    var reader = new FileReader();
    reader.onloadend = function(e){
      var content = e.target.result;
      console.log(content);
      try{
        if(content.indexOf('<?xml') !== -1){ // TODO make it works
          jQuery('.retrieve-message').append('<p class="list-group-item list-group-item-error"><span class="badge alert-error pull-right">Error</span>Remove the "<?>" tags</p>').show(500);
          return;
        }
        var package = getPropertyCaseInsensitive(jQuery.xml2json(content),'package');
        delete package.$;
        console.log(package);
        // TODO Implement tests remember
        if(package.types.constructor !== Array) {
          var type = package.types;
          package.types = [];
          package.types.push(type);
        }
        package.types.forEach(function(type){
          delete type.$;
          if(typeof type.members !== 'object') {
            type.members = [type.members];
          }
        });
        doRetrieve.call(that,package);
      } catch(e){
        console.log(e);
        jQuery('.retrieve-message').append('<p class="list-group-item list-group-item-error"><span class="badge alert-error pull-right">Error</span>'+htmlSpecialChars(''+e)+'</p>').show(500);
      }
    };
    reader.readAsText(file);
  },

  // Public members
  retrievePackage = function(file){
    if (!file) {
        var error = 'No file selected';
         jQuery('.retrieve-message').append('<p class="list-group-item list-group-item-error"><span class="badge alert-error pull-right">Error</span>'+error+'</p>').show(500);
        return;
    }
    if(file.type === 'text/csv'){
      createPackageCSV.call(this, file);
    } else if(file.type === 'text/xml') {
      createPackageXML.call(this, file);
    }
  },

  deployPackage = function(options) {
    var that = this;
    if(typeof this.deployConn === 'undefined') {
      var state = {
        status : '1',
        instanceUrl : retrieve_config.instanceUrl,
        accessToken : retrieve_config.accessToken
      };
      var url = 'https://'+(jQuery('#retrieve-prod').is(':checked') ? 'login' : 'test') + '.salesforce.com/services/oauth2/authorize?response_type=token&client_id='+Oauth2AppConfig.clientId+'&redirect_uri='+Oauth2AppConfig.redirectUri+'&prompt=login&display=popup&state='+encodeURIComponent(JSON.stringify(state));
      window.open(url,'_self');
      return;
    }

    if(options.testLevel === 'RunSpecifiedTests') {
      options.runTests = this._tests;
    }
    this.deployConn.metadata.deploy(sessionStorage.getItem('zip'), options)
    .complete(function(err, result) {
      if (err) {
        jQuery('.deploy-message').append('<p class="list-group-item list-group-item-error"><span class="badge alert-error pull-right">Error</span>'+err+'</p>').show(500);
        return;
      }
      jQuery('.deploy-message').append('<p class="list-group-item list-group-item-success"><span class="badge alert-success pull-right">Success</span>'+result.status+'</p>').show(500);
      jQuery('#deploy-info').html('<p>'+
          'done ? :' + result.done + ', \n'
      + 'success ? : ' + result.true + ', \n'
      + 'state : ' + result.state + ', \n'
      + 'component errors: ' + result.numberComponentErrors + ', \n'
      + 'components deployed: ' + result.numberComponentsDeployed + ', \n'
      + 'tests completed: ' + result.numberTestsCompleted
      +'</p>').show(500);
      that.deployConn.metadata.checkDeployStatus(result.id,true,function(error,res){
        if (err) {
          jQuery('.deploy-message').append('<p class="list-group-item list-group-item-error"><span class="badge alert-error pull-right">Error</span>'+err+'</p>').show(500);
          return;
        }
        jQuery('#deploy-info').append('<p>'+JSON.stringify(res.details,null,1)+'</p>');
      })
    });
  },

  doRetrieve = function(package) {
    var that = this;
    if(typeof this.retrieveConn === 'undefined') {
      sessionStorage.setItem('package',JSON.stringify(package));
      var state = {status : '0'};
      var url = 'https://'+(jQuery('#retrieve-prod').is(':checked') ? 'login' : 'test') + '.salesforce.com/services/oauth2/authorize?response_type=token&client_id='+Oauth2AppConfig.clientId+'&redirect_uri='+Oauth2AppConfig.redirectUri+'&prompt=login&display=popup&state='+encodeURIComponent(JSON.stringify(state));
      window.open(url,'_self');
      return;
    }
    jQuery('.retrieve-message').append('<p class="list-group-item list-group-item-success"><span class="badge alert-success pull-right">Success</span>Package parsed</p>').show(500);
    jQuery('.retrieve-info').html(JSON.stringify(package, null,1)).show(500);
    this.retrieveConn.metadata.retrieve({ unpackaged:package })
    .complete(function(err, result) {
      if (err) {
        jQuery('.retrieve-message').append('<p class="list-group-item list-group-item-error"><span class="badge alert-error pull-right">Error</span>'+err+'</p>').show(500);
        return;
      }
      var a = document.createElement('a'); a.href = "data:application/zip;base64," + result.zipFile; a.download = (new Date()).toLocaleString()+'.zip'; a.click();
      jQuery('.retrieve-message').append('<p class="list-group-item list-group-item-success"><span class="badge alert-success pull-right">Success</span>'+result.status+'</p>').show(500);
    });
  };

  return {
    retrievePackage : retrievePackage,
    deployPackage : deployPackage,
    doRetrieve : doRetrieve
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