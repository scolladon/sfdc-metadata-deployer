/*
TODO
  - Handle deconnexion :)
  - Handle deletion (pre and post)
  - Allow giving github repo to see
*/
jQuery.noConflict();
jQuery(function(){
  var dep = new Deployment(),
      at = jQuery.getUrlVar('access_token'),
      iu = jQuery.getUrlVar('instance_url');
  if(at && iu) {
    var state = JSON.parse(decodeURIComponent(jQuery.getUrlVar('state')));
    localStorage.setItem(state.prefix,JSON.stringify({accessToken:decodeURIComponent(at),instanceUrl:decodeURIComponent(iu)}));
    jQuery('#'+state.prefix+'-prod').prop('checked', state.env === 'login');
    var options = {env:state.env};
    if(state.prefix === 'retrieve') {
      dep.retrievePackage(options)
      .then(HandleRetrieve.success)
      .catch(HandleRetrieve.error);
    } else if (state.prefix === 'deploy') {
      dep.deployPackage(options)
      .then(HandleDeploy.success)
      .catch(HandleDeploy.error);
    }
  }
  //window.history.pushState(null, "Salesforce Metadata Deployment", "/apex/deployment");
  jQuery('#retrieve-prod').change(function(){
    OAuthHelper.resetConn('retrieve');
  });

  jQuery('#retrieve-reset').click(function(){
    OAuthHelper.resetConn('retrieve');
  });

  jQuery('#deploy-prod').change(function(){
    OAuthHelper.resetConn('deploy');
  });

  jQuery('#deploy-reset').click(function(){
    OAuthHelper.resetConn('deploy');
  });

  jQuery('.deploy').on('drop', function(e) {
    if(e.originalEvent.dataTransfer
      && e.originalEvent.dataTransfer.files.length){
      var file = e.originalEvent.dataTransfer.files[0];
      var read = new Promise(function(rs,rj) {
        var reader = new FileReader();
        reader.onerror = rj;
        reader.onload = rs;
        reader.readAsBinaryString(file);
      })
      e.preventDefault();
      e.stopPropagation();
      read.then(function(resolve,reject) {
        sessionStorage.setItem('zip', Base64String.compress(btoa(e.target.result)));
        var options = {};
        options.testLevel = jQuery('.radio :checked').val();
        options.rollbackOnError = jQuery('#rollback').is(':checked');
        options.checkOnly = jQuery('#check').is(':checked');
        options.env = jQuery('#deploy-prod').is(':checked') ? 'login' : 'test';
        dep.deployPackage(options)
        .then(HandleDeploy.success)
        .catch(HandleDeploy.error);
      });
    }
    jQuery(this).removeClass('drop');
    return false;
  });

  jQuery('.retrieve').on('drop', function(e) {
    if(e.originalEvent.dataTransfer
      && e.originalEvent.dataTransfer.files.length){
       e.preventDefault();
       e.stopPropagation();
       var file = e.originalEvent.dataTransfer.files[0];
       dep.retrievePackage({file:file,env:jQuery('#deploy-prod').is(':checked') ? 'login' : 'test'})
       .then(HandleRetrieve.success)
       .catch(HandleRetrieve.error);
    }
    jQuery(this).removeClass('drop');
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

var ConnectionHelper = function() {};
ConnectionHelper.prototype = function(){
  var getConn = function(authOptions){
    var options = localStorage.getItem(authOptions.prefix);
    if(options) {
      options = JSON.parse(options);
      var conn = new jsforce.Connection({
        instanceUrl : options.instanceUrl,
        accessToken : options.accessToken,
        proxyUrl : '/services/proxy'
      });
      conn.metadata.pollTimeout= 3000000;
      return conn;
    } else {
      window.open('https://'+ authOptions.env + '.salesforce.com/services/oauth2/authorize?response_type=token&client_id='+encodeURIComponent(ConnectedAppConfig.clientId)+'&redirect_uri='+encodeURIComponent(ConnectedAppConfig.redirectUri)+'&scope=api&display=popup&state='+encodeURIComponent(JSON.stringify(authOptions)),'_self');
    }
  },
  resetConn = function(prefix) {
    localStorage.removeItem(prefix);
  };
  return {
    getConn: getConn,
    resetConn: resetConn
  };
}();
var OAuthHelper = new ConnectionHelper();

var Deployment = function() {
  this._tests = [];
};
Deployment.prototype = function(){

  var createPackageCSV = function(options){
    var that = this;
    return new Promise(function(resolve,reject){
      Papa.parsePromise(options.file)
      .then(function(results) {
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
          type.members.indexOf(member) === -1) {
          type.members.push(member);
            member = member.toLowerCase();
            if(typename === 'ApexClass' && member.indexOf("test") > -1){
              that._tests.push(member);
            }
          }
        });
        options.package = package;
        sessionStorage.setItem('retrieve-options',JSON.stringify(options));
        resolve(options);
      })
      .catch(reject);
    });
  },

  createPackageXML = function(options){
    var that = this;
    return new Promise(function(resolve,reject){
      var read = new Promise(function(rs,rj) {
        var reader = new FileReader();
        reader.onerror = rj;
        reader.onload = rs;
        reader.readAsText(options.file);
      });
      read.then()
      .then(function(e){
        var content = e.target.result;
        try{
          content = content.replace('<?xml version="1.0" encoding="UTF-8"?>','');
          var package = getPropertyCaseInsensitive(jQuery.xml2json(content),'package');
          delete package.$;
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
            if(type.name === 'ApexClass') {
              type.members.forEach(function(mem){
                mem = mem.toLowerCase();
                if(mem.indexOf("test") > -1){
                  that._tests.push(mem);
                }
              })
            }
          });
          options.package = package;
          sessionStorage.setItem('retrieve-options',JSON.stringify(options));
          resolve(options);
        } catch(e){
          reject(htmlSpecialChars(''+e));
        }
      }).catch(reject);
    });
  },

  retrievePackage = function(options){
    return new Promise(function(resolve,reject){
      // TODO handle arguments
      optionsFromLocalStorage = JSON.parse(sessionStorage.getItem('retrieve-options'));
      if(optionsFromLocalStorage && optionsFromLocalStorage.package) {
        return doRetrieve(optionsFromLocalStorage)
        .then(resolve)
        .catch(reject);
      }
      if (!options.file) {return reject('No file selected');}
      var createPackage;
      var extension = options.file.name.split('.').pop();
      if(extension === 'csv'){
        createPackage = createPackageCSV;
      } else if(extension === 'xml') {
        createPackage = createPackageXML;
      } else {
        reject('File type not supported');
      }
      createPackage(options)
      .then(doRetrieve)
      .then(resolve)
      .catch(reject);
    })
  },

  deployPackage = function(options) {
    return new Promise(function(resolve,reject) {
      var conn = OAuthHelper.getConn({prefix:'deploy',env:options.env});
      if(!conn) {resolve('Authent in progress')}
      delete options.env;
      conn.metadata.deploy(Base64String.decompress(sessionStorage.getItem('zip')), options)
      .complete(true,function(error, result) {
        sessionStorage.removeItem('zip');
        localStorage.removeItem('deploy');
        if (error) {return reject(error);}

        resolve(result);
      });
    });
  },

  doRetrieve = function(options) {
    if(!options.package){
      options.package = JSON.parse(sessionStorage.getItem('package'));
    }
    return new Promise(function(resolve,reject){
      var conn = OAuthHelper.getConn({prefix:'retrieve',env:options.env});
      if(!conn) {resolve('Authent in progress')}
      conn.metadata.retrieve({ unpackaged:options.package })
      .complete(function(err, result) {
        sessionStorage.removeItem('package');
        localStorage.removeItem('retrieve');
        if (err) {return reject(err);}
        var a = document.createElement('a'); a.href = "data:application/zip;base64," + result.zipFile; a.download = (new Date()).toLocaleString()+'.zip'; a.click();
        resolve(options.package);
      });
    });
  };

  return {
    retrievePackage : retrievePackage,
    deployPackage : deployPackage
  };
}();

var HandleRetrieve = {
  success : function(res){
    jQuery('.retrieve-message').append('<pre class="alert-success">'+JSON.stringify(res,null,2)+'</pre>').show(500);
  }, error : function(err){
    jQuery('.retrieve-message').append('<p class="alert-error">'+JSON.stringify(err,null,2)+'</p>').show(500);
  }
};

var HandleDeploy = {
  success : function(res){
    jQuery('.deploy-message').append('<pre class="alert-success">'+JSON.stringify(res,null,2)+'</pre>').show(500);
  }, error : function(err){
    jQuery('.deploy-message').append('<p class="alert-error">'+JSON.stringify(err,null,2)+'</p>').show(500);
  }
};

Papa.parsePromise = function(file) {
  return new Promise(function(resolve, reject) {
    Papa.parse(file, { complete: resolve, error: reject });
  });
};

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