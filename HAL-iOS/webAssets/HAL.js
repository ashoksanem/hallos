var windowsConnector = (function windowsConnector() {
    'use strict';

    return function windowConnectorConstructor() {
        var _this = this;

        _this.passDataToWeb = function (data) {
            //window.alert(data);
            console.log(data);
            return 13;
        };

        _this.util = function() {
            _this.util.amIinHal = function () {
                //this check lets us know if we're in a normal web browers or HAL.
                if( typeof(webInterface) == "undefined" )
                    return _this.passDataToWeb(`{"amIinHal" : "false"}`);
        
                webInterface.amIinHal();
            };

            _this.util.storeData = function (key, val) {
                console.log(`${key} data stored: ${webInterface.storeData(key, val)}`);
            };

            _this.util.restoreData = function (key) {
                return webInterface.restoreData(key);
            };

            _this.util.getLocationInformation = function () {
                var junk = `{
                    "LocationInformation": {
                        "DivInfo": {"Num": "71", },
                        "StoreInfo": { "Num": "166" }
                    }
                }`;

                return junk;
            };
                        
            _this.util.objectToString = function( object ) {
                 jsonStr = JSON.stringify(message),  // THE OBJECT STRINGIFIED
                 regeStr = '', // A EMPTY STRING TO EVENTUALLY HOLD THE FORMATTED STRINGIFIED OBJECT
                     f = {
                         brace: 0
                     };
                     var regeStr = jsonStr.replace(/({|}[,]*|[^{}:]+:[^{}:,]*[,{]*)/g, function (m, p1) {
                                                      var rtnFn = function() {
                                                      return '<div style="text-indent: ' + (f['brace'] * 20) + 'px;">' + p1 + '</div>';
                                                      },
                                                      rtnStr = 0;
                                                      if (p1.lastIndexOf('{') === (p1.length - 1)) {
                                                      rtnStr = rtnFn();
                                                      f['brace'] += 1;
                                                      } else if (p1.indexOf('}') === 0) {
                                                      f['brace'] -= 1;
                                                      rtnStr = rtnFn();
                                                      } else {
                                                      rtnStr = rtnFn();
                                                      }
                                                      return rtnStr;
                                                      });
                    return regeStr;
            };

        }; // _this.util
        _this.util();

        // a collection of functions for associate authentication
        _this.sso = function () {

            // returns the currently logged in associate. If nobody is logged in throw exception
            _this.sso.getAuthenticatedAssociate = function () {
                //if( false )
                    //throw new Error();

                var junkAssociate = `{
                    "Associate": {
                        "ErrorInfo": { "errorCode": "0" },
                        "JWTTokenInfo": { "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6Imp3dCJ9.eyJhdXRobWV0aG9kIjoiYWQiLCJDb21tb25OYW1lIjoiQjQxNTU3MCIsImlzcyI6ImNvbS5tYWN5cy5hc3NvY2lhdGVhdXRoZW50aWNhdGUiLCJTYW1BY2NvdW50TmFtZSI6IkI0MTU1NzAiLCJVc2VyTmFtZSI6IkI0MTU1NzAiLCJEaXNwbGF5TmFtZSI6IkJyaWFuIERlbWJpbnNraSIsIkRpc3Rpbmd1aXNoZWROYW1lIjoiQ049QjQxNTU3MCxPVT1Vc2VycyxPVT1GU0csREM9ZmVkZXJhdGVkLERDPWZkcyIsIkxhc3ROYW1lIjoiRGVtYmluc2tpIiwiRW1wbG95ZWVJRCI6IjAxNDE1NTcwIiwiZXhwIjoxNDczODgxNjMzLCJHaXZlbk5hbWUiOiJCcmlhbiIsIk1lbWJlck9mIjoiQ049TVNULVN0b3Jlc0RvbWFpbi1Vc2VycyxPVT1Hcm91cHMsT1U9X0ZlZGVyYXRlZCxEQz1mZWRlcmF0ZWQsREM9ZmRzIiwiVXNlclByaW5jaXBhbE5hbWUiOiJCNDE1NTcwQGZlZGVyYXRlZC5mZHMiLCJNYWlsIjoiYnJpYW4uZGVtYmluc2tpQG1hY3lzLmNvbSIsIlVpZCI6bnVsbH0.ksOHA1ULHGgB3UT3YZhxZ-HB8ObvsJHe1jXCGyuVA_xzU7tu_HTNqerUmQuaN6TZv5DtyDJ1mjqOr_oa3Q3q0hwK43G1ZQL0tNWrecVkKYd6YuKmslMUU6xUVEk-itvPxFeMceNu1KwFlGjtUpakUGH1O_T1hNNRrE8LwY-BTDOaGmylGQTLRgPQbJcKv_k0GoNlpnimLwMsGr8OWhVSTBqbVJB98dbO0ebH-4exertfko2Xn7Kunn9WMUDTil08Xb99Nj1M7NR-_qexlbBmdwr_XrNH74bCum12zGSVPIlT2_M2kpUb5oLRpoNof5ANJI-eqN0WGsfevqL2NajrCw" },
                        "AssociateInfo": { "userid": "B415570" },
                        "ADGrpList": {
                            "adGrp": [
                                "Users",
                                "Domain Users",
                                "WEBSENSE_FULL"
                                ]
                            }
                        }
                    }`;

                return junkAssociate;
            };

            // if no parameters are passed the sign on page has empty text fields
            // if a user parameter is passed that user will be prepopulated in the user text field
            // if a forceRacf parameter is passed as true we will force the user to enter a RACF (more than 4 characters)
            _this.sso.authenticateAssociate = function (user, forceRacf) {
                console.log(`user: ${user}`);
                console.log(`forceRacf: ${forceRacf}`);

                return _this.sso.getAuthenticatedAssociate();
            };

            // remove all information about the user and display the sign on page
            _this.sso.logoutAssociate  = function() {
                console.log(`logoutAssociate: associate is logged out.`);
            };

            _this.sso.getJwtPublicKey = function () {
                var resp = associateAuthentication.getJwtPublicKey();
                return resp;
            };

        }; // _this.sso
        _this.sso();

        _this.peripheral = function () {
            _this.peripheral.scanner = function () {
                _this.peripheral.scanner.enable = function () {
                    webInterface.enableScanner(); 
                };
            }; // _this.peripheral.scanner
            _this.peripheral.scanner();

        }; // _this.peripheral
        _this.peripheral();
    };

}());

function iosConnector() {
    'use strict';

    function passDataToWeb(data) {
        window.alert(data);
        return 13;
    };
    this.passDataToWeb = passDataToWeb;
    function launchSSOPage() {
        document.getElementById("halmsg").innerHTML="";
        webkit.messageHandlers.launchSSOPage.postMessage(" ");
    };
    this.launchSSOPage = launchSSOPage;
    
    // a collection of functions for associate authentication
    this.sso = function () {
        
        // returns the currently logged in associate. If nobody is logged in throw exception
        this.sso.getAuthenticatedAssociate = function () {
            //if( false )
            //throw new Error();
            
            var junkAssociate = `{
                "Associate": {
                    "ErrorInfo": { "errorCode": "0" },
                    "JWTTokenInfo": { "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6Imp3dCJ9.eyJhdXRobWV0aG9kIjoiYWQiLCJDb21tb25OYW1lIjoiQjQxNTU3MCIsImlzcyI6ImNvbS5tYWN5cy5hc3NvY2lhdGVhdXRoZW50aWNhdGUiLCJTYW1BY2NvdW50TmFtZSI6IkI0MTU1NzAiLCJVc2VyTmFtZSI6IkI0MTU1NzAiLCJEaXNwbGF5TmFtZSI6IkJyaWFuIERlbWJpbnNraSIsIkRpc3Rpbmd1aXNoZWROYW1lIjoiQ049QjQxNTU3MCxPVT1Vc2VycyxPVT1GU0csREM9ZmVkZXJhdGVkLERDPWZkcyIsIkxhc3ROYW1lIjoiRGVtYmluc2tpIiwiRW1wbG95ZWVJRCI6IjAxNDE1NTcwIiwiZXhwIjoxNDczODgxNjMzLCJHaXZlbk5hbWUiOiJCcmlhbiIsIk1lbWJlck9mIjoiQ049TVNULVN0b3Jlc0RvbWFpbi1Vc2VycyxPVT1Hcm91cHMsT1U9X0ZlZGVyYXRlZCxEQz1mZWRlcmF0ZWQsREM9ZmRzIiwiVXNlclByaW5jaXBhbE5hbWUiOiJCNDE1NTcwQGZlZGVyYXRlZC5mZHMiLCJNYWlsIjoiYnJpYW4uZGVtYmluc2tpQG1hY3lzLmNvbSIsIlVpZCI6bnVsbH0.ksOHA1ULHGgB3UT3YZhxZ-HB8ObvsJHe1jXCGyuVA_xzU7tu_HTNqerUmQuaN6TZv5DtyDJ1mjqOr_oa3Q3q0hwK43G1ZQL0tNWrecVkKYd6YuKmslMUU6xUVEk-itvPxFeMceNu1KwFlGjtUpakUGH1O_T1hNNRrE8LwY-BTDOaGmylGQTLRgPQbJcKv_k0GoNlpnimLwMsGr8OWhVSTBqbVJB98dbO0ebH-4exertfko2Xn7Kunn9WMUDTil08Xb99Nj1M7NR-_qexlbBmdwr_XrNH74bCum12zGSVPIlT2_M2kpUb5oLRpoNof5ANJI-eqN0WGsfevqL2NajrCw" },
                    "AssociateInfo": { "userid": "B415570" },
                    "ADGrpList": {
                        "adGrp": [
                                  "Users",
                                  "Domain Users",
                                  "WEBSENSE_FULL"
                                  ]
                    }
                }
            }`;
            
            return junkAssociate;
        };
        this.sso.getAuthenticatedAssociate()
        // if no parameters are passed the sign on page has empty text fields
        // if a user parameter is passed that user will be prepopulated in the user text field
        // if a forceRacf parameter is passed as true we will force the user to enter a RACF (more than 4 characters)
        this.sso.authenticateAssociate = function (user, forceRacf) {
            console.log(`user: ${user}`);
            console.log(`forceRacf: ${forceRacf}`);
            webkit.messageHandlers.launchSSOPage.postMessage(" ");
            //return this.sso.getAuthenticatedAssociate;
        };
        
        // remove all information about the user and display the sign on page
        this.sso.logoutAssociate  = function() {
            webkit.messageHandlers.logoutAssociate.postMessage(" ");
        };
        
        this.sso.getJwtPublicKey = function () {
            var resp = associateAuthentication.getJwtPublicKey();
            return resp;
        };
        
    }; // _this.sso
    this.sso();
    
    this.util = function () {
        this.util.getDeviceId = function ( callback ) {
            webkit.messageHandlers.getDeviceId.postMessage( String( callback ) );
        };
    };
    this.util();
    
    function enableScanner( val ) {
        if( webInterface === undefined )
            return ({"amIinHal" : "false"});
        
        webInterface.enableScanner( val ); 
    }
    this.enableScanner = enableScanner;
    
    function amIinHal()
    {
        if( typeof(webInterface) == "undefined" )
            return passXmlDataToWeb(`{"amIinHal" : "false"}`);
        
        webInterface.amIinHal();
    }
    this.amIinHal = amIinHal;
};

function MSTWebBrowserConnector() {
    'use strict';
    var instance;

    function getInstance() {

        if (instance === null || instance === undefined) {
            var iOS = /(iPad|iPhone|iPod)/g.test(navigator.userAgent),
                isSafari = /(Safari)/g.test(navigator.userAgent),
                windows = /(Windows)/g.test(navigator.userAgent),
                android = /(Android)/g.test(navigator.userAgent);
            debugger;
            if (iOS || isSafari) {
                //				var v = (navigator.appVersion).match(/OS (\d+)_(\d+)_?(\d+)?/);
                //				var ver = [parseInt(v[1], 10), parseInt(v[2], 10), parseInt(v[3] || 0, 10)];
                //				if(ver[0] < 7) {
                instance = new iosConnector();
                //				}
            } else if (windows) {
                instance = new windowsConnector();
            } else if (android) {
                window.console.log("Android!");
                instance = AndroidMSTWebBrowser;
            }
        }
        return instance;
    }
    this.getInstance = getInstance;
}

var HAL = new MSTWebBrowserConnector().getInstance();




function showIOSAlert(){
    webkit.messageHandlers.showIOSAlert.postMessage(" ");
}

function authenticateUser(){
    webkit.messageHandlers.authenticateUser.postMessage(" ");
}
function amInHal(message){
    webkit.messageHandlers.amInHal.postMessage(" ");
}
function passSSOData(message){
    document.getElementById("halmsg").innerHTML=message;
}
function launchSSOPage(message){
    webkit.messageHandlers.launchSSOPage.postMessage(" ");
}
function clear() {
    alert("clearing");
    document.getElementById("halmsg").innerHTML="";
}
function isSSOAuthenticated() {
    webkit.messageHandlers.isSSOAuthenticated.postMessage(" ");
}
function passDataToWeb(message){
    jsonStr = JSON.stringify(message),  // THE OBJECT STRINGIFIED
    regeStr = '', // A EMPTY STRING TO EVENTUALLY HOLD THE FORMATTED STRINGIFIED OBJECT
    f = {
    brace: 0
    };
    var regeStr = jsonStr.replace(/({|}[,]*|[^{}:]+:[^{}:,]*[,{]*)/g, function (m, p1) {
                                  var rtnFn = function() {
                                  return '<div style="text-indent: ' + (f['brace'] * 20) + 'px;">' + p1 + '</div>';
                                  },
                                  rtnStr = 0;
                                  if (p1.lastIndexOf('{') === (p1.length - 1)) {
                                  rtnStr = rtnFn();
                                  f['brace'] += 1;
                                  } else if (p1.indexOf('}') === 0) {
                                  f['brace'] -= 1;
                                  rtnStr = rtnFn();
                                  } else {
                                  rtnStr = rtnFn();
                                  }
                                  return rtnStr;
                                  });
    document.getElementById("halmsg").innerHTML=regeStr;
}
function sendSSOAuthenticationMessageToWeb(message){
    jsonStr = JSON.stringify(message),
    regeStr = '',
    f = {
    brace: 0
    };
    var regeStr = jsonStr.replace(/({|}[,]*|[^{}:]+:[^{}:,]*[,{]*)/g, function (m, p1) {
                                  var rtnFn = function() {
                                  return '<div style="text-indent: ' + (f['brace'] * 20) + 'px;">' + p1 + '</div>';
                                  },
                                  rtnStr = 0;
                                  if (p1.lastIndexOf('{') === (p1.length - 1)) {
                                  rtnStr = rtnFn();
                                  f['brace'] += 1;
                                  } else if (p1.indexOf('}') === 0) {
                                  f['brace'] -= 1;
                                  rtnStr = rtnFn();
                                  } else {
                                  rtnStr = rtnFn();
                                  }
                                  return rtnStr;
                                  });
    document.getElementById("SSOMessage").innerHTML=regeStr;
}


